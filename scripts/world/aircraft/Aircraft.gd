class_name Aircraft
extends RigidBody3D

signal state_reset

enum ControlMode { ENABLED, UNRESPONSIVE, AUTOPILOT, LOCKED, REPLAY }
var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity") # m/s²

const YAW_AXIS := Vector3.UP
const PITCH_AXIS := Vector3.LEFT
const ROLL_AXIS := Vector3.FORWARD
const LONGITUDINAL_AXIS := Vector3.FORWARD
const LATERAL_AXIS := Vector3.LEFT
const VERTICAL_AXIS := Vector3.UP

static func llv_to_vector(longitudinal: float, lateral: float, vertical: float) -> Vector3:
	return (longitudinal * LONGITUDINAL_AXIS +
			lateral * LATERAL_AXIS +
			vertical * VERTICAL_AXIS)

static func ypr_to_vector(yaw: float, pitch: float, roll: float) -> Vector3:
	return (yaw * YAW_AXIS +
			pitch * PITCH_AXIS +
			roll * ROLL_AXIS)

class LLV:
	var longitudinal: float
	var lateral: float
	var vertical: float

	static func from_vector(vec: Vector3) -> LLV:
		var llv := LLV.new()
		llv.longitudinal = vec.dot(LONGITUDINAL_AXIS)
		llv.lateral = vec.dot(LATERAL_AXIS)
		llv.vertical = vec.dot(VERTICAL_AXIS)
		return llv

	func to_vector() -> Vector3:
		return Aircraft.llv_to_vector(longitudinal, lateral, vertical)

class YPR:
	var yaw: float
	var pitch: float
	var roll: float

	static func from_vector(vec: Vector3) -> YPR:
		var ypr := YPR.new()
		ypr.yaw = vec.dot(YAW_AXIS)
		ypr.pitch = vec.dot(PITCH_AXIS)
		ypr.roll = vec.dot(ROLL_AXIS)
		return ypr

	func to_vector() -> Vector3:
		return Aircraft.ypr_to_vector(yaw, pitch, roll)

class State:
	var apply: bool = false
	var linear_velocity: Vector3
	var transform: Transform3D

func sqr_sign(x: float) -> float:
	return sign(x) * (abs(x) ** 2)
func clamp_abs(x: float, bound: float) -> float:
	return clampf(x, -abs(bound), abs(bound))
# plane dim:
# length = 8m
# wingspan = 11m
# max speed = 600km/h ~> 170m/s | normal speed 180 km/h -> 50m/s
@export_range(0.0, 300.0, 1.0, "exp", "or_greater", "suffix:m/s")
var _initial_linear_speed := 50.0 # 180 km/h
@export_range(0.0, 60.0, 1.0, "exp", "or_greater", "suffix:m/s²")
var _linear_accel := 8.5 # should be lesser than gravity acceleration
@export_range(0.0, 300.0, 1.0, "exp", "or_greater", "suffix:m/s")
var _max_linear_speed := 170.0 # 600 km/h, to compute drag
@export_range(0.0, 300.0, 1.0, "exp", "or_greater", "suffix:m/s")
var _min_linear_speed := 30.0 # over this limit the lift is stronger than graviy

# at max_lin_speed, the deccel due to wind drag equals to lin_accel
var _wind_drag := (_linear_accel / (_max_linear_speed * _max_linear_speed)) # m/s² / (m/s)² = m^-1

@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _elevator_drag_factor := 0.1
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _elevator_strength := 0.12
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _rudder_drag_factor := 0.1
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _rudder_strength := 0.045
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _aileron_drag_factor := 0.1
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _aileron_strength := 0.35

var elevator_drag := _elevator_drag_factor * _wind_drag
var rudder_drag := _rudder_drag_factor * _wind_drag
var aileron_drag := _aileron_drag_factor * _wind_drag

@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _vertical_pitch_strength := 0.03 # convert vertical to pitch due to elevator drag
@export_range(0.0, 1.0, 0.0001, "exp", "or_greater")
var _lateral_yaw_strength := 0.015 # convert lateral to yaw due to rudder drag

var _linear_drag_factor := Aircraft.llv_to_vector(1, 300, 1000)
var _linear_drag := _linear_drag_factor * _wind_drag
var _angular_damp_3d := Aircraft.ypr_to_vector(0.96, 0.96, 0.998)

var _reset_state := State.new()
var _control_mode := ControlMode.LOCKED
var _throttle_command := 1.0  # 0% -> 100%

@onready var _rudder: ControlSurface = $RudderControlSurface
@onready var _elevator: ControlSurface = $ElevatorControlSurface
@onready var _aileron: ControlSurface = $AileronControlSurface
@onready var engine_audio: AudioStreamPlayer3D = $EngineAudio
@onready var wind_audio: AudioStreamPlayer3D = $WindAudio

var _debug_text := ""

func _ready() -> void:
	reset(Transform3D())
	_control_mode = ControlMode.ENABLED

