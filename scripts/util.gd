class_name Util
extends RefCounted

static func try_disconnect(sg: Signal, cb: Callable) -> void:
	if sg.is_connected(cb):
		sg.disconnect(cb)


static func try_connect(sg: Signal, cb: Callable, flags: int = 0) -> void:
	if not sg.is_connected(cb):
		sg.connect(cb, flags)


static func volume_of(vec: Vector3) -> float:
	return vec.x * vec.y * vec.z


static func is_current_frame_in_fps_interval(fps: int) -> bool:
	return Engine.get_process_frames() % fps == 0
