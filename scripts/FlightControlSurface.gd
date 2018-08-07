extends Object

var m_action_point
var m_action_point_direction
var m_axis
var m_default_orientation
var m_default_normal
var m_angle_max
var m_key_up
var m_key_down
var m_wind_force


func _init(action_point = Vector3(-1,0,0), axis = Vector3(0,1,0), default_orientation = Vector3(-1,0,0), angle_max = PI / 4, key_up = "ui_up", key_down = "ui_down"):
	m_action_point = action_point
	m_action_point_direction = m_action_point.normalized()
	m_axis = axis.normalized()
	m_default_orientation = default_orientation.normalized()
	m_default_normal = m_axis.cross(m_default_orientation)
	m_angle_max = angle_max
	m_key_up = key_up
	m_key_down = key_down
	
func read_input():
	input = 0
	if Input.is_action_pressed(m_key_up):
		input += 1
	if Input.is_action_pressed(m_key_down):
		input -= 1
	return input

func angle(input):
	return input * m_angle_max

func update_force(velocity, wind_direction):
	var surface_angle = angle(read_input())
	var normal = m_defaut_normal.rotated(m_axis, surface_angle)
	var orient = m_defaut_orientation.rotated(m_axis, surface_angle)
	
	var wind_load_coefficient = normal.dot(wind_direction)
	
	m_wind_force = normal * wind_load_coefficient * (velocity * velocity)
	m_drag = m_action_point_direction * m_wind_force.dot(m_action_point_direction)
	m_lever = m_wind_force - m_drag
