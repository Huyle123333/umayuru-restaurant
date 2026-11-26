extends CanvasLayer

const OrderTicket := preload("res://scripts/ui/order_ticket.gd")
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"

const ACTION := "toggle_orders"
const MARGIN := 28.0
const GAP := 6
## Chừa mép phải cho bảng đồng hồ & ví (hud_clock: rộng 300, lề 28) cộng một
const RIGHT_RESERVED := 300.0 + 28.0 + 16.0

const LABEL_WIDTH := 46.0
const SLIDE_SECONDS := 0.32

const COLOR_PANEL := Color(0.11, 0.09, 0.07, 0.80)
const COLOR_BORDER := Color("c2a173")
const COLOR_TITLE := Color(0.96, 0.93, 0.88)
const COLOR_DIM := Color(0.72, 0.67, 0.60)

## Ba bậc màu của viền nhãn, khớp đúng ba bậc trên bar kiên nhẫn của vé.
const COLOR_GREEN := Color("4f9d5d")
const COLOR_YELLOW := Color("d9a520")
const COLOR_RED := Color("c4433a")

## Bảng mở sẵn khi vào màn. Người chơi phải THẤY hệ đơn hàng tồn tại trước đã;
@export var open_by_default: bool = true

var is_open: bool = true

var _board: Control
## Dải vé kiểu BĂNG CHUYỀN (16/11/2026) — một Control trơn, các vé tự xếp
var _row: Control
var _label: PanelContainer
var _lbl_counter: Label
var _label_style: StyleBoxFlat
var _coin_icon: Texture2D = null
var _ticket: Dictionary = {}


func _ready() -> void:
	layer = 5
	if ResourceLoader.exists(COIN_ICON):
		_coin_icon = load(COIN_ICON)
	else:
		push_warning("Thiếu ảnh tiền: %s" % COIN_ICON)
	_build_ui()

	is_open = open_by_default
	_board.position.y = _y_open() if is_open else _y_closed()
	_label.visible = not is_open


# ------------------------------------------------------------ dựng hình ---

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- dải vé ---
	var design_width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	_board = Control.new()
	_board.size = Vector2(design_width - MARGIN - RIGHT_RESERVED, OrderTicket.HEIGHT)
	_board.position = Vector2(MARGIN, _y_closed())
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.clip_contents = true
	root.add_child(_board)

	_row = Control.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_row)

	# --- cái nhãn còn lại khi bảng đóng ---
	_label = PanelContainer.new()
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.offset_left = 0.0
	_label.offset_right = LABEL_WIDTH
	_label.offset_top = MARGIN
	_label.offset_bottom = MARGIN + 76.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_style = _label_frame()
	_label.add_theme_stylebox_override("panel", _label_style)
	root.add_child(_label)

	var label_col := VBoxContainer.new()
	label_col.add_theme_constant_override("separation", 0)
	_label.add_child(label_col)

	_lbl_counter = Label.new()
	_lbl_counter.text = "0"
	_lbl_counter.add_theme_font_size_override("font_size", 26)
	_lbl_counter.add_theme_color_override("font_color", COLOR_TITLE)
	_lbl_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_col.add_child(_lbl_counter)

	var key_label := Label.new()
	key_label.text = SettingsManager.key_name(ACTION)
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", COLOR_DIM)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_col.add_child(key_label)


# --------------------------------------------------------------- đóng mở ---

func _y_open() -> float:
	return MARGIN


func _y_closed() -> float:
	return -OrderTicket.HEIGHT - 16.0


## Bắt phím ở _unhandled_key_input chứ không phải _input.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION) and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	if open == is_open:
		return
	is_open = open
	if open:
		_label.visible = false

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_board, "position:y", _y_open() if open else _y_closed(), SLIDE_SECONDS)
	if not open:
		tween.finished.connect(func() -> void:
			if not is_open:
				_label.visible = true)


# -------------------------------------------------------------- dữ liệu ---

## Nối vào hệ khách. Chỉ cần hai tín hiệu: đơn sinh ra và đơn kết thúc.
func listen_to_orders(orders: Node) -> void:
	if orders == null:
		return
	if orders.has_signal("order_created"):
		orders.order_created.connect(add_order)
	if orders.has_signal("order_finished"):
		orders.order_finished.connect(_on_order_finished)


func add_order(order: RefCounted) -> void:
	if order == null or _ticket.has(order):
		return
	var v := OrderTicket.new()
	_row.add_child(v)
	v.position.x = _conveyor_end()
	v.build(order, _coin_icon)
	v.slide_in()
	_ticket[order] = v
	_update_label()


## Còn chỗ cho thêm MỘT vé nữa không (16/11/2026).
func has_room() -> bool:
	var used := 0.0
	for v in _ticket.values():
		if is_instance_valid(v):
			used += float(v.custom_minimum_size.x) + GAP
	return used + OrderTicket.width_for(OrderTicket.MAX_PARTS) <= _board.size.x


func _on_order_finished(order: RefCounted, _reason: String) -> void:
	remove_order(order)


func remove_order(order: RefCounted) -> void:
	var v = _ticket.get(order)
	if v == null:
		return
	_ticket.erase(order)
	if is_instance_valid(v):
		v.slide_out()
	_update_label()


## Mép phải của vé cuối cùng đang nằm trên băng — chỗ vé mới đặt vào.
func _conveyor_end() -> float:
	var end := 0.0
	for c in _row.get_children():
		var t := c as Control
		if t != null:
			end = maxf(end, t.position.x + t.custom_minimum_size.x + GAP)
	return end


## BĂNG CHUYỀN — vé xếp cạnh nhau bình thường, đơn CŨ NHẤT đứng đầu bên
const CONVEYOR_SPEED := 12.0

func _layout_conveyor(delta: float) -> void:
	var x := 0.0
	var k := minf(1.0, delta * CONVEYOR_SPEED)
	for c in _row.get_children():
		var t := c as Control
		if t == null or t.is_queued_for_deletion():
			continue
		t.size = Vector2(t.custom_minimum_size.x, OrderTicket.HEIGHT)
		t.position.x = lerpf(t.position.x, x, k)
		t.position.y = 0.0
		x += t.custom_minimum_size.x + GAP


func _process(delta: float) -> void:
	_layout_conveyor(delta)
	if not is_open:
		_update_label()


func _update_label() -> void:
	if _lbl_counter == null:
		return
	_lbl_counter.text = str(_ticket.size())

	var low := 1.0
	for order in _ticket.keys():
		if bool(order.in_queue):
			continue
		low = minf(low, float(order.patience_ratio()))

	var color := COLOR_GREEN
	if low <= 0.2:
		color = COLOR_RED
	elif low <= 0.5:
		color = COLOR_YELLOW
	if _label_style.border_color != color:
		_label_style.border_color = color


# ---------------------------------------------------------------- frame ---

func _label_frame() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.border_color = COLOR_GREEN
	sb.border_width_right = 3
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
