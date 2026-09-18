extends CanvasLayer
## Bảng theo dõi đơn hàng ở mép TRÁI màn hình. Bấm phím 1 để đóng/mở.
##
## Vì sao gộp các vé vào MỘT tấm bảng lớn thay vì để chúng lơ lửng thành cột:
## sáu tấm vé rời rạc chiếm 330 px chiều ngang và gần trọn chiều cao màn hình
## mà không bao giờ tắt được. Trong một game nhìn từ trên xuống thì đó là một
## phần ba sàn bếp bị che vĩnh viễn. Gom vào một tấm bảng thì cả cụm có MỘT
## công tắc: cần thì kéo ra đọc, xong thì đẩy vào, tầm nhìn trả lại nguyên vẹn.
##
## Cái nhãn nhỏ ở mép trái là phần bắt buộc của thiết kế này, không phải trang
## trí. Một bảng đóng hoàn toàn thì người chơi quên mất là có đơn đang chờ, và
## quên theo cách tệ nhất — không có gì trên màn hình nhắc họ. Cái nhãn giữ lại
## đúng hai thông tin cần để quyết định có mở bảng ra hay không: **có mấy đơn**
## và **đơn gấp nhất còn bao nhiêu kiên nhẫn** (viền nhãn đổi màu theo). Nó
## chiếm 46 px thay vì 354.
##
## Node này chỉ VẼ. Nó không đếm giờ, không tính tiền, không quyết định khi nào
## khách bỏ đi — nó nghe hai tín hiệu và đọc dữ liệu đơn. Luật nằm trọn ở
## quan_ly_khach.gd, nên muốn đổi luật thì sửa một file.

const VeDon := preload("res://scripts/giao_dien/ve_don.gd")
const ANH_TIEN := "res://assets/ui/tien/carrot_tien.png"

const LE := 28.0
const RONG_VE := 330.0
const DEM := 12.0            # đệm trong lòng bảng
const RONG := RONG_VE + DEM * 2.0
const CAO := 820.0           # tới sát khối "sức · tay · kĩ năng" ở y=850
const CACH := 8

const RONG_NHAN := 46.0
const GIAY_TRUOT := 0.32

const MAU_BANG := Color(0.11, 0.09, 0.07, 0.80)
const MAU_VIEN := Color("c2a173")
const MAU_TIEU_DE := Color(0.96, 0.93, 0.88)
const MAU_MO := Color(0.72, 0.67, 0.60)

## Ba bậc màu của viền nhãn, khớp đúng ba bậc trên thanh kiên nhẫn của vé.
const MAU_XANH := Color("4f9d5d")
const MAU_VANG := Color("d9a520")
const MAU_DO := Color("c4433a")

## Bảng mở sẵn khi vào màn. Người chơi phải THẤY hệ đơn hàng tồn tại trước đã;
## giấu nó đi ngay từ đầu thì người mới không biết có phím 1.
@export var mo_san: bool = true

var dang_mo: bool = true

var _bang: PanelContainer
var _cot: VBoxContainer
var _nhan: PanelContainer
var _lbl_dem: Label
var _sb_nhan: StyleBoxFlat
var _anh_tien: Texture2D = null
var _ve: Dictionary = {}    # DonHang -> node vé


func _ready() -> void:
	layer = 5
	if ResourceLoader.exists(ANH_TIEN):
		_anh_tien = load(ANH_TIEN)
	else:
		push_warning("Thiếu ảnh tiền: %s" % ANH_TIEN)
	_dung_giao_dien()

	dang_mo = mo_san
	# Đặt thẳng vào vị trí ở khung hình đầu, KHÔNG tween: chạy hiệu ứng lúc
	# vừa vào màn thì người chơi thấy bảng tự trôi mà không hiểu vì sao.
	_bang.position.x = _x_mo() if dang_mo else _x_dong()
	_nhan.visible = not dang_mo


# ------------------------------------------------------------ dựng hình ---

func _dung_giao_dien() -> void:
	var goc := Control.new()
	goc.set_anchors_preset(Control.PRESET_FULL_RECT)
	goc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(goc)

	# --- tấm bảng ---
	#
	# Neo để nguyên góc trên-trái (mọi anchor = 0) và ta gán size bằng tay.
	# KHÔNG dùng preset neo rồi tween position: neo tính lại rect từ anchor +
	# offset ở mỗi lần bố trí nên nó đánh nhau với position, và cái rect phình
	# thêm một ít sau mỗi khung hình.
	_bang = PanelContainer.new()
	_bang.size = Vector2(RONG, CAO)
	_bang.position = Vector2(_x_dong(), LE)
	_bang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bang.add_theme_stylebox_override("panel", _khung_bang())
	goc.add_child(_bang)

	var trong := VBoxContainer.new()
	trong.add_theme_constant_override("separation", 10)
	_bang.add_child(trong)

	var dau := HBoxContainer.new()
	trong.add_child(dau)

	var tieu_de := Label.new()
	tieu_de.text = "ĐƠN HÀNG"
	tieu_de.add_theme_font_size_override("font_size", 18)
	tieu_de.add_theme_color_override("font_color", MAU_TIEU_DE)
	tieu_de.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dau.add_child(tieu_de)

	var goi_y := Label.new()
	goi_y.text = "1  ẩn/hiện"
	goi_y.add_theme_font_size_override("font_size", 14)
	goi_y.add_theme_color_override("font_color", MAU_MO)
	dau.add_child(goi_y)

	_cot = VBoxContainer.new()
	_cot.add_theme_constant_override("separation", CACH)
	_cot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trong.add_child(_cot)

	# --- cái nhãn còn lại khi bảng đóng ---
	_nhan = PanelContainer.new()
	_nhan.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_nhan.offset_left = 0.0
	_nhan.offset_right = RONG_NHAN
	_nhan.offset_top = LE
	_nhan.offset_bottom = LE + 76.0
	_nhan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb_nhan = _khung_nhan()
	_nhan.add_theme_stylebox_override("panel", _sb_nhan)
	goc.add_child(_nhan)

	var cot_nhan := VBoxContainer.new()
	cot_nhan.add_theme_constant_override("separation", 0)
	_nhan.add_child(cot_nhan)

	_lbl_dem = Label.new()
	_lbl_dem.text = "0"
	_lbl_dem.add_theme_font_size_override("font_size", 26)
	_lbl_dem.add_theme_color_override("font_color", MAU_TIEU_DE)
	_lbl_dem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cot_nhan.add_child(_lbl_dem)

	var phim := Label.new()
	phim.text = "1"
	phim.add_theme_font_size_override("font_size", 14)
	phim.add_theme_color_override("font_color", MAU_MO)
	phim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cot_nhan.add_child(phim)


