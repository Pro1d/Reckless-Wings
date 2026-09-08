class_name HexaTile
extends Node3D

const HEXA_VEGETATION := preload("res://map_tiles/hexa_tiles/hexa_vegetation.tscn")

static var tree_count := 0

var ground_enabled := true
var hexa_curves : Array[HexaCurve]
var hexa_vegetation : HexaVegetation

func _ready() -> void:
	for c in get_children():
		var hc := c as HexaCurve
		if hc != null:
			hexa_curves.append(hc)
			hc.ground_enabled = ground_enabled
			hc.setup()

func spawn_vegetation(
	vegetation_params: HexaVegetation.Params,
	density_texture: HexaVegetation.DensityTexture3D,
	transform_func: Callable) -> void:
	hexa_vegetation = HEXA_VEGETATION.instantiate() as HexaVegetation
	add_child(hexa_vegetation)
	var spawn_points : PackedVector3Array
	for hc in hexa_curves:
		spawn_points.append_array(
			hc.vegetation_spawn_points(vegetation_params, density_texture, transform_func))
	
	hexa_vegetation.spawn_vegetation(spawn_points, vegetation_params)

func create_trimesh_collision() -> void:
	for hc in hexa_curves:
		hc.create_trimesh_collision() # FIXME method is intended for debug only

func meshes_transform(modifier: Callable) -> void:
	for hc in hexa_curves:
		hc.meshes_transform(modifier)
