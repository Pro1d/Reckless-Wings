extends Position3D

const Command = preload("res://scripts/definitions/Command.gd")
const Force = preload("res://scripts/definitions/Force.gd")
const Motion = preload("res://scripts/definitions/Motion.gd")

# LIMITATION:
#	axis aligned bounding box
#	(?) not rotation allowed - Considered NOT SUPPORTED for now
# default value for a right wing of simple plane
# factor apply to command, could be enum { idle=0, reverse=-1, normal=1 }

# rectangular shape for wind load
export var box : BoxShape
# drag coeff per squared metter --> F=-v^2 * drag/10000
export var drag : float = 3.0 * 10000
# x: typically aileron, y: typically elevatorn, z: typically rudder
export var command_rotation_factor : Vector3 = Vector3(1.0, 0.0, 0.0)
# thrust power and direction
export var thrust_force : Vector3 = Vector3(0.0, 0.0, 0.0)
# direction/intensity of the lift force due to command
export var command_lift_force : Vector3 = Vector3(0.0, 0.0, 9.0/2)
# direction/intensity of the lift force
export var base_lift_force : Vector3 = Vector3(0.0, 0.0, 9.8/2)
# direction of the wind that creates lift force
export var lift_wind_direction : Vector3 = Vector3(-1.0, 0.0, 0.0)
# below the threshold, the lift is reduce linearly to 0
export var lift_low_velocity_threshold : float = 25.0
# enable/disable force
export var enabled : bool = true

onready var drag_coefficient : float = drag / 10000
onready var dimensions : Vector3 = box.extents * 2
onready var dimensions_surf : Vector3 = Vector3(dimensions.y * dimensions.z,
										dimensions.z * dimensions.x,
										dimensions.x * dimensions.y)
var largest_surf_dim := Basis()
var smallest_surf_dim := Basis()
func _ready():
	largest_surf_dim.x = Vector3(0,1,0) if dimensions.y > dimensions.z else Vector3(0,0,1)
	largest_surf_dim.y = Vector3(0,0,1) if dimensions.z > dimensions.x else Vector3(1,0,0)
	largest_surf_dim.z = Vector3(1,0,0) if dimensions.x > dimensions.y else Vector3(0,1,0)
	smallest_surf_dim.x = Vector3(0,1,0) if dimensions.y <= dimensions.z else Vector3(0,0,1)
	smallest_surf_dim.y = Vector3(0,0,1) if dimensions.z <= dimensions.x else Vector3(1,0,0)
	smallest_surf_dim.z = Vector3(1,0,0) if dimensions.x <= dimensions.y else Vector3(0,1,0)

func integrale_drag_force(a : float, b : float, c : float, l : float, t : float) -> float:
	# integrale from a to b of c(xt+l)^2dx
	var i := (a * a + a * b + b * b) / 3
	var j := (a + b)
	return (b - a) * c * (i * (t * t) + j * (l * t) + (l * l))

func integrale_drag_torque(a : float, b : float, c : float, l : float, t : float) -> float:
	# integrale from a to b of c(xt+l)^2xdx
	var a2 := a * a
	var b2 := b * b
	var i := (b2 * b2 - a2 * a2) / 4
	var j := (b2 * b - a2 * a) * 2 / 3
	var k := (b2 - a2) / 2
	return c * (i * (t * t) + j * (l * t) + k * (l * l))

# return vector2: x is drag force, y is drag torque
func integrate_drag_force(lon_from : float, lon_to : float, lat : float, linear : float, twist : float) -> Vector2:
	var sign_from := sign(lon_from * twist + linear)
	var sign_to := sign(lon_to * twist + linear)
	if sign_from != sign_to:
		var null_point := -linear / twist
		var force_from := sign_from * integrale_drag_force(
			lon_from, null_point, drag_coefficient * lat, linear, twist)
		var force_to := sign_to * integrale_drag_force(
			null_point, lon_to, drag_coefficient * lat, linear, twist)
		var torque_from := sign_from * integrale_drag_torque(
			lon_from, null_point, drag_coefficient * lat, linear, twist)
		var torque_to := sign_to * integrale_drag_torque(
			null_point, lon_to, drag_coefficient * lat, linear, twist)
		return Vector2(force_from + force_to, torque_from + torque_to)
	else:
		var force := sign_from * integrale_drag_force(
			lon_from, lon_to, drag_coefficient * lat, linear, twist)
		var torque := sign_from * integrale_drag_torque(
			lon_from, lon_to, drag_coefficient * lat, linear, twist)
		return Vector2(force, torque)

