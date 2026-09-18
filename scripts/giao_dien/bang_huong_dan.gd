extends CanvasLayer
## Hộp thoại trainer của màn hướng dẫn, nằm ở mép PHẢI ngay dưới panel thời gian.
##
## Bố cục lấy theo tấm ảnh mẫu người dùng gửi: khung chữ bên trái, ảnh nhân vật
## bên phải, dưới ảnh là một dải nhãn nhỏ. Đọc từ trái sang phải thì mắt gặp
## CHỮ trước rồi mới tới mặt người nói — đúng thứ tự cần, vì cái phải làm nằm
## trong chữ chứ không nằm ở cái mặt.
##
## Vì sao ở góc phải dưới đồng hồ: hai khối HUD kia đều đã có chủ — mép trái là
## bảng đơn hàng, đáy giữa là danh sách trạm. Quan trọng hơn, hộp này KHÔNG
## được đè lên danh sách trạm: nó bảo người chơi "bấm E ở cái Thớt", mà cái
## danh sách chữ E nằm ở đáy giữa — che mất là câu hướng dẫn tự phủ định chính
## nó.
##
## Toàn bộ hình thức lấy từ theme cozy có sẵn (ui/theme/menu_theme.tres): panel
## gỗ, nút gỗ, màu chữ nâu. Không dựng StyleBox mới ở đây — đổi theme một lần
## là cả game đổi theo, còn tự vẽ riêng thì hộp này sẽ lạc lõng dần mỗi lần
## theme được chỉnh.

signal chon_bat_dau(dong_y: bool)

const THEME := "res://ui/theme/menu_theme.tres"
const ANH_TRAINER := "res://assets/ui/avatars/trainer_avt1.png"
const KHUNG_ANH := "res://assets/ui/megacozy/Frames/EmptyWoodenFrame.png"
const NHAN_RIBBON := "res://assets/ui/megacozy/Labels/Label1_green.png"

const LE := 28.0
const RONG := 560.0
## Panel thời gian chiếm y 28…160, chừa 20 px rồi tới hộp này.
const TREN := 180.0

const CO_ANH := 116.0
const GIAY_TRUOT := 0.35

var _hop: PanelContainer
var _lbl_buoc: Label
var _lbl_loi: RichTextLabel
var _hang_nut: HBoxContainer
var _hien := false
var _che_do_chuot_cu := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 6   # trên bảng đơn hàng và panel thời gian (layer 5)
	_dung_giao_dien()
	# Bắt đầu ở ngoài mép phải; ai muốn hiện thì gọi mo().
	_hop.position.x = _x_an()


# ------------------------------------------------------------ dựng hình ---

