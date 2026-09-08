class_name HexaCurve
extends Node3D

enum Part { TOP = 1, CLIFF = 2, BOTTOM = 4, NONE=0, ALL=0xff }

@export var curve_size := 0
var mesh_instance_parts : Dictionary[MeshInstance3D, Part]
var ground_enabled := true

func _ready() -> void:
	_init_meshes()
	
func setup() -> void:
	_update_ground()
	_load_alternative_meshes()
	_assign_material()

func _init_meshes() -> void:
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

func _load_alternative_meshes() -> void:
	# TODO do it deterministically
	for c: MeshInstance3D in mesh_instance_parts:
		if not c.visible:
			continue
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

func _update_ground() -> void:
	for mesh_instance: MeshInstance3D in mesh_instance_parts:
		var part := mesh_instance_parts[mesh_instance]
		if part == Part.BOTTOM:
			mesh_instance.visible = ground_enabled
		
func _assign_material() -> void:
	for mesh_instance: MeshInstance3D in mesh_instance_parts:
		if not mesh_instance.visible:
			continue
		match mesh_instance_parts[mesh_instance]:
			Part.TOP:
				mesh_instance.set_surface_override_material(0, preload("res://resources/materials/top_triplanar.res"))
			_:
				const MatRes := preload("res://resources/materials/rock_grass.material")
				var mat := MatRes.duplicate() as ShaderMaterial
				mat.set_shader_parameter(
					"texture_mesh_normal",
					load("res://assets/texture/hexatiles-normal/%s_normal.png" % [mesh_instance.mesh.resource_path.get_file().replace('.res', '')]))
				mesh_instance.set_surface_override_material(0, mat)


static var _pointcloud_mesh_cache : Dictionary[String, ArrayMesh]

# Returns spawn points for vegetation with density filtering and deformation
func vegetation_spawn_points(
	vegetation_params: HexaVegetation.Params,
	density_texture: HexaVegetation.DensityTexture3D,
	transform_func: Callable
) -> PackedVector3Array:
	var points_global : PackedVector3Array
	for mesh_instance in mesh_instance_parts:
		var part := mesh_instance_parts[mesh_instance]
		if mesh_instance.visible and (vegetation_params.parts & part) != 0:
			var prefix : String
			match vegetation_params.pointcloud:
				HexaVegetation.Params.PointCloud.TREE:
					prefix = "p_tree_"
				HexaVegetation.Params.PointCloud.BUSH:
					prefix = "p_bush_"
			var pc_resource_path := (mesh_instance.mesh.resource_path
					.replace("top_", prefix + "top_")
					.replace("ground_", prefix + "ground_")
					.replace("cliff_", prefix + "cliff_"))
			
			if not _pointcloud_mesh_cache.has(pc_resource_path):
				_pointcloud_mesh_cache[pc_resource_path] = load(pc_resource_path)
			var pointcloud := _pointcloud_mesh_cache[pc_resource_path]
			
			var mdt := MeshDataTool.new()
			mdt.create_from_surface(pointcloud, 0)
			var number_of_points := mdt.get_vertex_count() / 3
			var offset_points := points_global.size()
			points_global.resize(offset_points + number_of_points)
			
			for vi in range(number_of_points):
				var v := mdt.get_vertex(vi * 3)
				
				var glob := transform_func.call(mesh_instance.to_global(v)) as Vector3
				if glob.y > 0 and randf() < density_texture.density_at(glob):
					points_global[offset_points] = glob
					offset_points += 1
			
			points_global.resize(offset_points)
	
	return points_global

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

func create_trimesh_collision() -> void:
	for mesh_instance in mesh_instance_parts:
		if not mesh_instance.visible:
			continue
		mesh_instance.create_trimesh_collision() # FIXME method is intended for debug only