func compute_drag(wind_motion : Motion, output_force : Force) -> void:
	var x := integrate_drag_force(
		-dimensions.dot(largest_surf_dim.x) / 2,
		dimensions.dot(largest_surf_dim.x) / 2,
		dimensions.dot(smallest_surf_dim.x),
		wind_motion.linear.x,
		wind_motion.twist.dot(smallest_surf_dim.x))

	var y := integrate_drag_force(
		-dimensions.dot(largest_surf_dim.y) / 2,
		dimensions.dot(largest_surf_dim.y) / 2,
		dimensions.dot(smallest_surf_dim.y),
		wind_motion.linear.y,
		wind_motion.twist.dot(smallest_surf_dim.y))

	var z := integrate_drag_force(
		-dimensions.dot(largest_surf_dim.z) / 2,
		dimensions.dot(largest_surf_dim.z) / 2,
		dimensions.dot(smallest_surf_dim.z),
		wind_motion.linear.z,
		wind_motion.twist.dot(smallest_surf_dim.z))

	output_force.linear_drag.x += x.x;
	output_force.linear_drag.y += y.x;
	output_force.linear_drag.z += z.x;
	output_force.angular_drag += smallest_surf_dim.x * x.y;
	output_force.angular_drag += smallest_surf_dim.y * y.y;
	output_force.angular_drag += smallest_surf_dim.z * z.y;

func compute_drag_force(wind_motion : Motion) -> Vector3:
	var wind_speed := wind_motion.linear
	var drag_factor := drag_coefficient * dimensions_surf
	return wind_speed.sign() * wind_speed * wind_speed * drag_factor

func compute_base_lift(lift_factor : float) -> Vector3:
	return base_lift_force * lift_factor

func compute_command_lift(lift_factor : float, command_rot : Vector3) -> Vector3:
	var command_intensity := command_rot.dot(command_rotation_factor)
	return command_lift_force * command_intensity * lift_factor

func compute_lift(wind_motion : Motion, command_rot : Vector3) -> Vector3:
	var effective_wind_speed := wind_motion.linear.dot(lift_wind_direction)
	var lift_effectiveness := abs(effective_wind_speed / lift_low_velocity_threshold)
	var lift_factor := clamp(lift_effectiveness, 0, 1)
	return compute_base_lift(lift_factor) + compute_command_lift(lift_factor, command_rot)

func compute_local_wind_motion(plane_wind_velocity : Motion) -> Motion:
	var wind_motion := Motion.new()
	wind_motion.linear += transform.basis.inverse() * plane_wind_velocity.linear
	wind_motion.linear += transform.basis.inverse() * (translation * plane_wind_velocity.twist)
	var quat := Quat(transform.basis)
	var twist := Quat(plane_wind_velocity.twist)
	wind_motion.twist += (quat * twist * quat.inverse()).get_euler()
	return wind_motion

func compute_thrust_force(command_thrust):
	# TODO consider wind speed for propeller (unlike reactor)
	return thrust_force * command_thrust

func compute_force(plane_relative_wind_velocity : Motion, commands : Command) -> Force:
	var wind_motion : Motion = compute_local_wind_motion(plane_relative_wind_velocity)
	var force := Force.new()
	if enabled:
		force.linear += compute_lift(wind_motion, commands.rotation)
		force.linear += compute_thrust_force(commands.thrust)
		compute_drag(wind_motion, force)
	return force
