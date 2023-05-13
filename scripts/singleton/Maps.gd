extends Node

const MAPS_DIRECTORY := "res://maps/"

func list_maps_in_directory(dir_path: String = Maps.MAPS_DIRECTORY) -> Array:
	var files := []
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tscn"):
			files.append(file)
	return files
