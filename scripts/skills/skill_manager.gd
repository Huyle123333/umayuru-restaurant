extends Node
## ──────────────────────────── KĨ NĂNG CHỈ ĂN KHI DÙNG ĐÚNG NHÂN VẬT ĐÓ

## Phát mỗi khi trạng thái sẵn sàng đổi. HUD nghe để tô màu hoặc tô xám ảnh.
signal ready_changed(is_ready: bool)

## Phát cùng lúc với ready_changed, mang phần SỐ của điều kiện để HUD vẽ thanh.
signal progress_changed(ratio: float, label: String)

const CUT_IN_PATH := "res://scripts/skills/skill_cut_in.gd"
const Registry := preload("res://scripts/skills/skill_registry.gd")

## Mỗi màn được dùng bao nhiêu lần.
@export var uses_per_level := 1

var _uses_left := 0
var _playing := false
## Nhân vật đang điều khiển, để khoá di chuyển trong lúc chiếu.
var _character: Node = null

## Hệ khách hàng và hệ bếp của màn. Node này CHỈ ghi vào chúng, không đọc
var _customers: Node = null
var _cooking: Node = null
## Đồng hồ màn (BangThoiGian). Có thể null — màn hướng dẫn không có đồng hồ.
var _clock: Node = null

## Hiệu ứng viết riêng đang chạy (thực thể của một file trong hieu_ung/).
var _effect: RefCounted = null

## Mô tả kĩ năng chủ động của nhân vật đang chơi, lấy từ SkillRegistry. RỖNG
var _active: Dictionary = {}


func _ready() -> void:
	_uses_left = uses_per_level
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameData.progress_changed.connect(_emit_state)
	call_deferred("_emit_state")


func track_character(character: Node) -> void:
	_character = character
	_apply_to_hands()


## Xác suất ghép hỏng ở bàn chế tạo. Bàn chế tạo do node Hands của NHÂN VẬT
var _craft_fail_chance := 0.0


func hands() -> Node:
	if _character == null or not is_instance_valid(_character):
		return null
	return _character.get_node_or_null("Hands")


func _apply_to_hands() -> void:
	var h := hands()
	if h != null and "craft_fail_chance" in h:
		h.craft_fail_chance = _craft_fail_chance


## Dựng kĩ năng chủ động thứ hai (nếu nhân vật có). Nó là một node con tự lo
func _build_secondary(character_id: String) -> void:
	var data := Registry.secondary(character_id)
	if data.is_empty() or get_node_or_null("SecondarySkill") != null:
		return
	var script_class := load(String(data.get("script", ""))) as GDScript
	if script_class == null:
		push_error("Không nạp được kĩ năng phụ: %s" % data.get("script", ""))
		return
	var node: Node = script_class.new()
	node.name = "SecondarySkill"
	add_child(node)
	node.setup(data, _customers, self)


## Kĩ năng có đang bấm được không.
func can_use() -> bool:
	if _playing:
		return false
	if _is_toggle():
		if _toggle_on or GameData.infinite_skill:
			return true
		return _budget_left > 0.0 and _meets_condition()
	if _active.is_empty() and not ignore_condition:
		return false
	if GameData.infinite_skill:
		return true
	if _uses_left <= 0:
		return false
	return _meets_condition()


## Điều kiện riêng của từng nhân vật đã đạt chưa.
@export var ignore_condition := false


func _meets_condition() -> bool:
	if ignore_condition:
		return true
	if _active.is_empty() or _customers == null:
		return false
	var n := _count_progress()
	var threshold := _threshold()
	return n >= 0 and threshold > 0 and n >= threshold


## Ngưỡng phải đạt của điều kiện hiện tại.
func _threshold() -> int:
	if String(_active.get("condition", "")) == Registry.COND_MENU_COVERED:
		return _customers.menu_dishes().size() if _customers != null else 0
	return int(_active.get("threshold", 0))


