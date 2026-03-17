@tool
@icon("res://addons/plenticons/icons/svg/3d/cube-gray.svg")
class_name CrateSpawnArea3D
extends Area3D

const crate_scene: PackedScene = preload("res://packed_scenes/crate/crate.tscn")

@onready var collision: CollisionShape3D = $AreaShape
@onready var shape_cast: ShapeCast3D = $ShapeCast3D

@export_group("State")
@export var crates: Array[Crate] = []
@export var max_crates: int = 16

@export_group("Crate Bound Back")
@export var minimum_distance: float = 5
@export var height_curve: Curve
@export var offset_height: float = 0
@export var duration: float = 1

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


func spawn_crate() -> void:
	assert(crates.size() <= max_crates, "Amount of crates is higher than maximum")
	if crates.size() == max_crates:
		return
	var crate_instance: Crate = crate_scene.instantiate()
	crates.append(crate_instance)
	add_child(crate_instance)
	crate_instance.tree_exiting.connect(func() -> void: crates.erase(crate_instance))
	crate_instance.scale = Vector3.ONE * randf_range(.4, .9)
	crate_instance.top_level = true
	crate_instance.global_position = get_next_spawn_point()


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
	if crates.size() < max_crates and Util.is_current_frame_in_fps_interval(30):
		spawn_crate()
	for crate in crates:
		if overlaps_body(crate):
			continue
		if (crate.global_position - global_position).length() < minimum_distance:
			continue
		if crate.is_bouncing_back:
			continue
		crate.bounce_back(Callable(get_origin), height_curve, offset_height, duration)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and (event as InputEventMouseButton).button_index == MouseButton.MOUSE_BUTTON_LEFT:
		spawn_crate()
