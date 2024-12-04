class_name TileMap3DData
extends Resource

class ExtendedTileType:
	var hole: bool  # false -> flat ground; true -> rotation + neighbors
	var rotation: int # in range [0; 5]
	var neighbors: int # mask of neighboring hole
	
	func is_empty() -> bool:
		return neighbors == 0b111111
	func is_full() -> bool:
		return not hole

@export var chunks : Dictionary  # chunks by origin

func get_chunk(i: Vector3i) -> TileMap3DChunk: # null if not existing
	return chunks.get(TileMap3DChunk.get_chunk_origin(i), null) as TileMap3DChunk

func make_chunk(i: Vector3i) -> TileMap3DChunk:
	var o := TileMap3DChunk.get_chunk_origin(i)
	var c := TileMap3DChunk.new(o)
	chunks[o] = c
	return c

func data_at(i: Vector3i) -> bool:
	var c := get_chunk(i)
	return c != null and c.data_at(i)

func set_data_at(i: Vector3i, d: bool) -> void:
	var c := get_chunk(i)
	if c == null:
		c = make_chunk(i)
	c.set_data_at(i, d)

func is_hole(i: Vector3i) -> bool:
	return not data_at(i)

func set_hole(i: Vector3i, hole: bool) -> void:
	set_data_at(i, not hole)

func left(i: Vector3i) -> Vector3i:
	return Vector3(i.x - 1, i.y, i.z)

func right(i: Vector3i) -> Vector3i:
	return Vector3i(i.x + 1, i.y, i.z)

func up_left(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x - 1 + odd_y, i.y - 1, i.z)

func up_right(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x + odd_y, i.y - 1, i.z)

func down_left(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x  - 1 + odd_y, i.y + 1, i.z)

func down_right(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x + odd_y, i.y + 1, i.z)

func neighbors(i: Vector3i) -> int:
	return (
		int(is_hole(right(i))) << 0
		| int(is_hole(up_right(i))) << 1
		| int(is_hole(up_left(i))) << 2
		| int(is_hole(left(i))) << 3
		| int(is_hole(down_left(i))) << 4
		| int(is_hole(down_right(i))) << 5
	)

func extended_tile_type(i: Vector3i) -> ExtendedTileType:
	var n := neighbors(i)
	var etd := ExtendedTileType.new()
	etd.neighbors = 0
	etd.hole = is_hole(i)
	if etd.hole and n != 0:
		for r in range(6):
			if (n & 1) != 0 and n > etd.neighbors:
				etd.neighbors = n
				etd.rotation = r
			n = ((n >> 1) | (n << 5)) & 0b111111
	return etd
