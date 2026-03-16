extends Node3D

const base_acceleration = 100

var speed: float = 0
var w: float = 0


func _process(delta: float) -> void:
	speed += (base_acceleration) * w * delta
	
	position.z += speed
	
	
