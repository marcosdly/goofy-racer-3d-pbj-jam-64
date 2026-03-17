@icon("./crate.svg")
class_name Crate
extends RigidBody3D

@onready var box: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var _target_position_getter: Callable = Callable()
var _elapsed_time: float = 0
var _is_bouncing_back: bool = false
var _height_curve: Curve # Graph: (0,0) -> (0.5,1) -> (1,0)
var _peak_height: float = 5.0
var _duration: float = 1.5

var is_bouncing_back: bool:
	get:
		return _is_bouncing_back


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


signal target_reached(start: Vector3, target: Vector3)


func get_aabb() -> AABB:
	return AABB(global_transform.origin, (collision.shape as BoxShape3D).size)


func _update_arc(body: PhysicsBody3D, start_p: Vector3, target_p: Vector3, t: float):
	# 1. Linear horizontal movement (X and Z)
	var current_pos = start_p.lerp(target_p, t)

	# 2. Vertical movement (Y) pulled from the Curve
	# sample(t) returns a value between 0 and 1 based on your graph
	current_pos.y += _height_curve.sample(t) * _peak_height

	# 3. Use Basis to face the movement
	if t < 1.0:
		var next_t = t + 0.01
		var next_pos = start_p.lerp(target_p, next_t)
		next_pos.y += _height_curve.sample(next_t) * _peak_height
		look_at(next_pos, Vector3.UP)

	body.global_position = current_pos


func move_along_curve(body: PhysicsBody3D, start_p: Vector3) -> void:
	var tween = create_tween()

	var callback: Callable = func(t: float) -> void:
		_update_arc(body, start_p, global_position, t)

	tween.tween_method(callback, 0.0, 1.0, _duration)


func _physics_process(delta):
	if not _is_bouncing_back:
		return

	var start_pos := global_transform.origin
	var target_pos: Vector3 = _target_position_getter.call()

	if _elapsed_time < _duration:
		_elapsed_time += delta

		# 1. Normalize progress (0.0 to 1.0)
		var t = clamp(_elapsed_time / _duration, 0.0, 1.0)

		# 2. Calculate Horizontal Position
		var current_pos = start_pos.lerp(target_pos, t)

		# 3. Apply Height from Curve
		# sample(t) pulls the Y-offset from your editor graph
		current_pos.y += _height_curve.sample(t) * _peak_height

		# 4. Orient the Basis (Look Forward)
		var next_t = min((_elapsed_time + 0.02) / _duration, 1.0)
		var next_pos = start_pos.lerp(target_pos, next_t)
		next_pos.y += _height_curve.sample(next_t) * _peak_height

		if current_pos.distance_to(next_pos) > 0.01:
			look_at(next_pos, Vector3.UP)

		# 5. Finalize Movement
		global_position = current_pos
	else:
		_is_bouncing_back = false
		_elapsed_time = 0
		_target_position_getter = Callable()
		if target_reached.has_connections():
			target_reached.emit(start_pos, target_pos)
