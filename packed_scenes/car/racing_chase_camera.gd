@tool
class_name CarCamera
extends RacingChaseCamera

var space_state: PhysicsDirectSpaceState3D:
	get:
		return get_world_3d().direct_space_state

var is_game_focused: bool:
	get:
		return not Engine.is_editor_hint() and get_window().has_focus()

@export_group("Debug")

@export var draw_node_mouse_intersection: bool = false

#region Boring spacial math

var mouse_3d_intersection: Dictionary = { }
const _QUERY_CAST_LENGTH: float = 50.0


func _get_mouse_3d_ray_query(mouse_position: Vector2) -> PhysicsRayQueryParameters3D:
	var ray_origin = underlying_camera.project_ray_origin(mouse_position)
	var ray_normal = underlying_camera.project_ray_normal(mouse_position)
	var ray_end = ray_origin + ray_normal * _QUERY_CAST_LENGTH
	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return query


func get_first_node3d_under_mouse() -> Dictionary:
	var mouse_position := underlying_camera.get_viewport().get_mouse_position()
	return space_state.intersect_ray(_get_mouse_3d_ray_query(mouse_position))


func _update_3d_mouse_intersection() -> void:
	if not (is_game_focused and cameraman.is_mouse_locked()):
		return
	mouse_3d_intersection = get_first_node3d_under_mouse()

#endregion

#region Mouse position

var mouse_delta: Vector2 = Vector2.ZERO
var mouse_screen_delta: Vector2 = Vector2.ZERO

signal mouse_delta_changed


func _try_set_mouse_delta(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion and cameraman.is_mouse_locked()):
		return
	event = event as InputEventMouseMotion
	var should_emit: bool = event.relative != mouse_delta or event.screen_relative != mouse_screen_delta
	mouse_delta = event.relative
	mouse_screen_delta = event.screen_relative
	if should_emit:
		mouse_delta_changed.emit()

#endregion

func _input(_event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	cameraman.assert_mouse_mode()
	_try_set_mouse_delta(_event)


func _on_game_window_focus_entered() -> void:
	cameraman.set_mouse_locked(true)


func _on_game_window_focus_exited() -> void:
	cameraman.set_mouse_locked(false)


## Overryde method
func _on_ready() -> void:
	super._on_ready()
	cameraman.MOUSE_MODE_LOCKED = Input.MouseMode.MOUSE_MODE_CONFINED
	cameraman.MOUSE_MODE_RELEASED = Input.MouseMode.MOUSE_MODE_VISIBLE
	var game_window := get_window()
	Util.try_connect(game_window.focus_entered, _on_game_window_focus_entered)
	Util.try_connect(game_window.focus_exited, _on_game_window_focus_exited)


func _exit_tree() -> void:
	var game_window := get_window()
	Util.try_disconnect(game_window.focus_entered, _on_game_window_focus_entered)
	Util.try_disconnect(game_window.focus_exited, _on_game_window_focus_exited)


## Override method
func _on_process(_delta: float) -> void:
	super._on_process(_delta)


func _physics_process(_delta: float) -> void:
	_update_3d_mouse_intersection()
	if draw_node_mouse_intersection:
		var origin: Vector3 = mouse_3d_intersection.get("position", position + Vector3.UP)
		DebugDraw3D.draw_sphere(origin, .25, Color.AQUA)