# --------------------------------------------------------------- đóng mở ---

func _x_mo() -> float:
	return LE


func _x_dong() -> float:
	return -RONG - 16.0


## Bắt phím ở _unhandled_key_input chứ không phải _input.
##
## Nghĩa là: hộp thoại, ô nhập chữ hay bất cứ Control nào đang nhận bàn phím
## sẽ NUỐT phím 1 trước khi tới đây. Đúng như mong muốn — gõ số 1 vào một ô
## nhập mà cái bảng đơn hàng nhảy ra thì rất khó chịu, và lỗi kiểu đó chỉ lộ
## ra khi đã có màn hướng dẫn với hộp thoại Có/Không.
func _unhandled_key_input(su_kien: InputEvent) -> void:
	var phim := su_kien as InputEventKey
	if phim == null or not phim.pressed or phim.echo:
		return
	# Nhận cả phím số hàng trên lẫn phím số bên bàn phím phụ.
	if phim.keycode == KEY_1 or phim.keycode == KEY_KP_1:
		bat_tat()
		get_viewport().set_input_as_handled()


func bat_tat() -> void:
	dat_mo(not dang_mo)


func dat_mo(mo: bool) -> void:
	if mo == dang_mo:
		return
	dang_mo = mo
	# Nhãn tắt NGAY khi bắt đầu mở, nhưng chỉ bật lại SAU khi bảng đóng xong:
	# hiện nhãn trong lúc tấm bảng còn đang trượt qua chỗ nó thì hai thứ chồng
	# lên nhau đúng một phần ba giây, nhìn như lỗi vẽ.
	if mo:
		_nhan.visible = false

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bang, "position:x", _x_mo() if mo else _x_dong(), GIAY_TRUOT)
	if not mo:
		tw.finished.connect(func() -> void:
			if not dang_mo:
				_nhan.visible = true)


# -------------------------------------------------------------- dữ liệu ---

## Nối vào hệ khách. Chỉ cần hai tín hiệu: đơn sinh ra và đơn kết thúc.
func nghe_don_hang(ql: Node) -> void:
	if ql == null:
		return
	if ql.has_signal("don_moi"):
		ql.don_moi.connect(them)
	if ql.has_signal("don_ket_thuc"):
		ql.don_ket_thuc.connect(_khi_ket_thuc)


func them(don: RefCounted) -> void:
	if don == null or _ve.has(don):
		return
	var v := VeDon.new()
	_cot.add_child(v)
	v.dung(don, _anh_tien)
	v.vao()
	_ve[don] = v
	_cap_nhat_nhan()


func _khi_ket_thuc(don: RefCounted, _ly_do: String) -> void:
	xoa(don)


func xoa(don: RefCounted) -> void:
	var v = _ve.get(don)
	if v == null:
		return
	_ve.erase(don)
	if is_instance_valid(v):
		v.ra()
	_cap_nhat_nhan()


func _process(_delta: float) -> void:
	# Chỉ cập nhật nhãn khi bảng đang ĐÓNG: lúc mở thì mọi thứ nhãn nói đều
	# đã hiện rõ trên từng tấm vé, tính lại mỗi khung hình là việc thừa.
	if not dang_mo:
		_cap_nhat_nhan()


func _cap_nhat_nhan() -> void:
	if _lbl_dem == null:
		return
	_lbl_dem.text = str(_ve.size())

	# Viền nhãn mang màu của đơn GẤP NHẤT, không phải trung bình.
	# Trung bình thì năm đơn thong thả kéo màu về xanh trong khi một đơn sắp
	# mất khách — mà cái người chơi cần biết chính là đơn tệ nhất.
	# BỎ QUA đơn của khách còn đang xếp hàng: thanh của họ chưa chạy, nhưng
	# `ti_le()` lúc đó trả về kiên nhẫn HÀNG ĐỢI đang tụt — tính vào đây thì
	# cái tab đỏ lên vì một đơn mà người chơi còn chưa được phép phục vụ.
	var thap := 1.0
	for don in _ve.keys():
		if bool(don.o_hang):
			continue
		thap = minf(thap, float(don.ti_le()))

	var mau := MAU_XANH
	if thap <= 0.2:
		mau = MAU_DO
	elif thap <= 0.5:
		mau = MAU_VANG
	if _sb_nhan.border_color != mau:
		_sb_nhan.border_color = mau


# ---------------------------------------------------------------- khung ---

func _khung_bang() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MAU_BANG
	sb.border_color = MAU_VIEN
	sb.border_width_right = 3
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = DEM
	sb.content_margin_right = DEM
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _khung_nhan() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MAU_BANG
	sb.border_color = MAU_XANH
	sb.border_width_right = 3
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
