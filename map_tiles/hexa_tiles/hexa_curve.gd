class_name HexaCurve
extends Node3D

enum Part { TOP = 1, CLIFF = 2, BOTTOM = 4, NONE=0, ALL=0xff }
enum Type { MODEL, VEG01, VEG02 }

class MeshIdentifier:
	var sides: int
	var part: Part
	var cliff_offsets: PackedByteArray
	var alt: int
	var type: Type
	
	func duplicate() -> MeshIdentifier:
		var mi := MeshIdentifier.new()
		mi.sides = sides
		mi.part = part
		mi.cliff_offsets = cliff_offsets
		mi.alt = alt
		mi.type = type
		return mi
	
	func to_str() -> String:
		return "_".join([
			str(sides),
			{Part.TOP: "top", Part.CLIFF: "cliff", Part.BOTTOM: "bottom"}[part],
			str(cliff_offsets[0], cliff_offsets[1], cliff_offsets[2], cliff_offsets[3]),
			str(alt).pad_zeros(2),
			{Type.MODEL: "model", Type.VEG01: "veg01", Type.VEG02: "veg02"}[type]
		])
	
	static func from_str(s: String) -> MeshIdentifier:
		var mi := MeshIdentifier.new()
		var fields := s.split("_")
		# example: "2_cliff_0101_00_model"
		if (fields.size() != 5
			or fields[0].length() != 1
			or fields[2].length() != 4
			or fields[3].length() != 2):
			return null
		
		# 0: sides
		mi.sides = fields[0].to_int()
		# 1: part
		match fields[1]:
			"top": mi.part = Part.TOP
			"cliff": mi.part = Part.CLIFF
			"bottom": mi.part = Part.BOTTOM
		# 2: cliff_offsets
		mi.cliff_offsets.resize(4)
		for i in range(mi.cliff_offsets.size()):
			mi.cliff_offsets[i] = fields[2].substr(i, 1).to_int()
		# 3: alt
		mi.alt = fields[3].to_int()
		# 4: type
		match fields[4]:
			"model": mi.type = Type.MODEL
			"veg01": mi.type = Type.VEG01
			"veg02": mi.type = Type.VEG02
		return mi

@export var curve_size := 0
@export var cliff_offsets : PackedByteArray
var mesh_identifiers : Dictionary[MeshInstance3D, MeshIdentifier]
var ground_enabled := true

func _ready() -> void:
	_init_meshes()
	
	# Make sure cliff_offsets size = 4, padding with 0s if necessary
	var prev_size := cliff_offsets.size()
	if prev_size < 4:
		cliff_offsets.resize(4)
		for i in range(prev_size, cliff_offsets.size()):
			cliff_offsets[i] = 0

func hexa_rot() -> int:
	# " - 1" because all curves are rotated by 60° so that first quadrant is a hole
	return posmod(roundi(rotation.y / (TAU / TileMap3DMath.SIDES)) - 1, TileMap3DMath.SIDES)

func setup() -> void:
	_update_ground()
	_update_cliff_offsets()
	_load_alternative_meshes()
	_assign_material()

static var curve_stats := {"total": 0}

func _init_meshes() -> void:
	for c in get_children():
		var mesh_instance := c as MeshInstance3D
		if c != null:
			var mesh_file := mesh_instance.mesh.resource_path.get_file()
			var stem := mesh_file.get_basename()
			mesh_identifiers[mesh_instance] = MeshIdentifier.from_str(stem)
			curve_stats[stem] = curve_stats.get(stem, 0) + 1
			curve_stats["total"] += 1

