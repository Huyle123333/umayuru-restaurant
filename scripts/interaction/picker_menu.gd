extends CanvasLayer
## Bảng chọn nguyên liệu của tủ lạnh và máy làm kem.
##
## Vì sao KHÔNG dùng danh sách Tab như các trạm khác:
## Danh sách Tab chỉ có chữ, và phải bấm Tab lần lượt qua từng mục. Với thứ
## người chơi lấy hàng chục lần mỗi màn thì đọc chữ là chậm — mắt nhận ra
## hình khối nhanh hơn nhiều so với đọc một từ. Đó cũng là lý do mọi game
## nấu ăn đều dùng icon chứ không dùng danh sách chữ.
##
## Vì sao bảng KHÔNG dừng game:
## Thanh kiên nhẫn của khách vẫn chạy trong lúc người chơi đứng chọn. Nếu
## dừng game thì bảng thành chỗ trú an toàn — mở ra suy nghĩ thoải mái rồi
## đóng lại, và mọi áp lực thời gian của thể loại này biến mất. Đứng mở tủ
## lạnh phải là một quyết định tốn thời gian thật.
##
## Nhưng nhân vật thì ĐỨNG YÊN khi bảng mở, vì W/S đang là phím đi lại. Để
## cả hai cùng nhận W/S thì mỗi lần đổi nguyên liệu nhân vật lại nhích lên
## nhích xuống — người chơi không thể chọn mà không xê dịch. Khoá di chuyển
## là cách duy nhất giữ được một phím cho hai việc mà không rối.

## Đã chọn xong một nguyên liệu.
signal item_chosen(station: Node, item_name: String)
## Bảng vừa mở hoặc vừa đóng — nhân vật nghe để khoá/mở di chuyển.
signal open_state_changed(is_open: bool)

## Mọi thứ về hình ảnh và tên gọi đều hỏi danh mục, bảng này không tự biết
## gì cả. Nhờ vậy đổi ảnh hay đổi tên một nguyên liệu chỉ sửa ở một chỗ.
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Cùng lý do với interaction_hud.gd: cỡ chữ tính theo viewport thiết kế
## 1920×1080, người chơi ở cửa sổ 1280×720 chỉ thấy 2/3 con số này.
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
	# Neo giữa màn hình: bảng này là việc người chơi đang tập trung làm, để
	# ở rìa thì mắt phải rời khỏi chỗ đang thao tác.
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
	# Bóng mờ chứ không đục: người chơi vẫn liếc thấy bếp phía sau, nên biết
	# mình đang tốn thời gian ở đâu.
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
## danh sách là những gì đang có trên mặt bàn (station.contents) thay vì danh
## mục cố định của tủ lạnh/máy kem (station.options). Một bảng, hai nguồn —
## người chơi đã quen W/S + E ở tủ lạnh nên không phải học thao tác mới.
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
##
## _input chạy TRƯỚC mọi thứ khác, nên bảng chắc chắn cướp được phím E trước
## khi bộ chọn mục tiêu kịp xử lý. Nếu để ở _unhandled_input thì thứ tự phụ
## thuộc vào ai được thêm vào cây scene sau — một thứ thay đổi âm thầm mỗi
## lần sửa level_base.gd.
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

	# W/S đảo qua lại và CUỘN VÒNG. Cuộn vòng vì danh sách ngắn (3–4 mục):
	# chặn ở hai đầu thì người chơi ở mục cuối muốn về mục đầu phải bấm ngược
	# hết cả danh sách.
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
		# Viền dày chỉ ở mục đang chọn — nhìn một cái là biết, không phải so
		# sánh độ sáng giữa các dòng.
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
		# (16/11/2026) Bỏ huy hiệu dao: công thức đã in trên vé đơn hàng, ảnh
		# trong tủ lạnh chỉ cần cho biết đây là nguyên liệu gì.
		return icon

	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(SIZE_ICON, SIZE_ICON)
	var k := StyleBoxFlat.new()
	# Màu suy ra từ chính tên nguyên liệu, nên mỗi thứ có một màu cố định —
	# vẫn phân biệt được bằng mắt kể cả khi chưa có ảnh nào.
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