func _physics_process(delta: float) -> void:
	var wind_velocity := LLV.from_vector(global_transform.basis.transposed() * linear_velocity)
	# FIXME wind_velicity with world's winds?
	# or consider them only after command? (stall / surface lift)
	
	# Commands
	match _control_mode:
		ControlMode.ENABLED:
			if Input.is_action_pressed("auto_pilot"):
				_autopilot(delta, wind_velocity.longitudinal)
			else:
				_elevator.update_with_input(wind_velocity.longitudinal, delta)
				_aileron.update_with_input(wind_velocity.longitudinal, delta)
			_rudder.update_with_input(wind_velocity.longitudinal, delta)
			_throttle_command = 1.0
		ControlMode.UNRESPONSIVE:
			pass  # TODO keep previous commands
		ControlMode.AUTOPILOT:
			_autopilot(delta, wind_velocity.longitudinal)
			_rudder.update_with_input(wind_velocity.longitudinal, delta)
		ControlMode.LOCKED, _:
			_rudder.update_with_command(wind_velocity.longitudinal, delta, 0.0)
			_elevator.update_with_command(wind_velocity.longitudinal, delta, 0.0)
			_aileron.update_with_command(wind_velocity.longitudinal, delta, 0.0)
			_throttle_command = 1.0

func get_debug() -> String:
	return _debug_text

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if _reset_state.apply:
		_reset_state.apply = false
		state.linear_velocity = _reset_state.linear_velocity
		state.angular_velocity = Vector3.ZERO
		state.transform = _reset_state.transform
		state_reset.emit()
		return
	_debug_text = ""
	_debug_text += "aileron angle %f drag %f lift %f\n" % [_aileron.surface_angle / ControlSurface.ANGLE_MAX, _aileron.drag, _aileron.lift]
	_debug_text += "elevator angle %f drag %f lift %f\n" % [_elevator.surface_angle / ControlSurface.ANGLE_MAX, _elevator.drag, _elevator.lift]
	_debug_text += "rudder angle %f drag %f lift %f\n" % [_rudder.surface_angle / ControlSurface.ANGLE_MAX, _rudder.drag, _rudder.lift]

	var s_basis := state.transform.basis
	var s_basis_T := state.transform.basis.transposed()
	var s_linear_velocity := state.linear_velocity
	var s_angular_velocity := state.angular_velocity
	var delta := state.step
	_debug_text += "s_origin %s\n" % [state.transform.origin]
	_debug_text += "s_forward %s\n" % [state.transform.basis * Vector3.FORWARD]
	_debug_text += "s_up %s\n" % [state.transform.basis * Vector3.UP]
	_debug_text += "s_linear_velocity %s\n" % [s_linear_velocity]
	_debug_text += "s_angular_velocity %s\n" % [s_angular_velocity]
	
	var thrust := _throttle_command * _linear_accel
	var wind_velocity := LLV.from_vector(s_basis_T * s_linear_velocity)
	_debug_text += "thrust %s\n" % [thrust]
	_debug_text += "wind_velocity [%f, %f, %f]\n" % [wind_velocity.longitudinal, wind_velocity.lateral, wind_velocity.vertical]
	_update_audio(_throttle_command * 1.0, wind_velocity)

	# Physics
	var gravity_dir := s_basis_T * Vector3.DOWN
	var gravity := gravity_dir * GRAVITY
	var stall := clampf(inverse_lerp(_min_linear_speed, 0.0, wind_velocity.longitudinal), 0.0, 1.0)
	_debug_text += "gravity %s\n" % [gravity]
	_debug_text += "stall %s\n" % [stall]
	
	# stalling, automatically put the nose down
	# FIXME 
