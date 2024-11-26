class_name HexaTile
extends Node3D

var ground_enabled := true :
	set(ge):
		ground_enabled = ge
		_update_ground()
var _generate_trees := false

func _ready() -> void:
	_update_ground()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	#var aabb := AABB()
	var positions : Array[Vector3]
	for c: MeshInstance3D in get_children():
		if c == null or not c.visible:
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
		c.set_surface_override_material(0, preload("res://resources/materials/terrain.material"))
		c.set_surface_override_material(1, preload("res://resources/materials/terrain.material"))
		if c.visible and _generate_trees: #c.mesh.resource_path.contains("ground_"):
			var pointcloud := load(
				c.mesh.resource_path.replace("top_", "p_tree_top_").replace("ground_", "p_tree_ground_").replace("cliff_", "p_tree_cliff_")
			) as ArrayMesh
			var mdt := MeshDataTool.new()
			mdt.create_from_surface(pointcloud, 0)
			for vi in range(mdt.get_vertex_count() / 3 / 8):
				var v := mdt.get_vertex(vi * 3 * 8)
				if v.y > 0:
					positions.append(c.transform * v)
	
	if _generate_trees:
		#mm.instance_count = positions.size()
		for vi in range(positions.size()):
			var t := Transform3D(
				Basis(Vector3.UP, randf_range(0, 2*PI)).scaled(Vector3.ONE * 0.015),
				positions[vi]
			)
			#mm.set_instance_transform(vi, t)
			var mi := MeshInstance3D.new()
			mi.mesh = preload("res://resources/meshes/low-poly-tree-pack/Tree Type6 03 Model.res")
			mi.transform = t
			add_child(mi)
			#if not aabb:
				#aabb = AABB(v, Vector3.ZERO)
			#else:
				#aabb = aabb.expand(v)
	
		#var mmi_tree := MultiMeshInstance3D.new()
		#mm.mesh = preload("res://resources/meshes/low-poly-tree-pack/Tree Type6 03 Model.res")
		##mm.custom_aabb = aabb.grow(mm.mesh.get_aabb().get_longest_axis_size())
		#mmi_tree.multimesh = mm
		#add_child(mmi_tree)
	
	#create_trimesh_collision()

func create_trimesh_collision() -> void:
	for n in get_children():
		var c := n as MeshInstance3D
		if c == null or not c.visible:
			continue
		c.create_trimesh_collision() # FIXME method is intended for debug only

func _update_ground() -> void:
	for c in get_children():
		if c.name.begins_with("Ground") and c is Node3D:
			(c as Node3D).visible = ground_enabled

func meshes_transform(modifier: Callable) -> void:
	for n in get_children():
		var c := n as MeshInstance3D
		if c != null:
			c.mesh = _apply_to_vertex(c.mesh as ArrayMesh, transform * c.transform, modifier)

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
