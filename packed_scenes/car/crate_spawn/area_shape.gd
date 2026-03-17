class_name CrateSpawnAreaShape
extends CollisionShape3D

var _init_position_backup: Vector3 = Vector3.ZERO


func _enter_tree() -> void:
	_init_position_backup = position


func _physics_process(_delta: float) -> void:
	position = _init_position_backup
	rotation = Vector3.ZERO
