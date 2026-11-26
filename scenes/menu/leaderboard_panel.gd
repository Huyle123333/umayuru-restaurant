extends Control
## ─────────────────────────────────────────────── VÌ SAO LÀM NHƯ THẾ NÀY

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)
const COLOR_GOLD := Color("f2c230")

## Màu của từng hạng — GIỮ ĐÚNG bảng màu của bang_ket_qua.gd để người chơi
const COLOR_RANK := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"D": Color("5b8fb0"),
	"": Color("9a8f84"),
}

## Ba huy chương cho ba dòng đầu. Không dùng ảnh: ba ký tự này có sẵn trong
const MEDALS: Array[String] = ["🥇", "🥈", "🥉"]

@onready var _tabs: HBoxContainer = %Tabs
@onready var _table: VBoxContainer = %Table
@onready var _lbl_empty: Label = %LblEmpty
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null
var _group := ButtonGroup.new()
var _level_shown: String = ""


func _ready() -> void:
	hide()
	_btn_close.pressed.connect(close)
	_build_tabs()


## Dựng bốn nút tab từ GameData.MAN_XEP_HANG.
func _build_tabs() -> void:
	for id in GameData.RANKED_LEVELS:
		var code_ := String(id)
		var btn := Button.new()
		btn.text = String(GameData.RANKED_LEVEL_NAMES.get(code_, code_))
		btn.toggle_mode = true
		btn.button_group = _group
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_select_level.bind(code_))
		_tabs.add_child(btn)


## Mở bảng. `focus_on_close` là nút sẽ được trả lại focus lúc đóng, để chơi
func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	show()
	var first := String(GameData.RANKED_LEVELS[0])
	var first_btn := _tabs.get_child(0) as Button
	first_btn.button_pressed = true
	_select_level(first)
	first_btn.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------- nội dung ---

func _select_level(level_id: String) -> void:
	_level_shown = level_id
	_draw_table()


func _draw_table() -> void:
	for child in _table.get_children():
		_table.remove_child(child)
		child.queue_free()

	var list_ := GameData.level_leaderboard(_level_shown)
	if list_.is_empty():
		_lbl_empty.show()
		var is_real := GameData.LEVELS.has(_level_shown)
		_lbl_empty.text = tr("RANK_EMPTY") if is_real else tr("LEVEL_COMING_SOON")
		return

	_lbl_empty.hide()
	_table.add_child(_header_row())
	var place := 0
	for i in list_.size():
		var record: Dictionary = list_[i]
		if bool(record.get("pinned", false)):
			_table.add_child(_data_row(-1, record))
		else:
			_table.add_child(_data_row(place, record))
			place += 1


func _header_row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(_cell("#", 46, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	h.add_child(_cell(tr("RANK_COL_CHARACTER"), 0, COLOR_DIM, 17))
	h.add_child(_cell(tr("RANK_COL_MONEY"), 130, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_RIGHT))
	if _level_shown == GameData.ENDLESS_LEVEL:
		h.add_child(_cell(Lang.t("Thời gian"), 90, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	elif _level_shown == GameData.ASIAN_LEVEL:
		h.add_child(_cell(Lang.t("Kết quả"), 90, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		h.add_child(_cell(tr("RANK_COL_PLACE"), 60, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	return h


func _data_row(index: int, record: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)

	var place: String = "0"
	if index >= 0:
		place = MEDALS[index] if index < MEDALS.size() else str(index + 1)
	h.add_child(_cell(place, 46, COLOR_TEXT, 20, HORIZONTAL_ALIGNMENT_CENTER))

	var name_ := GameData.character_name(String(record.get("character", record.get("nv", ""))))
	var name_color: Color = COLOR_GOLD if index == 0 else COLOR_TEXT
	h.add_child(_cell(name_, 0, name_color, 20))

	h.add_child(_cell(str(int(record.get("money", record.get("tien", 0)))), 130, COLOR_TEXT, 20,
		HORIZONTAL_ALIGNMENT_RIGHT))

	# Asian: thắng thì ghi "Thắng", thua thì ghi thời gian đã trụ được.
	if _level_shown == GameData.ASIAN_LEVEL:
		var won := String(record.get("rank", "")) == "WIN"
		var t := int(float(record.get("time", 0.0)))
		@warning_ignore("integer_division")
		var txt := Lang.t("Thắng") if won else "%d:%02d" % [t / 60, t % 60]
		h.add_child(_cell(txt, 90, COLOR_GOLD if won else COLOR_TEXT, 20, HORIZONTAL_ALIGNMENT_CENTER))
		return h

	if _level_shown == GameData.ENDLESS_LEVEL:
		var s := int(float(record.get("time", 0.0)))
		@warning_ignore("integer_division")
		h.add_child(_cell("%d:%02d" % [s / 60, s % 60], 90, COLOR_TEXT, 20, HORIZONTAL_ALIGNMENT_CENTER))
		return h

	var rank := String(record.get("rank", record.get("hang", "")))
	var rank_cell: Label = _cell(rank if not rank.is_empty() else "—", 60,
		Color(COLOR_RANK.get(rank, COLOR_RANK[""])), 20, HORIZONTAL_ALIGNMENT_CENTER)
	h.add_child(rank_cell)
	return h


## Một ô chữ trong bảng. `rong` = 0 nghĩa là ô co giãn chiếm hết chỗ trống —
func _cell(text_: String, width: int, color_: Color, size_: int,
		can: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", color_)
	l.horizontal_alignment = can
	if width > 0:
		l.custom_minimum_size = Vector2(width, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
