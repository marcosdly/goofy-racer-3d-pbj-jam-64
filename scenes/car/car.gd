@tool
extends Node3D

var has_spoiler: bool
var color: Color
var camera_mode: CameraMode
var max_speed: int
var max_rpm: int
var gears: Array[Curve]

enum CameraMode {
	BACK,
	FRONT,
	BEHIND,
}

@onready var vehicle: VehicleBody3D = $VehicleBody3D

var body: Node3D
var _body_idx: int = 0
@export var body_index: int:
	set(v):
		body_index = clampi(v, 0, get_body_placeholders().size())
		set_body(body_index)

var rims: Array[Node3D]
var _rims_idx: int
@export var rims_index: int:
	set(v):
		rims_index = clampi(v, 0, get_rims_placeholders().size())
		set_rims(rims_index)

var spoiler: Node3D
var _spoiler_idx: int
@export var spoiler_index: int:
	set(v):
		spoiler_index = clampi(v, 0, get_spoiler_placeholders().size())
		set_spoiler(spoiler_index)


func get_body_placeholders():
	return [get_node_or_null("Placeholders/A_R7_Body_1"), get_node_or_null("Placeholders/A_R7_Body_2"), get_node_or_null("Placeholders/A_R7_Body_3")]


func get_spoiler_placeholders():
	return [get_node_or_null("Placeholders/A_R7_Spoiler_1fbx"), get_node_or_null("Placeholders/A_R7_Spoiler_2fbx")]


func get_rims_placeholders():
	return [{ "right": get_node_or_null("Placeholders/Rims_1_R"), "left": get_node_or_null("Placeholders/Rims_2_L") }]


func remove_body():
	if body == null:
		return
	if body.is_inside_tree():
		body.get_parent().remove_child(body)
	body.queue_free()
	body = null
	_body_idx = -1


func remove_spoiler():
	if spoiler == null:
		return
	if spoiler.is_inside_tree():
		spoiler.get_parent().remove_child(spoiler)
	spoiler.queue_free()
	spoiler = null
	_spoiler_idx = -1


func remove_rims():
	if rims.is_empty():
		return
	var tmp_rims := rims
	rims = []
	_rims_idx = -1
	for node in tmp_rims:
		if node.is_inside_tree():
			node.get_parent().remove_child(node)
		node.queue_free()


func set_body(idx: int):
	remove_body()
	if _body_idx != idx:
		_body_idx = idx
	var p = get_body_placeholders()[idx]
	if p == null:
		return
	body = p.duplicate()
	body.visible = true
	body.position = Vector3.ZERO


func set_rims(idx: int):
	remove_rims()
	if _rims_idx != idx:
		_rims_idx = idx
	var lazy = get_rims_placeholders()[idx]
	var r = lazy["right"]
	var l = lazy["left"]
	if r == null or l == null:
		return
	var ne = r.duplicate()
	var se = r.duplicate()
	var nw = l.duplicate()
	var sw = l.duplicate()
	rims = [ne, se, nw, sw]
	var wne = vehicle.get_node_or_null("WheelNE")
	var wse = vehicle.get_node_or_null("WheelSE")
	var wnw = vehicle.get_node_or_null("WheelNW")
	var wsw = vehicle.get_node_or_null("WheelSW")
	if wne == null or wse == null or wnw == null or wsw == null:
		return
	wne.add_child(ne)
	wse.add_child(se)
	wnw.add_child(nw)
	wsw.add_child(sw)
	for node in rims:
		node.visible = true
		node.position = Vector3.ZERO


func set_spoiler(idx: int):
	remove_spoiler()
	if _spoiler_idx != idx:
		_spoiler_idx = idx
	var p = get_spoiler_placeholders()[idx]
	if p == null:
		return
	spoiler = p.duplicate()
	spoiler.visible = true
	spoiler.position = Vector3.ZERO
