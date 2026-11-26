extends Node
## ─────────────────────────────────────────────── vì sao cần thêm một node nữa
## ────────────────────────────────────────────────────── các khoá trong `luat`


var _customers: Node
var _clock: Node
var _rules: Dictionary = {}

var _stages: Array = []
## Chặng đang áp dụng. -1 = chưa áp chặng nào.
var _index := -1


## Gắn luật vào màn. Gọi từ level_base ngay sau khi dựng xong đồng hồ.
func setup(customers: Node, clock: Node, rules: Dictionary) -> bool:
	if customers == null or rules.is_empty():
		return false
	_customers = customers
	_clock = clock
	_rules = rules

	_apply_static()
	_stages = _rules.get("stages", [])
	_go_to_stage(0)
	return true


## Những thứ đặt một lần rồi thôi.
func _apply_static() -> void:
	if _rules.has("max_customers"):
		_customers.max_customers = int(_rules["max_customers"])
	if _rules.has("max_tables"):
		_customers.max_tables = int(_rules["max_tables"])
	if _rules.has("max_queue"):
		_customers.max_queue = int(_rules["max_queue"])
	if _rules.has("first_wait"):
		_customers.first_wait = float(_rules["first_wait"])
	if _rules.has("price_factor"):
		_customers.price_factor = float(_rules["price_factor"])
	if _rules.has("menu"):
		var picked_menu: Array[String] = []
		for m in _rules["menu"]:
			picked_menu.append(String(m))
		_customers.menu = picked_menu
	if _rules.has("weights"):
		_customers.weights = _rules["weights"]

	if _clock != null and _rules.has("duration"):
		var t := float(_rules["duration"])
		_clock.duration = t
		_clock.time_left = t


## Đổi độ khó theo thời gian đã trôi.
func _process(_delta: float) -> void:
	if _customers == null or _clock == null:
		return

	var elapsed: float = float(_clock.duration) - float(_clock.time_left)


	for i in _stages.size():
		var c: Dictionary = _stages[i]
		if elapsed < float(c.get("until", 0.0)):
			if i != _index:
				_go_to_stage(i)
			return
	if not _stages.is_empty() and _index != _stages.size() - 1:
		_go_to_stage(_stages.size() - 1)


func _go_to_stage(i: int) -> void:
	if i < 0 or i >= _stages.size():
		return
	_index = i
	var c: Dictionary = _stages[i]
	if c.has("interval"):
		_customers.spawn_interval = float(c["interval"])
	var range_: Array = c.get("interval_range", [])
	_customers.spawn_interval_min = float(range_[0]) if range_.size() == 2 else 0.0
	_customers.spawn_interval_max = float(range_[1]) if range_.size() == 2 else 0.0
	if c.has("tier_weights"):
		_customers.tier_weights = c["tier_weights"]
	if c.has("max_customers"):
		_customers.max_customers = int(c["max_customers"])
