extends Area3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var mesh_size := (mesh.mesh as PlaneMesh).size.x
@onready var offset_step: float = (
	(($CollisionShape as CollisionShape3D).shape as BoxShape3D).size.x
	/ (mesh.mesh.surface_get_material(0) as StandardMaterial3D).uv1_scale.x
)

func _ready() -> void:
	($AnimationPlayer as AnimationPlayer).play("uv1")

func _process(_delta: float) -> void:
	var current_camera := get_viewport().get_camera_3d()
	if current_camera != null:
		var cam_origin := current_camera.global_position
		var mesh_origin := mesh.global_position
		mesh_origin.x = snappedf(cam_origin.x, offset_step)
		mesh_origin.z = snappedf(cam_origin.z, offset_step)
		mesh.global_position = mesh_origin
		mesh.scale = Vector3.ONE * ceilf(tan(deg_to_rad(88.0)) * cam_origin.y / (mesh_size / 2))
