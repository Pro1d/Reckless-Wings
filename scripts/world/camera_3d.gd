extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if current:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	var emm := event as InputEventMouseMotion
	var emb := event as InputEventMouseButton
	var ek := event as InputEventKey
	if emb != null and emb.button_index == MOUSE_BUTTON_LEFT and emb.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE
	if emm != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= emm.relative.x * TAU / 300
		rotation.x -= emm.relative.y * TAU / 300
	if ek != null:
		if ek.is_pressed():
			match ek.physical_keycode:
				KEY_UP:
					global_position += global_transform.basis * Vector3.FORWARD
				KEY_DOWN:
					global_position += global_transform.basis * Vector3.BACK
				KEY_LEFT:
					global_position += global_transform.basis * Vector3.LEFT
				KEY_RIGHT:
					global_position += global_transform.basis * Vector3.RIGHT
