extends CanvasLayer
## Bảng theo dõi đơn hàng ở mép TRÁI màn hình. Bấm phím 1 để đóng/mở.
##
## Vì sao gộp các vé vào MỘT tấm bảng lớn thay vì để chúng lơ lửng thành cột:
## sáu tấm vé rời rạc chiếm 330 px chiều ngang và gần trọn chiều cao màn hình
## mà không bao giờ tắt được. Trong một game nhìn từ trên xuống thì đó là một
## phần ba sàn bếp bị che vĩnh viễn. Gom vào một tấm bảng thì cả cụm có MỘT
## công tắc: cần thì kéo slide_out đọc, xong thì đẩy vào, tầm nhìn trả lại nguyên vẹn.
##
## Cái nhãn nhỏ ở mép trái là phần bắt buộc của thiết kế này, không phải trang
## trí. Một bảng đóng hoàn toàn thì người chơi quên mất là có đơn đang chờ, và
## quên theo cách tệ nhất — không có gì trên màn hình nhắc họ. Cái nhãn giữ lại
## đúng hai thông tin cần để quyết định có mở bảng slide_out hay không: **có mấy đơn**
## và **đơn gấp nhất còn bao nhiêu kiên nhẫn** (viền nhãn đổi màu theo). Nó
## chiếm 46 px thay vì 354.
##
## Node này chỉ VẼ. Nó không đếm giờ, không tính tiền, không quyết định khi nào
## khách bỏ đi — nó nghe hai tín hiệu và đọc dữ liệu đơn. Luật nằm trọn ở
## quan_ly_khach.gd, nên muốn đổi luật thì sửa một file.

const OrderTicket := preload("res://scripts/ui/order_ticket.gd")
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"

const MARGIN := 28.0
const TICKET_WIDTH := 330.0
const COUNTER_SIZE := 12.0            # đệm empty lòng bảng
const WIDTH := TICKET_WIDTH + COUNTER_SIZE * 2.0
const HEIGHT := 820.0           # tới sát khối "sức · tay · kĩ năng" ở y=850
const GAP := 8

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
## giấu nó đi ngay từ đầu thì người mới không biết có phím 1.
@export var open_by_default: bool = true

var is_open: bool = true

var _board: PanelContainer
var _col: VBoxContainer
var _label: PanelContainer
var _lbl_counter: Label
var _label_style: StyleBoxFlat
var _coin_icon: Texture2D = null
var _ticket: Dictionary = {}    # DonHang -> node vé


func _ready() -> void:
	layer = 5
	if ResourceLoader.exists(COIN_ICON):
		_coin_icon = load(COIN_ICON)
	else:
		push_warning("Thiếu ảnh tiền: %s" % COIN_ICON)
	_build_ui()

	is_open = open_by_default
	# Đặt thẳng vào vị trí ở frame hình đầu, KHÔNG tween: chạy hiệu ứng lúc
	# vừa vào màn thì người chơi thấy bảng tự trôi mà không hiểu vì sao.
	_board.position.x = _x_open() if is_open else _x_closed()
	_label.visible = not is_open


# ------------------------------------------------------------ dựng hình ---

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- tấm bảng ---
	#
	# Neo để nguyên góc trên-trái (mọi anchor = 0) và ta gán size bằng tay.
	# KHÔNG dùng preset neo rồi tween position: neo tính lại rect từ anchor +
	# offset ở mỗi lần bố trí nên nó đánh nhau với position, và cái rect phình
	# thêm một ít sau mỗi frame hình.
	_board = PanelContainer.new()
	_board.size = Vector2(WIDTH, HEIGHT)
	_board.position = Vector2(_x_closed(), MARGIN)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_theme_stylebox_override("panel", _board_frame())
	root.add_child(_board)

	var empty := VBoxContainer.new()
	empty.add_theme_constant_override("separation", 10)
	_board.add_child(empty)

	var head := HBoxContainer.new()
	empty.add_child(head)

	var title := Label.new()
	title.text = "ĐƠN HÀNG"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	var hint := Label.new()
	hint.text = "1  ẩn/hiện"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", COLOR_DIM)
	head.add_child(hint)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", GAP)
	_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty.add_child(_col)

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
	key_label.text = "1"
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", COLOR_DIM)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_col.add_child(key_label)


