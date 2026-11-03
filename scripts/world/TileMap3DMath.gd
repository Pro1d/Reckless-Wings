class_name TileMap3DMath

enum TileSide { RIGHT=0, TOP_RIGHT, TOP_LEFT, LEFT, BOTTOM_LEFT, BOTTOM_RIGHT }

const SIDES := 6

class SideIndex:
	var tile_index: Vector3i
	var side: TileSide
	var reverse_horizontal: bool = false
	func normalize() -> void:
		if side >= TileSide.LEFT:
			tile_index = TileMap3DMath.neighbor(tile_index, side)
			side = (side as int - TileSide.LEFT as int) as TileSide
			reverse_horizontal = not reverse_horizontal

static func left(i: Vector3i) -> Vector3i:
	return Vector3(i.x - 1, i.y, i.z)

static func right(i: Vector3i) -> Vector3i:
	return Vector3i(i.x + 1, i.y, i.z)

static func up_left(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x - 1 + odd_y, i.y - 1, i.z)

static func up_right(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x + odd_y, i.y - 1, i.z)

static func down_left(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x  - 1 + odd_y, i.y + 1, i.z)

static func down_right(i: Vector3i) -> Vector3i:
	var odd_y := i.y & 1
	return Vector3i(i.x + odd_y, i.y + 1, i.z)

#static var _neighbor : Array[Callable] = [right, up_right, up_left, left, down_left, down_right]

static func neighbor(i: Vector3i, side: TileSide) -> Vector3i:
	match side:
		TileSide.RIGHT:
			return right(i)
		TileSide.TOP_RIGHT:
			return up_right(i)
		TileSide.TOP_LEFT:
			return up_left(i)
		TileSide.LEFT:
			return left(i)
		TileSide.BOTTOM_LEFT:
			return down_left(i)
		TileSide.BOTTOM_RIGHT:
			return down_right(i)
		_:
			return i
