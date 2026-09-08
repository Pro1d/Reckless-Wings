class_name HexaVegetation
extends MultiMeshInstance3D

class Params:
	var base_transform := Transform3D.IDENTITY
	var mesh_resource: ArrayMesh
	var mesh_material: BaseMaterial3D
	var mesh_scale: float
	var visibility_range_end: float
	var visibility_range_end_margin: float
	var parts: int
	enum PointCloud { TREE, BUSH }
	var pointcloud: PointCloud

class DensityTexture3D:
	var textures: Array[Image]
	var texture_size: Vector3i
	var texture_scale: Vector3
	func density_at(global_pos: Vector3) -> float:
		var iglob := (Vector3i((global_pos * texture_scale).round()) % texture_size + texture_size) % texture_size
		return textures[iglob.z].get_pixel(iglob.x, iglob.y).r

static var _tree_count := 0
func spawn_vegetation(
	spawn_points: PackedVector3Array,
	vegetation_params: Params) -> void:
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var enable_color = vegetation_params.mesh_material != null and vegetation_params.mesh_material.vertex_color_use_as_albedo
	multimesh.use_colors = enable_color
	multimesh.instance_count = spawn_points.size()
	multimesh.mesh = vegetation_params.mesh_resource
	material_override = vegetation_params.mesh_material
	visibility_range_end = vegetation_params.visibility_range_end
	visibility_range_end_margin = vegetation_params.visibility_range_end_margin
	visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for vi in range(spawn_points.size()):
		var t := Transform3D(
			Basis(Vector3.LEFT, randf_range(0, deg_to_rad(3.0)))
				.rotated(Vector3.UP, randf_range(0, 2 * PI))
				.scaled(Vector3.ONE * vegetation_params.mesh_scale * randfn(1.0, 0.1)),
			to_local(spawn_points[vi])
		) * vegetation_params.base_transform
		multimesh.set_instance_transform(vi, t)
		if enable_color:
			var darken := randf_range(0.5, 1.0)
			var color := Color(darken, darken, darken)
			multimesh.set_instance_color(vi, color)
	
	_tree_count += spawn_points.size()
	prints("Total tree count:", _tree_count)
