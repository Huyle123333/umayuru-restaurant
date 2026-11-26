extends CanvasLayer

## Đã chọn xong một nguyên liệu.
signal item_chosen(station: Node, item_name: String)
## Bảng vừa mở hoặc vừa đóng — nhân vật nghe để khoá/mở di chuyển.
signal open_state_changed(is_open: bool)

## Mọi thứ về hình ảnh và tên gọi đều hỏi danh mục, bảng này không tự biết
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Cùng lý do với interaction_hud.gd: cỡ chữ tính theo viewport thiết kế
const SIZE_TITLE := 32
const SIZE_SELECTED := 30
const SIZE_DIM := 24
const SIZE_KEY := 18
const SIZE_ICON := 76

const COLOR_SELECTED := Color(1, 1, 1)
const COLOR_DIM := Color(0.66, 0.70, 0.67)
const COLOR_BORDER := Color(0.898039, 0.678431, 0.352941)

var _station: Workstation = null
var _entries: PackedStringArray = PackedStringArray()
var _index := 0

var _frame: PanelContainer
var _column: VBoxContainer
var _rows: Array[Control] = []


func _ready() -> void:
	layer = 20
	_build_ui()
	hide()


func _build_ui() -> void:
	_frame = PanelContainer.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	_frame.offset_left = -260.0
	_frame.offset_right = 260.0
	_frame.offset_top = -270.0
	_frame.offset_bottom = 270.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.07, 0.06, 0.74)
	bg.border_color = Color(COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b, 0.55)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(14)
	bg.set_content_margin_all(16)
	bg.shadow_color = Color(0, 0, 0, 0.45)
	bg.shadow_size = 18
	_frame.add_theme_stylebox_override("panel", bg)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	_frame.add_child(_column)


# ------------------------------------------------------------- mở / đóng ---

## Bàn chế tạo dùng chung bảng này để LẤY RA một thứ đang nằm trên bàn:
func open(station: Workstation) -> void:
	if station == null:
		return
	var list_ := PackedStringArray(station.contents) if station.kind == "crafting_table" \
		else station.options
	if list_.is_empty():
		return
	_station = station
	_entries = list_
	_index = 0
	_redraw()
	show()
	open_state_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	_station = null
	open_state_changed.emit(false)


func is_open() -> bool:
	return visible


# ---------------------------------------------------------------- nhập ---

## Dùng _input chứ không phải _unhandled_input.
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("cancel_menu"):
		close()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		var item_name := String(_entries[_index])
		var t := _station
		close()
		item_chosen.emit(t, item_name)
		get_viewport().set_input_as_handled()
		return

	var step := 0
	if event.is_action_pressed("move_up", true):
		step = -1
	elif event.is_action_pressed("move_down", true):
		step = 1
	if step != 0:
		_index = wrapi(_index + step, 0, _entries.size())
		_redraw()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- vẽ ---

func _redraw() -> void:
	for child in _column.get_children():
		child.queue_free()
	_rows.clear()

	var title := Label.new()
	title.text = _station.display_name if _station != null else ""
	title.add_theme_color_override("font_color", COLOR_BORDER)
	title.add_theme_font_size_override("font_size", SIZE_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(title)
	_column.add_child(HSeparator.new())

	for i in _entries.size():
		_column.add_child(_build_row(String(_entries[i]), i == _index))

	var hint := Label.new()
	hint.text = Lang.t("W/S: chọn     E: lấy     C: đóng")
	hint.add_theme_color_override("font_color", COLOR_DIM)
	hint.add_theme_font_size_override("font_size", SIZE_KEY)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(hint)


func _build_row(item_name: String, selected: bool) -> Control:
	var row_box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.10) if selected else Color(1, 1, 1, 0.0)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	if selected:
		style.set_border_width_all(2)
		style.border_color = COLOR_BORDER
	row_box.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row_box.add_child(hbox)
	hbox.add_child(_build_icon(item_name, selected))

	var label := Label.new()
	label.text = ItemCatalog.display_name(item_name)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_SELECTED if selected else COLOR_DIM)
	label.add_theme_font_size_override("font_size", SIZE_SELECTED if selected else SIZE_DIM)
	hbox.add_child(label)
	return row_box


## Ô ảnh minh hoạ. Thiếu file thì trả về ô màu có chữ cái đầu.
func _build_icon(item_name: String, selected: bool) -> Control:
	var path := ItemCatalog.icon_path(item_name)
	if ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.texture = load(path)
		icon.custom_minimum_size = Vector2(SIZE_ICON, SIZE_ICON)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate.a = 1.0 if selected else 0.7
		return icon

	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(SIZE_ICON, SIZE_ICON)
	var k := StyleBoxFlat.new()
	k.bg_color = Color.from_hsv(float(hash(item_name) % 360) / 360.0, 0.45, 0.55)
	k.set_corner_radius_all(8)
	cell.add_theme_stylebox_override("panel", k)
	var letter := Label.new()
	letter.text = ItemCatalog.display_name(item_name).substr(0, 1).to_upper()
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.add_theme_font_size_override("font_size", 36)
	cell.add_child(letter)
	return cell
