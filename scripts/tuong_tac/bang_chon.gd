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
signal da_chon(tram: Node, ten: String)
## Bảng vừa mở hoặc vừa đóng — nhân vật nghe để khoá/mở di chuyển.
signal doi_trang_thai(dang_mo: bool)

## Mọi thứ về hình ảnh và tên gọi đều hỏi danh mục, bảng này không tự biết
## gì cả. Nhờ vậy đổi ảnh hay đổi tên một nguyên liệu chỉ sửa ở một chỗ.
const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")

## Cùng lý do với hud_tuong_tac.gd: cỡ chữ tính theo viewport thiết kế
## 1920×1080, người chơi ở cửa sổ 1280×720 chỉ thấy 2/3 con số này.
const CO_TIEU_DE := 32
const CO_CHON := 30
const CO_MO := 24
const CO_PHIM := 18
const CO_ANH := 76

const MAU_CHON := Color(1, 1, 1)
const MAU_MO := Color(0.66, 0.70, 0.67)
const MAU_VIEN := Color(0.898039, 0.678431, 0.352941)

var _tram: TramTuongTac = null
var _muc: PackedStringArray = PackedStringArray()
var _chi_so := 0

var _khung: PanelContainer
var _cot: VBoxContainer
var _cac_dong: Array[Control] = []


func _ready() -> void:
	layer = 20
	_dung_giao_dien()
	hide()


func _dung_giao_dien() -> void:
	_khung = PanelContainer.new()
	# Neo giữa màn hình: bảng này là việc người chơi đang tập trung làm, để
	# ở rìa thì mắt phải rời khỏi chỗ đang thao tác.
	_khung.set_anchors_preset(Control.PRESET_CENTER)
	_khung.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_khung.grow_vertical = Control.GROW_DIRECTION_BOTH
	_khung.offset_left = -260.0
	_khung.offset_right = 260.0
	_khung.offset_top = -270.0
	_khung.offset_bottom = 270.0
	_khung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_khung)

	var nen := StyleBoxFlat.new()
	# Bóng mờ chứ không đục: người chơi vẫn liếc thấy bếp phía sau, nên biết
	# mình đang tốn thời gian ở đâu.
	nen.bg_color = Color(0.05, 0.07, 0.06, 0.74)
	nen.border_color = Color(MAU_VIEN.r, MAU_VIEN.g, MAU_VIEN.b, 0.55)
	nen.set_border_width_all(3)
	nen.set_corner_radius_all(14)
	nen.set_content_margin_all(16)
	nen.shadow_color = Color(0, 0, 0, 0.45)
	nen.shadow_size = 18
	_khung.add_theme_stylebox_override("panel", nen)

	_cot = VBoxContainer.new()
	_cot.add_theme_constant_override("separation", 6)
	_khung.add_child(_cot)


# ------------------------------------------------------------- mở / đóng ---

func mo(tram: TramTuongTac) -> void:
	if tram == null or tram.lua_chon.is_empty():
		return
	_tram = tram
	_muc = tram.lua_chon
	_chi_so = 0
	_ve_lai()
	show()
	doi_trang_thai.emit(true)


func dong() -> void:
	if not visible:
		return
	hide()
	_tram = null
	doi_trang_thai.emit(false)


func dang_mo() -> bool:
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

	if event.is_action_pressed("huy_bang"):
		dong()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		var ten := String(_muc[_chi_so])
		var t := _tram
		dong()
		da_chon.emit(t, ten)
		get_viewport().set_input_as_handled()
		return

	# W/S đảo qua lại và CUỘN VÒNG. Cuộn vòng vì danh sách ngắn (3–4 mục):
	# chặn ở hai đầu thì người chơi ở mục cuối muốn về mục đầu phải bấm ngược
	# hết cả danh sách.
	var buoc := 0
	if event.is_action_pressed("move_up", true):
		buoc = -1
	elif event.is_action_pressed("move_down", true):
		buoc = 1
	if buoc != 0:
		_chi_so = wrapi(_chi_so + buoc, 0, _muc.size())
		_ve_lai()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- vẽ ---

func _ve_lai() -> void:
	for con in _cot.get_children():
		con.queue_free()
	_cac_dong.clear()

	var tieu_de := Label.new()
	tieu_de.text = _tram.ten_hien_thi if _tram != null else ""
	tieu_de.add_theme_color_override("font_color", MAU_VIEN)
	tieu_de.add_theme_font_size_override("font_size", CO_TIEU_DE)
	tieu_de.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cot.add_child(tieu_de)
	_cot.add_child(HSeparator.new())

	for i in _muc.size():
		_cot.add_child(_dung_dong(String(_muc[i]), i == _chi_so))

	var goi_y := Label.new()
	goi_y.text = "W/S: chọn     E: lấy     C: đóng"
	goi_y.add_theme_color_override("font_color", MAU_MO)
	goi_y.add_theme_font_size_override("font_size", CO_PHIM)
	goi_y.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cot.add_child(goi_y)


func _dung_dong(ten: String, dang_chon: bool) -> Control:
	var hang := PanelContainer.new()
	var kieu := StyleBoxFlat.new()
	kieu.bg_color = Color(1, 1, 1, 0.10) if dang_chon else Color(1, 1, 1, 0.0)
	kieu.set_corner_radius_all(8)
	kieu.set_content_margin_all(6)
	if dang_chon:
		# Viền dày chỉ ở mục đang chọn — nhìn một cái là biết, không phải so
		# sánh độ sáng giữa các dòng.
		kieu.set_border_width_all(2)
		kieu.border_color = MAU_VIEN
	hang.add_theme_stylebox_override("panel", kieu)

	var ngang := HBoxContainer.new()
	ngang.add_theme_constant_override("separation", 12)
	hang.add_child(ngang)
	ngang.add_child(_dung_anh(ten, dang_chon))

	var nhan := Label.new()
	nhan.text = DanhMuc.ten(ten)
	nhan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nhan.add_theme_color_override("font_color", MAU_CHON if dang_chon else MAU_MO)
	nhan.add_theme_font_size_override("font_size", CO_CHON if dang_chon else CO_MO)
	ngang.add_child(nhan)
	return hang


## Ô ảnh minh hoạ. Thiếu file thì trả về ô màu có chữ cái đầu.
func _dung_anh(ten: String, dang_chon: bool) -> Control:
	var duong_dan := DanhMuc.duong_dan_anh(ten)
	if ResourceLoader.exists(duong_dan):
		var anh := TextureRect.new()
		anh.texture = load(duong_dan)
		anh.custom_minimum_size = Vector2(CO_ANH, CO_ANH)
		anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		anh.modulate.a = 1.0 if dang_chon else 0.7
		return anh

	var o := PanelContainer.new()
	o.custom_minimum_size = Vector2(CO_ANH, CO_ANH)
	var k := StyleBoxFlat.new()
	# Màu suy ra từ chính tên nguyên liệu, nên mỗi thứ có một màu cố định —
	# vẫn phân biệt được bằng mắt kể cả khi chưa có ảnh nào.
	k.bg_color = Color.from_hsv(float(hash(ten) % 360) / 360.0, 0.45, 0.55)
	k.set_corner_radius_all(8)
	o.add_theme_stylebox_override("panel", k)
	var chu := Label.new()
	chu.text = DanhMuc.ten(ten).substr(0, 1).to_upper()
	chu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chu.add_theme_font_size_override("font_size", 36)
	o.add_child(chu)
	return o
