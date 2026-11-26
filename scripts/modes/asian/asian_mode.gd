extends CanvasLayer

const START_LIVES := 3
const START_MONEY := 200
const VAT_RATE := 0.10
## Tiền/giây theo kiểu mẻ trong cooking_system ("cook" = bếp, "bake" = lò).
const FEE_PER_SECOND := {"cook": 1.0, "bake": 2.0}
const FRIDGE_FEE_PER_SECOND := 1.0
## Số đơn hoàn hảo liên tiếp để hồi 1 mạng.
const STREAK_FOR_LIFE := 8
## Đồ cháy vứt vào thùng rác bị trừ bấy nhiêu lần tiền nguyên liệu.
const BURNT_PENALTY_FACTOR := 2

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const Registry := preload("res://scripts/skills/skill_registry.gd")

const COLOR_TEXT := Color(1, 1, 1)
const COLOR_DIM := Color(0.78, 0.74, 0.69)
const COLOR_BAD := Color("de6459")

var lives := START_LIVES
var _level: Node
var _customers: Node
var _clock: Node
var _cooking: Node
var _picker: Node
var _fee_debt := 0.0
var _ended := false
var _lbl_lives: Label
var _streak := 0
## Tiền đổi cho mỗi mạng hồi VƯỢT tối đa. 0 = bỏ phần dư (mặc định). Kĩ năng
var overflow_life_money := 0
## Chuỗi hồi mạng có tính đơn được kĩ năng ÉP hoàn hảo không (Aura farming).
var _streak_counts_forced := false
var _events: Node


func setup(level: Node, customers: Node, clock: Node, cooking: Node, picker: Node,
		hands: Node = null) -> void:
	_level = level
	_customers = customers
	_clock = clock
	_cooking = cooking
	_picker = picker
	layer = 6

	var p := Registry.passive(String(GameData.selected_character))
	lives = int(p.get("start_lives", START_LIVES))
	overflow_life_money = int(p.get("overflow_life_money", 0))
	_streak_counts_forced = bool(p.get("streak_counts_forced", false))
	_customers.vat_rate = VAT_RATE
	_customers.wrong_dish_leaves = true
	_customers.money_on_table = true
	if hands != null and hands.has_signal("item_discarded"):
		hands.item_discarded.connect(_on_item_discarded)
	_customers.add_money(START_MONEY - int(_customers.money))
	_customers.money_changed.connect(_on_money_changed)
	_customers.order_finished.connect(_on_order_finished)
	_build_ui()
	var cls := load("res://scripts/modes/asian/event_director.gd") as GDScript
	if cls != null:
		_events = cls.new()
		_events.name = "EventDirector"
		add_child(_events)
		_events.setup(level, customers, clock, hands)


## Thời gian đã trụ được (giây).
func survived_seconds() -> float:
	return maxf(0.0, float(_clock.duration) - float(_clock.time_left))


## Kết quả cho bảng tổng kết. `fail_note` là lý do thua level_base nhận được.
func result(fail_note: String) -> Dictionary:
	var note := fail_note
	if note.is_empty() and float(_clock.time_left) > 0.0:
		note = Lang.t("Đóng quán sớm — Asian Mode chỉ thắng khi trụ đủ 10 phút.")
	return {
		"won": note.is_empty() and lives > 0,
		"note": note,
		"seconds": survived_seconds(),
		"lives": lives,
	}


func _on_order_finished(order_: RefCounted, reason: String) -> void:
	if _ended:
		return
	if reason == "served":
		if bool(order_.truly_perfect) or (_streak_counts_forced and bool(order_.was_perfect)):
			_streak += 1
			if _streak >= STREAK_FOR_LIFE:
				_streak = 0
				restore_lives(1)
		else:
			_streak = 0
		return
	if reason != "left":
		return
	if bool(_customers.clearing_all):
		return
	_streak = 0
	lives -= 1
	if order_.has_meta("vip"):
		lives -= 1
	if _events != null and lives > 0:
		_events.trigger("review")
	_draw_lives(true)
	if lives <= 0:
		_lose(Lang.t("Thua: hết mạng."))


