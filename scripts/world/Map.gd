class_name Map
extends Marker3D

signal aircraft_start_reached(aircraft: Aircraft)
signal aircraft_checkpoint_reached(aircraft: Aircraft, checkpoint_id: int)
signal aircraft_finish_reached(aircraft: Aircraft)

var _checkpoint_count: int# number of checkpoint to be crossed before finnishing the race

func _ready() -> void:
	_checkpoint_count = 0
	for tile in get_children():
		var nodes := tile.find_children("*", "Area3D", false)
		if nodes.size() == 1:
			var area: Area3D = nodes[0]
			if area.name.begins_with("Start"):
				area.body_entered.connect(_on_body_entered_start_area)
			elif area.name.begins_with("Checkpoint"):
				area.body_entered.connect(_on_body_entered_checkpoint_area.bind(_checkpoint_count))
				_checkpoint_count += 1
			elif area.name.begins_with("Finish"):
				area.body_entered.connect(_on_body_entered_finish_area)

func get_start_position() -> Transform3D:
	for tile in get_children():
		var sp := tile.find_child("StartPosition*", false)
		if sp != null:
			return (sp as Node3D).global_transform
	printerr("Cannot find StartPosition* node")
	return Transform3D()

func get_checkpoint_count():
	return _checkpoint_count

func _on_body_entered_start_area(body: Node3D) -> void:
	if body is Aircraft:
		aircraft_start_reached.emit(body)

func _on_body_entered_finish_area(body: Node3D) -> void:
	if body is Aircraft:
		aircraft_finish_reached.emit(body)

func _on_body_entered_checkpoint_area(body: Node3D, checkpoint_id: int) -> void:
	if body is Aircraft:
		aircraft_checkpoint_reached.emit(body, checkpoint_id)
