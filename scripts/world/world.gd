extends Node3D


@onready var _tile_map_3d := $TileMap3D as TileMap3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_tile_map_3d.load_map("res://maps/aaa.res")
	#_tile_map_3d.distort()
