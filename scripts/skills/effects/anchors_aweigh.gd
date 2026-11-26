extends RefCounted

var _pending := false


func enable(_ctx: Dictionary) -> void:
	_pending = true


func tick(_delta: float, ctx: Dictionary) -> void:
	if not _pending:
		return
	_pending = false
	var data: Dictionary = ctx.get("data", {})
	var customers: Node = ctx.get("customers")
	if customers != null and customers.has_method("add_money"):
		customers.add_money(int(data.get("reward_money", 0)))
	var level: Node = ctx.get("level")
	if not bool(data.get("end_level", true)):
		var asian: Node = level.get_node_or_null("AsianMode") if level != null else null
		if asian != null:
			asian.restore_lives(int(data.get("restore_lives", 0)))
		return
	GameData.skill_win_pending = true
	if level != null and level.has_method("_end_level"):
		level._end_level("")
