@tool
@icon("res://addons/plenticons/icons/svg/3d/cube-gray.svg")
class_name CrateSpawnArea3D
extends Area3D

const crate_scene: PackedScene = preload("res://packed_scenes/crate/crate.tscn")

@onready var collision: CollisionShape3D = $AreaShape

@export_group("State")
@export var crates: Array[Crate] = []
@export var max_crates: int = 16

@export_group("Crate sizing")
@export_range(0, .5) var gap_per_direction: float = 0.05
#@export var gap_is_between_only: bool = true
@export var max_attempts_per_box: int = 200

@export_group("Crate Bound Back")
@export var minimum_distance: float = 5
@export var height_curve: Curve
@export var offset_height: float = 0
@export var duration: float = 1
@export var orbit_length: float = 5

@export_group("Debug")
@export var draw_aabb: bool = false
@export var draw_plane: bool = false
@export var draw_normal: bool = false
@export var draw_random_spawn_points: bool = false
@export var spawn_crates_on_interval: bool = false
@export_tool_button("Spawn 1 Crate", "res://packed_scenes/crate/crate.svg") @warning_ignore("unused_private_class_variable") var _debug_spawn_crate: Callable = spawn_crate

var size: Vector3:
	get:
		return shape.size

var shape: BoxShape3D:
	get:
		return collision.shape

var _crate_positions: PackedVector3Array = []


func _cleanup_debug_state_pre() -> void:
	if crates.size() > 0:
		for crate in crates:
			if crate.is_visible_in_tree():
				remove_child(crate)
			crate.free()
		crates = []
	for child in get_children():
		assert(child is not Crate, "Crate already spawned before running game")


func _ready() -> void:
	_cleanup_debug_state_pre()

#region Spatial shapes getters

## Experimental
func get_aabb() -> AABB:
	return AABB(global_transform.origin - size / 2, size)


## Experimental
func get_normal() -> Vector3:
	return collision.global_transform * Vector3(0, size.y / 2, 0)


## Experimental
func get_normal_direction() -> Vector3:
	return collision.global_transform.origin.direction_to(get_normal()).normalized()


## Experimental
func get_spawn_plane() -> Plane:
	var normal := get_normal()
	var center := collision.global_transform.origin
	return Plane(get_normal_direction(), normal.dot(center))


func get_top_face_corners() -> PackedVector3Array:
	var t := collision.global_transform
	var s: Vector3 = size / 2
	return [
		t * (Vector3(1, 1, 1) * s), # bottom right
		t * (Vector3(1, 1, -1) * s), # bottom left
		t * (Vector3(-1, 1, -1) * s), # top left
		t * (Vector3(-1, 1, 1) * s), # top right
	]


## Ensure pC is opposite pA for this formula to work well with convex quads.
## pA, pB, pC, pD should define the corners in order (e.g., clockwise or counter-clockwise).
func get_random_point_in_quad(pA: Vector3, pB: Vector3, pC: Vector3, pD: Vector3) -> Vector3:
	var r1 := randf()
	var r2 := randf()
	var point_ab = pA + (pB - pA) * r1
	var point_dc = pD + (pC - pD) * r1

	# Interpolate between the two new points
	var random_point = point_ab + (point_dc - point_ab) * r2

	return random_point

#endregion

func get_next_spawn_point() -> Vector3:
	return get_random_point_in_quad.callv(get_top_face_corners())


func get_origin() -> Vector3:
	return collision.global_position

#region Spawn logic

func spawn_crate() -> void:
	assert(crates.size() <= max_crates, "Amount of crates is higher than maximum")
	if crates.size() == max_crates:
		return
	var crate_instance: Crate = crate_scene.instantiate()
	crates.append(crate_instance)
	add_child(crate_instance)
	crate_instance.scale = Vector3.ONE * randf_range(.4, .9)
	crate_instance.top_level = true
	crate_instance.global_position = get_next_spawn_point()

	crate_instance.tree_exiting.connect(
		func() -> void:
			crates.erase(crate_instance)
	)

	crate_instance.bounce_back_start.connect(
		func() -> void:
			crate_instance.physics_body.sleeping = true
	)

	crate_instance.bounce_back_end.connect(
		func() -> void:
			crate_instance.physics_body.sleeping = false
	)


func check_bounce_back() -> void:
	for i in range(crates.size()):
		var crate := crates[i]
		if overlaps_body(crate):
			continue
		if global_position.distance_to(crate.global_position) < minimum_distance:
			continue
		if crate.is_bouncing_back:
			continue
		var callback := func() -> Vector3:
			if _crate_positions.size() <= i:
				return get_origin() # out of bounds
			return get_origin() + _crate_positions[i]
		crate.bounce_back(callback, height_curve, offset_height, duration)


## Find proportional x in the relationship
##  a -> c
## ---  ---
##  b -> x
func _simple_rule_of_three(a: float, b: float, c: float) -> float:
	return a / (c * b)


func _key_sum_crate_volume(accum: float, crate: Crate):
	return Util.volume_of(crate.size) + accum


func check_crate_sizes() -> void:
	if crates.size() == 0:
		return
	if size.length_squared() == 0:
		return
	var area_volume := Util.volume_of(size)
	for crate in crates:
		var crate_volume := Util.volume_of(crate.scale)
		if crate_volume <= area_volume or crate_volume <= 0:
			continue # already fits or zero
		var factor := pow(area_volume / crate_volume, 1.0 / 3.0)
		crate.scale *= factor


