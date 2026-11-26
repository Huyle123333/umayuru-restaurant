extends RefCounted

const GUGUGAGA := {"path": "res://assets/models/customer_gugugaga.glb", "scale": 1.5, "yaw": 0.0}

var _d: Node
var _guest: Node
var _retry := 0.0


func start(director: Node) -> void:
	_d = director


func tick(delta: float) -> void:
	if _guest != null:
		return
	_retry -= delta
	if _retry > 0.0:
		return
	_retry = 1.0
	_guest = _d._customers.spawn_customer(GUGUGAGA, true)
	if _guest == null:
		return
	var tag := Label3D.new()
	tag.text = "VIP"
	tag.font_size = 72
	tag.pixel_size = 0.004
	tag.modulate = Color("ffd76a")
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.position = Vector3(0, 2.6, 0)
	_guest.add_child(tag)
	_guest.tree_exited.connect(func() -> void: _d.finish("vip"))


func stop(_director: Node) -> void:
	pass
