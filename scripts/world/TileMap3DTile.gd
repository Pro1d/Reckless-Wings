class_name TileMap3DTile
extends Resource

# Canyon Side Index:
#     10^  4     3  ^9
# 11^  5   __-o-__   2  ^8
#     o--¨¨       ¨¨--o
#   # |               | 1  ^7
#     |               |
#   # |               | 0  ^6
#     o--__       __--o
#      #   ¨¨-o-¨¨   #
#          #     #


const STORED_EDGES := 3  # store left & top-left & top-right edges (others are stored by adjacent tiles)
const CANYON_SIDES_PER_EDGE := 2
const VERTICAL_EDGES := 2 # bottom & top (each tile has both; allowing discontinuity on cliff_offsets)

@export var fill : bool = false
@export var cliff_offsets: PackedByteArray

func _init() -> void:
	cliff_offsets.resize(CANYON_SIDES_PER_EDGE * STORED_EDGES * VERTICAL_EDGES)
	cliff_offsets.fill(0)

static func cliff_offset_index(side: TileMap3DMath.TileSide, horizontal_index: int, vertical_index: int) -> int:
	return horizontal_index + CANYON_SIDES_PER_EDGE * (side + STORED_EDGES * vertical_index)
	
func set_cliff_offset(side: TileMap3DMath.TileSide, horizontal_index: int, vertical_index: int, offset: int) -> void:
	cliff_offsets[cliff_offset_index(side, horizontal_index, vertical_index)] = offset
	
func get_cliff_offset(side: TileMap3DMath.TileSide, horizontal_index: int, vertical_index: int) -> int:
	return cliff_offsets[cliff_offset_index(side, horizontal_index, vertical_index)]
