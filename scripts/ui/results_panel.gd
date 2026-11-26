extends CanvasLayer

const THEME := "res://ui/theme/menu_theme.tres"
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"
const LEVEL_SELECT_SCENE := "res://scenes/menu/level_select.tscn"

const WIDTH := 660.0

## Màu của từng hạng. Đúng bảng màu người dùng chốt: S vàng, A orange, B hồng,
const COLOR_GRADE := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"D": Color("5b8fb0"),
	"": Color("9a8f84"),
}

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)

var _box: PanelContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dựng và hiện bảng.
var fail_note := ""

## Endless Mode: số giây trụ được. Âm = không phải Endless (mặc định).
var endless_seconds := -1.0

## Asian Mode: {"won", "note", "seconds", "lives"} do asian_mode.result() trả.
var asian_result: Dictionary = {}

## Tiền shop vừa nhận ở lượt này (0 = không nhận, không in dòng).
var _shop_gain := 0


func show_results(money: int, served: int, perfect: int, left_angry: int,
		ep_hang: String = "") -> void:
	var level_id := ""
	if get_node_or_null("/root/GameData") != null:
		level_id = String(GameData.current_level)

	if not asian_result.is_empty():
		GameData.record_asian(bool(asian_result["won"]), money,
			float(asian_result["seconds"]))
		if bool(asian_result["won"]):
			_shop_gain = GameData.award_shop_coins(money)
		_build_asian_ui(money, served, perfect, left_angry)
		_show()
		return

	if endless_seconds >= 0.0:
		var old_best := GameData.get_best_money(level_id)
		var is_best := GameData.record_endless(money, endless_seconds)
		_shop_gain = GameData.award_shop_coins(money)
		_build_endless_ui(money, served, perfect, left_angry, old_best, is_best)
		_show()
		return

	var row := ep_hang
	if row.is_empty():
		row = GameData.rank_for(level_id, money) if not level_id.is_empty() else ""

	if not fail_note.is_empty():
		row = ""

	var old_record := 0
	var place := not row.is_empty()
	_skill_win = GameData.skill_win_pending
	if not level_id.is_empty():
		old_record = GameData.get_best_money(level_id)
		if place:
			GameData.complete_level(level_id, money)
			if ep_hang.is_empty() and not _skill_win and level_id != GameData.AAA_LEVEL:
				_shop_gain = GameData.award_shop_coins(money)
		if ep_hang.is_empty():
			GameData.record_rank(level_id, money, row)

	_build_ui(money, served, perfect, left_angry, row, old_record, place)
	_show()


## Tạm dừng game và cho bảng bật ra. Dùng chung cho bảng thường và Endless.
func _show() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.stop_music()
	AmThanh.play_sfx("results")

	_box.resized.connect(func() -> void:
		_box.pivot_offset = _box.size * 0.5)
	_box.pivot_offset = _box.size * 0.5

	_box.scale = Vector2(0.9, 0.9)
	_box.modulate.a = 0.0
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_box, "scale", Vector2.ONE, 0.28)
	tween.tween_property(_box, "modulate:a", 1.0, 0.20)


# ------------------------------------------------------------ dựng hình ---

var _skill_win := false


func _build_ui(money: int, served: int, perfect: int, left_angry: int,
		row: String, old_record: int, place: bool) -> void:
	var col := _make_box()
	_fill_normal(col, money, served, perfect, left_angry, row, old_record, place)


