class_name TileMap3D
extends Node3D


const TILE_HEIGHT := 1.0

class MeshTile:
	var mesh_resource: Mesh
	var hole: bool = true
	var neighbors: int = 0

@export var tiles: TileMap3DData
@export var generate_collisions := true
@export var horizontal_displacement_texture : Texture2D
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
var _mesh_tiles := {}


func _ready() -> void:
	pass #_rebuild()

func _rebuild() -> void:
	for c: Node3D in _mesh_tiles.values():
		remove_child(c)
		c.queue_free()
	_mesh_tiles.clear()
	for chunk: TileMap3DChunk in tiles.chunks.values():
		for x in range(chunk.origin.x - 1, chunk.origin.x + TileMap3DChunk.SIZE.x + 1):
			for y in range(chunk.origin.y - 1, chunk.origin.y + TileMap3DChunk.SIZE.y + 1):
				for z in range(5):
					var i := Vector3i(x, y, z)
					if _mesh_tiles.has(i):
						continue
					#var ck := tiles.get_chunk(i)
					#if not (ck == null or ck == chunk):
						#continue # skip border tile belonging to an other chunk
					var ett := tiles.extended_tile_type(i)
					if ett.is_empty():
						continue # skip empty tile
					var res : PackedScene
					res = meshes[ett.neighbors if ett.hole else -1]
					var tile := res.instantiate() as HexaTile
					tile.ground_enabled = (z == 0)
					tile.rotation = PI / 3 * ett.rotation * Vector3.UP
					tile.position = index_to_position(i)
					add_child(tile, false, Node.InternalMode.INTERNAL_MODE_FRONT)
					_mesh_tiles[i] = tile

func save_map(path: String) -> Error:
	return ResourceSaver.save(tiles, path)

func load_map(path: String) -> void:
	tiles = ResourceLoader.load(path)
	_rebuild()

func index_to_position(i: Vector3i) -> Vector3:
	return Vector3(
		cos(PI / 6) * (2 * i.x + (i.y & 1)),
		i.z * TILE_HEIGHT,
		i.y * (1 + cos(PI / 3))
	)

func position_to_index(pos: Vector3) -> Vector2i:
	var x := pos.x
	var y := pos.z
	var iy := floori(y / (1 + cos(PI / 3)) + .5)
	return Vector2i(
		floori((x / cos(PI / 6) - (iy & 1)) / 2 + .5), iy
	)

func distort() -> void:
	if generate_collisions:
		await horizontal_displacement_texture.changed
		var img := horizontal_displacement_texture.get_image()
		print(horizontal_displacement_texture, " ", img)
		const noise_scale := 10.0
		const noise_strength := 0.1
		for tile: HexaTile in _mesh_tiles.values():
			await get_tree().process_frame
			tile.meshes_transform((
				func(vertex: Vector3, image: Image) -> Vector3:
					var c := image.get_pixel(
						wrapi(roundi(vertex.x * noise_scale), 0, image.get_size().x),
						wrapi(roundi(vertex.z * noise_scale), 0, image.get_size().y)
					)
					return vertex + Vector3(c.r * 2 - 1, 0.0, c.g * 2 - 1).normalized() * noise_strength
					#return vertex + Vector3(
						#sin(vertex.x * 1.0) * .5,
						#sin(vertex.x * .1+vertex.z * .15) * .2,
						#sin(vertex.z * 1.5) * .4
					#)
			).bind(img))
			tile.create_trimesh_collision()