## Tiến độ điều kiện, dạng "3/5". Rỗng khi nhân vật chưa có kĩ năng chủ động
func progress_text() -> String:
	var n := _count_progress()
	if n < 0:
		return ""
	return "%d/%d" % [mini(n, _threshold()), _threshold()]


## Tỉ lệ hoàn thành điều kiện, 0…1 đã kẹp sẵn. Trả 0 khi không đếm được.
func condition_ratio() -> float:
	if _is_toggle() and (_toggle_on or _meets_condition()):
		var budget := float(_active.get("budget_seconds", 0.0))
		return clampf(_budget_left / budget, 0.0, 1.0) if budget > 0.0 else 0.0
	var n := _count_progress()
	var threshold := _threshold()
	if n < 0 or threshold <= 0:
		return 0.0
	return clampf(float(n) / float(threshold), 0.0, 1.0)


## Bộ đếm hiện tại của điều kiện, hoặc -1 nếu không đếm được.
func _count_progress() -> int:
	if _active.is_empty() or _customers == null:
		return -1
	match String(_active.get("condition", "")):
		Registry.COND_PERFECT_ORDERS:
			return int(_customers.perfect_orders)
		Registry.COND_ORDERS_DONE:
			return int(_customers.orders_done) - _progress_base
		Registry.COND_ORDERS_WITH_DISHES:
			return int(_customers.counted_orders_done)
		Registry.COND_TIME_ELAPSED:
			return _elapsed_seconds()
		Registry.COND_MONEY_EARNED:
			return maxi(0, int(_customers.money))
		Registry.COND_MENU_COVERED:
			var covered := 0
			for dish in _customers.menu_dishes():
				if _customers.perfect_dishes.has(dish):
					covered += 1
			return covered
	return -1


## Số đơn đã có lúc dùng kĩ năng lần gần nhất. Chỉ kĩ năng khai "repeat" đụng tới.
var _progress_base := 0


## Số giây ĐÃ TRÔI của màn, đọc từ đồng hồ màn. 0 nếu màn không có đồng hồ.
func _elapsed_seconds() -> int:
	if _clock == null:
		return 0
	return int(float(_clock.duration) - float(_clock.time_left))


## Gắn vào màn chơi: áp các kĩ năng BỊ ĐỘNG và bắt đầu theo dõi điều kiện.
func setup(customers: Node, cooking: Node, clock: Node = null) -> void:
	_customers = customers
	_cooking = cooking
	_clock = clock
	var id := String(GameData.selected_character)
	_active = Registry.active(id)
	_uses_left = int(_active.get("uses", uses_per_level))
	_budget_left = float(_active.get("budget_seconds", 0.0))
	_apply_passive(Registry.passive(id))
	if _customers != null \
			and String(_active.get("condition", "")) == Registry.COND_ORDERS_WITH_DISHES:
		_customers.counted_dishes = _active.get("dishes", [])

	if _customers != null and _customers.has_signal("order_finished"):
		_customers.order_finished.connect(_on_order_finished)
	if _customers != null and _customers.has_signal("money_changed"):
		_customers.money_changed.connect(func(_t: int, _a: int, _s: Vector3) -> void:
			_emit_state())
	_build_secondary(id)
	_emit_state()


## Vặn núm của các hệ khác theo bộ số bị động.
func _apply_passive(p: Dictionary) -> void:
	if _customers != null:
		_customers.patience_factor = float(p["patience_factor"])
		_customers.perfect_bonus += float(p["perfect_bonus_add"])
		_customers.bonus_payout_chance = float(p["bonus_payout_chance"])
		_customers.bonus_payout_multiplier = float(p["bonus_payout_multiplier"])
		_customers.dish_price_factors = p["dish_price_factors"]
		_customers.dish_weight_factors = p["dish_weight_factors"]
		_customers.skill_price_factor = float(p["all_price_factor"])
		_customers.time_scale = float(p["time_scale"])
		if bool(p["force_perfect"]):
			_customers.force_perfect = true
	if _clock != null:
		_clock.time_scale = float(p["time_scale"])
	_craft_fail_chance = float(p["cook_fail_chance"])
	_apply_to_hands()
	_refill_stamina_on_order = bool(p["refill_stamina_on_order"])
	if _cooking != null:
		_cooking.fail_chance = float(p["cook_fail_chance"])
		_cooking.speed_factor = float(p["time_scale"])
		_cooking.burn_time_cut += float(p["burn_time_cut"])
		_cooking.cook_time_cut += float(p["cook_time_cut"])
		_cooking.cook_time_cut_items = p["cook_time_cut_items"]
		_cooking.bake_time_cut += float(p["bake_time_cut"])