## Nền tối + khung bảng giữa màn hình. Trả về cột để đổ nội dung vào.
func _make_box() -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER)
	_box.custom_minimum_size = Vector2(WIDTH, 0.0)

	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists(THEME):
		_box.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s" % THEME)
	bg.add_child(_box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_box.add_child(col)
	return col


func _fill_normal(col: VBoxContainer, money: int, served: int, perfect: int,
		left_angry: int, row: String, old_record: int, place: bool) -> void:
	# --- tiêu đề ---
	var title := Label.new()
	title.text = Lang.t("HOÀN THÀNH") if place else Lang.t("CHƯA ĐẠT")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	# --- chữ hạng ---
	var grade_text := Label.new()
	grade_text.text = row if place else "—"
	grade_text.add_theme_font_size_override("font_size", 96)
	grade_text.add_theme_color_override("font_color", COLOR_GRADE.get(row, COLOR_GRADE[""]))
	grade_text.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.06))
	grade_text.add_theme_constant_override("outline_size", 10)
	grade_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(grade_text)

	col.add_child(_divider())

	# --- doanh thu ---
	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 10)
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(money_row)

	if ResourceLoader.exists(COIN_ICON):
		var icon := TextureRect.new()
		icon.texture = load(COIN_ICON)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		money_row.add_child(icon)

	var amount := Label.new()
	amount.text = str(money)
	amount.add_theme_font_size_override("font_size", 44)
	amount.add_theme_color_override("font_color", COLOR_TEXT)
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money_row.add_child(amount)

	var record := Label.new()
	if money > old_record and place and not _skill_win:
		record.text = Lang.t("KỶ LỤC MỚI!  (cũ: %d)") % old_record
		record.add_theme_color_override("font_color", COLOR_GRADE["A"])
	else:
		record.text = Lang.t("Kỷ lục: %d") % old_record
		record.add_theme_color_override("font_color", COLOR_DIM)
	record.add_theme_font_size_override("font_size", 17)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(record)

	col.add_child(_divider())

	# --- thống kê ---
	col.add_child(_row(Lang.t("Đơn đã phục vụ"), str(served)))
	col.add_child(_row(Lang.t("Trong đó hoàn hảo"), str(perfect)))
	col.add_child(_row(Lang.t("Khách bỏ đi"), str(left_angry)))
	if _shop_gain > 0:
		col.add_child(_row(Lang.t("Tiền shop nhận được"), "+%d" % _shop_gain))

	if not place and get_node_or_null("/root/GameData") != null:
		var mark: Dictionary = GameData.rank_thresholds_for(String(GameData.current_level))
		var missing := int(mark.get(GameData.MIN_RANK, 0)) - money
		var note := Label.new()
		note.text = Lang.t("Cần thêm %d nữa để đạt hạng %s.") % [maxi(missing, 0), GameData.MIN_RANK]
		if not fail_note.is_empty():
			note.text = fail_note
		note.add_theme_font_size_override("font_size", 17)
		note.add_theme_color_override("font_color", COLOR_GRADE[GameData.MIN_RANK])
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(note)

	# --- nút ---
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)

	var again := Button.new()
	again.text = Lang.t("Chơi lại")
	again.pressed.connect(_replay)
	button_row.add_child(again)

	var ticket := Button.new()
	ticket.text = Lang.t("Về chọn màn")
	ticket.pressed.connect(_go_level_select)
	button_row.add_child(ticket)

	var ending_needs := ""
	var here := ""
	if get_node_or_null("/root/GameData") != null:
		ending_needs = String(GameData.LEVELS.get(GameData.ENDING_LEVEL, {}).get("needs", ""))
		here = String(GameData.current_level)
	if place and not here.is_empty() and here == ending_needs:
		var ending := Button.new()
		ending.text = "Ending"
		ending.pressed.connect(_go_ending)
		button_row.add_child(ending)
		ending.grab_focus()
	else:
		again.grab_focus()


