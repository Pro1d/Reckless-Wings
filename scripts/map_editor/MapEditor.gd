class_name MapEditor
extends Node3D

@onready var _tile_map_3d := $TileMap3D as TileMap3D

var _edit_height := 1

func _ready() -> void:
	var plane := $SeaLevelPlane as StaticBody3D
	plane.input_event.connect(_on_plane_input_event)

func _unhandled_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	var me := event as InputEventMouseButton
	if ke != null and ke.is_pressed():
		var key_name := ke.as_text_physical_keycode()
		if key_name.is_valid_int():
			_edit_height = key_name.to_int()
			($SeaLevelPlane as Node3D).position.y = (_edit_height - 1) * TileMap3D.TILE_HEIGHT
		elif key_name == "S":
			var path := "res://maps/bbb.res"
			print("saving to ", path, ": ", _tile_map_3d.save_map(path))
		elif key_name == "L":
			var path := "res://maps/bbb.res"
			print("loading from ", path)
			_tile_map_3d.load_map(path)
	elif me != null:
		if me.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			($Camera3D as Node3D).translate_object_local(Vector3.FORWARD * -1.0)
		if me.button_index == MOUSE_BUTTON_WHEEL_UP:
			($Camera3D as Node3D).translate_object_local(Vector3.FORWARD * 1.0)

func _on_plane_input_event(
	_camera: Node3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	event_position = _tile_map_3d.to_local(event_position)
	var mm := event as InputEventMouse
	if mm != null:
		var index := _tile_map_3d.position_to_index(event_position)
		#var i3 := Vector3i(index.x, index.y, _edit_height)
		var hole := mm.button_mask == MOUSE_BUTTON_MASK_RIGHT
		var full := mm.button_mask == MOUSE_BUTTON_MASK_LEFT
		if hole or full:
			for z in range(5):
				_tile_map_3d.tiles.set_hole(Vector3i(index.x, index.y, z), hole or z >= _edit_height)
			_tile_map_3d._rebuild()