func _update_cliff_offsets() -> void:
	for m: MeshInstance3D in mesh_identifiers:
		var co := cliff_offsets.duplicate()
		if mesh_identifiers[m] == null:
			continue
		if mesh_identifiers[m].sides == 6:
			# end = begin
			co[0] = mini(co[0], 1)
			co[2] = mini(co[2], 1)
			co[1] = co[0]
			co[3] = co[2]
		if mesh_identifiers[m].part == Part.TOP:
			# bottom = top
			co[0] = co[2]
			co[1] = co[3]
		if mesh_identifiers[m].part == Part.TOP and mesh_identifiers[m].sides == 7:
			# all = 0
			co.fill(0)
		mesh_identifiers[m].cliff_offsets = co
		var array_mesh := load(m.mesh.resource_path.get_base_dir().path_join(mesh_identifiers[m].to_str()+".res"))
		if array_mesh != null:
			m.mesh = array_mesh
		else:
			printerr("Mesh not found: ", mesh_identifiers[m].to_str())

func _load_alternative_meshes() -> void:
	# TODO do it deterministically
	for c: MeshInstance3D in mesh_identifiers:
		if not c.visible or mesh_identifiers[c] == null:
			continue
		var max_alt := 0
		if (curve_size == 1 or curve_size == 2) and mesh_identifiers[c].part == Part.CLIFF:
			max_alt = 1
		if curve_size == 7:
			max_alt = 2
		if max_alt > 0:
			mesh_identifiers[c].alt = randi_range(0, max_alt)
			if mesh_identifiers[c].alt > 0:
				var m := load(c.mesh.resource_path.get_base_dir().path_join(mesh_identifiers[c].to_str()+".res"))
				if m != null:
					c.mesh = m
				else:
					printerr("Mesh not found: ", mesh_identifiers[c].to_str())

func _update_ground() -> void:
	for m: MeshInstance3D in mesh_identifiers:
		if mesh_identifiers[m] == null or mesh_identifiers[m].part == Part.BOTTOM:
			m.visible = ground_enabled
		
func _assign_material() -> void:
	for m: MeshInstance3D in mesh_identifiers:
		if not m.visible:
			continue
		if mesh_identifiers[m] != null and mesh_identifiers[m].part == Part.TOP:
			m.set_surface_override_material(0, preload("res://resources/materials/top_triplanar.res"))
		else:
			const MatRes := preload("res://resources/materials/rock_grass.material")
			var mat := MatRes.duplicate() as ShaderMaterial
			mat.set_shader_parameter(
				"texture_mesh_normal",
				load("res://assets/texture/hexatiles-normal/%s_normal.png" % [mesh_identifiers[m].to_str()]) if mesh_identifiers[m] != null else null)
			m.set_surface_override_material(0, mat)


#static var _pointcloud_mesh_cache : Dictionary[String, ArrayMesh]

# Returns spawn points for vegetation with density filtering and deformation
func vegetation_spawn_points(
	vegetation_params: HexaVegetation.Params,
	density_texture: HexaVegetation.DensityTexture3D,
	transform_func: Callable
) -> PackedVector3Array:
	var points_global : PackedVector3Array
	for mesh_instance in mesh_identifiers:
		var mi := mesh_identifiers[mesh_instance]
		if mi == null:
			continue
		if mesh_instance.visible and (vegetation_params.parts & mi.part) != 0:
			var mi_veg := mi.duplicate()
			match vegetation_params.pointcloud:
				HexaVegetation.Params.PointCloud.TREE:
					mi_veg.type = Type.VEG02
				HexaVegetation.Params.PointCloud.BUSH:
					mi_veg.type = Type.VEG01
			var pc_resource_path := (mesh_instance.mesh.resource_path.get_base_dir().path_join(
					mi_veg.to_str() + ".res"))
			
			#if not _pointcloud_mesh_cache.has(pc_resource_path):
				#_pointcloud_mesh_cache[pc_resource_path] = load(pc_resource_path)
			#var pointcloud := _pointcloud_mesh_cache[pc_resource_path]
			var pointcloud := load(pc_resource_path) as ArrayMesh
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
	for mesh_instance in mesh_identifiers:
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
	for mesh_instance in mesh_identifiers:
		if not mesh_instance.visible:
			continue
		mesh_instance.create_trimesh_collision() # FIXME method is intended for debug only
