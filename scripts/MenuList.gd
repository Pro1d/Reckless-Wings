extends CanvasLayer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("back"):
		get_tree().quit()
