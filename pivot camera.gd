extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
var mouseclick : bool = false

func _process(delta: float) -> void:
	if Input.is_action_pressed("click"): #continuously check for mouseclick
		mouseclick = true
	else:
		mouseclick = false
			
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouseclick == true:
		rotation.y -= event.relative.x*0.01 #full 360°
		if rotation.x <= 0 and rotation.x > -PI/3: #from 0 to 60°
			rotation.x -= event.relative.y*0.01
			rotation.x = clampf(rotation.x,-PI/3+0.001, 0) #limit the view to these angles (for some reason, it needed that extra 0.001 or it would get stuck...)
			
			
