extends RefCounted

var _d: Node
var _doro: Node


func start(director: Node) -> void:
	_d = director
	_doro = director._level.get_node_or_null("Doro")
	if _doro == null:
		director.finish("dog_thief")
		return
	_doro.escaped.connect(_on_escaped)
	_doro.escape_stopped.connect(_on_stopped)
	_doro.start_escape(director._customers._door.global_position)


func _on_escaped() -> void:
	_d.lose(Lang.t("Thua: Doro bị trộm mất."))


func _on_stopped() -> void:
	_d.finish("dog_thief")


func tick(_delta: float) -> void:
	pass


func stop(_director: Node) -> void:
	if _doro == null or not is_instance_valid(_doro):
		return
	if _doro.escaped.is_connected(_on_escaped):
		_doro.escaped.disconnect(_on_escaped)
	if _doro.escape_stopped.is_connected(_on_stopped):
		_doro.escape_stopped.disconnect(_on_stopped)
	if _doro.is_escaping():
		_doro.stop_escape()
