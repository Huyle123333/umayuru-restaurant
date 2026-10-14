extends Node
## KĨ NĂNG PHỤ: Fan tê liệt (Tokai Teio) — bảng chọn một món để nhận ngay.
##
## Bấm phím "skill_alt" (mặc định 3) → game tạm dừng, hiện bảng các món trong
## thực đơn hôm nay → chọn một món → món đó nằm sẵn trên tay. Số lần dùng mỗi
## màn khai ở khoá "uses" của SECONDARY trong teio.gd.
##
## Vì sao TẠM DỪNG lúc mở bảng: bảng che giữa màn hình và dùng chuột/phím mũi
## tên để chọn — đúng những phím đang điều khiển nhân vật. Để game chạy tiếp
## thì nhân vật trôi đi trong lúc người chơi dò món, và mỗi lần mở bảng là một
## lần đánh cược với thanh kiên nhẫn.
##
## Vì sao là node riêng chứ không nằm trong skill_manager: nó có phím riêng,
## giao diện riêng, bộ đếm lượt riêng và không dùng thứ gì của kĩ năng Space
## (điều kiện, cut-in, thanh tiến độ).

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

const ACTION := "skill_alt"
const THEME := "res://ui/theme/menu_theme.tres"
const ICON_SIZE := 72.0
const COLUMNS := 5

var _data: Dictionary = {}
var _customers: Node = null
var _manager: Node = null
var _uses_left := 0
var _layer: CanvasLayer = null


func setup(data: Dictionary, customers: Node, manager: Node) -> void:
	_data = data
	_customers = customers
	_manager = manager
	_uses_left = int(data.get("uses", 0))
	# Phải nhận phím cả khi cây scene đang dừng: chính bảng này dừng game, và
	# nó phải tự đóng lại được.
	process_mode = Node.PROCESS_MODE_ALWAYS


func uses_left() -> int:
	return _uses_left


func is_open() -> bool:
	return _layer != null


func _input(event: InputEvent) -> void:
	if _layer != null:
		# Đang mở: nuốt phím đóng ở đây, trước khi ESC kịp mở menu tạm dừng.
		if event.is_action_pressed(ACTION) or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		return
	if event.is_action_pressed(ACTION):
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	if _layer != null or _customers == null or _manager == null:
		return
	# Game đang dừng vì thứ khác (menu tạm dừng, phim cut-in, bảng kết quả),
	# hoặc chưa vào ca: không mở.
	if get_tree().paused:
		return
	var level := _manager.get_parent()
	if level != null and (level.get_node_or_null("LevelIntro") != null
			or level.get_node_or_null("ResultsPanel") != null):
		return
	var hands: Node = _manager.hands()
	if hands == null:
		return
	if _uses_left <= 0 and not GameData.infinite_skill:
		hands.notice.emit(Lang.t("%s: đã dùng hết lượt") % Lang.t(String(_data.get("name", ""))), false)
		AmThanh.play_sfx("craft_fail")
		return
	if hands.is_holding():
		hands.notice.emit(Lang.t("Tay đang cầm đồ — đặt xuống trước đã"), false)
		AmThanh.play_sfx("craft_fail")
		return

	_build_ui()
	get_tree().paused = true


func close() -> void:
	if _layer == null:
		return
	_layer.queue_free()
	_layer = null
	get_tree().paused = false


func _pick(id: String) -> void:
	var hands: Node = _manager.hands() if _manager != null else null
	close()
	if hands == null or not hands.give_item(id):
		return
	if not GameData.infinite_skill:
		_uses_left -= 1
	AmThanh.play_sfx("perfect")
	hands.notice.emit(Lang.t("%s: %s (còn %d lượt)") % [
		Lang.t(String(_data.get("name", ""))), ItemCatalog.display_name(id), maxi(0, _uses_left)], true)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)

	var panel := PanelContainer.new()
	if ResourceLoader.exists(THEME):
		panel.theme = load(THEME)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var title := Label.new()
	var left_text := "∞" if GameData.infinite_skill else str(_uses_left)
	title.text = Lang.t("%s — còn %s/%d lượt") % [
		Lang.t(String(_data.get("name", ""))).to_upper(), left_text, int(_data.get("uses", 0))]
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var hint := Label.new()
	hint.text = Lang.t("Chọn một món để nhận ngay trên tay. ESC để đóng.")
	hint.add_theme_font_size_override("font_size", 17)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)

	var first: Button = null
	for id in _customers.menu_dishes():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 132)
		btn.text = ItemCatalog.display_name(id)
		btn.add_theme_font_size_override("font_size", 16)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", int(ICON_SIZE))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var path := ItemCatalog.icon_path(id)
		if ResourceLoader.exists(path):
			btn.icon = load(path)
		btn.pressed.connect(_pick.bind(id))
		grid.add_child(btn)
		if first == null:
			first = btn
	# Đặt tiêu điểm sẵn vào món đầu: chọn được bằng mũi tên + Enter mà không
	# phải với tay sang chuột.
	if first != null:
		first.grab_focus.call_deferred()
