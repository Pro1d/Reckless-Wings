class_name TileMap3DData
extends Resource

class ExtendedTileType:
	var hole: bool  # false -> flat ground; true -> rotation + neighbors
	var rotation: int
	var neighbors: int
	
	func is_empty() -> bool:
		return neighbors == 0b111111

class Chunk:
	const SIZE := Vector2i(10, 10)
	static func get_chunk_origin(i: Vector3i) -> Vector2i:
		return (Vector2i(i.x, i.y) - SIZE / 2).snapped(SIZE)
		
	var data := PackedInt32Array()
	var origin := Vector2i.ZERO
	
	func _init(o: Vector2i) -> void:
		origin = o
		data.resize(SIZE.x * SIZE.y)
		data.fill(0)
	
	func is_inside(i: Vector3i) -> bool:
		var irel := Vector2i(i.x, i.y) - origin
		return (0 <= irel.x and irel.x < SIZE.x and
				0 <= irel.y and irel.y < SIZE.y)
	
	func data_at(i: Vector3i) -> bool:
		var irel := Vector2i(i.x, i.y) - origin
		return ((data[irel.x + irel.y * SIZE.x] >> i.z) & 1) != 0
	
	func set_data_at(i: Vector3i, d: bool) -> void:
		var irel := Vector2i(i.x, i.y) - origin
		if d:
			data[irel.x + irel.y * SIZE.x] |= 1 << i.z
		else:
			data[irel.x + irel.y * SIZE.x] &= ~(1 << i.z)
	
# 0: fill (land), 1: hole (canyon, cliff, sea)

# 0: |0|1|2|3|
# 1:  |0|1|2|3|
# 2: |0|1|2|3|
# 3:  |0|1|2|3|

var chunks : Dictionary  # chunks by origin
func get_chunk(i: Vector3i) -> Chunk: # null if not existing
	return chunks.get(Chunk.get_chunk_origin(i), null) as Chunk
func make_chunk(i: Vector3i) -> Chunk:
	var o := Chunk.get_chunk_origin(i)
	var c := Chunk.new(o)
	chunks[o] = c
	return c

func position_to_index(pos: Vector3) -> Vector2i:
	var x := pos.x
	var y := pos.z
	var iy := floori(y / (1 + cos(PI / 3)) + .5)
	return Vector2i(
		floori((x / cos(PI / 6) - (iy & 1)) / 2 + .5), iy
	)

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
