extends CanvasLayer
## Màn hình mở đầu: tên màn + đếm ngược trước khi đồng hồ bắt đầu chạy.
##
## KHÔNG tạm dừng game. Đây là điểm khác biệt num với mọi bảng khác trong game.
##
## Mười giây này không phải để người chơi ngồi đọc chữ — nó để họ ĐI THỬ MỘT
## VÒNG BẾP. Bếp có mười tám trạm nằm rải khắp phòng, và người mới cần biết
## cái tủ lạnh ở đâu trước khi có khách. Tạm dừng thì họ chỉ đứng nhìn một con
## số đếm lùi, tức là mười giây chết.
##
## Vì thế màn này để TRỐNG hết mức: chỉ tên màn và con số đếm lùi. Không nền
## tối, không câu gợi ý. Cả hai thứ đó đều kéo mắt người chơi về phía giữa màn
## hình, đúng lúc đáng ra họ phải nhìn quanh phòng bếp.
##
## KHÔNG CÓ NÚT BỎ QUA — và đây là chỗ đã sai một lần, đáng ghi lại.
##
## Bản đầu cho "bấm phím bất kỳ để vào sớm", nghĩ là để người chơi lại màn khỏi
## phải đợi. Nhưng mười giây này lại là mười giây người chơi ĐANG ĐI LẠI, nên
## phím đầu tiên họ bấm chính là W — và cái tính năng "bỏ qua" tự kích hoạt
## đúng lúc người chơi bắt đầu làm việc mà nó được tạo ra để phục vụ. Tính năng
## tự huỷ chính mục đích của nó.
##
## Sửa bằng cách bỏ hẳn thay vì đổi sang một phím khác: mười giây là quãng
## nghỉ có chủ ý trước ca làm, không phải một hộp thoại chờ bấm.
##
## Cái được đóng băng là ĐỒNG HỒ MÀN và VIỆC SINH KHÁCH — hai thứ tạo áp lực —
## chứ không phải quyền điều khiển. level_base lo phần đóng băng đó; node này
## chỉ đếm và báo khi hết.

## (2/10/2026) Thời gian chờ là 30 giây, và trong lúc đó bảng THỰC ĐƠN HÔM NAY
## mở ở mép phải. Bảng đó là node riêng (menu_panel.gd) chứ không nằm trong
## node này: nó còn sống suốt màn chơi để người chơi bấm phím mở lại, trong khi
## node này tự xoá ngay khi đếm xong. level_base nối hai thứ với nhau.

signal started

const COUNTDOWN_SECONDS := 30.0

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
	# KHÔNG chặn chuột và không chặn phím: người chơi phải đi lại được trong
	# lúc đếm. Đây là cả lý do tồn tại của mười giây này.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# KHÔNG có lớp nền tối. Bản trước phủ đen 32% toàn màn hình, nhưng lớp phủ
	# đó làm tối đúng cái bếp mà mười giây này sinh ra để người chơi nhìn. Chữ
	# đứng được trên nền sáng là nhờ viền đậm quanh chữ (xem _text), không cần
	# phải dìm cả frame hình xuống.

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
	# Viền đậm quanh chữ: chữ nằm đè lên cái bếp nhiều màu, không có viền thì
	# đúng chỗ nào trùng màu là chỗ đó biến mất.
	l.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	l.add_theme_constant_override("outline_size", border)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
