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
	if mesh_instance != null:
		print(node.name, " ", mesh_instance.mesh)
		ResourceSaver.save(mesh_instance.mesh, "res://map_tiles/hexa_parts".path_join(node.name+".res"))
	if node != null:
		for child: Node in node.get_children():
			iterate(child)
