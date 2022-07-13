extends RigidBody

onready var plane_node = get_parent()
var static_transform

func _ready():
	static_transform = transform

# warning-ignore:unused_argument
func _on_race_initialized(checkpoint_count):
	mode = RigidBody.MODE_STATIC
	set_axis_velocity(Vector3.ZERO)
	transform = static_transform

func _on_plane_destroyed():
	mode = RigidBody.MODE_RIGID
	var velocity = plane_node.global_transform.basis * plane_node.get_linear_speed()
	set_axis_velocity(velocity)
