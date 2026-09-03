extends Area3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var mesh_size := (mesh.mesh as PlaneMesh).size.x
@onready var material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
@onready var texture_world_size := mesh_size * mesh.scale.x

func _ready() -> void:
	($AnimationPlayer as AnimationPlayer).play("uv1")

func _process(_delta: float) -> void:
	var current_camera := get_viewport().get_camera_3d()
	if current_camera != null:
		var cam_origin := current_camera.global_position
		var mesh_origin := mesh.global_position
		mesh_origin.x = snappedf(cam_origin.x, texture_world_size)
		mesh_origin.z = snappedf(cam_origin.z, texture_world_size)
		mesh.global_position = mesh_origin
		var scale_factor := snappedf(
			tan(deg_to_rad(89.8)) * absf(cam_origin.y) / (mesh_size / 2), 2.0)
		scale_factor = maxf(scale_factor, 2.0)
		mesh.scale = Vector3.ONE * scale_factor
		material.uv1_scale = Vector3.ONE * scale_factor
