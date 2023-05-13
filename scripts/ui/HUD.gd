class_name HUD
extends Control

const TO_KPH := 3600.0 / 1000.0
var get_world_speed_func: Callable
var get_debug_func: Callable
var get_elapsed_frames_func: Callable

@onready var speed_label: Label = $MarginContainer/SpeedLabel
@onready var delta_time_label: Label = $CenterContainer/MarginContainer/VBoxContainer/DeltaTimeToBestLabel
@onready var chronometer_label: Label = $CenterContainer/MarginContainer/VBoxContainer/ChronometerLabel
@onready var checkpoints_label: Label = $CenterContainer/MarginContainer/VBoxContainer/CheckpointsLabel
@onready var physics_fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var delta_time_tween: Tween

func _process(_delta: float) -> void:
	if get_world_speed_func != null:
		var speed: float = get_world_speed_func.call()
		speed_label.text = "{} kph".format([roundf(speed * TO_KPH)], "{}")
	if get_debug_func != null:
		($DebugLabel as Label).text = get_debug_func.call()
	if get_elapsed_frames_func != null:
		var frame: int = get_elapsed_frames_func.call()
		chronometer_label.text = "%2d:%02d.%02d" % frame_to_time(frame)

func on_checkpoints_changed(current: int, total_checkpoints: int) -> void:
	checkpoints_label.text = "%2d/%2d" % [current, total_checkpoints]

func on_checkpoint_crossed(frame_delta_to_best: int) -> void:
	var time := frame_to_time(absi(frame_delta_to_best))
	var sign_str := ""
	if frame_delta_to_best < 0:
		sign_str = "-"
		delta_time_label.modulate = Color.RED
	elif frame_delta_to_best > 0:
		sign_str = "+"
		delta_time_label.modulate = Color.FOREST_GREEN
	else:
		delta_time_label.modulate = Color.WHITE

	if time[0] > 0:
		delta_time_label.text = sign_str + "%2d:%02d.%02d" % time
	else:
		delta_time_label.text = sign_str + "%2d.%02d" % time.slice(1)

	if delta_time_tween != null:
		delta_time_tween.kill()
	delta_time_tween = create_tween()
	delta_time_tween.tween_property(delta_time_label, "modulate:a", 1.0, 2.0).from(1.0)
	delta_time_tween.tween_property(delta_time_label, "modulate:a", 0.0, 0.3).from(1.0)

func frame_to_time(frame: int) -> Array[int]:
	var milliseconds := frame * 1000 / physics_fps
	milliseconds = min(milliseconds, (99 * 60 + 59) * 1000 + 999)
	var centis := (milliseconds / 10) % 100
	var seconds := (milliseconds / 1000) % 60
	var minutes := (milliseconds / (1000 * 60))
	return [minutes, seconds, centis]
