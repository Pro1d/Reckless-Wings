extends Node3D

class CameraPosition:
	var action: String
	var transform: Transform3D
	func _init(a: String, t: Transform3D) -> void:
		action = a
		transform = t

@export_range(0.0, 1.0, 0.01, "or_greater", "suffix:seconds")
var transition_duration := 1.0

var default_active_camera := 0
var temporary_active_camera := -1
var _tween: Tween

@onready var camera: Camera3D = $Camera3D
@onready var positions: Array[CameraPosition] = [
	CameraPosition.new("camera_up", ($UpPosition as Node3D).transform),
	CameraPosition.new("camera_center", ($CenterPosition as Node3D).transform),
	CameraPosition.new("camera_first_person", ($FirstPersonPosition as Node3D).transform)
]

func _ready() -> void:
	set_camera_position(default_active_camera)

func set_camera_position(position_index: int, animate: bool = false) -> void:
	var cam_pos := positions[position_index]
	if animate:
		if _tween != null:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(camera, "transform", cam_pos.transform, 0.4).from_current()
	else:
		camera.transform = cam_pos.transform

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_camera"):
		default_active_camera = (default_active_camera + 1) % positions.size()
		set_camera_position(default_active_camera, true)
	
	for i in positions.size():
		var cam_pos := positions[i]
		if event.is_action_pressed(cam_pos.action):
			temporary_active_camera = i
			set_camera_position(temporary_active_camera)
		elif event.is_action_released(cam_pos.action) and temporary_active_camera == i:
			temporary_active_camera = -1
			set_camera_position(default_active_camera)
