extends ShapeCast3D

@export var draw_debug_line: bool = false
@export var length: float = 50:
	set(v):
		length = v
		(shape as BoxShape3D).size.z = length


func _on_car_camera_mouse_delta_changed(source: CarCamera) -> void:
	pass
