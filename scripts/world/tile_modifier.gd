extends Node

@export_group("Displacement", "disp_")
@export var disp_h_texture : Texture2D
@export var disp_v_texture : Texture2D
@export var disp_h_scale : float = 0.05
@export var disp_h_strength : float = 0.925
@export var disp_v_scale : float = 0.01
@export var disp_v_strength : float = 0.8
@export var disp_v_min_height : float = 0.8

@export_group("Vegetation", "veg_")
@export var veg_tree_density_texture : Texture3D

var h_img : Image
var v_img : Image

@onready var _tile_map := get_parent() as TileMap3D

func _ready() -> void:
	assert(_tile_map != null)
	_tile_map.loaded.connect(_on_tile_map_loaded)
	
func _on_tile_map_loaded() -> void:
	await wait_images()
	await _transform_all_tiles()
	#await _spawn_trees_on_all_tiles() # FIXME does not work if done after _transform_all_tiles

## vertex: in global coord
func _transform_vertex(vertex: Vector3) -> Vector3:
	var map_scale := _tile_map.scale.x
	var dh := (_read_image(
		h_img,
		vertex.x / map_scale * disp_h_scale,
		vertex.z / map_scale * disp_h_scale
		) * 2.0 - Vector3.ONE) * map_scale * disp_h_strength
	vertex += Vector3(dh.x, 0.0, dh.y)
	var dv := _read_image(
		v_img,
		vertex.x / map_scale * disp_v_scale,
		vertex.z / map_scale * disp_v_scale
	).x
	vertex.y *= disp_v_min_height + dv * disp_v_strength
	return vertex

func _identity_transform_vertex(v: Vector3) -> Vector3:
	return v

func _transform_all_tiles() -> void:
	var td_imgs := await _wait_image_3d(veg_tree_density_texture)
	var td_size := Vector3i(
		veg_tree_density_texture.get_width(),
		veg_tree_density_texture.get_height(),
		veg_tree_density_texture.get_depth()
	)
	var density_texture := HexaTile.DensityTexture3D.new()
	density_texture.textures = td_imgs
	density_texture.texture_size = td_size
	density_texture.texture_scale = Vector3.ONE * 0.1
	
	var bush_params := HexaTile.VegetationParams.new()
	bush_params.mesh_resource = preload("uid://bquctpri1enm")
	bush_params.mesh_material = preload("uid://b8ni0cqlh10kq")
	bush_params.mesh_scale = 0.0005
	bush_params.visibility_range_end = 500
	bush_params.visibility_range_end_margin = 100
	bush_params.parts = HexaTile.Part.ALL
	bush_params.pointcloud = HexaTile.VegetationParams.PointCloud.BUSH
	
	var tree_params := HexaTile.VegetationParams.new()
	tree_params.mesh_resource = preload("uid://dxvw52xf6051q") #preload("res://resources/meshes/low-poly-tree-pack/Tree Type1 03 Model.res")
	tree_params.mesh_material = preload("uid://k4yo4w5fxjab") #null
	tree_params.mesh_scale = 0.05
	tree_params.base_transform = Transform3D(Basis(Vector3.LEFT, PI/2))
	tree_params.visibility_range_end = 1000
	tree_params.visibility_range_end_margin = 300
	tree_params.parts = HexaTile.Part.TOP
	tree_params.pointcloud = HexaTile.VegetationParams.PointCloud.TREE
	
	for tile: HexaTile in _tile_map.hexa_tiles.values():
		await get_tree().process_frame
		var transform_func := _identity_transform_vertex # _transform_vertex
		tile.spawn_vegetation(bush_params, density_texture, transform_func)
		tile.spawn_vegetation(tree_params, density_texture, transform_func)
		#await get_tree().process_frame
		#tile.meshes_transform(transform_func)
		#await get_tree().process_frame
		#tile.create_trimesh_collision()

func _spawn_trees_on_all_tiles() -> void:
	var td_imgs := await _wait_image_3d(veg_tree_density_texture)
	var td_size := Vector3i(
		veg_tree_density_texture.get_width(),
		veg_tree_density_texture.get_height(),
		veg_tree_density_texture.get_depth()
	)
	var density_texture := HexaTile.DensityTexture3D.new()
	density_texture.textures = td_imgs
	density_texture.texture_size = td_size
	density_texture.texture_scale = Vector3.ONE * 0.1
	var bush_params := HexaTile.VegetationParams.new()
	bush_params.mesh_resource = preload("uid://bquctpri1enm")
	bush_params.mesh_material = preload("uid://b8ni0cqlh10kq")
	bush_params.mesh_scale = 0.0005
	bush_params.visibility_range_end = 500
	bush_params.visibility_range_end_margin = 100
	bush_params.parts = HexaTile.Part.ALL
	bush_params.pointcloud = HexaTile.VegetationParams.PointCloud.BUSH
	
	for tile: HexaTile in _tile_map.hexa_tiles.values():
		await get_tree().process_frame
		tile.spawn_vegetation(bush_params, density_texture, _transform_vertex)

func wait_images() -> void:
	if h_img == null:
		h_img = await _wait_image(disp_h_texture)
	if v_img == null:
		v_img = await _wait_image(disp_v_texture)
	
static func _wait_image(t: Texture2D) -> Image:
	var img := t.get_image()
	if img == null:
		await t.changed
		img = t.get_image()
	return img

static func _wait_image_3d(t: Texture3D) -> Array[Image]:
	var img := t.get_data()
	if img.is_empty():
		await t.changed
		img = t.get_data()
	return img

static func _read_image(image: Image, x: float, y: float) -> Vector3:
	var w := image.get_width()
	var h := image.get_height()
	# to pixel center
	x = x * w - .5
	y = y * h - .5
	#var c := image.get_pixel(posmod(floori(x), w), posmod(floori(y), h))
	# neighboring pixel coords + weights
	var x1 := floori(x)
	var dx := x - x1
	var y1 := floori(y)
	var dy := y - y1
	x1 = posmod(x1, w)
	var x2 := (x1 + 1) % w
	y1 = posmod(y1, h)
	var y2 := (y1 + 1) % h
	# pixel values
	var p11 := image.get_pixel(x1, y1)
	var p21 := image.get_pixel(x2, y1)
	var p12 := image.get_pixel(x1, y2)
	var p22 := image.get_pixel(x2, y2)
	var c := p11.lerp(p21, dx).lerp(p12.lerp(p22, dx), dy)
	return Vector3(c.r, c.g, c.b)
