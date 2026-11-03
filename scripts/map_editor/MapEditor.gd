class_name MapEditor
extends Node3D

@onready var _tile_map_3d := $TileMap3D as TileMap3D
@onready var _camera_3d: Camera3D = $Camera3D

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
			var path := "res://maps/aaa.res"
			print("saving to ", path, ": ", _tile_map_3d.save_map(path))
		elif key_name == "L":
			var path := "res://maps/aaa.res"
			print("loading from ", path)
			_tile_map_3d.load_map(path)
			_clean_map()
			_tile_map_3d._rebuild()
		else:
			match ke.keycode:
				KEY_LEFT:
					_camera_3d.translate(Vector3.LEFT)
				KEY_RIGHT:
					_camera_3d.translate(Vector3.RIGHT)
				KEY_DOWN:
					_camera_3d.global_position += Vector3.BACK
				KEY_UP:
					_camera_3d.global_position += Vector3.FORWARD
	elif me != null:
		if me.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera_3d.translate_object_local(Vector3.FORWARD * -1.0)
		if me.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera_3d.translate_object_local(Vector3.FORWARD * 1.0)

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
			for z in range(TileMap3DChunk.SIZE.z):
				_tile_map_3d.tiles.set_hole(Vector3i(index.x, index.y, z), hole or z >= _edit_height)
			_tile_map_3d._rebuild()

func _clean_map() -> void:
	var tiles := _tile_map_3d.tiles
	for chunk: TileMap3DChunk in tiles.chunks.values():
		for x in range(chunk.origin.x, chunk.origin.x + TileMap3DChunk.SIZE.x):
			for y in range(chunk.origin.y, chunk.origin.y + TileMap3DChunk.SIZE.y):
				var below : TileMap3DTile = null
				for z in range(0, TileMap3DChunk.SIZE.z):
					var data := chunk.data_at(Vector3i(x, y, z))
					for side in range(TileMap3DTile.STORED_EDGES):
						for h in range(2):
							if z == 0:
								var co := data.get_cliff_offset(side, h, 1)
								co = mini(co, 1)
								data.set_cliff_offset(side, h, 1, co)
								data.set_cliff_offset(side, h, 0, randi_range(0,2))
							if below != null:
								var co := data.get_cliff_offset(side, h, 0)
								co = mini(co, below.get_cliff_offset(side, h, 1))
								data.set_cliff_offset(side, h, 0, co)
					below = data