## Bảng kết quả của Endless: chữ to ở giữa là THỜI GIAN chứ không phải hạng.
func _build_endless_ui(money: int, served: int, perfect: int, left_angry: int,
		old_best: int, is_best: bool) -> void:
	const EndlessMode := preload("res://scripts/modes/endless/endless_mode.gd")
	var col := _make_box()

	var title := Label.new()
	title.text = Lang.t("HẾT GIỜ")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 10)
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(money_row)
	if ResourceLoader.exists(COIN_ICON):
		var icon := TextureRect.new()
		icon.texture = load(COIN_ICON)
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		money_row.add_child(icon)
	var big := Label.new()
	big.text = str(money)
	big.add_theme_font_size_override("font_size", 72)
	big.add_theme_color_override("font_color", COLOR_GRADE["S"] if is_best else COLOR_TEXT)
	big.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.06))
	big.add_theme_constant_override("outline_size", 8 if is_best else 0)
	money_row.add_child(big)

	var record := Label.new()
	if is_best:
		record.text = Lang.t("KỶ LỤC MỚI!  (cũ: %d)") % old_best
		record.add_theme_color_override("font_color", COLOR_GRADE["A"])
	else:
		record.text = Lang.t("Kỷ lục: %d") % old_best
		record.add_theme_color_override("font_color", COLOR_DIM)
	record.add_theme_font_size_override("font_size", 17)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(record)

	col.add_child(_divider())
	col.add_child(_row(Lang.t("Thời gian trụ được"), EndlessMode.format_time(endless_seconds)))
	col.add_child(_row(Lang.t("Đơn đã phục vụ"), str(served)))
	col.add_child(_row(Lang.t("Trong đó hoàn hảo"), str(perfect)))
	col.add_child(_row(Lang.t("Khách bỏ đi"), str(left_angry)))
	if _shop_gain > 0:
		col.add_child(_row(Lang.t("Tiền shop nhận được"), "+%d" % _shop_gain))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)
	var again := Button.new()
	again.text = Lang.t("Chơi lại")
	again.pressed.connect(_replay)
	button_row.add_child(again)
	var back := Button.new()
	back.text = Lang.t("Về chọn màn")
	back.pressed.connect(_go_level_select)
	button_row.add_child(back)
	again.grab_focus()


## Bảng kết quả Asian: chữ to là THẮNG / THUA, kèm lý do thua.
func _build_asian_ui(money: int, served: int, perfect: int, left_angry: int) -> void:
	const EndlessMode := preload("res://scripts/modes/endless/endless_mode.gd")
	var won := bool(asian_result["won"])
	var col := _make_box()

	var big := Label.new()
	big.text = Lang.t("THẮNG") if won else Lang.t("THUA")
	big.add_theme_font_size_override("font_size", 96)
	big.add_theme_color_override("font_color", COLOR_GRADE["S"] if won else COLOR_GRADE[""])
	big.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.06))
	big.add_theme_constant_override("outline_size", 10)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(big)

	if not won:
		var note := Label.new()
		note.text = String(asian_result["note"])
		note.add_theme_font_size_override("font_size", 18)
		note.add_theme_color_override("font_color", COLOR_DIM)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(note)

	col.add_child(_divider())
	col.add_child(_row(Lang.t("Doanh thu"), str(money)))
	col.add_child(_row(Lang.t("Thời gian trụ được"), EndlessMode.format_time(float(asian_result["seconds"]))))
	col.add_child(_row(Lang.t("Mạng còn lại"), str(maxi(int(asian_result["lives"]), 0))))
	col.add_child(_row(Lang.t("Đơn đã phục vụ"), str(served)))
	col.add_child(_row(Lang.t("Trong đó hoàn hảo"), str(perfect)))
	col.add_child(_row(Lang.t("Khách bỏ đi"), str(left_angry)))
	if _shop_gain > 0:
		col.add_child(_row(Lang.t("Tiền shop nhận được"), "+%d" % _shop_gain))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)
	var again := Button.new()
	again.text = Lang.t("Chơi lại")
	again.pressed.connect(_replay)
	button_row.add_child(again)
	var back := Button.new()
	back.text = Lang.t("Về chọn màn")
	back.pressed.connect(_go_level_select)
	button_row.add_child(back)
	again.grab_focus()


func _row(label: String, value: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var a := Label.new()
	a.text = label
	a.add_theme_font_size_override("font_size", 19)
	a.add_theme_color_override("font_color", COLOR_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)

	var b := Label.new()
	b.text = value
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	h.add_child(b)
	return h


func _divider() -> Control:
	var d := ColorRect.new()
	d.color = Color(0.29, 0.153, 0.071, 0.22)
	d.custom_minimum_size = Vector2(0, 2)
	return d


# ---------------------------------------------------------------- nút ---

## Bỏ tạm dừng TRƯỚC khi đổi màn.
func _replay() -> void:
	_leave_pause()
	get_tree().reload_current_scene()


func _go_ending() -> void:
	_leave_pause()
	get_tree().change_scene_to_file(GameData.start_story_level(GameData.ENDING_LEVEL))


func _go_level_select() -> void:
	_leave_pause()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _leave_pause() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
