extends Node

var current_map_path: String

func change_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func change_to_race(map_path: String) -> void:
	current_map_path = map_path
	get_tree().change_scene_to_file("res://scenes/logic/Race.tscn")
