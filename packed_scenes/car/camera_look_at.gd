@tool
extends Marker3D

@onready var car: VehicleBody3D = get_parent()
@export var distance_from_car: float = 5.0


func _physics_process(_delta: float) -> void:
	var target_position: Vector3 = Vector3(car.position.x, car.position.y, distance_from_car).rotated(Vector3.UP, car.rotation.y)
	position = target_position
