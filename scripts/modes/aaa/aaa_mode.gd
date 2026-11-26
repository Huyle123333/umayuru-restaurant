extends Node

const Planner := preload("res://scripts/modes/aaa/objective_planner.gd")
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const DlcOfferPanel := preload("res://scripts/modes/aaa/dlc_offer_panel.gd")
const PatchScreen := preload("res://scripts/modes/aaa/patch_screen.gd")
const ReviewPanel := preload("res://scripts/modes/aaa/review_panel.gd")
const GuideLine := preload("res://scripts/modes/aaa/guide_line.gd")
const ObjectiveTracker := preload("res://scripts/modes/aaa/objective_tracker.gd")
const GuideTrainer := preload("res://scripts/modes/aaa/guide_trainer.gd")
const DlcCard := preload("res://scripts/modes/aaa/dlc_card.gd")
const DlcCatalog := preload("res://scripts/modes/aaa/dlc_catalog.gd")

## Thẻ DLC bật lên giữa ca: bao lâu một lần, và hiện bao lâu.
const POPUP_EVERY := 45.0
const POPUP_SHOW := 5.0

## Tính lại bước tiếp theo 4 lần/giây. Không theo từng tín hiệu: khách được
const REPLAN_SECONDS := 0.25

## Các loại trạm luôn bị khoá trong AAA Mode.
const LOCKED_KINDS := ["oven", "ice_cream_machine", "pot_stack"]

var _player: CharacterBody3D
var _customers: Node
var _held := ""
var _stations := {}
var _line: Node3D
var _tracker: CanvasLayer
var _trainer: Node
var _replan_left := 0.0
var _review_shown := false


func setup(level: Node, player: CharacterBody3D, hands: Node, customers: Node,
		stations: Array, intro: Node) -> void:
	_player = player
	_customers = customers
	if hands != null:
		hands.held_item_changed.connect(func(id: String) -> void: _held = id)

	# Góc nhìn thứ 3 là một tuỳ chọn cheat — chế độ này không nhận cheat.
	if GameData.third_person_active:
		GameData.set_third_person_active(false)

	_lock_kitchen(stations)

	DlcCatalog.advance_sale()

	AmThanh.set_music_hushed(true)

	_line = GuideLine.new()
	_line.name = "AaaGuideLine"
	level.add_child(_line)
	_line.follow(player)

	_tracker = ObjectiveTracker.new()
	_tracker.name = "AaaObjective"
	level.add_child(_tracker)

	_trainer = GuideTrainer.new()
	_trainer.name = "AaaTrainerBrain"
	add_child(_trainer)
	_trainer.setup(player)
	_trainer.offer_requested.connect(_show_offer.bind("trainer"))

	if intro != null:
		var banner := _build_countdown_cards()
		level.add_child(banner)
		intro.started.connect(func() -> void:
			banner.queue_free()
			_in_shift = true)
	else:
		_in_shift = true

	level.add_child.call_deferred(PatchScreen.new())


## Gom trạm theo vai trò cho bộ suy luận, và khoá những trạm "thuộc DLC".
func _lock_kitchen(stations: Array) -> void:
	var allowed := _allowed_ingredients()
	var shelves := {}
	var tables := {}
	var stoves: Array = []
	for st in stations:
		var kind := String(st.kind)
		match kind:
			"stove":
				stoves.append(st)
			"ingredient_shelf":
				if allowed.has(String(st.item_id)):
					shelves[String(st.item_id)] = st
				else:
					_lock(st)
			"fridge":
				var keep := PackedStringArray()
				for o in st.options:
					if allowed.has(String(o)):
						keep.append(o)
				if keep.is_empty():
					_lock(st)
				else:
					st.options = keep
					_stations["fridge"] = st
			"guest_table":
				tables[int(st.table_number)] = st
			_:
				if LOCKED_KINDS.has(kind):
					_lock(st)
				elif not _stations.has(kind):
					_stations[kind] = st
	stoves.sort_custom(func(a: Node, b: Node) -> bool: return String(a.display_name) < String(b.display_name))
	for i in stoves.size():
		if i == 0:
			_stations["stove"] = stoves[i]
		else:
			_lock(stoves[i])
	_stations["shelves"] = shelves
	_stations["tables"] = tables


