extends AudioStreamPlayer3D

export var modulate_pitch := true
export var modulate_db := false
var fade_in := 0.0
onready var plane_node = get_node("/root/World/Plane")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.stop()

func _process(delta):
	if self.playing:
		#if fade_in < 1.0:
		#	fade_in = min(1.0, fade_in + delta * 2)
		#	self.volume_db = -(1.0 - fade_in) * 80
		var speed_min := 150.0 / 3.6
		var speed_max := 500.0 / 3.6
		var speed = clamp(plane_node.get_linear_speed().length(), speed_min, speed_max)
		if modulate_pitch:
			self.pitch_scale = lerp(1.5, 2.5, inverse_lerp(speed_min, speed_max, speed))
		if modulate_db:
			self.unit_size = lerp(2.5, 6.0, inverse_lerp(speed_min, speed_max, speed))

func _on_Plane_race_initialized(checkpoint_count):
	#self.volume_db = 0
	self.play()
	fade_in = 0.0


func _on_Plane_plane_destroyed():
	pass#self.volume_db -= 20
