extends KinematicBody

signal race_initialized(checkpoint_count)
signal race_started(checkpoint_count)
signal race_ended(checkpoint_count)
signal checkpoint_crossed(current_checkpoint, checkpoint_count)
signal plane_destroyed

# plane dim:
# length = 8m
# wingspan = 11m
# max speed = 600km/h ~> 170m/s | normal speed 180 km/h -> 50m/s
const LIN_SPEED = 50.0 # m/s
const LIN_ACCEL = 7.0 # m/s² , should be lesser than gravity acceleration
const MAX_LIN_SPEED = 170.0 # m/s, to compute drag, the drag will compensate lin_accel at this max speed
const MIN_LIN_SPEED = 20 # m/s, over this limit the lift is stronger than graviy

# at max_lin_speed, the decel due to wind drag equals to lin_accel
const WIND_DRAG = (LIN_ACCEL / (MAX_LIN_SPEED*MAX_LIN_SPEED)) # m/s² / (m/s)² = m^-1
# at lin_speed, the decel due to full elevator equals to X m/s²
const ELEVATOR_DRAG = 1.0 / (LIN_SPEED*LIN_SPEED) 
const ELEVATOR_SPEED = 0.018
# at lin_speed, the decel due to full rudder equals to X m/s²
const RUDDER_DRAG = 1.0 / (LIN_SPEED*LIN_SPEED)
const RUDDER_SPEED = 0.0054
# at lin_speed, the decel due to full rudder equals to X m/s²
const AILERON_DRAG = 0.6 / (LIN_SPEED*LIN_SPEED)
const AILERON_SPEED = 0.045

# gravity
const GRAVITY = 9.8  # m/s²
const GRAVITY_DIR = Vector3(0,-1,0)

var throttle = LIN_ACCEL
var linear_speed = LIN_SPEED
var angular_velocity = Vector3(0, 0, 0)
onready var rudder = load("res://scripts/ControlSurface.gd").new(JOY_AXIS_3, -1, KEY_W, KEY_X)
onready var elevator = load("res://scripts/ControlSurface.gd").new(JOY_AXIS_1, -1, KEY_UP, KEY_DOWN, 0.6)
onready var aileron = load("res://scripts/ControlSurface.gd").new(JOY_AXIS_0, 1, KEY_RIGHT, KEY_LEFT)

var map # = get_node("/root/World/Map") # TODO receive signal "map_loaded"
var crossed_checkpoints = []
const RACE_INITIALIZED = 0 # Before crossing start line
const RACE_IN_PROGRESS = 1
const RACE_FINISHED = 2 # After crossing finish line
var race_state = RACE_INITIALIZED
const PLANE_NORMAL = 0
const PLANE_LOCKED = 1
const PLANE_DESTROYED = 2
var plane_state = PLANE_NORMAL

var winds = {}
var total_winds = Vector3(0,0,0)

