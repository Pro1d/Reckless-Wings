extends Skeleton

onready var plane_node = get_node('../../..')
onready var AileronL = find_bone("AileronL")
onready var AileronR = find_bone("AileronR")
onready var Elevator = find_bone("Elevator")
onready var Rudder = find_bone("Rudder")

func _process(delta):
	set_bone_pose(AileronL, Transform(Quat(Vector3(1,0,0), plane_node.aileron.surface_angle)))
	set_bone_pose(AileronR, Transform(Quat(Vector3(-1,0,0), plane_node.aileron.surface_angle)))
	set_bone_pose(Elevator, Transform(Quat(Vector3(1,0,0), plane_node.elevator.surface_angle)))
	set_bone_pose(Rudder, Transform(Quat(Vector3(0,1,0), plane_node.rudder.surface_angle)))
