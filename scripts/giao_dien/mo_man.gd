extends CanvasLayer
## Màn hình mở đầu: tên màn + đếm ngược trước khi đồng hồ bắt đầu chạy.
##
## KHÔNG tạm dừng game. Đây là điểm khác biệt so với mọi bảng khác trong game.
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

signal bat_dau

const GIAY_DEM := 10.0
const THEME := "res://ui/theme/menu_theme.tres"

const MAU_TEN := Color(1, 0.96, 0.89)
const MAU_VIEN_CHU := Color(0.22, 0.12, 0.06)
const MAU_MO := Color(0.86, 0.79, 0.70)

var _con: float = GIAY_DEM
var _xong := false

var _goc: Control
var _lbl_ten: Label
var _lbl_dem: Label


func _ready() -> void:
	layer = 30
	_dung_giao_dien()


## `ten` là chữ lớn hiện giữa màn hình, ví dụ "NGÀY 1".
func bat_dau_dem(ten: String) -> void:
	_lbl_ten.text = ten
	_con = GIAY_DEM
	_xong = false
	_goc.show()
	_goc.modulate.a = 0.0
	create_tween().tween_property(_goc, "modulate:a", 1.0, 0.35)
	set_process(true)


func _process(delta: float) -> void:
	if _xong:
		return
	_con -= delta
	_lbl_dem.text = "Bắt đầu sau %d" % maxi(int(ceilf(_con)), 0)
	if _con <= 0.0:
		_ket_thuc()


func _ket_thuc() -> void:
	if _xong:
		return
	_xong = true
	set_process(false)
	bat_dau.emit()

	var tw := create_tween()
	tw.tween_property(_goc, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


# ------------------------------------------------------------ dựng hình ---

func _dung_giao_dien() -> void:
	_goc = Control.new()
	_goc.set_anchors_preset(Control.PRESET_FULL_RECT)
	# KHÔNG chặn chuột và không chặn phím: người chơi phải đi lại được trong
	# lúc đếm. Đây là cả lý do tồn tại của mười giây này.
	_goc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_goc)

	# KHÔNG có lớp nền tối. Bản trước phủ đen 32% toàn màn hình, nhưng lớp phủ
	# đó làm tối đúng cái bếp mà mười giây này sinh ra để người chơi nhìn. Chữ
	# đứng được trên nền sáng là nhờ viền đậm quanh chữ (xem _chu), không cần
	# phải dìm cả khung hình xuống.

	var cot := VBoxContainer.new()
	cot.set_anchors_preset(Control.PRESET_CENTER)
	cot.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cot.grow_vertical = Control.GROW_DIRECTION_BOTH
	cot.alignment = BoxContainer.ALIGNMENT_CENTER
	cot.add_theme_constant_override("separation", 6)
	cot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME):
		cot.theme = load(THEME)
	_goc.add_child(cot)

	_lbl_ten = _chu("", 92, MAU_TEN, 14)
	cot.add_child(_lbl_ten)

	_lbl_dem = _chu("", 30, MAU_TEN, 10)
	cot.add_child(_lbl_dem)


func _chu(noi_dung: String, co: int, mau: Color, vien: int) -> Label:
	var l := Label.new()
	l.text = noi_dung
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	# Viền đậm quanh chữ: chữ nằm đè lên cái bếp nhiều màu, không có viền thì
	# đúng chỗ nào trùng màu là chỗ đó biến mất.
	l.add_theme_color_override("font_outline_color", MAU_VIEN_CHU)
	l.add_theme_constant_override("outline_size", vien)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
