@tool
class_name TileMap3D
extends Node3D

class MeshTile:
	var mesh_resource: Mesh
	var hole: bool = true
	var neighbors: int = 0

@export var tiles: TileMap3DData
var meshes: Dictionary = {
	0b000000: preload("res://map_tiles/hexa/000000.res"),
	0b000001: preload("res://map_tiles/hexa/000001.res"),
	0b001001: preload("res://map_tiles/hexa/001001.res"),
	0b010001: preload("res://map_tiles/hexa/010001.res"),
	0b010101: preload("res://map_tiles/hexa/010101.res"),
	0b100001: preload("res://map_tiles/hexa/100001.res"),
	0b100101: preload("res://map_tiles/hexa/100101.res"),
	0b101001: preload("res://map_tiles/hexa/101001.res"),
	0b101101: preload("res://map_tiles/hexa/101101.res"),
	0b110001: preload("res://map_tiles/hexa/110001.res"),
	0b110101: preload("res://map_tiles/hexa/110101.res"),
	0b111001: preload("res://map_tiles/hexa/111001.res"),
	0b111101: preload("res://map_tiles/hexa/111101.res"),
	0b111111: preload("res://map_tiles/hexa/111111.res"),
	-1: preload("res://map_tiles/hexa/full.res"),
}
var anim := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	anim += delta
	if anim < 0.5:
		return
	anim -= 0.5
	tiles.set_hole(Vector2i(randi_range(0, tiles.width - 1), randi_range(0, tiles.height - 1)), true)
	for c in $Tiles.get_children():
		$Tiles.remove_child(c)
	for x in range(tiles.width):
		for y in range(tiles.height):
			var mesh_instance := MeshInstance3D.new()
			var ett := tiles.extended_tile_type(Vector2i(x, y))
			mesh_instance.mesh = meshes[ett.neighbors if ett.hole else -1]
			mesh_instance.rotation = PI / 3 * ett.rotation * Vector3.UP
			mesh_instance.position = Vector3(
				cos(PI / 6) * (2 * x + (y % 2)),
				0,
				y * (1 + cos(PI / 3))
			)
			$Tiles.add_child(mesh_instance)
