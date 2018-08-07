extends Node

const OFFSET_STEP = 16000 / 200 # mesh size / uv scale

onready var mesh_node = get_node("MeshInstance")

func _ready():
	get_node("AnimationPlayer").play("uv1")

func _process(delta):
	var cam_origin = get_viewport().get_camera().global_transform.origin
	var mesh_origin = mesh_node.global_transform.origin
	mesh_origin.x = round(cam_origin.x / OFFSET_STEP) * OFFSET_STEP
	mesh_origin.z = round(cam_origin.z / OFFSET_STEP) * OFFSET_STEP
	mesh_node.global_transform.origin = mesh_origin