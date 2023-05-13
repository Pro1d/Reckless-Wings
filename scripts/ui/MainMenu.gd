extends Control

@onready var map_button_template: Button = $MarginContainer/VBoxContainer/ScrollContainer/CenterContainer/VBoxContainer/MapButtonTemplate

func _ready() -> void:
	var maps_path := Maps.list_maps_in_directory()
	var list := map_button_template.get_parent()
	for mp in maps_path:
		var button: Button = map_button_template.duplicate()
		button.text = mp
		button.pressed.connect(_on_map_button_pressed.bind(mp))
		list.add_child(button)
		if list.get_child_count() == 1:
			button.grab_focus()
	map_button_template.hide()

func _on_map_button_pressed(map: String) -> void:
	print_debug("Selected map: ", map)
	SceneManager.change_to_race(Maps.MAPS_DIRECTORY + map)

func _input(event: InputEvent):
	if event.is_action_pressed("back"):
		get_tree().quit()
