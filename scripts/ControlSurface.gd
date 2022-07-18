extends Object

# Aileron at center of plane, horizontal, both side

const ANGLE_MAX := PI / 4 # rad
const MOVING_RATE := ANGLE_MAX / 0.1 # rad/sec
var min_lift_velocity := 20.0
var _action_plus := ""
var _action_minus := ""
var _pos_input_factor := 0.0
var surface_angle := 0.0
var drag := 0.0
var lift := 0.0

func _init(action_plus : String, action_minus : String, lift_velocity : float, pos_input_factor := 1.0):
	_action_plus = action_plus
	_action_minus = action_minus
	_pos_input_factor = pos_input_factor
	min_lift_velocity = lift_velocity

func read_input() -> float:
	var input := Input.get_action_strength(_action_plus) - Input.get_action_strength(_action_minus)
	return input * _pos_input_factor if input > 0 else input

func reset() -> void:
	surface_angle = 0
	drag = 0
	lift = 0

func _update_surface_angle(delta : float, input : float) -> void:
	var target_surface_angle := ANGLE_MAX * input
	var delta_angle := target_surface_angle - surface_angle
	surface_angle += clamp(delta_angle, -MOVING_RATE * delta, MOVING_RATE * delta)

func _update_drag() -> void:
	drag = surface_angle * surface_angle / (ANGLE_MAX * ANGLE_MAX)

func _update_lift(wind_velocity : float) -> void:
	#angular_velocity = abs(surface_angle) * surface_angle / (ANGLE_MAX*ANGLE_MAX) * wind_velocity
	var factor := clamp(inverse_lerp(0, min_lift_velocity, wind_velocity), 0, 1)
	lift = surface_angle / ANGLE_MAX * wind_velocity * factor

func update_with_input(wind_velocity : float, delta : float):
	_update_surface_angle(delta, read_input())
	_update_drag()
	_update_lift(wind_velocity)

func update_with_command(wind_velocity : float, delta : float, command : float):
	_update_surface_angle(delta, command)
	_update_drag()
	_update_lift(wind_velocity)

func update_override(wind_velocity : float, delta : float, angle : float):
	surface_angle = angle
	_update_drag()
	_update_lift(wind_velocity)