func _on_order_finished(_order: Variant, reason: String) -> void:
	if _refill_stamina_on_order and reason == "served" \
			and _character != null and _character.has_method("refill_stamina"):
		_character.refill_stamina()
	_emit_state()


var _refill_stamina_on_order := false
var _toggle_on := false
var _budget_left := 0.0
var _cut_in_shown := false
## Nhịp cập nhật HUD cho điều kiện đếm THỜI GIAN và cho ngân sách đang chạy.
var _hud_tick := 0.0


## Rời màn khi kĩ năng còn đang bật (thoát ra menu, chơi lại): phải TẮT hiệu
func _exit_tree() -> void:
	if _toggle_on:
		disable_effect()


## Màn chơi kết thúc (hết giờ, thua, đóng quán sớm): tắt kĩ năng bật/tắt nếu
func end_of_level() -> void:
	if _toggle_on:
		_set_toggle(false)


func _is_toggle() -> bool:
	return bool(_active.get("toggle", false))


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	if _effect != null and not _playing and not get_tree().paused \
			and _effect.has_method("tick"):
		_effect.tick(delta, _context())
	if _toggle_on and not _playing and not get_tree().paused:
		_budget_left -= delta
		if _budget_left <= 0.0:
			_budget_left = 0.0
			_set_toggle(false)
	_hud_tick -= delta
	if _hud_tick <= 0.0:
		_hud_tick = 0.25
		if _is_toggle() or String(_active.get("condition", "")) == Registry.COND_TIME_ELAPSED:
			_emit_state()


func _set_toggle(on: bool) -> void:
	if _toggle_on == on:
		return
	_toggle_on = on
	if on:
		_apply_effect()
	else:
		disable_effect()
	_emit_state()


## Space với kĩ năng bật/tắt. Trả về true nếu đã xử lý.
func _activate_toggle() -> void:
	if _toggle_on:
		_set_toggle(false)
		return
	if _budget_left <= 0.0 and not GameData.infinite_skill:
		return
	if not (_meets_condition() or GameData.infinite_skill):
		return
	if GameData.infinite_skill and _budget_left <= 0.0:
		_budget_left = float(_active.get("budget_seconds", 30.0))
	if not _cut_in_shown:
		_cut_in_shown = true
		var cut_in := _make_cut_in()
		if cut_in != null:
			get_tree().current_scene.add_child(cut_in)
			if cut_in.play(str(GameData.selected_character)):
				_playing = true
				_lock_character(true)
				cut_in.finished.connect(_on_cut_in_finished)
			else:
				cut_in.queue_free()
	_set_toggle(true)


## Bật hiệu ứng của kĩ năng chủ động.
func _apply_effect() -> void:
	var path := String(_active.get("script", ""))
	if not path.is_empty():
		_run_custom_effect(path)
		return

	match String(_active.get("effect", "")):
		Registry.FX_FORCE_PERFECT:
			if _customers != null:
				_customers.force_perfect = true
		Registry.FX_WILDCARD_DISHES:
			if _customers != null:
				_customers.wildcard_dishes = _active.get("wildcard_dishes", [])

	var multiplier := float(_active.get("perfect_payout_multiplier", 1.0))
	if _customers != null and not is_equal_approx(multiplier, 1.0):
		_customers.perfect_payout_multiplier = multiplier


