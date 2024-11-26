class_name TileMap3DChunk
extends Resource

# 0: fill (land), 1: hole (canyon, cliff, sea)

# 0: |0|1|2|3|
# 1:  |0|1|2|3|
# 2: |0|1|2|3|
# 3:  |0|1|2|3|

const SIZE := Vector2i(10, 10)
static func get_chunk_origin(i: Vector3i) -> Vector2i:
	return (Vector2i(i.x, i.y) - SIZE / 2).snapped(SIZE)
	
@export var data := PackedInt32Array()
@export var origin := Vector2i.ZERO

func _init(o: Vector2i = Vector2.ZERO) -> void:
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
	