func _dung_giao_dien() -> void:
	var goc := Control.new()
	goc.set_anchors_preset(Control.PRESET_FULL_RECT)
	goc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(goc)

	_hop = PanelContainer.new()
	# Neo góc trên-trái (mọi anchor = 0) rồi tự gán size và position. Không
	# dùng preset neo phải rồi tween offset: neo tính lại rect mỗi lần bố trí
	# nên nó đánh nhau với tween, và cái rect phình thêm sau mỗi khung hình.
	_hop.size = Vector2(RONG, 0.0)
	_hop.position = Vector2(_x_an(), TREN)
	_hop.mouse_filter = Control.MOUSE_FILTER_STOP   # nút bên trong cần bấm được
	if ResourceLoader.exists(THEME):
		_hop.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s — hộp hướng dẫn sẽ dùng giao diện mặc định." % THEME)
	goc.add_child(_hop)

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 14)
	_hop.add_child(hang)

	# --- cột chữ ---
	var cot := VBoxContainer.new()
	cot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cot.add_theme_constant_override("separation", 8)
	hang.add_child(cot)

	_lbl_buoc = Label.new()
	_lbl_buoc.add_theme_font_size_override("font_size", 15)
	_lbl_buoc.add_theme_color_override("font_color", Color(0.52, 0.38, 0.22))
	cot.add_child(_lbl_buoc)

	_lbl_loi = RichTextLabel.new()
	_lbl_loi.bbcode_enabled = true
	_lbl_loi.fit_content = true
	_lbl_loi.scroll_active = false
	_lbl_loi.add_theme_font_size_override("normal_font_size", 21)
	_lbl_loi.add_theme_font_size_override("bold_font_size", 21)
	_lbl_loi.add_theme_color_override("default_color", Color(0.29, 0.153, 0.071))
	# BẮT BUỘC có bề rộng tối thiểu.
	#
	# RichTextLabel/Label có xuống dòng tự động mà KHÔNG được cho bề rộng thì
	# Godot tính chiều cao tối thiểu ở bề rộng 0 — tức mỗi chữ một dòng — và ra
	# một chiều cao khổng lồ. Đây đúng là cái bẫy đã làm hỏng bảng info màn
	# chọn nhân vật (một Label đòi 5396 px chiều cao).
	_lbl_loi.custom_minimum_size = Vector2(RONG - CO_ANH - 130.0, 92.0)
	cot.add_child(_lbl_loi)

	_hang_nut = HBoxContainer.new()
	_hang_nut.add_theme_constant_override("separation", 12)
	_hang_nut.visible = false
	cot.add_child(_hang_nut)

	# --- cột ảnh trainer ---
	var cot_anh := VBoxContainer.new()
	cot_anh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cot_anh.add_theme_constant_override("separation", 4)
	hang.add_child(cot_anh)

	# Khung gỗ làm NỀN, ảnh nằm đè lên trên — không dùng NinePatch bọc ngoài vì
	# khung này là ảnh có tỉ lệ cố định, kéo giãn sẽ méo phần vân gỗ.
	var o_anh := Control.new()
	o_anh.custom_minimum_size = Vector2(CO_ANH, CO_ANH)
	cot_anh.add_child(o_anh)

	if ResourceLoader.exists(KHUNG_ANH):
		var khung := TextureRect.new()
		khung.texture = load(KHUNG_ANH)
		khung.set_anchors_preset(Control.PRESET_FULL_RECT)
		khung.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		khung.stretch_mode = TextureRect.STRETCH_SCALE
		khung.mouse_filter = Control.MOUSE_FILTER_IGNORE
		o_anh.add_child(khung)

	var anh := TextureRect.new()
	if ResourceLoader.exists(ANH_TRAINER):
		anh.texture = load(ANH_TRAINER)
	else:
		push_warning("Thiếu ảnh trainer %s" % ANH_TRAINER)
	anh.set_anchors_preset(Control.PRESET_FULL_RECT)
	anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# GIỮ TỈ LỆ, canh giữa: ảnh trainer gần vuông và đã tự gọn trong khung tròn
	# xanh của nó, nên không cần cắt. Dùng COVERED thì cắt mất hai bên vai.
	anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o_anh.add_child(anh)

	# --- dải nhãn dưới ảnh ---
	var nhan := Control.new()
	nhan.custom_minimum_size = Vector2(CO_ANH, 26.0)
	cot_anh.add_child(nhan)

	if ResourceLoader.exists(NHAN_RIBBON):
		var vien := NinePatchRect.new()
		vien.texture = load(NHAN_RIBBON)
		# Ảnh gốc 34×11: chừa 6 px hai đầu làm mép, phần giữa kéo dài ra.
		vien.patch_margin_left = 6
		vien.patch_margin_right = 6
		vien.patch_margin_top = 3
		vien.patch_margin_bottom = 3
		vien.set_anchors_preset(Control.PRESET_FULL_RECT)
		vien.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nhan.add_child(vien)

	var chu_nhan := Label.new()
	chu_nhan.text = "HƯỚNG DẪN"
	chu_nhan.add_theme_font_size_override("font_size", 14)
	chu_nhan.add_theme_color_override("font_color", Color(1, 0.98, 0.92))
	chu_nhan.add_theme_color_override("font_outline_color", Color(0.16, 0.32, 0.16))
	chu_nhan.add_theme_constant_override("outline_size", 5)
	chu_nhan.set_anchors_preset(Control.PRESET_FULL_RECT)
	chu_nhan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chu_nhan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chu_nhan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nhan.add_child(chu_nhan)


# ------------------------------------------------------------- ra / vào ---

func _x_an() -> float:
	return 1920.0 + 20.0


func _x_hien() -> float:
	return 1920.0 - LE - RONG


func mo() -> void:
	if _hien:
		return
	_hien = true
	_truot(_x_hien())


func dong() -> void:
	if not _hien:
		return
	_hien = false
	_truot(_x_an())


func _truot(dich: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hop, "position:x", dich, GIAY_TRUOT)


# -------------------------------------------------------------- nội dung ---

## Đặt nội dung một bước. `so` và `tong` để hiện "BƯỚC 3 / 10".
func dat_buoc(loi: String, so: int, tong: int) -> void:
	_lbl_buoc.text = "BƯỚC %d / %d" % [so, tong]
	_lbl_loi.text = loi
	_an_nut()


## Hiện hai nút lựa chọn. Bấm xong phát chon_bat_dau(true/false).
func hoi(loi: String, chu_co: String, chu_khong: String) -> void:
	_lbl_buoc.text = "HƯỚNG DẪN"
	_lbl_loi.text = loi
	_an_nut()

	var co := Button.new()
	co.text = chu_co
	co.add_theme_font_size_override("font_size", 20)
	co.pressed.connect(_khi_chon.bind(true))
	_hang_nut.add_child(co)

	var khong := Button.new()
	khong.text = chu_khong
	khong.add_theme_font_size_override("font_size", 20)
	khong.pressed.connect(_khi_chon.bind(false))
	_hang_nut.add_child(khong)

	_hang_nut.visible = true

	# Trả con trỏ chuột về cho người chơi rồi NHỚ lại chế độ cũ.
	#
	# Màn chơi khoá con trỏ (pause_menu đặt lại MOUSE_MODE_CAPTURED mỗi lần
	# thoát tạm dừng), mà chuột bị khoá thì hai cái nút này bấm không được.
	# Phải nhớ chế độ cũ chứ không đặt cứng CAPTURED lúc trả lại: nếu sau này
	# có màn nào chơi bằng chuột thì đặt cứng sẽ khoá mất chuột của màn đó.
	_che_do_chuot_cu = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	co.grab_focus()


func _khi_chon(dong_y: bool) -> void:
	_an_nut()
	if _che_do_chuot_cu != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _che_do_chuot_cu
	chon_bat_dau.emit(dong_y)


func _an_nut() -> void:
	_hang_nut.visible = false
	for n in _hang_nut.get_children():
		n.queue_free()
