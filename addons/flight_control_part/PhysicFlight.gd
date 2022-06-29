tool
extends EditorPlugin


func _enter_tree():
	add_custom_type(
		"PhysicComponent",
		"Position3D",
		preload("PhysicComponent.gd"),
		preload("flight_control_part.png"))
	add_custom_type(
		"PhysicPlane",
		"RigidBody",
		preload("PhysicPlane.gd"),
		preload("flight_control_part.png"))


func _exit_tree():
	remove_custom_type("PhysicComponent")
	remove_custom_type("PhysicPlane")
