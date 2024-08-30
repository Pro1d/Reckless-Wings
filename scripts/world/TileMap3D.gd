class_name TileMap3D
extends Node3D

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
var anim := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var plane := $SeaLevelPlane as StaticBody3D
	plane.input_event.connect(_on_plane_input_event)

func _process(_delta: float) -> void:
	#anim += delta
	#if anim < 0.5:
	#	return
	#anim -= 0.5
	#tiles.set_hole(Vector2i(randi_range(0, tiles.width - 1), randi_range(0, tiles.height - 1)), true)
	for c: Node3D in $Tiles.get_children():
		$Tiles.remove_child(c)
		c.queue_free()
	for x in range(tiles.width):
		for y in range(tiles.height):
			var ett := tiles.extended_tile_type(Vector2i(x, y))
			var res : PackedScene
			res = meshes[ett.neighbors if ett.hole else -1]
			var tile := res.instantiate() as Node3D
			tile.rotation = PI / 3 * ett.rotation * Vector3.UP
			tile.position = Vector3(
				cos(PI / 6) * (2 * x + (y % 2)),
				0,
				y * (1 + cos(PI / 3))
			)
			for c: MeshInstance3D in tile.get_children():
				if c == null:
					continue
				c.set_surface_override_material(0, preload("res://resources/triplanar_grid.material"))
			$Tiles.add_child(tile)
			#var mesh_instance := MeshInstance3D.new()
			#var ett := tiles.extended_tile_type(Vector2i(x, y))
			#mesh_instance.mesh = meshes[ett.neighbors if ett.hole else -1]
			#mesh_instance.rotation = PI / 3 * ett.rotation * Vector3.UP
			#mesh_instance.position = Vector3(
				#cos(PI / 6) * (2 * x + (y % 2)),
				#0,
				#y * (1 + cos(PI / 3))
			#)
			#$Tiles.add_child(mesh_instance)

func _on_plane_input_event(
	_camera: Node3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	event_position = ($Tiles as Node3D).to_local(event_position)
	var mm := event as InputEventMouseMotion
	if mm != null:
		var index := tiles.position_to_index(event_position)
		if tiles.is_inside(index):
			if mm.button_mask == MOUSE_BUTTON_MASK_LEFT:
				tiles.set_hole(tiles.position_to_index(event_position), true)
			if mm.button_mask == MOUSE_BUTTON_MASK_RIGHT:
				tiles.set_hole(tiles.position_to_index(event_position), false)
