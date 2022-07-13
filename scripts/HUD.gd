extends CanvasLayer

signal game_paused(pause)

onready var plane_node = get_node("/root/World/Plane")
onready var recorder_node = plane_node.get_node("Recorder")
var race_in_progress = false

func _ready():
	$VBoxContainer/BestTimeDiff.set_text("")
	

# warning-ignore:unused_argument
func _process(delta):
	$Speed.set_text(str(floor(plane_node.get_linear_speed().length() * 3.6))+" Kph")
	if recorder_node:
		update_chronometer_text(recorder_node.race_time)

	if Input.is_action_just_pressed("back"):
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://scenes/MenuList.tscn")
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var pause = not get_tree().paused
	get_tree().paused = pause
	get_node("Pause").visible = pause
	emit_signal("game_paused", pause)

func time_to_str(time, always_show_minute):
	var centi = time % 100
	time /= 100
	var second = time % 60
	var minute = time / 60
	return (str(minute)+":"+str(second).pad_zeros(2) if always_show_minute or minute > 0 else str(second))+"."+str(centi).pad_zeros(2)

func update_chronometer_text(time):
	$VBoxContainer/Chronometer.set_text(time_to_str(time, true))

func trigger_best_time_diff(time_diff):
	var neg = time_diff < 0
	if neg:
		$VBoxContainer/BestTimeDiff.set_text("-" + time_to_str(-time_diff, false))
		$VBoxContainer/BestTimeDiff.add_color_override("font_color", Color(0.2,0.8,0))
	else:
		$VBoxContainer/BestTimeDiff.set_text("+" + time_to_str(time_diff, false))
		$VBoxContainer/BestTimeDiff.add_color_override("font_color", Color(1,0,0))
		
	$VBoxContainer/BestTimeDiff/Timer.start()

func _on_best_time_diff_timeout():
	$VBoxContainer/BestTimeDiff.set_text("")

func update_checkpoint_text(current, total):
	$VBoxContainer/CheckpointCount.set_text(""+str(current)+"/"+str(total+1))

func _on_race_initialized(checkpoint_count):
	update_checkpoint_text(0, checkpoint_count)
	race_in_progress = false
	$Destroyed.visible = false

func _on_checkpoint_crossed(current, checkpoint_count):
	$LaserHigh.play()
	update_checkpoint_text(current, checkpoint_count)
	if recorder_node.has_best_track():
		trigger_best_time_diff(recorder_node.race_time - recorder_node.best_track["checkpoint"][current-1])

func _on_race_ended(checkpoint_count):
	$LaserLow.play()
	update_checkpoint_text(checkpoint_count+1, checkpoint_count)
	race_in_progress = false
	if recorder_node.has_best_track():
		trigger_best_time_diff(recorder_node.race_time - recorder_node.best_track["time"])

func _on_race_started(checkpoint_count):
	$LaserLow.play()
	update_checkpoint_text(0, checkpoint_count)
	race_in_progress = true

func _on_plane_destroyed():
	$Destroyed.visible = true