func check_crate_sizes_with_gaps() -> void:
	var count: int = crates.size()
	if count == 0:
		return
	if size.length_squared() == 0:
		return

	var padding_outer := Vector3.ZERO

	var gaps_between := Vector3.ZERO

	# If we assume items are roughly spread in all 3 dimensions,
	# we can conservatively reserve space for (n-1) gaps per axis.
	if count > 1:
		gaps_between = Vector3.ONE * gap_per_direction * (count - 1)

	var effective_size := size - padding_outer - gaps_between

	# Prevent negative / zero size
	effective_size.x = maxf(effective_size.x, 0.001)
	effective_size.y = maxf(effective_size.y, 0.001)
	effective_size.z = maxf(effective_size.z, 0.001)

	var effective_vol := effective_size.x * effective_size.y * effective_size.z

	for crate in crates:
		var crate_volume := Util.volume_of(crate.scale)
		if crate_volume <= 0:
			continue # already fits or zero
		if crate_volume <= effective_vol:
			# even the original is already smaller than effective volume
			continue
		var factor := (effective_vol / crate_volume) ** (1.0 / 3.0)
		crate.scale *= factor
		# Minimum size safeguard
		crate.scale = crate.scale.max(Vector3(0.05, 0.05, 0.05))


func randomize_positions_no_overlap() -> void:
	if crates.is_empty() or size.length_squared() == 0:
		return

	var center := get_aabb().get_center()
	var placed_aabbs: Array[AABB] = []
	var new_positions: PackedVector3Array = []

	for crate in crates:
		var half_extents := (crate.scale * 0.5) + Vector3.ONE * gap_per_direction

		var placed := false
		var attempts := 0

		while not placed and attempts < max_attempts_per_box:
			attempts += 1

			# Random position inside the big box (centered)
			var pos := Vector3(
				randf_range(-center.x, center.x),
				randf_range(-center.y, center.y),
				randf_range(-center.z, center.z),
			)

			var candidate := AABB(pos - half_extents, half_extents * 2.0)

			# Check against all already placed
			var overlaps := false
			for existing in placed_aabbs:
				if candidate.intersects(existing):
					overlaps = true
					break

			if not overlaps:
				new_positions.append(pos)
				placed_aabbs.append(candidate)
				placed = true

		if not placed:
			push_warning("Could not place %s after %d attempts — too dense?" % [crate.name, max_attempts_per_box])

		_crate_positions = new_positions


func randomize_positions_no_overlap_via_areas() -> void:
	if crates.is_empty() or size.length_squared() == 0:
		return

	var new_positions: PackedVector3Array = []

	# sort largest-first better packing success
	crates.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			var va := a.scale.length_squared()
			var vb := b.scale.length_squared()
			return va > vb
	)

	var half_big := size / 2
	var center := collision.global_position
	var success_count := 0

	for i in range(crates.size()):
		# FIX: Create tmp copy to calculate and them get back
		var crate := crates[i]
		var test_area := crate.test_area

		var placed := false
		var attempts := 0

		while not placed and attempts < max_attempts_per_box:
			attempts += 1

			# Random centered position
			var pos := Vector3(
				randf_range(-half_big.x, half_big.x),
				randf_range(-half_big.y, half_big.y),
				randf_range(-half_big.z, half_big.z),
			)

			# Temporarily move to test position
			var original_pos: Vector3 = crate.global_position
			test_area.global_position = pos

			# Optional tiny safety inflate: makes gap enforcement stricter
			var original_scale: Vector3 = test_area.scale
			test_area.scale += Vector3.ONE * (gap_per_direction / test_area.scale.length()) # approximate

			# Force physics to recognize current state (very important!)
			# Without this, overlaps may not update instantly in some cases
			await get_tree().physics_frame # or get_tree().process_frame if desperate

			var overlapping = test_area.get_overlapping_areas()

			# Clean up test inflate
			test_area.scale = original_scale

			var is_clear: bool = overlapping.is_empty()

			# Revert
			test_area.global_position = original_pos

			if is_clear:
				# Keep the position
				placed = true
				success_count += 1
				new_positions.append(pos)
			else:
				# Fallback
				new_positions.append(center)

		if not placed:
			push_warning("Failed to place %s after %d attempts (too dense?)" % [crate.name, max_attempts_per_box])
			# Optional fallback: hide, place at center, shrink more, etc.
			# node.visible = false

	print("Placed %d / %d boxes successfully" % [success_count, crates.size()])

	_crate_positions = new_positions

#endregion

func _process(_delta: float) -> void:
	if draw_aabb:
		var aabb := get_aabb()
		DebugDraw3D.draw_aabb(aabb, Color.AQUAMARINE)
		for i in range(8):
			DebugDraw3D.draw_text(aabb.get_endpoint(i), str(i), 32, Color.CHARTREUSE)
	if draw_normal:
		var normal := get_normal()
		DebugDraw3D.draw_sphere(normal, .05, Color.CORAL)
		DebugDraw3D.draw_arrow(normal, normal + get_normal_direction(), Color.CORAL, .1, true)
	if draw_plane:
		DebugDraw3D.draw_plane(get_spawn_plane(), Color.RED)
	if draw_random_spawn_points and Util.is_current_frame_in_fps_interval(30):
		DebugDraw3D.draw_square(get_next_spawn_point(), .1, Color.DARK_GOLDENROD, 1)
	if spawn_crates_on_interval and Util.is_current_frame_in_fps_interval(60) and not Engine.is_editor_hint():
		spawn_crate()


func _physics_process(_delta: float) -> void:
	check_bounce_back()
	if gap_per_direction == 0:
		check_crate_sizes()
	else:
		check_crate_sizes_with_gaps()


func _on_timer_timeout() -> void:
	if crates.size() < max_crates:
		spawn_crate()
	#randomize_positions_no_overlap_via_areas()
	#randomize_positions_no_overlap()