# --------------------------------------------------------------- đóng mở ---

func _x_open() -> float:
	return MARGIN


func _x_closed() -> float:
	return -WIDTH - 16.0


## Bắt phím ở _unhandled_key_input chứ không phải _input.
##
## Nghĩa là: hộp thoại, ô nhập chữ hay bất cứ Control nào đang nhận bàn phím
## sẽ NUỐT phím 1 trước khi tới đây. Đúng như mong muốn — gõ số 1 vào một ô
## nhập mà cái bảng đơn hàng nhảy slide_out thì rất khó chịu, và lỗi kiểu đó chỉ lộ
## slide_out khi đã có màn hướng dẫn với hộp thoại Có/Không.
func _unhandled_key_input(su_kien: InputEvent) -> void:
	var key_label := su_kien as InputEventKey
	if key_label == null or not key_label.pressed or key_label.echo:
		return
	# Nhận cả phím số hàng trên lẫn phím số bên bàn phím phụ.
	if key_label.keycode == KEY_1 or key_label.keycode == KEY_KP_1:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	if open == is_open:
		return
	is_open = open
	# Nhãn tắt NGAY khi bắt đầu mở, nhưng chỉ bật lại SAU khi bảng đóng xong:
	# hiện nhãn empty lúc tấm bảng còn đang trượt qua chỗ nó thì hai thứ chồng
	# lên nhau đúng một phần ba giây, nhìn như lỗi vẽ.
	if open:
		_label.visible = false

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_board, "position:x", _x_open() if open else _x_closed(), SLIDE_SECONDS)
	if not open:
		tween.finished.connect(func() -> void:
			if not is_open:
				_label.visible = true)


# -------------------------------------------------------------- dữ liệu ---

## Nối vào hệ khách. Chỉ cần hai tín hiệu: đơn sinh slide_out và đơn kết thúc.
func listen_to_orders(ql: Node) -> void:
	if ql == null:
		return
	if ql.has_signal("don_moi"):
		ql.don_moi.connect(add_order)
	if ql.has_signal("don_ket_thuc"):
		ql.don_ket_thuc.connect(_on_order_finished)


func add_order(order: RefCounted) -> void:
	if order == null or _ticket.has(order):
		return
	var v := OrderTicket.new()
	_col.add_child(v)
	v.build(order, _coin_icon)
	v.slide_in()
	_ticket[order] = v
	_update_label()


func _on_order_finished(order: RefCounted, _ly_do: String) -> void:
	remove_order(order)


func remove_order(order: RefCounted) -> void:
	var v = _ticket.get(order)
	if v == null:
		return
	_ticket.erase(order)
	if is_instance_valid(v):
		v.slide_out()
	_update_label()


func _process(_delta: float) -> void:
	# Chỉ cập nhật nhãn khi bảng đang ĐÓNG: lúc mở thì mọi thứ nhãn nói đều
	# đã hiện rõ trên từng tấm vé, tính lại mỗi frame hình là việc thừa.
	if not is_open:
		_update_label()


func _update_label() -> void:
	if _lbl_counter == null:
		return
	_lbl_counter.text = str(_ticket.size())

	# Viền nhãn mang màu của đơn GẤP NHẤT, không phải trung bình.
	# Trung bình thì năm đơn thong thả kéo màu về xanh empty khi một đơn sắp
	# mất khách — mà cái người chơi cần biết chính là đơn tệ nhất.
	# BỎ QUA đơn của khách còn đang xếp hàng: bar của họ chưa chạy, nhưng
	# `ti_le()` lúc đó trả về kiên nhẫn HÀNG ĐỢI đang tụt — tính vào đây thì
	# cái tab đỏ lên vì một đơn mà người chơi còn chưa được phép phục vụ.
	var low := 1.0
	for order in _ticket.keys():
		if bool(order.o_hang):
			continue
		low = minf(low, float(order.ti_le()))

	var color := COLOR_GREEN
	if low <= 0.2:
		color = COLOR_RED
	elif low <= 0.5:
		color = COLOR_YELLOW
	if _label_style.border_color != color:
		_label_style.border_color = color


# ---------------------------------------------------------------- frame ---

func _board_frame() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.border_color = COLOR_BORDER
	sb.border_width_right = 3
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = COUNTER_SIZE
	sb.content_margin_right = COUNTER_SIZE
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


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
