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
static var empty_tile := TileMap3DTile.new()

func get_chunk(i: Vector3i) -> TileMap3DChunk: # null if not existing
	return chunks.get(TileMap3DChunk.get_chunk_origin(i), null) as TileMap3DChunk

func make_chunk(i: Vector3i) -> TileMap3DChunk:
	var o := TileMap3DChunk.get_chunk_origin(i)
	var c := TileMap3DChunk.new(o)
	chunks[o] = c
	return c

func fill_at(i: Vector3i) -> bool:
	var c := get_chunk(i)
	return c != null and c.data_at(i).fill

func tile_at(i: Vector3i) -> TileMap3DTile:
	var c := get_chunk(i)
	return null if c == null else c.data_at(i)

func set_fill_at(i: Vector3i, fill: bool) -> void:
	var c := get_chunk(i)
	if c == null:
		if not fill:
			return
		c = make_chunk(i)
	c.data_at(i).fill = fill

func is_hole(i: Vector3i) -> bool:
	return not fill_at(i)

func set_hole(i: Vector3i, hole: bool) -> void:
	set_fill_at(i, not hole)

func neighbors(i: Vector3i) -> int:
	return (
		int(is_hole(TileMap3DMath.right(i))) << 0
		| int(is_hole(TileMap3DMath.up_right(i))) << 1
		| int(is_hole(TileMap3DMath.up_left(i))) << 2
		| int(is_hole(TileMap3DMath.left(i))) << 3
		| int(is_hole(TileMap3DMath.down_left(i))) << 4
		| int(is_hole(TileMap3DMath.down_right(i))) << 5
	)

func extended_tile_type(i: Vector3i) -> ExtendedTileType:
	var n := neighbors(i)
	var etd := ExtendedTileType.new()
	etd.neighbors = 0
	etd.hole = is_hole(i)
	if etd.hole and n != 0:
		for r in range(TileMap3DMath.SIDES):
			if (n & 1) != 0 and n > etd.neighbors:
				etd.neighbors = n
				etd.rotation = r
			n = ((n >> 1) | (n << 5)) & 0b111111
	return etd