## Nguyên liệu THÔ mà thực đơn AAA cần — suy từ công thức, không gõ tay. Đổi
func _allowed_ingredients() -> Array[String]:
	var out: Array[String] = []
	for dish in _customers.menu:
		var key := ItemCatalog._recipe_key_for(String(dish))
		for part in key.split("+"):
			var raw := Planner._raw_source(String(part))
			if not out.has(raw):
				out.append(raw)
	return out


## Khoá một trạm: đổi `kind` sang loại không ai xử lý (đôi tay bỏ qua), tắt
func _lock(st: Node) -> void:
	st.kind = "dlc_locked"
	st.use_picker = false
	var dlc_sign := Label3D.new()
	dlc_sign.text = "DLC"
	dlc_sign.font_size = 72
	dlc_sign.pixel_size = 0.005
	dlc_sign.modulate = Color(1.0, 0.35, 0.3)
	dlc_sign.outline_modulate = Color(0.15, 0.0, 0.0)
	dlc_sign.outline_size = 14
	dlc_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	st.add_child(dlc_sign)
	var base: Vector3 = st.aim_position() if st.has_method("aim_position") else st.global_position
	dlc_sign.global_position = Vector3(base.x, maxf(base.y + 0.9, _top_of(st) + 0.35), base.z)
	st.interacted.connect(func(_s: Node, _i: int) -> void: _show_offer("kitchen"))


## Độ cao nóc của mọi mesh trong trạm (toạ độ thế giới). Bỏ qua Label3D để
func _top_of(st: Node) -> float:
	var top := -INF
	for c in st.find_children("*", "VisualInstance3D", true, false):
		if c is Label3D:
			continue
		var box: AABB = c.global_transform * c.get_aabb()
		top = maxf(top, box.end.y)
	return top


func _show_offer(kind: String) -> void:
	if get_tree().paused:
		return
	var panel := DlcOfferPanel.new()
	get_parent().add_child(panel)
	panel.show_offer(kind)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill"):
		get_viewport().set_input_as_handled()
		_show_offer("skill")


var _in_shift := false
var _popup_timer := POPUP_EVERY
var _popup_layer: CanvasLayer
var _popup_card: Control
var _popup_left := 0.0
var _popup_next := 0


## Cột 5 thẻ cho lúc đếm ngược. Ngoài phạm vi thẻ không chặn chuột: người chơi
func _build_countdown_cards() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "AaaSaleBanner"
	layer.layer = 8
	var col := VBoxContainer.new()
	col.position = Vector2(24, 24)
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(col)
	var head := Label.new()
	head.text = Lang.t("SIÊU SALE DLC")
	head.add_theme_font_size_override("font_size", 32)
	head.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	head.add_theme_color_override("font_outline_color", Color(0.3, 0.05, 0.0))
	head.add_theme_constant_override("outline_size", 10)
	col.add_child(head)
	var muted := Label.new()
	muted.text = Lang.t("Nhạc nền có trong Music Pack")
	muted.add_theme_font_size_override("font_size", 20)
	muted.add_theme_color_override("font_color", Color(1, 1, 1))
	muted.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.1))
	muted.add_theme_constant_override("outline_size", 8)
	col.add_child(muted)
	for id in DlcCatalog.ORDER:
		var card: Control = DlcCard.new()
		card.desc_side = "right"
		card.compact = true
		card.setup(String(id), 380.0)
		col.add_child(card)
	return layer


## Trả nhạc nền khi rời màn (về menu, chơi lại, sang đoạn kết).
func _exit_tree() -> void:
	AmThanh.set_music_hushed(false)


