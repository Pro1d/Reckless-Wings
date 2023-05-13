class_name ControlSurface
extends Node

# Aileron at center of plane, horizontal, both side

const ANGLE_MAX := PI / 4 # rad
const MOVING_RATE := ANGLE_MAX / 0.1 # rad/sec

@export
var _action_plus := ""
@export
var _action_minus := ""
@export_range(0.0, 100.0, 0.1, "exp", "or_greater", "suffix:m/s")
var _min_lift_velocity := 30.0
@export_range(0.0, 1.0, 0.01)
var _pos_input_factor := 1.0

var command := 0.0 # range -1..1
var surface_angle := 0.0 # range -ANGLE_MAX..ANGLE_MAX
var drag := 0.0 # range 0..1
var lift := 0.0 # range 0..wind_velocity

func read_input() -> float:
	var input := Input.get_action_strength(_action_plus) - Input.get_action_strength(_action_minus)
	return input * _pos_input_factor if input > 0 else input

func reset() -> void:
	surface_angle = 0
	drag = 0
	lift = 0

func update_with_input(wind_velocity: float, delta: float) -> void:
	update_with_command(wind_velocity, delta, read_input())

func update_with_command(wind_velocity: float, delta: float, cmd: float) -> void:
	# Update command
	command = cmd
	# Update surface angle
	var target_surface_angle := ANGLE_MAX * command
	var delta_angle := target_surface_angle - surface_angle
	surface_angle += clamp(delta_angle, -MOVING_RATE * delta, MOVING_RATE * delta)
	# Update drag
	drag = surface_angle * surface_angle / (ANGLE_MAX * ANGLE_MAX)
	# Update lift
	var factor := clampf(inverse_lerp(0, _min_lift_velocity, wind_velocity), 0, 1)
	lift = surface_angle / ANGLE_MAX * wind_velocity * factor
