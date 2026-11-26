extends CanvasLayer


signal started

const COUNTDOWN_SECONDS := 15.0

const THEME := "res://ui/theme/menu_theme.tres"

const COLOR_NAME := Color(1, 0.96, 0.89)
const COLOR_OUTLINE := Color(0.22, 0.12, 0.06)
const COLOR_DIM := Color(0.86, 0.79, 0.70)

var _left: float = COUNTDOWN_SECONDS
var _done := false

var _root: Control
var _lbl_title: Label
var _lbl_counter: Label


func _ready() -> void:
	layer = 30
	_build_ui()


## `name_` là chữ lớn hiện giữa màn hình, ví dụ "NGÀY 1".
func start_countdown(name_: String) -> void:
	_lbl_title.text = name_
	_left = COUNTDOWN_SECONDS
	_done = false
	_root.show()
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.35)
	set_process(true)


func _process(delta: float) -> void:
	if _done:
		return
	_left -= delta
	_lbl_counter.text = Lang.t("Bắt đầu sau %d") % maxi(int(ceilf(_left)), 0)
	if _left <= 0.0:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	started.emit()

	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


# ------------------------------------------------------------ dựng hình ---

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)


	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME):
		col.theme = load(THEME)
	_root.add_child(col)

	_lbl_title = _text("", 92, COLOR_NAME, 14)
	col.add_child(_lbl_title)

	_lbl_counter = _text("", 30, COLOR_NAME, 10)
	col.add_child(_lbl_counter)


func _text(content: String, font_size: int, color: Color, border: int) -> Label:
	var l := Label.new()
	l.text = content
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	l.add_theme_constant_override("outline_size", border)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