## Nạp và chạy một hiệu ứng trong thư mục hieu_ung/. Xem effects/_template.gd để
func _run_custom_effect(path: String) -> void:
	var script_class := load(path) as GDScript
	if script_class == null:
		push_error("Không nạp được hiệu ứng kĩ năng: %s" % path)
		return
	if _effect != null and _effect.has_method("disable"):
		_effect.disable(_context())
	_effect = script_class.new()
	if not _effect.has_method("enable"):
		push_error("Hiệu ứng %s thiếu hàm enable()." % path)
		_effect = null
		return
	_effect.enable(_context())


## Gói mọi thứ một hiệu ứng có thể cần. Danh sách khoá ghi ở effects/_template.gd.
func _context() -> Dictionary:
	return {
		"customers": _customers,
		"cooking": _cooking,
		"clock": _clock,
		"level": get_parent(),
		"character": _character,
		"data": _active,
	}


## Tắt hiệu ứng đang chạy, nếu nó là loại bật/tắt được.
func disable_effect() -> void:
	if _effect != null and _effect.has_method("disable"):
		_effect.disable(_context())


## Người chơi bấm Space.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("skill"):
		return
	get_viewport().set_input_as_handled()
	activate()


func activate() -> void:
	if get_parent() != null and get_parent().get_node_or_null("LevelIntro") != null:
		return
	if _is_toggle():
		if not _playing:
			_activate_toggle()
		return
	if not can_use():
		return
	var id := str(GameData.selected_character)
	var skip_film := bool(_active.get("repeat", false)) and _cut_in_shown
	var cut_in: Node = null if skip_film else _make_cut_in()
	if cut_in != null:
		get_tree().current_scene.add_child(cut_in)
		if not cut_in.play(id):
			cut_in.queue_free()
			cut_in = null

	# Chỉ trừ lượt khi cheat TẮT, để cheat đúng nghĩa "không giới hạn".
	if not GameData.infinite_skill:
		_uses_left -= 1
	if bool(_active.get("repeat", false)) and _customers != null:
		_progress_base = int(_customers.orders_done)

	if cut_in == null:
		AmThanh.play_sfx("perfect")
		_apply_effect()
		_emit_state()
		return

	_cut_in_shown = true
	_playing = true
	_lock_character(true)
	_emit_state()
	cut_in.finished.connect(_on_cut_in_finished)

	_apply_effect()


func _on_cut_in_finished() -> void:
	_playing = false
	_lock_character(false)
	_emit_state()


func _lock_character(locked: bool) -> void:
	if _character != null and "movement_locked" in _character:
		_character.movement_locked = locked


func _emit_state() -> void:
	var usable := can_use()
	ready_changed.emit(usable)
	progress_changed.emit(condition_ratio(), _progress_label(usable))


## Chữ hiện cạnh thanh tiến trình. Ba trạng thái, ba câu khác hẳn nhau — không
func _progress_label(usable: bool) -> String:
	if _active.is_empty():
		return ""
	if _is_toggle():
		return _toggle_label()
	if usable:
		return "SPACE"
	if _uses_left <= 0 and not GameData.infinite_skill:
		return Lang.t("Đã dùng")
	var text := progress_text()
	return text if not text.is_empty() else "..."


## Chữ trên HUD của kĩ năng bật/tắt:
func _toggle_label() -> String:
	if _toggle_on:
		return "%ds" % int(ceilf(_budget_left))
	if _budget_left <= 0.0 and not GameData.infinite_skill:
		return Lang.t("Đã dùng")
	if _meets_condition() or GameData.infinite_skill:
		return "SPACE"
	var wait := maxi(0, int(_active.get("threshold", 0)) - _elapsed_seconds())
	return "%d:%02d" % [floori(wait / 60.0), wait % 60]


## Nạp lúc chạy chứ không preload, cùng lý do với level_base.gd: lỗi cú pháp
func _make_cut_in() -> Node:
	var script_class := load(CUT_IN_PATH) as GDScript
	if script_class == null:
		push_error("Không nạp được %s" % CUT_IN_PATH)
		return null
	var n: Node = script_class.new()
	n.name = "SkillCutIn"
	return n
