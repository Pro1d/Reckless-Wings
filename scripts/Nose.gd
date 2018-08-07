extends Area

signal start_line_crossed
signal checkpoint_crossed
signal finish_line_crossed
signal wind_entered(area)
signal wind_exited(area)

func _on_area_entered(area):
	if area.name.begins_with("Start"):
		emit_signal("start_line_crossed")
	elif area.name.begins_with("Checkpoint"):
		emit_signal("checkpoint_crossed", area)
	elif area.name.begins_with("Finish"):
		emit_signal("finish_line_crossed")
	elif area.name.begins_with("Wind"):
		emit_signal("wind_entered", area)


func _on_area_exited(area):
	if area.name.begins_with("Wind"):
		emit_signal("wind_exited", area)
