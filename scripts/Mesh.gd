extends RigidBody

onready var plane_node = get_parent()
var static_transform

func _ready():
	static_transform = transform

func _on_race_initialized(checkpoint_count):
	mode = RigidBody.MODE_STATIC
	set_axis_velocity(Vector3(0,0,0))
	transform = static_transform

func _on_plane_destroyed():
	mode = RigidBody.MODE_RIGID
	var velocity = plane_node.to_global(Vector3(plane_node.get_linear_speed(), 0, 0)) - plane_node.global_transform.origin
	set_axis_velocity(velocity)