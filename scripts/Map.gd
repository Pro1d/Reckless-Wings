extends Position3D

var checkpoint_count # number of checkpoint to be crossed before finnishing the course

func get_start_position():
	for tile in get_children():
		var sp = tile.find_node("StartPosition*", false)
		if sp != null:
			return sp.global_transform

func _ready():
	checkpoint_count = 0
	for tile in get_children():
		if tile.find_node("Checkpoint*", false) != null:
			checkpoint_count += 1
	

func get_checkpoint_count():
	return checkpoint_count