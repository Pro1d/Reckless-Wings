extends VBoxContainer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
func list_maps_in_directory(path):
    var files = []
    var dir = Directory.new()
    dir.open(path)
    dir.list_dir_begin()

    while true:
        var file = dir.get_next()
        if file == "":
            break
        elif not file.begins_with(".") and file.ends_with(".tscn"):
            files.append(file)

    dir.list_dir_end()

    return files
	
func _ready():
	while get_child_count():
		remove_child(get_child(0))
	var maps = list_maps_in_directory(Globals.MAP_DIRECTORY)
	var button_scene = load("res://scenes/MenuList/RaceButton.tscn")
	for m in maps:
		var b = button_scene.instance()
		b.set_name(m)
		b.text = m
		b.connect("button_down", self, "_on_race_selected", [m])
		add_child(b)
	if get_child_count():
		get_child(0).grab_focus()

func _on_race_selected(name):
	Globals.MAP_NAME = name
	get_tree().change_scene("res://scenes/world.tscn")

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
