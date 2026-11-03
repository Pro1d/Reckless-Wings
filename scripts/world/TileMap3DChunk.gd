class_name TileMap3DChunk
extends Resource

# true: fill (land), false: hole (canyon, cliff, sea)

# 2D:    -- x -->
# |  0: |0|1|2|3|
# y  1:  |0|1|2|3|
# |  2: |0|1|2|3|
# v  3:  |0|1|2|3|

# 3D.x = 2D.x
# 3D.y = height
# 3D.z = 2D.y

const SIZE := Vector3i(10, 10, 16)
const SIZE2 := Vector2i(SIZE.x, SIZE.y)


static func get_chunk_origin(i: Vector3i) -> Vector2i:
	# snapped() rounds, '-SIZE2/2' compensate the round
	return (Vector2i(i.x, i.y) - SIZE2/2).snapped(SIZE2)

@export var data : Array[TileMap3DTile]
@export var origin := Vector2i.ZERO

func _init(o: Vector2i = Vector2.ZERO) -> void:
	origin = o
	data.resize(SIZE.x * SIZE.y * SIZE.z)
	for i in range(data.size()):
		data[i] = TileMap3DTile.new()

func to_linear_index(i: Vector3i) -> int:
	var irel := Vector2i(i.x, i.y) - origin
	return irel.x + SIZE.x * (irel.y + SIZE.y * (i.z))

func is_inside(i: Vector3i) -> bool:
	var irel := Vector2i(i.x, i.y) - origin
	return (0 <= irel.x and irel.x < SIZE2.x and
			0 <= irel.y and irel.y < SIZE2.y)

func data_at(i: Vector3i) -> TileMap3DTile:
	var ilin := to_linear_index(i)
	return data[ilin]
