extends KinematicBody

const ControlSurface = preload("res://scripts/ControlSurface.gd")

class Local:
	var longitudinal : float # Vector3.FORWARD
	var lateral : float # Vector3.LEFT
	var vertical : float # Vector3.UP
	func _init(lon, lat, ver):
		longitudinal = lon
		lateral = lat
		vertical = ver
	static func fromVector3(v : Vector3) -> Local:
		return Local.new(v.dot(Vector3.FORWARD), v.dot(Vector3.LEFT), v.dot(Vector3.UP))
	func toVector3() -> Vector3:
		return longitudinal * Vector3.FORWARD + lateral * Vector3.LEFT + vertical * Vector3.UP

class Euler:
	var yaw : float # Vector3.FORWARD
	var pitch : float # Vector3.LEFT
	var roll : float # Vector3.UP
	func _init(a, p, r):
		yaw = a
		pitch = p
		roll = r
	func toVector3():
		return yaw * Vector3.UP + pitch * Vector3.LEFT + roll * Vector3.FORWARD

signal race_initialized(checkpoint_count)
signal race_started(checkpoint_count)
signal race_ended(checkpoint_count)
signal checkpoint_crossed(current_checkpoint, checkpoint_count)
signal plane_destroyed()

# plane dim:
# length = 8m
# wingspan = 11m
# max speed = 600km/h ~> 170m/s | normal speed 180 km/h -> 50m/s
const LIN_SPEED := 50.0 # m/s
const LIN_ACCEL := 7.0 # m/s² , should be lesser than gravity acceleration
const MAX_LIN_SPEED := 170.0 # m/s, to compute drag, the drag will compensate lin_accel at this max speed
const MIN_LIN_SPEED := 30.0 # m/s, over this limit the lift is stronger than graviy

# at max_lin_speed, the decel due to wind drag equals to lin_accel
const WIND_DRAG := (LIN_ACCEL / (MAX_LIN_SPEED * MAX_LIN_SPEED)) # m/s² / (m/s)² = m^-1

const ELEVATOR_DRAG := 0.1 * WIND_DRAG
const ELEVATOR_STRENGTH := 0.12
const RUDDER_DRAG := 0.1 * WIND_DRAG
const RUDDER_STRENGTH := 0.045
const AILERON_DRAG := 0.06 * WIND_DRAG
const AILERON_STRENGTH := 0.35

const VERTICAL_PITCH_STRENGTH := 0.03
const LATERAL_YAW_STRENGTH := 0.015

var LINEAR_DRAG := Local.new(WIND_DRAG, WIND_DRAG * 300, WIND_DRAG * 1000)
var ANGULAR_DAMP := Euler.new(0.96, 0.96, 0.998)

# gravity
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity") # m/s²

# In local coordinates
var linear_speed := Local.new(0, 0, 0)
var angular_velocity := Euler.new(0, 0, 0)

var throttle := LIN_ACCEL
var rudder := ControlSurface.new("rudder+", "rudder-", MIN_LIN_SPEED)
var elevator := ControlSurface.new("elevator+", "elevator-", MIN_LIN_SPEED, 0.6)
var aileron := ControlSurface.new("aileron+", "aileron-", MIN_LIN_SPEED)

var map # = get_node("/root/World/Map") # TODO receive signal "map_loaded"
var crossed_checkpoints := []
enum RaceState {RACE_INITIALIZED, RACE_IN_PROGRESS, RACE_FINISHED}
var race_state = RaceState.RACE_INITIALIZED
enum PlaneState {PLANE_NORMAL, PLANE_LOCKED, PLANE_DESTROYED}
var plane_state = PlaneState.PLANE_NORMAL

var winds = {}
var total_winds := Vector3(0,0,0)

var debug_frame := 0

