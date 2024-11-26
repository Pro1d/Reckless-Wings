@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene: Node) -> Node:
	# Change all node names to "modified_[oldnodename]"
	iterate(scene)
	return scene # Remember to return the imported scene

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node: Node) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and node.name.ends_with("Model"):
		print(node.name, " ", mesh_instance.mesh)
		(mesh_instance.mesh as ArrayMesh).surface_set_material(
			0, preload("res://resources/materials/trees_normal.material")
		)
		ResourceSaver.save(mesh_instance.mesh, "res://resources/meshes/low-poly-tree-pack".path_join(node.name+".res"))
	if node != null:
		for child: Node in node.get_children():
			iterate(child)
