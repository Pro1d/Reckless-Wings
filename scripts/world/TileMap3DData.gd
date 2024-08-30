class_name TileMap3DData
extends Resource

class ExtendedTileType:
	var hole: bool  # false -> flat ground; true -> rotation + neighbors
	var rotation: int
	var neighbors: int

# 0: fill (land), 1: hole (canyon, cliff, sea)

# 0: |0|1|2|3|
# 1:  |0|1|2|3|
# 2: |0|1|2|3|
# 3:  |0|1|2|3|
var data: PackedInt32Array
var width := 20
var height := 20

func _init() -> void:
	data.resize(width * height)
	data.fill(0)

func position_to_index(pos: Vector3) -> Vector2i:
	#position = Vector3(
				#cos(PI / 6) * (2 * x + (y % 2)),
				#0,
				#y * (1 + cos(PI / 3))
			#)
	var x := pos.x
	var y := pos.z
	var iy := floori(y / (1 + cos(PI / 3)) + .5)
	return Vector2i(
		floori((x / cos(PI / 6) - (iy % 2)) / 2 + .5), iy
	)

func is_inside(i : Vector2i) -> bool:
	return (
		0 <= i.x
		and i.x < width
		and 0 <= i.y
		and i.y < height
	)

func data_at(i: Vector2i) -> bool:
	assert(0 <= i.x)
	assert(i.x < width)
	assert(0 <= i.y)
	assert(i.y < height)
	return (data[i.x + i.y * width] & 1) != 0

func set_data_at(i: Vector2i, d: bool) -> void:
	assert(0 <= i.x)
	assert(i.x < width)
	assert(0 <= i.y)
	assert(i.y < height)
	if d:
		data[i.x + i.y * width] |= 1
	else:
		data[i.x + i.y * width] &= ~0b1

func is_hole(i: Vector2i) -> bool:
	if (0 <= i.x) and (i.x < width) and (0 <= i.y) and (i.y < height):
		return data_at(i)
	else:
		return true

func set_hole(i: Vector2i, hole: bool) -> void:
	set_data_at(i, hole)

func left(i: Vector2i) -> Vector2i:
	return Vector2i(i.x - 1, i.y)
func right(i: Vector2i) -> Vector2i:
	return Vector2i(i.x + 1, i.y)
func up_left(i: Vector2i) -> Vector2i:
	var odd_y := i.y % 2
	return Vector2i(i.x - 1 + odd_y, i.y - 1)
func up_right(i: Vector2i) -> Vector2i:
	var odd_y := i.y % 2
	return Vector2i(i.x + odd_y, i.y - 1)
func down_left(i: Vector2i) -> Vector2i:
	var odd_y := i.y % 2
	return Vector2i(i.x  - 1 + odd_y, i.y + 1)
func down_right(i: Vector2i) -> Vector2i:
	var odd_y := i.y % 2
	return Vector2i(i.x + odd_y, i.y + 1)

func neighbors(i: Vector2i) -> int:
	return (
		int(is_hole(right(i))) << 0
		| int(is_hole(up_right(i))) << 1
		| int(is_hole(up_left(i))) << 2
		| int(is_hole(left(i))) << 3
		| int(is_hole(down_left(i))) << 4
		| int(is_hole(down_right(i))) << 5
	)

func extended_tile_type(i: Vector2i) -> ExtendedTileType:
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
