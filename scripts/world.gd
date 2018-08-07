extends Position3D

signal map_loaded(map_node)

func _ready():
	load_record()
	var map_node = load_map()
	emit_signal("map_loaded", map_node)

func load_map():
	var map_filename = Globals.MAP_DIRECTORY + Globals.MAP_NAME
	var button_scene = load(map_filename)
	var map = button_scene.instance()
	map.set_name("Map")
	var old_map = get_node("Map")
	remove_child(old_map)
	old_map.queue_free()
	add_child(map)
	return map

func load_record():
	get_node("Plane/Recorder").load_map_record()

