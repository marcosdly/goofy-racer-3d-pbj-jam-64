@tool
extends PhantomCamera3D

@export var mouse_follow_sensitivity: float = .5
@export var mouse_follow_limit: float = 5
@export var mouse_rotate_sensitivity: float = .5
@export var platform_node: Node3D

var is_holding: bool = false
var mouse_delta: Vector2 = Vector2.ZERO
var mouse_screen_delta: Vector2 = Vector2.ZERO

signal mouse_delta_changed


func _input(event: InputEvent) -> void:
	cameraman.assert_mouse_mode()
	_try_set_mouse_delta(event)
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_holding = event.is_pressed()
	if event is InputEventMouseMotion:
		mouse_delta = event.relative


func get_mouse_position() -> Vector2:
	if Engine.is_editor_hint():
		var _mouse := DisplayServer.mouse_get_position()
		return Vector2(_mouse.x, _mouse.y)
	else:
		return get_viewport().get_mouse_position()


func get_viewport_size() -> Vector2:
	if Engine.is_editor_hint():
		var _size := DisplayServer.window_get_size()
		return Vector2(_size.x, _size.y)
	else:
		return get_viewport().get_visible_rect().size


const BASE_FOLLOW_OFFSET_Y := 1.5
const BASE_FOLLOW_OFFSET_Z := 6.7


func _handle_look_at_offset():
	var m: Vector2 = get_mouse_position()
	var s: Vector2 = get_viewport_size() / 2
	var rat := (m - s) / s
	var res := Vector3(mouse_follow_limit * rat.x, mouse_follow_limit * rat.y * -1, 0) * mouse_follow_sensitivity
	#if Util.is_current_frame_in_fps_interval(30):
	#prints(m, s, rat, res)
	look_at_offset = Vector3(res.x, -res.y, 0)
	follow_offset = Vector3(0, BASE_FOLLOW_OFFSET_Y + res.y, BASE_FOLLOW_OFFSET_Z)
	if not is_holding and platform_node != null:
		platform_node.rotation.y += deg_to_rad(-res.x) * mouse_follow_sensitivity


var damping := 10.0


func _handle_platform_rotation(_delta: float):
	if not is_holding or platform_node == null:
		return
	print('this')
	var s := get_viewport_size()
	#platform_node.rotation.y += deg_to_rad(mouse_delta.x) * mouse_rotate_sensitivity
	var delta_y := PI * (mouse_delta.x / s.x)
	#var y := platform_node.rotation.y
	platform_node.rotation.y += delta_y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	_handle_look_at_offset()
	_handle_platform_rotation(delta)


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	cameraman.MOUSE_MODE_LOCKED = Input.MouseMode.MOUSE_MODE_CONFINED
	cameraman.MOUSE_MODE_RELEASED = Input.MouseMode.MOUSE_MODE_VISIBLE
	var game_window := get_window()
	Util.try_connect(game_window.focus_entered, _on_game_window_focus_entered)
	Util.try_connect(game_window.focus_exited, _on_game_window_focus_exited)

#region Mouse position

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

func _on_game_window_focus_entered() -> void:
	cameraman.set_mouse_locked(true)


func _on_game_window_focus_exited() -> void:
	cameraman.set_mouse_locked(false)


func _exit_tree() -> void:
	var game_window := get_window()
	Util.try_disconnect(game_window.focus_entered, _on_game_window_focus_entered)
	Util.try_disconnect(game_window.focus_exited, _on_game_window_focus_exited)