func _physics_process(delta : float):
	if plane_state != PlaneState.PLANE_LOCKED:
		throttle = LIN_ACCEL #Input.get_action_strength("throttle") * LIN_ACCEL
		# Aileron, elevator and rudder controls
		if Input.is_action_pressed("auto_pilot"):
			autopilot(delta, linear_speed.longitudinal)
		else:
			aileron.update_with_input(linear_speed.longitudinal, delta)
			elevator.update_with_input(linear_speed.longitudinal, delta)
		rudder.update_with_input(linear_speed.longitudinal, delta)
		
	
	if plane_state != PlaneState.PLANE_DESTROYED:
		var gravity_dir := global_transform.basis.inverse() * Vector3.DOWN
		var gravity := gravity_dir * GRAVITY
		var stall := clamp(inverse_lerp(MIN_LIN_SPEED, 0, linear_speed.longitudinal), 0, 1)
		
		# stalling, automatically put the nose down
		var rot_angle = Vector3.FORWARD.angle_to((Vector3.FORWARD + 0.75 * delta * gravity).normalized()) * stall
		if rot_angle > PI/1024:
			rotate_object_local(Vector3.FORWARD.cross(gravity_dir).normalized(), rot_angle)
		
		# Self speed relative to the wind
		var wind_relative_speed := Local.fromVector3(global_transform.basis.inverse() * -total_winds)
		wind_relative_speed.longitudinal += linear_speed.longitudinal
		wind_relative_speed.lateral += linear_speed.lateral
		wind_relative_speed.vertical += linear_speed.vertical
		
		# linear drag
		var lon_drag = pow(abs(wind_relative_speed.longitudinal), 2) * sign(wind_relative_speed.longitudinal) * (
			LINEAR_DRAG.longitudinal
			+ AILERON_DRAG * aileron.drag
			+ ELEVATOR_DRAG * elevator.drag
			+ RUDDER_DRAG * rudder.drag)
		var lat_drag = pow(abs(wind_relative_speed.lateral), 2) * sign(wind_relative_speed.lateral) * LINEAR_DRAG.lateral
		var ver_drag = pow(abs(wind_relative_speed.vertical), 2) * sign(wind_relative_speed.vertical) * LINEAR_DRAG.vertical
		
		lon_drag = sign(lon_drag) * min(abs(wind_relative_speed.longitudinal) / delta, abs(lon_drag))
		lat_drag = sign(lat_drag) * min(abs(wind_relative_speed.lateral) / delta, abs(lat_drag))
		ver_drag = sign(ver_drag) * min(abs(wind_relative_speed.vertical) / delta, abs(ver_drag))
		
		# active forces
		var local_gravity := Local.fromVector3(gravity)
		var lift := GRAVITY * (1 - stall) # lift compensates exactly the gravity, except at low speed
		
		# update linear speed
		linear_speed.longitudinal += (throttle - lon_drag + local_gravity.longitudinal) * delta
		linear_speed.lateral += (-lat_drag + local_gravity.lateral) * delta
		linear_speed.vertical += (-ver_drag + local_gravity.vertical + lift) * delta
		
		var vertical_to_pitch := -pow(abs(wind_relative_speed.vertical), 2) * sign(wind_relative_speed.vertical) * VERTICAL_PITCH_STRENGTH
		var lateral_to_yaw := pow(abs(wind_relative_speed.lateral), 2) * sign(wind_relative_speed.lateral) * LATERAL_YAW_STRENGTH
		var yaw_lift := RUDDER_STRENGTH * rudder.lift
		var pitch_lift := ELEVATOR_STRENGTH * elevator.lift
		var roll_lift := AILERON_STRENGTH * aileron.lift
		
		# update angular velocity
		angular_velocity.yaw *= pow(1 - ANGULAR_DAMP.yaw, delta)
		angular_velocity.yaw += (yaw_lift + lateral_to_yaw) * delta
		angular_velocity.pitch *= pow(1 - ANGULAR_DAMP.pitch, delta)
		angular_velocity.pitch += (pitch_lift + vertical_to_pitch) * delta
		angular_velocity.roll *= pow(1 - ANGULAR_DAMP.roll, delta)
		angular_velocity.roll += roll_lift * delta
		
		# actual motion
		var linear_motion := linear_speed.toVector3() * delta
		var angular_motion := Basis(angular_velocity.toVector3() * delta)
		global_transform.basis *= angular_motion
		
		linear_speed = Local.fromVector3(angular_motion.inverse() * linear_speed.toVector3())
		
		debug_frame += 1
		if debug_frame % 10 == 1:
			print("------------")
			print("aileron ", aileron.surface_angle / ControlSurface.ANGLE_MAX, " ", aileron.drag, " ", aileron.lift)
			print("elevator ", elevator.surface_angle / ControlSurface.ANGLE_MAX, " ", elevator.drag, " ", elevator.lift)
			print("rudder ", rudder.surface_angle / ControlSurface.ANGLE_MAX, " ", rudder.drag, " ", rudder.lift)
			print("wind rel speed ", wind_relative_speed.longitudinal, " ", wind_relative_speed.lateral, " ", wind_relative_speed.vertical)
			print("lin drag ", lon_drag, " ", lat_drag, " ", ver_drag)
			print("gravity ", local_gravity.longitudinal, " ", local_gravity.lateral, " ", local_gravity.vertical)
			print("lift ", lift)
			print("stall ", stall)
			print("yaw lift ", yaw_lift)
			print("pitch lift ", pitch_lift)
			print("roll lift ", roll_lift)
			print("vertical_to_pitch ", vertical_to_pitch)
			print("lateral_to_yaw ", lateral_to_yaw)
			print("linear_speed ", linear_speed.longitudinal, " ", linear_speed.lateral, " ", linear_speed.vertical)
			print("angular_speed ", angular_velocity.yaw, " ", angular_velocity.pitch, " ", angular_velocity.roll)

		var collision_data = move_and_collide(global_transform.basis * linear_motion)
		if collision_data != null:
			destroy()