func _physics_process(delta):
	
	if plane_state != PLANE_LOCKED:
		# throtle control
		if Input.is_key_pressed(KEY_A):
			throttle += delta * 5
		if Input.is_key_pressed(KEY_Q):
			throttle -= delta * 5
		throttle = min(1 - Input.get_joy_axis(0, 2), 1) * LIN_ACCEL
		# Aileron, elevator and rudder controls
		if Input.is_action_pressed("auto_pilot"):
			autopilot(delta, linear_speed)
		else:
			aileron.update_with_input(linear_speed, delta)
			elevator.update_with_input(linear_speed, delta)
		rudder.update_with_input(linear_speed, delta)
	
		angular_velocity.x = AILERON_SPEED * aileron.angular_velocity
		angular_velocity.y = ELEVATOR_SPEED * elevator.angular_velocity
		angular_velocity.z = RUDDER_SPEED * rudder.angular_velocity
	
	if plane_state != PLANE_DESTROYED:
		var gravity_dir = to_local(GRAVITY_DIR) - to_local(Vector3(0,0,0))
		var gravity = gravity_dir * GRAVITY
		var fall = 0
		var lateral_speed = 0
		if linear_speed < MIN_LIN_SPEED:
			var stall = clamp(inverse_lerp(MIN_LIN_SPEED, 0, linear_speed), 0, 1)
			fall = gravity.z * stall * delta
			lateral_speed = gravity.y * stall * delta
			var rot_angle = Vector3(1,0,0).angle_to((Vector3(1,0,0) + delta * gravity).normalized()) * stall
			if rot_angle > PI/1024:
				rotate_object_local(Vector3(1,0,0).cross(gravity_dir).normalized(), rot_angle)
		
		var forward = to_global(Vector3(1,0,0)) - global_transform.origin
		var frontal_wind_velocity = total_winds.dot(-forward) + linear_speed
		var drag = WIND_DRAG * frontal_wind_velocity * frontal_wind_velocity
		var adrag = AILERON_DRAG * aileron.drag
		var edrag = ELEVATOR_DRAG * elevator.drag
		var rdrag = RUDDER_DRAG * rudder.drag
		linear_speed += (throttle - drag - edrag - rdrag - adrag + gravity.x) * delta
		
		var linear_motion = Vector3(
			linear_speed * delta,
			lateral_speed * delta + gravity.y * delta * delta * 150,
			fall * delta + (GRAVITY + gravity.z) * delta * delta * 150)
		
		rotate_object_local(Vector3(1,0,0), angular_velocity.x * delta)
		rotate_object_local(Vector3(0,1,0), angular_velocity.y * delta - 0.01 * (GRAVITY + gravity.z) * delta)
		rotate_object_local(Vector3(0,0,1), angular_velocity.z * delta + 0.005 * gravity.y * delta)
		
		#translate_object_local(linear_motion)
		var collision_data = move_and_collide(to_global(linear_motion)-to_global(Vector3(0,0,0)))
		if collision_data != null:
			destroy()

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("restart"):
		init_race()
	if Input.is_action_just_pressed("ui_cancel"):
		if race_state == RACE_IN_PROGRESS:
			destroy()

func autopilot(delta, frontal_wind_velocity):
	# Maintain the plane horizontal
	var gravity_dir = to_local(GRAVITY_DIR) - to_local(Vector3(0,0,0))
	var elevator_cmd = gravity_dir.dot(Vector3(-1,0,0)) * 4
	var aileron_cmd = gravity_dir.dot(Vector3(0,1,0)) * 1
	aileron.update_with_command(frontal_wind_velocity, delta, clamp(aileron_cmd, -1, 1))
	elevator.update_with_command(frontal_wind_velocity, delta, clamp(elevator_cmd, -1, 1))

func reset_plane(t):
	aileron.reset()
	elevator.reset()
	rudder.reset()
	throttle = LIN_ACCEL
	linear_speed = LIN_SPEED
	angular_velocity = Vector3(0, 0, 0)
	global_transform = t
	plane_state = PLANE_LOCKED

func get_linear_speed():
	return linear_speed # TODO return ground speed not wind speed

func init_race():
	reset_plane(map.get_start_position())
	plane_state = PLANE_LOCKED
	crossed_checkpoints = []
	winds.clear()
	total_winds = Vector3(0,0,0)
	race_state = RACE_INITIALIZED
	emit_signal("race_initialized", map.get_checkpoint_count())

func start_race():
	if race_state == RACE_INITIALIZED:
		plane_state = PLANE_NORMAL
		race_state = RACE_IN_PROGRESS
		emit_signal("race_started", map.get_checkpoint_count())

func end_race():
	if race_state == RACE_IN_PROGRESS:
		if len(crossed_checkpoints) >= map.get_checkpoint_count():
			race_state = RACE_FINISHED
			emit_signal("race_ended", map.get_checkpoint_count())

func cross_checkpoint(id):
	if race_state == RACE_IN_PROGRESS:
		if not (id in crossed_checkpoints) and len(crossed_checkpoints) < map.get_checkpoint_count():
			crossed_checkpoints.append(id)
			emit_signal("checkpoint_crossed", len(crossed_checkpoints), map.get_checkpoint_count())

func destroy():
	plane_state = PLANE_DESTROYED
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
