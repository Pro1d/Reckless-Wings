extends Node

signal checkpoints_changed(current: int, total_checkpoints: int)
signal checkpoint_crossed(delta_time: int)

class RaceState:
	enum State {INITIALIZING, STARTING, IN_PROGRESS, FINISHED}
	var state: State = State.INITIALIZING
	var frame: int
	var checkpoint_count := 0
	var checkpoint_done: Array[bool] = []
	var checkpoint_time: Array[int] = []

	func reset(cp_count : int) -> void:
		state = State.STARTING
		frame = 0
		checkpoint_count = 0
		checkpoint_done.resize(cp_count)
		checkpoint_done.fill(false)
		checkpoint_time.clear()

	func try_validate_checkpoint(cp_idx: int) -> bool:
		if checkpoint_done[cp_idx]:
			return false
		checkpoint_done[cp_idx] = true
		checkpoint_count += 1
		checkpoint_time.append(frame)
		return true

var map: Map
var race_state := RaceState.new()

@onready var _aircraft: Aircraft = $Aircraft
@onready var hud: HUD = $HUD

func _ready() -> void:
	# Map
	var map_res: PackedScene = load(SceneManager.current_map_path)
	map = map_res.instantiate()
	add_child(map)
	map.aircraft_start_reached.connect(_on_aircraft_start_reached)
	map.aircraft_checkpoint_reached.connect(_on_aircraft_checkpoint_reached)
	map.aircraft_finish_reached.connect(_on_aircraft_finish_reached)
	
	# HUD
	hud.get_world_speed_func = _aircraft.get_world_speed
	hud.get_debug_func = _aircraft.get_debug
	hud.get_elapsed_frames_func = func() -> int: return race_state.frame
	checkpoints_changed.connect(hud.on_checkpoints_changed)
	checkpoint_crossed.connect(hud.on_checkpoint_crossed)
	
	_start_race()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
	elif event.is_action_pressed("restart"):
		_start_race()
	elif event.is_action_pressed("back"):
		SceneManager.change_to_main_menu()

func _physics_process(_delta: float) -> void:
	if race_state.state == race_state.State.IN_PROGRESS:
		race_state.frame += 1

func _start_race() -> void:
	race_state.state = RaceState.State.INITIALIZING
	_aircraft.set_control_mode(Aircraft.ControlMode.LOCKED)
	_aircraft.reset(map.get_start_position())
	await _aircraft.state_reset # SO BAAAAAAD! :(
	race_state.reset(map.get_checkpoint_count())
	checkpoints_changed.emit(race_state.checkpoint_count, map.get_checkpoint_count())

func _on_aircraft_start_reached(_unused_aircraft: Aircraft) -> void:
	if race_state.state == RaceState.State.STARTING:
		_aircraft.set_control_mode(Aircraft.ControlMode.ENABLED)
		race_state.state = RaceState.State.IN_PROGRESS

func _on_aircraft_checkpoint_reached(_unused_aircraft: Aircraft, checkpoint_id: int) -> void:
	if race_state.state == RaceState.State.IN_PROGRESS:
		if race_state.try_validate_checkpoint(checkpoint_id):
			checkpoint_crossed.emit(0)
			checkpoints_changed.emit(race_state.checkpoint_count, map.get_checkpoint_count())

func _on_aircraft_finish_reached(_unused_aircraft: Aircraft) -> void:
	if race_state.state == RaceState.State.IN_PROGRESS:
		if race_state.checkpoint_count == map.get_checkpoint_count():
			_aircraft.set_control_mode(Aircraft.ControlMode.AUTOPILOT)
			race_state.state = RaceState.State.FINISHED
