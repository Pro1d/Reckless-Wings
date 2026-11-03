class_name HexaTile
extends Node3D

const HEXA_VEGETATION := preload("res://map_tiles/hexa_tiles/hexa_vegetation.tscn")

class CliffOffsets:
	var begin_bottom_offsets: PackedByteArray
	var end_bottom_offsets: PackedByteArray
	var begin_top_offsets: PackedByteArray
	var end_top_offsets: PackedByteArray
	func _init() -> void:
		begin_bottom_offsets.resize(TileMap3DMath.SIDES)
		end_bottom_offsets.resize(TileMap3DMath.SIDES)
		begin_top_offsets.resize(TileMap3DMath.SIDES)
		end_top_offsets.resize(TileMap3DMath.SIDES)

static var tree_count := 0

var cliff_offsets : CliffOffsets
var ground_enabled := true
var hexa_curves : Array[HexaCurve]
var hexa_vegetation : HexaVegetation

func _ready() -> void:
	#print(position)
	#print(cliff_offsets.begin_bottom_offsets)
	#print(cliff_offsets.end_bottom_offsets)
	#print(cliff_offsets.begin_top_offsets)
	#print(cliff_offsets.end_top_offsets)
	for c in get_children():
		var hc := c as HexaCurve
		if hc != null:
			hexa_curves.append(hc)
			var hrot_begin := posmod((hexa_rot() + hc.hexa_rot()), TileMap3DMath.SIDES)
			var hrot_end := posmod(hrot_begin + hc.curve_size + 1, TileMap3DMath.SIDES)
			hc.cliff_offsets[0] = cliff_offsets.begin_bottom_offsets[hrot_begin]
			hc.cliff_offsets[1] = cliff_offsets.end_bottom_offsets[hrot_end]
			hc.cliff_offsets[2] = cliff_offsets.begin_top_offsets[hrot_begin]
			hc.cliff_offsets[3] = cliff_offsets.end_top_offsets[hrot_end]
			#prints(hc, hc.cliff_offsets, hexa_rot(), '|', hrot_begin, hrot_end, 'cs',  hc.curve_size)
			hc.ground_enabled = ground_enabled
			hc.setup()

func hexa_rot() -> int:
	return posmod(roundi(rotation.y / (TAU / TileMap3DMath.SIDES)), TileMap3DMath.SIDES)

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
