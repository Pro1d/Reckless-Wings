extends Object

# Aileron at center of plane, horizontal, both side

const ANGLE_MAX = PI / 4 # rad
const ANGLE_ACCEL_MAX = ANGLE_MAX * 0.01 # rad/frame
var _joy_axis # axis
var _key_dec # key
var _key_inc # key
var _pos_input_factor
var _inv_axis
var angular_velocity = 0.0 # rad/s
var drag = 0.0
var surface_angle = 0.0
var _surface_angle_delta = 0.0

func _init(joy_axis, inv_axis, key_inc, key_dec, pos_input_factor = 1.0):
	_joy_axis = joy_axis
	_inv_axis = -1 if inv_axis < 0 else 1
	_key_inc = key_inc
	_key_dec = key_dec
	_pos_input_factor = pos_input_factor

func read_input():
	var input = Input.get_joy_axis(0, _joy_axis) * _inv_axis
	if Input.is_key_pressed(_key_dec):
		input -= 1
	if Input.is_key_pressed(_key_inc):
		input += 1
	return input * _pos_input_factor if input > 0 else input

func reset():
	drag = 0
	surface_angle = 0
	angular_velocity = 0
	_surface_angle_delta = 0

func _update_surface_angle(delta, input):
	var target_surface_angle = ANGLE_MAX * input
	var delta_angle = target_surface_angle - surface_angle
	if _surface_angle_delta*delta_angle <= 0:
		_surface_angle_delta = 0
	_surface_angle_delta += clamp(delta_angle - _surface_angle_delta, -ANGLE_ACCEL_MAX, ANGLE_ACCEL_MAX)
	surface_angle += _surface_angle_delta

func _update_drag(wind_velocity):
	drag = surface_angle * surface_angle * wind_velocity * wind_velocity / (ANGLE_MAX*ANGLE_MAX)

func _update_angular_velocity(wind_velocity):
	#angular_velocity = abs(surface_angle) * surface_angle / (ANGLE_MAX*ANGLE_MAX) * wind_velocity
	angular_velocity = surface_angle / ANGLE_MAX * wind_velocity

func update_with_input(wind_velocity, delta):
	_update_surface_angle(delta, read_input())
	_update_drag(wind_velocity)
	_update_angular_velocity(wind_velocity)

func update_with_command(wind_velocity, delta, command):
	_update_surface_angle(delta, command)
	_update_drag(wind_velocity)
	_update_angular_velocity(wind_velocity)