#	var rot_angle := Vector3.FORWARD.angle_to((Vector3.FORWARD + 0.75 * delta * gravity).normalized()) * stall
#	if rot_angle > PI/1024:
#		rotate_object_local(Vector3.FORWARD.cross(gravity_dir).normalized(), rot_angle)
	
	# consider world's winds for wind_velocity only from here?
	# linear drag
	var llv_drag := LLV.from_vector(_linear_drag)
	var lon_drag := sqr_sign(wind_velocity.longitudinal) * (
		llv_drag.longitudinal
		+ rudder_drag * _rudder.drag
		+ elevator_drag * _elevator.drag
		+ aileron_drag * _aileron.drag)
	var lat_drag := sqr_sign(wind_velocity.lateral) * llv_drag.lateral
	var ver_drag := sqr_sign(wind_velocity.vertical) * llv_drag.vertical
	_debug_text += "cs drag  {%f, %f, %f}\n" % [rudder_drag * _rudder.drag, elevator_drag * _elevator.drag, aileron_drag * _aileron.drag]
	_debug_text += "llv_drag [%f, %f, %f]\n" % [llv_drag.longitudinal, llv_drag.lateral, llv_drag.vertical]
	
	# drag can slow down to zero (cannot change velocity direction)
	lon_drag = clamp_abs(lon_drag, wind_velocity.longitudinal / delta)
	lat_drag = clamp_abs(lat_drag, wind_velocity.lateral / delta)
	ver_drag = clamp_abs(ver_drag, wind_velocity.vertical / delta)
	_debug_text += "llv_drag dV [%f, %f, %f]\n" % [lon_drag, lat_drag, ver_drag]
	
	# active forces
	var llv_gravity := LLV.from_vector(gravity)
	var lift := GRAVITY * (1.0 - stall) # lift compensates exactly the gravity, except at low speed
	_debug_text += "llv_gravity [%f, %f, %f]\n" % [llv_gravity.longitudinal, llv_gravity.lateral, llv_gravity.vertical]
	_debug_text += "lift %s\n" % [lift]
	
	# linear speed variation
	var llv_velocity_variation := LLV.new()
	llv_velocity_variation.longitudinal = (thrust - lon_drag + llv_gravity.longitudinal) * delta
	llv_velocity_variation.lateral = (-lat_drag + llv_gravity.lateral) * delta
	llv_velocity_variation.vertical = (-ver_drag + llv_gravity.vertical + lift) * delta
	_debug_text += "llv_velocity_variation [%f, %f, %f]\n" % [llv_velocity_variation.longitudinal, llv_velocity_variation.lateral, llv_velocity_variation.vertical]
	
	var vertical_to_pitch := -sqr_sign(wind_velocity.vertical) * _vertical_pitch_strength
	var lateral_to_yaw := sqr_sign(wind_velocity.lateral) * _lateral_yaw_strength
	var yaw_lift := _rudder_strength * _rudder.lift
	var pitch_lift := _elevator_strength * _elevator.lift
	var roll_lift := _aileron_strength * _aileron.lift
	_debug_text += "vertical_to_pitch %f\n" % [vertical_to_pitch]
	_debug_text += "lateral_to_yaw %f\n" % [lateral_to_yaw]
	
	# update angular velocity
	var ypr_angular_damp := YPR.from_vector(_angular_damp_3d)
	var ypr_velocity := YPR.from_vector(s_basis_T * s_angular_velocity)
	var ypr_velocity_variation := YPR.new()
	ypr_velocity_variation.yaw = -ypr_velocity.yaw * (1 - pow(1 - ypr_angular_damp.yaw, delta))
	ypr_velocity_variation.yaw += (yaw_lift + lateral_to_yaw) * delta
	ypr_velocity_variation.pitch = -ypr_velocity.pitch * (1 - pow(1 - ypr_angular_damp.pitch, delta))
	ypr_velocity_variation.pitch += (pitch_lift + vertical_to_pitch) * delta
	ypr_velocity_variation.roll = -ypr_velocity.roll * (1 - pow(1 - ypr_angular_damp.roll, delta))
	ypr_velocity_variation.roll += roll_lift * delta
	_debug_text += "ypr dV [%f, %f, %f]\n" % [ypr_velocity_variation.yaw, ypr_velocity_variation.pitch, ypr_velocity_variation.roll]
	
	state.linear_velocity += s_basis * llv_velocity_variation.to_vector()
	state.angular_velocity += s_basis * ypr_velocity_variation.to_vector()

func reset(pose: Transform3D, initial_velocity_factor: float = 1.0) -> void:
	_reset_state.apply = true
	_reset_state.linear_velocity = pose.basis * (LONGITUDINAL_AXIS * _initial_linear_speed * initial_velocity_factor)
	_reset_state.transform = pose

func set_control_mode(mode: ControlMode) -> void:
	_control_mode = mode

func get_world_speed() -> float:
	return linear_velocity.length()

func _autopilot(delta: float, frontal_wind_velocity: float):
	# Maintain the plane horizontal
	var gravity_dir := global_transform.basis.transposed() * Vector3.DOWN
	var elevator_cmd := gravity_dir.dot(Vector3.BACK) * 0.8
	var aileron_cmd := gravity_dir.dot(Vector3.LEFT) * 0.4
	_aileron.update_with_command(frontal_wind_velocity, delta, clamp(aileron_cmd, -1, 1))
	_elevator.update_with_command(frontal_wind_velocity, delta, clamp(elevator_cmd, -1, 1))

func _update_audio(throttle: float, wind_velocity: LLV) -> void:
	var clamped_speed := clampf(wind_velocity.longitudinal, 0, _max_linear_speed)
	var air_resistance := remap(clamped_speed, 0, _max_linear_speed, 1.0, 0.0)
	var engine_rps := remap(throttle, 0.0, 1.0, 1.5, 2.5) * remap(air_resistance, 0.0, 1.0, 1.0, 0.5)
	engine_audio.pitch_scale = clampf(engine_rps, 0.8, 2.5)
	var wind_speed := wind_velocity.to_vector().length()
	var air_drag := remap(wind_speed, 0, _max_linear_speed, 0.0, 1.0) ** 2
	wind_audio.volume_db = remap(air_drag, 0.0, 1.0, -24, 2.5)