## Hồi `n` mạng, tối đa START_LIVES. Mọi nguồn hồi mạng (chuỗi hoàn hảo, kĩ
func restore_lives(n: int) -> void:
	var gained := mini(n, START_LIVES - lives)
	lives += gained
	var extra := n - gained
	if extra > 0 and overflow_life_money > 0:
		_customers.add_money(extra * overflow_life_money)
	_draw_lives(false)
	if gained > 0:
		AmThanh.play_sfx("perfect")


## Vứt đồ CHÁY vào thùng rác: trừ thêm gấp đôi tiền nguyên liệu của nó.
func _on_item_discarded(id: String, station: Node) -> void:
	if _ended or station == null:
		return
	if station.has_method("_on_fed"):
		return
	var at: Vector3 = station.global_position
	var source := _burnt_source(id)
	if source.is_empty():
		return
	var penalty := BURNT_PENALTY_FACTOR * _raw_cost(source, 0)
	if penalty > 0:
		_customers.add_money(-penalty, at)
		_customers._money_popup(at, -penalty, false)


## Thứ mà để cháy thì ra `id` (vd. "ham_cooked_fail" <- "ham"), hoặc rỗng.
func _burnt_source(id: String) -> String:
	for src in ItemCatalog.items():
		if ItemCatalog.burnt_state(String(src)) == id:
			return String(src)
	return ""


## Tổng tiền nguyên liệu THÔ tạo nên `id`: lần ngược công thức / sơ chế / nấu
func _raw_cost(id: String, depth: int) -> int:
	if depth > 8:
		return 0
	var own := ItemCatalog.cost(id)
	if own > 0:
		return own
	var key := ItemCatalog._recipe_key_for(id)
	if not key.is_empty():
		var total := 0
		for part in key.split("+"):
			total += _raw_cost(part, depth + 1)
		return total
	var src := ItemCatalog._source_of(id)
	return _raw_cost(src, depth + 1) if not src.is_empty() else 0


func _on_money_changed(total: int, _added: int, _spot: Vector3) -> void:
	if total <= 0 and not _ended:
		_lose(Lang.t("Thua: phá sản."))


func _process(delta: float) -> void:
	if _ended or _clock == null or not bool(_clock.counting_down):
		return
	var rate := 0.0
	if _cooking != null:
		for station in _cooking._running:
			var batch: Dictionary = _cooking._running[station]
			if not bool(batch.get("done", false)):
				rate += float(FEE_PER_SECOND.get(String(batch.get("mode", "")), 0.0))
	if _picker != null and _picker.is_open() and _picker._station != null \
			and String(_picker._station.kind) == "fridge":
		rate += FRIDGE_FEE_PER_SECOND
	if rate <= 0.0:
		return
	_fee_debt += rate * delta
	if _fee_debt >= 1.0:
		var n := int(_fee_debt)
		_fee_debt -= n
		_customers.add_money(-n)


## Thua từ bên ngoài (sự kiện thanh tra, trộm chó).
func lose(note: String) -> void:
	if not _ended:
		_lose(note)


func _lose(note: String) -> void:
	_ended = true
	if _events != null:
		_events.stop_all()
	_level.call_deferred("_end_level", "", note)


# ------------------------------------------------------------ giao diện ---

func _build_ui() -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	frame.offset_right = -28.0
	frame.offset_left = -328.0
	frame.offset_top = 196.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.07, 0.72)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)
	_lbl_lives = Label.new()
	_lbl_lives.add_theme_font_size_override("font_size", 24)
	_lbl_lives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_lbl_lives)
	_draw_lives(false)


func _draw_lives(flash: bool) -> void:
	_lbl_lives.text = Lang.t("MẠNG  %d / %d") % [maxi(lives, 0), START_LIVES]
	_lbl_lives.add_theme_color_override("font_color", COLOR_BAD if lives <= 1 else COLOR_TEXT)
	if flash:
		_lbl_lives.pivot_offset = _lbl_lives.size * 0.5
		var tw := create_tween()
		tw.tween_property(_lbl_lives, "scale", Vector2(1.35, 1.35), 0.1)
		tw.tween_property(_lbl_lives, "scale", Vector2.ONE, 0.2)
		AmThanh.play_sfx("time_warning")
