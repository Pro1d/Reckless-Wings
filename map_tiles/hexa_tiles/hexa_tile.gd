class_name HexaTile
extends Node3D

enum Part { TOP = 1, CLIFF = 2, BOTTOM = 4, NONE=0, ALL=0xff }

class DensityTexture3D:
	var textures: Array[Image]
	var texture_size: Vector3i
	var texture_scale: Vector3
	func density_at(global_pos: Vector3) -> float:
		var iglob := (Vector3i((global_pos * texture_scale).round()) % texture_size + texture_size) % texture_size
		return textures[iglob.z].get_pixel(iglob.x, iglob.y).r

class VegetationParams:
	var base_transform := Transform3D.IDENTITY
	var mesh_resource: ArrayMesh
	var mesh_material: BaseMaterial3D
	var mesh_scale: float
	var visibility_range_end: float
	var visibility_range_end_margin: float
	var parts: int
	enum PointCloud { TREE, BUSH }
	var pointcloud: PointCloud

static var tree_count := 0

var ground_enabled := true :
	set(ge):
		ground_enabled = ge
		_update_ground()
var mesh_instance_parts : Dictionary[MeshInstance3D, Part]

func _ready() -> void:
	for c in get_children():
		var mesh_instance := c as MeshInstance3D
		if c != null:
			var mesh_file := mesh_instance.mesh.resource_path.get_file()
			var part_name := mesh_file.split("_")[0]
			match part_name:
				"top":
					mesh_instance_parts[mesh_instance] = Part.TOP
				"ground":
					mesh_instance_parts[mesh_instance] = Part.BOTTOM
				"cliff":
					mesh_instance_parts[mesh_instance] = Part.CLIFF
	_update_ground()
	# Load alternative tiles
	# FIXME do it deterministically
	for c: MeshInstance3D in mesh_instance_parts:
		if not c.visible:
			continue
		#c.set_surface_override_material(0, preload("res://resources/materials/rock_grass.material"))
		#c.set_surface_override_material(0, preload("res://resources/materials/terrain.material"))
		match randi_range(0, 2):
			0:
				pass
			1:
				var m := load(c.mesh.resource_path.replace('.res', 'b.res'))
				if m != null:
					c.mesh = m
			2:
				var m := load(c.mesh.resource_path.replace('.res', 'c.res'))
				if m != null:
					c.mesh = m

func spawn_vegetation(
	vegetation_params: VegetationParams,
	density_texture: DensityTexture3D,
	transform_func: Callable) -> void:
	var positions : Array[Vector3]
	for mesh_instance in mesh_instance_parts:
		var part := mesh_instance_parts[mesh_instance]
		if mesh_instance.visible and (vegetation_params.parts & part) != 0:
			var prefix : String
			match vegetation_params.pointcloud:
				VegetationParams.PointCloud.TREE:
					prefix = "p_tree_"
				VegetationParams.PointCloud.BUSH:
					prefix = "p_bush_"
			var pointcloud := load(
				mesh_instance.mesh.resource_path
					.replace("top_", prefix + "top_")
					.replace("ground_", prefix + "ground_")
					.replace("cliff_", prefix + "cliff_")
			) as ArrayMesh
			var mdt := MeshDataTool.new()
			mdt.create_from_surface(pointcloud, 0)
			for vi in range(mdt.get_vertex_count() / 3):
				var v := mdt.get_vertex(vi * 3)
				var glob := transform_func.call(mesh_instance.to_global(v)) as Vector3
				if glob.y > 0 and randf() < density_texture.density_at(glob):
					positions.append(to_local(glob))
	
	tree_count += positions.size()
	prints("Total tree count:", tree_count)
	
	var mmi_tree := MultiMeshInstance3D.new()
	mmi_tree.multimesh = MultiMesh.new()
	mmi_tree.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var enable_color = vegetation_params.mesh_material != null and vegetation_params.mesh_material.vertex_color_use_as_albedo
	mmi_tree.multimesh.use_colors = enable_color
	mmi_tree.multimesh.instance_count = positions.size()
	mmi_tree.multimesh.mesh = vegetation_params.mesh_resource
	mmi_tree.material_override = vegetation_params.mesh_material
	mmi_tree.visibility_range_end = vegetation_params.visibility_range_end
	mmi_tree.visibility_range_end_margin = vegetation_params.visibility_range_end_margin
	mmi_tree.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for vi in range(positions.size()):
		var t := Transform3D(
			Basis(Vector3.LEFT, randf_range(0, deg_to_rad(3.0)))
				.rotated(Vector3.UP, randf_range(0, 2 * PI))
				.scaled(Vector3.ONE * vegetation_params.mesh_scale * randfn(1.0, 0.1)),
			positions[vi]
		) * vegetation_params.base_transform
		mmi_tree.multimesh.set_instance_transform(vi, t)
		if enable_color:
			var darken := randf_range(0.5, 1.0)
			var color := Color(darken, darken, darken)
			mmi_tree.multimesh.set_instance_color(vi, color)
	add_child(mmi_tree)
	
	#create_trimesh_collision()

func create_trimesh_collision() -> void:
	for n in get_children():
		var c := n as MeshInstance3D
		if c == null or not c.visible:
			continue
		c.create_trimesh_collision() # FIXME method is intended for debug only

func _update_ground() -> void:
	for c in get_children():
		var mesh_instance := c as MeshInstance3D
		var part = mesh_instance_parts.get(mesh_instance, Part.NONE)
		if (c.name.begins_with("Ground") or part == Part.BOTTOM) and c is Node3D:
			(c as Node3D).visible = ground_enabled
		
		if part == Part.TOP:
			mesh_instance.set_surface_override_material(0, preload("res://resources/materials/top_triplanar.res"))
		elif part != Part.NONE:
			const MatRes := preload("res://resources/materials/rock_grass.material")
			var mat := MatRes.duplicate() as ShaderMaterial
			mat.set_shader_parameter(
				"texture_mesh_normal",
				load("res://assets/texture/hexatiles-normal/%s_normal.png" % [mesh_instance.mesh.resource_path.get_file().replace('.res', '')]))
			mesh_instance.set_surface_override_material(0, mat)

func meshes_transform(modifier: Callable) -> void:
	for mesh_instance in mesh_instance_parts:
		mesh_instance.mesh = _apply_to_vertex(mesh_instance.mesh as ArrayMesh, mesh_instance.global_transform, modifier)

func _apply_to_vertex(mesh: ArrayMesh, tile_transform: Transform3D, modifier: Callable) -> ArrayMesh:
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	var tile_transform_inv := tile_transform.affine_inverse()
	for i in range(mdt.get_vertex_count()):
		var vertex := modifier.call(tile_transform * mdt.get_vertex(i)) as Vector3
		mdt.set_vertex(i, tile_transform_inv * vertex)
	
	var out_mesh := ArrayMesh.new()
	mdt.commit_to_surface(out_mesh)
	return out_mesh
