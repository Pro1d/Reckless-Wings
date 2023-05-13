class_name Recorder
extends Node


"""
Recorder and official chronometer
used : for ghost, best time, checkpoint diff
"""

var best_track := {"pose": PackedFloat32Array(), "checkpoint": [], "time": 0}

var record_pose := PackedFloat32Array()
var record_checkpoint := []
var record_time

var recording := false
var race_time := 0
@onready var plane_node : Aircraft = get_parent()
@onready var mesh : RigidBody3D = plane_node.get_node("RigidBody3D")

func _ready():
	set_physics_process(false)

# warning-ignore:unused_argument
func _physics_process(_delta):
	if recording:
		record_pose.append_array(acquire_frame())
		race_time += 1

func acquire_frame() -> Array:
	var t := mesh.global_transform
	var q := t.basis.get_rotation_quaternion()
	var o := t.origin
	return [
		o.x, o.y, o.z,
		q.x, q.y, q.z, q.w,
		plane_node.aileron.surface_angle,
		plane_node.elevator.surface_angle,
		plane_node.rudder.surface_angle,
		plane_node.linear_speed.longitudinal,
		plane_node.linear_speed.lateral,
		plane_node.linear_speed.vertical,
		plane_node.angular_velocity.yaw,
		plane_node.angular_velocity.pitch,
		plane_node.angular_velocity.roll,
	]

func reset():
	record_pose.resize(0)
	record_checkpoint = []
	recording = false
	race_time = 0

func start_record():
	recording = true
	set_physics_process(true)

func stop_record():
	if not has_best_track() or record_time <= best_track["time"]:
		best_track["pose"] = record_pose
		best_track["checkpoint"] = record_checkpoint
		best_track["time"] = record_time
		save_map_record()
	recording = false
	set_physics_process(false)

# warning-ignore:unused_argument
func _on_race_initialized(_checkpoint_count):
	reset()
	start_record()

# warning-ignore:unused_argument
func _on_race_ended(_checkpoint_count):
	record_time = race_time
	stop_record()

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_checkpoint_crossed(_current_checkpoint, _checkpoint_count):
	record_checkpoint.append(race_time)

# warning-ignore:unused_argument
func _on_race_started(_checkpoint_count):
	race_time = 0

func has_best_track():
	return best_track["time"] > 0

func load_map_record():
	print("Loading best track...")
	var fname := get_map_record_filename()
	var file := FileAccess.open(fname, FileAccess.READ)
	if file == null:
		printerr("File open error (", fname, "):", FileAccess.get_open_error())
		return
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_line())
	var data = test_json_conv.get_data()
	file.close()
	if typeof(data["best_track"]) == TYPE_DICTIONARY:
		best_track["pose"] = PackedFloat32Array(data["best_track"]["pose"])
		# convert float to int
		best_track["time"] = int(data["best_track"]["time"])
		var checkpoint := []
		best_track["checkpoint"] = checkpoint
		for c in data["best_track"]["checkpoint"]:
			checkpoint.append(int(c))

func save_map_record():
	print("Saving best track...")
	var fname := get_map_record_filename()
	var file := FileAccess.open(fname, FileAccess.WRITE)
	if file == null:
		printerr("Cannot open ", fname, " in write mode!")
		return

	file.store_line(JSON.stringify({
		"best_track": best_track
	}))
	file.close()

func get_map_record_filename() -> String:
	var fname := Globals.MAP_DIRECTORY + Globals.MAP_NAME
	fname = fname.get_basename() + ".json"
	print("File: ", fname)
	return fname