# warning-ignore:unused_argument
func _process(delta : float):
	if Input.is_action_just_pressed("restart"):
		init_race()
	if Input.is_action_just_pressed("ui_cancel"):
		if race_state == RaceState.RACE_IN_PROGRESS:
			destroy()

func autopilot(delta : float, frontal_wind_velocity : float):
	# Maintain the plane horizontal
	var gravity_dir = global_transform.basis.inverse() * Vector3.DOWN
	var elevator_cmd = gravity_dir.dot(Vector3.BACK) * 0.8
	var aileron_cmd = gravity_dir.dot(Vector3.LEFT) * 0.4
	aileron.update_with_command(frontal_wind_velocity, delta, clamp(aileron_cmd, -1, 1))
	elevator.update_with_command(frontal_wind_velocity, delta, clamp(elevator_cmd, -1, 1))

func reset_plane(t : Transform):
	aileron.reset()
	elevator.reset()
	rudder.reset()
	throttle = LIN_ACCEL
	linear_speed.longitudinal = LIN_SPEED
	linear_speed.lateral = 0
	linear_speed.vertical = 0
	angular_velocity.yaw = 0
	angular_velocity.pitch = 0
	angular_velocity.roll = 0
	global_transform = t
	plane_state = PlaneState.PLANE_LOCKED

func get_linear_speed() -> Vector3:
	return linear_speed.toVector3() # TODO return ground speed not wind speed

func init_race():
	reset_plane(map.get_start_position())
	plane_state = PlaneState.PLANE_LOCKED
	crossed_checkpoints = []
	winds.clear()
	total_winds = Vector3.ZERO
	race_state = RaceState.RACE_INITIALIZED
	emit_signal("race_initialized", map.get_checkpoint_count())

func start_race():
	if race_state == RaceState.RACE_INITIALIZED:
		plane_state = PlaneState.PLANE_NORMAL
		race_state = RaceState.RACE_IN_PROGRESS
		emit_signal("race_started", map.get_checkpoint_count())

func end_race():
	if race_state == RaceState.RACE_IN_PROGRESS:
		if len(crossed_checkpoints) >= map.get_checkpoint_count():
			race_state = RaceState.RACE_FINISHED
			emit_signal("race_ended", map.get_checkpoint_count())

func cross_checkpoint(id):
	if race_state == RaceState.RACE_IN_PROGRESS:
		if not (id in crossed_checkpoints) and len(crossed_checkpoints) < map.get_checkpoint_count():
			crossed_checkpoints.append(id)
			emit_signal("checkpoint_crossed", len(crossed_checkpoints), map.get_checkpoint_count())

func destroy():
	if plane_state != PlaneState.PLANE_DESTROYED:
		plane_state = PlaneState.PLANE_DESTROYED
		emit_signal("plane_destroyed")

func _on_Nose_start_line_crossed():
	start_race()

func _on_Nose_finish_line_crossed():
	end_race()

func _on_Nose_checkpoint_crossed(id):
	cross_checkpoint(id)

# warning-ignore:unused_argument
func _on_body_entered(body):
	destroy()

func _on_map_loaded(map_node):
	map = map_node
	init_race()

func _on_Nose_wind_entered(area):
	if not winds.has(area):
		winds[area] = area.to_global(Vector3(0,0,100)) - area.global_transform.origin
		total_winds += winds[area]
		print("total wind: ", total_winds)

func _on_Nose_wind_exited(area):
	if winds.has(area):
		total_winds -= winds[area]
		winds.erase(area)
		print("total wind: ", total_winds)
