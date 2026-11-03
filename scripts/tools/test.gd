@tool
extends EditorScript

func _run() -> void:
	var si := TileMap3DMath.SideIndex.new()
	for side: TileMap3DMath.TileSide in TileMap3DMath.TileSide.values():
		si.tile_index = Vector3i.ZERO
		si.side = side
		si.reverse_horizontal = false
		si.normalize()
		prints(si.tile_index, si.side, si.reverse_horizontal)
		print(TileMap3DMath.neighbor(si.tile_index, si.side))
