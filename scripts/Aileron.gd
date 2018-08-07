extends Object

# Aileron at center of plane, horizontal, both side

const ANGLE_ACCEL_MAX = PI/4 / 100 # rad/
const ANGLE_MAX = PI / 4 # rad
const ANGULAR_SPEED_FACTOR = 0.045 # rad/s / rad
const KEY_DEC = KEY_LEFT # key
const KEY_INC = KEY_RIGHT # key
const JOY_AXIS = JOY_AXIS_0
var angular_velocity = 0.0 # rad/s
var drag = 0.0
var surface_angle = 0.0
var m_surface_angle_delta = 0.0

func read_input():
	var input = Input.get_joy_axis(0, JOY_AXIS)
	if Input.is_key_pressed(KEY_DEC):
		input -= 1
	if Input.is_key_pressed(KEY_INC):
		input += 1
	return input

func reset():
	drag = 0
	surface_angle = 0
	angular_velocity = 0
	m_surface_angle_delta = 0

func _update_surface_angle(delta):
	var target_surface_angle = ANGLE_MAX * read_input()
	var delta_angle = target_surface_angle - surface_angle
	
	if m_surface_angle_delta*delta_angle <= 0:
		m_surface_angle_delta = 0

	m_surface_angle_delta += clamp(delta_angle - m_surface_angle_delta,
								   -ANGLE_ACCEL_MAX, ANGLE_ACCEL_MAX)
	surface_angle += m_surface_angle_delta

func _update_drag(wind_velocity):
	drag = surface_angle * surface_angle * wind_velocity * wind_velocity / (ANGLE_MAX*ANGLE_MAX)

func _update_angular_velocity(wind_velocity):
	angular_velocity = abs(surface_angle) * surface_angle / (ANGLE_MAX*ANGLE_MAX) * wind_velocity * ANGULAR_SPEED_FACTOR

func update(wind_velocity, delta):
	_update_surface_angle(delta)
	_update_drag(wind_velocity)
	_update_angular_velocity(wind_velocity)
