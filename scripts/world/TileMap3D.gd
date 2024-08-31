class_name TileMap3D
extends Node3D


const TILE_HEIGHT := 1.0

class MeshTile:
	var mesh_resource: Mesh
	var hole: bool = true
	var neighbors: int = 0

@export var tiles: TileMap3DData
var meshes: Dictionary = {
	0b000000: preload("res://map_tiles/hexa_tiles/000000.tscn"),
	0b000001: preload("res://map_tiles/hexa_tiles/000001.tscn"),
	0b001001: preload("res://map_tiles/hexa_tiles/001001.tscn"),
	0b010001: preload("res://map_tiles/hexa_tiles/010001.tscn"),
	0b010101: preload("res://map_tiles/hexa_tiles/010101.tscn"),
	0b100001: preload("res://map_tiles/hexa_tiles/100001.tscn"),
	0b100101: preload("res://map_tiles/hexa_tiles/100101.tscn"),
	0b101001: preload("res://map_tiles/hexa_tiles/101001.tscn"),
	0b101101: preload("res://map_tiles/hexa_tiles/101101.tscn"),
	0b110001: preload("res://map_tiles/hexa_tiles/110001.tscn"),
	0b110101: preload("res://map_tiles/hexa_tiles/110101.tscn"),
	0b111001: preload("res://map_tiles/hexa_tiles/111001.tscn"),
	0b111101: preload("res://map_tiles/hexa_tiles/111101.tscn"),
	0b111111: preload("res://map_tiles/hexa_tiles/111111.tscn"),
	-1: preload("res://map_tiles/hexa_tiles/full.tscn"),
}
var _edit_height := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var plane := $SeaLevelPlane as StaticBody3D
	plane.input_event.connect(_on_plane_input_event)
	_rebuild()

func _rebuild() -> void:
	for c: Node3D in $Tiles.get_children():
		$Tiles.remove_child(c)
		c.queue_free()
	for chunk: TileMap3DData.Chunk in tiles.chunks.values():
		for x in range(chunk.origin.x - 1, chunk.origin.x + TileMap3DData.Chunk.SIZE.x + 1):
			for y in range(chunk.origin.y - 1, chunk.origin.y + TileMap3DData.Chunk.SIZE.y + 1):
				for z in range(5):
					var i := Vector3i(x, y, z)
					var ck := tiles.get_chunk(i)
					if not (ck == null or ck == chunk):
						continue # skip border tile belonging to an other chunk
					var ett := tiles.extended_tile_type(i)
					if ett.is_empty():
						continue # skip empty tile
					var res : PackedScene
					res = meshes[ett.neighbors if ett.hole else -1]
					var tile := res.instantiate() as HexaTile
					tile.ground_enabled = (z == 0)
					tile.rotation = PI / 3 * ett.rotation * Vector3.UP
					tile.position = Vector3(
						cos(PI / 6) * (2 * x + (y & 1)),
						z * TILE_HEIGHT,
						y * (1 + cos(PI / 3))
					)
					$Tiles.add_child(tile)

func _unhandled_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke != null:
		var key_name := ke.as_text_physical_keycode()
		if key_name.is_valid_int():
			_edit_height = key_name.to_int()
			($SeaLevelPlane as Node3D).position.y = (_edit_height - 1) * TILE_HEIGHT

func _on_plane_input_event(
	_camera: Node3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	event_position = ($Tiles as Node3D).to_local(event_position)
	var mm := event as InputEventMouse
	if mm != null:
		var index := tiles.position_to_index(event_position)
		#var i3 := Vector3i(index.x, index.y, _edit_height)
		var hole := mm.button_mask == MOUSE_BUTTON_MASK_RIGHT
		var full := mm.button_mask == MOUSE_BUTTON_MASK_LEFT
		if hole or full:
			for z in range(5):
				tiles.set_hole(Vector3i(index.x, index.y, z), hole or z >= _edit_height)
			_rebuild()
