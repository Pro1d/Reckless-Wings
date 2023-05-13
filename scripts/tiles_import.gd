extends Node

var dir = Directory.new()
const EVENT_AREA_LAYER_ID = 1
const PLAYER_AREA_LAYER_ID = 3
var saved_tiles = 0

func make_event_area(node):
		var tr = node.transform
		var nm = node.name
		var child = node.get_children()[0]
		node.remove_child(child)
		var parent = node.get_parent()
		parent.remove_child(node)
		var area = Area3D.new()
		parent.add_child(area)
		area.name = nm
		area.transform = tr
		area.set_collision_layer_value(0, false)
		area.set_collision_layer_value(EVENT_AREA_LAYER_ID, true)
		area.set_collision_mask_value(0, false)
		area.set_collision_mask_value(PLAYER_AREA_LAYER_ID, true)
		area.add_child(child)
		return area

func update_owner(nodes, own):
	for c in nodes:
		c.set_owner(own)
		update_owner(c.get_children(), own)

func save(node):
	# clear transform
	var tr = node.global_transform
	node.global_transform = Transform3D()
	# set owner
	update_owner(node.get_children(), node)
	# pack
	var packed_scene = PackedScene.new()
	packed_scene.pack(node)
	# save in file
	var fn = "res://map_tiles/canyon/"+node.name+".scn" 
	#var fn = "res://map_tiles/canyon/"+get_path_to(node)+".scn"
	dir.make_dir_recursive(fn.get_base_dir())
	ResourceSaver.save(fn, packed_scene)
	print("Saved: ", fn)
	saved_tiles += 1
	node.global_transform = tr
	

func save_recc(node, depth = 1):
	var has_spatial_children = false
	for c in node.get_children():
		if str(c).begins_with("[Node3D:") and not c.name.begins_with("StartPosition"):
			save_recc(c)
			has_spatial_children = true
		elif c.name.ends_with("-convcolonly") and str(c).begins_with("[StaticBody3D:"):
			make_event_area(c)
			print("Converted area: ", c.name)
	if not has_spatial_children and node.get_child_count() > 0:
		save(node)

func _ready():
	save_recc(self)
	print("Saved ", saved_tiles, " tiles!")
