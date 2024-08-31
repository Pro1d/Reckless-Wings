class_name HexaTile
extends Node3D

var ground_enabled := true :
	set(ge):
		ground_enabled = ge
		_update_ground()

func _ready() -> void:
	_update_ground()
	for c: MeshInstance3D in get_children():
		if c == null:
			continue
		c.set_surface_override_material(0, preload("res://resources/triplanar_grid.material"))

func create_trimesh_collision() -> void:
	for c: MeshInstance3D in get_children():
		if c == null:
			continue
		c.create_trimesh_collision() # FIXME method is intended for debug only

func _update_ground() -> void:
	for c in get_children():
		if c.name.begins_with("Ground") and c is Node3D:
			(c as Node3D).visible = ground_enabled
