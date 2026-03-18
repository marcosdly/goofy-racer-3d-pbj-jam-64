@icon("./crate.svg")
class_name Crate
extends Area3D

@onready var box: MeshInstance3D = $RigidBody3D/CrateMesh
@onready var collision: CollisionShape3D = $Collision
@onready var test_area: Area3D = $PhysicsTestSubject
@onready var physics_body: RigidBody3D = $RigidBody3D

var _target_position_getter: Callable = Callable()
var _elapsed_time: float = 0
var _is_bouncing_back: bool = false
var _height_curve: Curve
var _peak_height: float = 5.0
var _duration: float = 1.5

var is_bouncing_back: bool:
	get:
		return _is_bouncing_back

var size: Vector3:
	get:
		return (collision.shape as BoxShape3D).size

var _was_bouncing_back: bool = false
var _start_p: Vector3
var _target_p: Vector3
var _start_r: Vector3
var _target_r: Vector3

signal bounce_back_start
signal bounce_back_end

var start_position: Vector3:
	get:
		return _start_p

var target_position: Vector3:
	get:
		return _target_p

var start_rotation: Vector3:
	get:
		return _start_r

var target_rotation: Vector3:
	get:
		return _target_r


func bounce_back(
		target_position_getter: Callable,
		height_curve: Curve,
		peak_height: float,
		duration: float,
) -> void:
	assert(not _is_bouncing_back, "Trying to bounce during a bounce back")
	_target_position_getter = target_position_getter
	_height_curve = height_curve
	_peak_height = peak_height
	_duration = duration
	_is_bouncing_back = true


func get_aabb() -> AABB:
	return AABB(global_transform.origin, size)


func get_physics_origin() -> Vector3:
	return physics_body.global_position


func _physics_process(delta):
	if not _is_bouncing_back:
		return

	assert(not _target_position_getter.is_null(), "Target position getter is null")

	if _elapsed_time >= _duration:
		# Ending bounce back routine
		_is_bouncing_back = false
		_was_bouncing_back = false
		_elapsed_time = 0
		_target_position_getter = Callable()
		if bounce_back_end.has_connections():
			bounce_back_end.emit()
		return

	if not _was_bouncing_back:
		# Starting bounce back routine
		_was_bouncing_back = true
		_start_p = physics_body.global_position
		_start_r = physics_body.global_rotation
		_target_r = Vector3.ZERO
		if bounce_back_start.has_connections():
			bounce_back_start.emit()

	_target_p = _target_position_getter.call()
	_elapsed_time += delta

	# Normalize progress (0.0 to 1.0)
	var t = clamp(_elapsed_time / _duration, 0.0, 1.0)

	# Calculate Horizontal Position
	var current_pos = _start_p.lerp(_target_p, t)

	# Apply Height from Curve
	# sample(t) pulls the Y-offset from your editor graph
	current_pos.y += _height_curve.sample(t) * _peak_height

	# Orient the Basis (Look Forward)
	var next_t = min((_elapsed_time + 0.02) / _duration, 1.0)
	var next_pos = _start_p.lerp(_target_p, next_t)
	next_pos.y += _height_curve.sample(next_t) * _peak_height

	if current_pos.distance_to(next_pos) > 0.01:
		look_at(next_pos, Vector3.UP)

	physics_body.global_position = current_pos
	collision.global_position = current_pos

	var current_rot = _start_r.lerp(_target_r, t)

	collision.global_rotation = current_rot
	physics_body.global_rotation = current_rot