## Thẻ bật lên giữa ca, góc dưới phải. Đang trỏ chuột vào thẻ thì KHÔNG đếm
func _tick_popup(delta: float) -> void:
	if not _in_shift or get_tree().paused:
		return
	if _popup_card != null and is_instance_valid(_popup_card):
		var hovering := _popup_card.get_global_rect().has_point(_popup_card.get_global_mouse_position())
		if not hovering:
			_popup_left -= delta
		if _popup_left <= 0.0:
			_popup_layer.queue_free()
			_popup_card = null
		return
	_popup_timer -= delta
	if _popup_timer > 0.0:
		return
	_popup_timer = POPUP_EVERY
	var id := String(DlcCatalog.ORDER[_popup_next % DlcCatalog.ORDER.size()])
	_popup_next += 1
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 8
	get_parent().add_child(_popup_layer)
	_popup_card = DlcCard.new()
	_popup_card.desc_side = "left"
	_popup_card.setup(id, 220.0)
	_popup_layer.add_child(_popup_card)
	_popup_card.reset_size()
	var dest := Vector2(1920 - _popup_card.size.x - 24, 1080 - _popup_card.size.y - 150)
	_popup_card.position = Vector2(1940, dest.y)
	_popup_card.create_tween().tween_property(_popup_card, "position", dest, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_left = POPUP_SHOW


func _process(delta: float) -> void:
	_tick_popup(delta)
	_replan_left -= delta
	if _replan_left > 0.0:
		return
	_replan_left = REPLAN_SECONDS
	var order_ := _target_order()
	var plan: Dictionary = Planner.plan(order_, _held, _stations)
	var target: Node3D = plan.get("target")
	var guest: Node3D = null
	var mission := Lang.t("Chờ khách gọi món")
	if order_ != null:
		guest = _stations["tables"].get(int(order_.table_number()))
		mission = Lang.t("NHIỆM VỤ: Nấu %s cho Bàn %d") % [ItemCatalog.display_name(String(order_.dish)), int(order_.table_number())]
	_line.point_to(target, String(plan.get("key", "")), guest)

	var dist := -1.0
	var dir := ""
	var station_name := ""
	if target != null and is_instance_valid(target):
		var aim: Vector3 = target.aim_position() if target.has_method("aim_position") else target.global_position
		var off := aim - _player.global_position
		dist = Vector2(off.x, off.z).length()
		dir = _direction_word(off)
		station_name = _station_name(target)
	_tracker.show_plan(mission, plan, dist)
	_trainer.update_step(String(plan.get("text", "")), station_name, String(plan.get("key", "")),
		dir, maxf(dist, 0.0), int(plan.get("step", 1)), int(plan.get("total", 1)))


## Khách đang ngồi bàn có kiên nhẫn thấp nhất — game tự quyết thay người chơi.
func _target_order() -> Object:
	var best: Object = null
	for o in _customers.active_orders():
		if bool(o.in_queue) or o.table == null:
			continue
		if best == null or o.patience_ratio() < best.patience_ratio():
			best = o
	return best


## Hướng tới trạm, tính theo GÓC NHÌN camera chứ không theo trục thế giới:
func _direction_word(off: Vector3) -> String:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Lang.t("phía trước")
	var local := cam.global_transform.basis.inverse() * off
	if absf(local.x) > absf(local.z):
		return Lang.t("bên phải") if local.x > 0.0 else Lang.t("bên trái")
	return Lang.t("phía trước") if local.z < 0.0 else Lang.t("phía sau")


func _station_name(st: Node) -> String:
	var kind := String(st.kind)
	if kind == "ingredient_shelf":
		return Lang.t("Kệ %s") % ItemCatalog.display_name(String(st.item_id))
	if kind == "guest_table":
		return Lang.t("Bàn %d") % int(st.table_number)
	return Planner._name(kind)


## level_base gọi thay cho bảng kết quả thường.
func show_review() -> void:
	if _review_shown:
		return
	_review_shown = true
	_customers.close_shop()
	var panel := ReviewPanel.new()
	panel.name = "ResultsPanel"
	get_parent().add_child(panel)
	panel.show_review(int(_customers.money), int(_customers.orders_done), int(_trainer.nag_count))
