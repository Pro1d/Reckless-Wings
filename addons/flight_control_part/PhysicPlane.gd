extends RigidBody

const PhysicComponent = preload("res://addons/flight_control_part/PhysicComponent.gd")
const Command = preload("res://scripts/definitions/Command.gd")
const Force = preload("res://scripts/definitions/Force.gd")
const Motion = preload("res://scripts/definitions/Motion.gd")

const GRAVITY := 9.8  # m/s²
const delta_physics := 0.01 # s
enum ControlMode { INPUT, REPLAY }
export(ControlMode) var control_mode 

var wind_velocity := Vector3.ZERO
var plane_motion := Motion.new()
var physic_components := []

# Called when the node enters the scene tree for the first time.
func _ready():
	for c in get_children():
		if c is PhysicComponent:
			physic_components.append(c)

func read_input() -> Command:
	var command := Command.new()
	command.rotation.x += Input.get_action_strength("aileron+")
	command.rotation.x -= Input.get_action_strength("aileron-")
	command.rotation.y += Input.get_action_strength("elevator+")
	command.rotation.y -= Input.get_action_strength("elevator-")
	command.rotation.z += Input.get_action_strength("rudder+")
	command.rotation.z -= Input.get_action_strength("rudder-")
	command.thrust += Input.get_action_strength("throttle")
	return command
	
#func _physics_process(delta):
#	var command : Command = read_input()
#	compute_force(Vector3(0,0,0), command)

func _integrate_forces(state : PhysicsDirectBodyState):
	var logs = null #""
	var commands := read_input()
	var quat := Quat(state.transform.basis)
	var inv_quat := quat.inverse()
	plane_motion.linear = state.transform.basis.inverse() * state.linear_velocity
	plane_motion.twist = (quat * (Quat(state.angular_velocity) * inv_quat)).get_euler()

	var relative_wind_motion := Motion.new()
	relative_wind_motion.linear = -plane_motion.linear + wind_velocity
	relative_wind_motion.twist = -plane_motion.twist
	if logs != null:
		logs += "+ command: R={} ; Th={}\n".format([
			commands.rotation, commands.thrust], "{}")
		logs += "+ Velocity local:  Vl={} ; Vt={}\n".format([
			plane_motion.linear, plane_motion.twist], "{}")
		logs += "+ Velocity global: Vl={} ; Vt={}\n".format([
			state.linear_velocity, state.angular_velocity], "{}")
		logs += "+ Relative wind: Vl={} ; Vt={}\n".format([
			relative_wind_motion.linear, relative_wind_motion.twist], "{}")
	var total_drag_force := Vector3.ZERO
	var total_drag_torque := Vector3.ZERO
	for c in physic_components:
		var component := c as PhysicComponent
		var force := component.compute_force(relative_wind_motion, commands)
		
		var action_point := component.translation
		var global_offset := state.transform.basis * action_point
		
		var global_force := state.transform.basis * force.linear
		state.add_force(global_force * mass, global_offset)
		
		var global_torque := (inv_quat * (Quat(force.twist) * quat)).get_euler()
		state.add_torque(global_torque)
		
		var global_linear_drag := state.transform.basis * force.linear_drag
		total_drag_force += global_linear_drag
		total_drag_torque += global_offset.cross(global_linear_drag)
		
		var global_angular_drag := (inv_quat * (Quat(force.angular_drag) * quat)).get_euler()
		total_drag_torque += global_angular_drag
	
		if logs != null:
			logs += "integrate force from {} : F={} + D={} at {} ; T={}\n".format([
				component.name, force.linear, force.linear_drag, action_point, force.twist], "{}")
			logs += "-------------------- {} : F={} + D={} at {} ; T={}\n".format([
				component.name, global_force, global_linear_drag, global_offset, global_torque], "{}")
			logs += "-------------------- {} : AngularD={}\n".format([
				component.name, force.angular_drag], "{}")
			logs += "-------------------- {} : AngularD={}\n".format([
				component.name, global_angular_drag], "{}")
	
	if logs != null:
		logs += "total drag force {}\n".format([total_drag_force], "{}")
		logs += "total drag torque {}\n".format([total_drag_torque], "{}")
	var drag_max := -state.linear_velocity / delta_physics / state.inverse_mass
	total_drag_force.x = clamp(total_drag_force.x, -abs(drag_max.x), abs(drag_max.x))
	total_drag_force.y = clamp(total_drag_force.y, -abs(drag_max.y), abs(drag_max.y))
	total_drag_force.z = clamp(total_drag_force.z, -abs(drag_max.z), abs(drag_max.z))
	state.add_central_force(total_drag_force)
	var angular_drag_max := -state.angular_velocity / delta_physics / state.inverse_inertia
	total_drag_torque.x = clamp(total_drag_torque.x, -abs(angular_drag_max.x), abs(angular_drag_max.x))
	total_drag_torque.y = clamp(total_drag_torque.y, -abs(angular_drag_max.y), abs(angular_drag_max.y))
	total_drag_torque.z = clamp(total_drag_torque.z, -abs(angular_drag_max.z), abs(angular_drag_max.z))
	state.add_torque(total_drag_torque)
	if logs != null:
		logs += "clamp drag force {}\n".format([total_drag_force], "{}")
		logs += "clamp drag torque {}\n".format([total_drag_torque], "{}")

	#print("integrate force GRAVITY : G=", Vector3.DOWN * GRAVITY / state.inverse_mass)
	state.add_central_force(Vector3.DOWN * GRAVITY * mass)
	if logs != null:
		print(logs)

func get_linear_speed() -> float:
	return plane_motion.linear.x
