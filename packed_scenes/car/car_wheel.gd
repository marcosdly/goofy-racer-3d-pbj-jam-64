@tool
extends VehicleWheel3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var flip: bool = false:
	set(v):
		flip = v
		_check_flip_wheel()


func _check_flip_wheel() -> void:
	if mesh == null or not flip:
		return
	mesh.rotation_degrees.y = -180 if flip else 0
	mesh.position.x = 0.15 if flip else -0.15


func _ready() -> void:
	_check_flip_wheel()


func _enter_tree() -> void:
	_check_flip_wheel()
