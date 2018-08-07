extends Node

var default_active_camera = 0
var temporary_active_camera = -1
var action_camera = {"camera_up" : 0, "camera_center" : 1, "camera_first_person" : 2}

func _ready():
	get_child(default_active_camera).make_current()

func _process(delta):
	if Input.is_action_just_pressed("next_camera"):
		default_active_camera = (default_active_camera + 1) % get_child_count()
		get_child(default_active_camera).make_current()
	
	for action in action_camera:
		if Input.is_action_just_pressed(action):
			temporary_active_camera = action_camera[action]
			get_child(temporary_active_camera).make_current()
		elif Input.is_action_just_released(action) and temporary_active_camera == action_camera[action]:
			temporary_active_camera = -1
			get_child(default_active_camera).make_current()
	
	