extends Node3D

@export
var _rudder_bone := "Rudder"
@export
var _elevator_bone := "Elevator"
@export
var _left_aileron_bone := "AileronL"
@export
var _right_aileron_bone := "AileronR"
@export
var _rudder_axis := Vector3(0, 1, 0)
@export
var _elevator_axis := Vector3(1, 0, 0)
@export
var _left_aileron_axis := Vector3(1, 0, 0)
@export
var _right_aileron_axis := Vector3(-1, 0, 0)
@export
var _rudder: ControlSurface
@export
var _elevator: ControlSurface
@export
var _aileron: ControlSurface

@onready var _skeleton: Skeleton3D = $PlaneSkeleton/Skeleton3D
@onready var _rudder_bone_idx := _skeleton.find_bone(_rudder_bone)
@onready var _elevator_bone_idx := _skeleton.find_bone(_elevator_bone)
@onready var _left_aileron_bone_idx := _skeleton.find_bone(_left_aileron_bone)
@onready var _right_aileron_bone_idx := _skeleton.find_bone(_right_aileron_bone)
@onready var _rudder_rest := _skeleton.get_bone_rest(_rudder_bone_idx).basis.get_rotation_quaternion()
@onready var _elevator_rest := _skeleton.get_bone_rest(_elevator_bone_idx).basis.get_rotation_quaternion()
@onready var _left_aileron_rest := _skeleton.get_bone_rest(_left_aileron_bone_idx).basis.get_rotation_quaternion()
@onready var _right_aileron_rest := _skeleton.get_bone_rest(_right_aileron_bone_idx).basis.get_rotation_quaternion()

func _process(_delta: float) -> void:
	_skeleton.set_bone_pose_rotation(
		_rudder_bone_idx,
		_rudder_rest * Quaternion(
			_rudder_axis, _rudder.surface_angle
		))
	_skeleton.set_bone_pose_rotation(
		_elevator_bone_idx,
		_elevator_rest * Quaternion(
			_elevator_axis, _elevator.surface_angle
		))
	_skeleton.set_bone_pose_rotation(
		_left_aileron_bone_idx,
		_left_aileron_rest * Quaternion(
			_left_aileron_axis, _aileron.surface_angle
		))
	_skeleton.set_bone_pose_rotation(
		_right_aileron_bone_idx,
		_right_aileron_rest * Quaternion(
			_right_aileron_axis, _aileron.surface_angle
		))
