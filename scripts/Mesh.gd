extends RigidBody3D

@onready var plane_node : Aircraft = get_parent()
var static_transform

func _ready():
	static_transform = transform

func _on_race_initialized(_checkpoint_count):
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true
	# FIXME mode = RigidBody3D.FREEZE_MODE_STATIC
	set_axis_velocity(Vector3.ZERO)
	transform = static_transform

func _on_plane_destroyed():
	freeze = false
	# FIXME mode = RigidBody3D.MODE_RIGID
	var velocity := plane_node.global_transform.basis * plane_node.get_linear_speed()
	set_axis_velocity(velocity)
