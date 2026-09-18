extends CanvasLayer
## Menu hướng dẫn đầy đủ — phím F1. Cột nút bên trái, nội dung cuộn ở giữa.
##
## LÀ AUTOLOAD, không phải node của một màn chơi.
##
## Lý do: F1 phải bấm được ở MỌI nơi — trong bếp, ở menu chính, ở màn chọn màn,
## và nhất là ở màn hướng dẫn nơi trainer vừa nhắc "bấm F1 lúc nào cũng được".
## Gắn vào từng scene thì có bao nhiêu scene là bấy nhiêu chỗ phải nhớ gắn, và
## quên một chỗ thì F1 im lặng không làm gì — người chơi kết luận là game hỏng.
## Autoload thì nó tồn tại một lần, sống suốt phiên chơi, và luôn có mặt.
##
## Giá phải trả: node này tồn tại cả ở những màn không cần tới. Nhưng lúc đóng
## nó chỉ là một CanvasLayer ẩn, không _process, không vẽ gì — gần như không
## tốn gì. Đổi lại là một lời hứa không bao giờ lỡ.
##
## TOÀN BỘ NỘI DUNG nằm ở noi_dung_huong_dan.gd. File này chỉ biết VẼ.

const NoiDung := preload("res://scripts/giao_dien/noi_dung_huong_dan.gd")
const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")
const THEME := "res://ui/theme/menu_theme.tres"

const RONG_KHUNG := 1440.0
const CAO_KHUNG := 860.0
const RONG_COT_TRAI := 300.0
const CO_ANH_NL := 46.0

const MAU_CHU := Color(0.29, 0.153, 0.071)
const MAU_MO := Color(0.52, 0.38, 0.22)
const MAU_TIEU_DE := Color(0.72, 0.36, 0.12)

var dang_mo := false

var _nen: ColorRect
var _khung: PanelContainer
var _cot_noi_dung: VBoxContainer
var _lbl_ten_muc: Label
var _nut: Array[Button] = []
var _muc_dang_xem := 0
var _paused_cu := false
var _chuot_cu := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 40   # trên mọi HUD và cả bảng tổng kết (20)
	# Phải chạy được TRONG LÚC cây scene bị tạm dừng — chính menu này là thứ
	# tạm dừng game, nên nếu nó cũng bị dừng thì không bấm được nút nào cả.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dung_giao_dien()
	_dong_ngay()


# ------------------------------------------------------------- đóng / mở ---

func _unhandled_key_input(su_kien: InputEvent) -> void:
	var phim := su_kien as InputEventKey
	if phim == null or not phim.pressed or phim.echo:
		return
	if phim.keycode == KEY_F1:
		bat_tat()
		get_viewport().set_input_as_handled()
		return
	# ESC chỉ đóng menu khi menu ĐANG MỞ, và nuốt luôn phím đó.
	#
	# Không nuốt thì ESC vừa đóng menu vừa bật bảng tạm dừng phía sau — người
	# chơi bấm một lần mà nhận hai kết quả.
	if dang_mo and phim.keycode == KEY_ESCAPE:
		dong()
		get_viewport().set_input_as_handled()


func bat_tat() -> void:
	if dang_mo:
		dong()
	else:
		mo()


func mo() -> void:
	if dang_mo:
		return
	dang_mo = true

	# NHỚ trạng thái cũ rồi mới đổi, chứ không đặt cứng false lúc đóng.
	#
	# F1 bấm được cả khi đang ở bảng tạm dừng hoặc bảng tổng kết — hai thứ đó
	# cũng đang giữ get_tree().paused = true. Đóng menu mà đặt cứng false thì
	# game chạy tiếp phía sau một bảng lẽ ra vẫn đang dừng.
	_paused_cu = get_tree().paused
	_chuot_cu = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_nen.show()
	_nen.modulate.a = 0.0
	_khung.scale = Vector2(0.97, 0.97)
	var tw := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_nen, "modulate:a", 1.0, 0.16)
	tw.tween_property(_khung, "scale", Vector2.ONE, 0.20)

	_chon_muc(_muc_dang_xem)


func dong() -> void:
	if not dang_mo:
		return
	dang_mo = false
	_nen.hide()
	get_tree().paused = _paused_cu
	if _chuot_cu != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _chuot_cu


func _dong_ngay() -> void:
	dang_mo = false
	_nen.hide()


# ------------------------------------------------------------ dựng hình ---

func _dung_giao_dien() -> void:
	_nen = ColorRect.new()
	_nen.color = Color(0, 0, 0, 0.62)
	_nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_nen)

	_khung = PanelContainer.new()
	_khung.set_anchors_preset(Control.PRESET_CENTER)
	_khung.custom_minimum_size = Vector2(RONG_KHUNG, CAO_KHUNG)
	# Nở đều hai phía quanh điểm neo. PRESET_CENTER một mình chỉ ghim GÓC
	# TRÊN-TRÁI vào tâm màn hình, nên khung sẽ lệch xuống dưới-phải đúng nửa
	# kích thước của nó.
	_khung.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_khung.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists(THEME):
		_khung.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s" % THEME)
	_nen.add_child(_khung)
	_khung.resized.connect(func() -> void:
		_khung.pivot_offset = _khung.size * 0.5)

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 18)
	_khung.add_child(hang)

	hang.add_child(_dung_cot_trai())
	hang.add_child(_dung_cot_phai())


func _dung_cot_trai() -> Control:
	var cot := VBoxContainer.new()
	cot.custom_minimum_size = Vector2(RONG_COT_TRAI, 0)
	cot.add_theme_constant_override("separation", 8)

	var tieu := Label.new()
	tieu.text = "HƯỚNG DẪN"
	tieu.add_theme_font_size_override("font_size", 26)
	tieu.add_theme_color_override("font_color", MAU_TIEU_DE)
	cot.add_child(tieu)

	var phim := Label.new()
	phim.text = "F1 hoặc ESC để đóng"
	phim.add_theme_font_size_override("font_size", 14)
	phim.add_theme_color_override("font_color", MAU_MO)
	cot.add_child(phim)

	cot.add_child(_khoang(10))

	_nut.clear()
	for i in NoiDung.MUC.size():
		var b := Button.new()
		b.text = String(NoiDung.MUC[i]["ten"])
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_chon_muc.bind(i))
		cot.add_child(b)
		_nut.append(b)

	# Đẩy nút Đóng xuống đáy cột.
	var day := Control.new()
	day.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cot.add_child(day)

	var dong_nut := Button.new()
	dong_nut.text = "Đóng"
	dong_nut.add_theme_font_size_override("font_size", 20)
	dong_nut.pressed.connect(dong)
	cot.add_child(dong_nut)
	return cot


func _dung_cot_phai() -> Control:
	var cot := VBoxContainer.new()
	cot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cot.add_theme_constant_override("separation", 10)

	_lbl_ten_muc = Label.new()
	_lbl_ten_muc.add_theme_font_size_override("font_size", 30)
	_lbl_ten_muc.add_theme_color_override("font_color", MAU_TIEU_DE)
	cot.add_child(_lbl_ten_muc)

	var cuon := ScrollContainer.new()
	cuon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Cuộn DỌC thôi. Cho cuộn ngang thì một tấm ảnh rộng quá sẽ kéo cả trang
	# lệch sang phải, và chữ bị đẩy ra ngoài khung nhìn.
	cuon.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cot.add_child(cuon)

	_cot_noi_dung = VBoxContainer.new()
	_cot_noi_dung.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cot_noi_dung.add_theme_constant_override("separation", 12)
	cuon.add_child(_cot_noi_dung)
	return cot


# -------------------------------------------------------------- nội dung ---

func _chon_muc(i: int) -> void:
	if i < 0 or i >= NoiDung.MUC.size():
		return
	_muc_dang_xem = i

	for k in _nut.size():
		# Đánh dấu mục đang xem bằng ĐỘ SÁNG chứ không đổi StyleBox: nút gỗ
		# lấy từ theme chung, tự vẽ một style riêng cho trạng thái chọn thì
		# đổi theme một cái là cái nút này lạc lõng ngay.
		_nut[k].modulate = Color(1.25, 1.15, 1.0) if k == i else Color.WHITE

	var muc: Dictionary = NoiDung.MUC[i]
	_lbl_ten_muc.text = String(muc["ten"]).to_upper()

	for c in _cot_noi_dung.get_children():
		c.queue_free()
	for khoi in muc["khoi"]:
		_dung_khoi(khoi as Dictionary)


func _dung_khoi(khoi: Dictionary) -> void:
	if khoi.has("h"):
		_cot_noi_dung.add_child(_tieu_de_nho(String(khoi["h"])))
	elif khoi.has("p"):
		_cot_noi_dung.add_child(_doan_van(String(khoi["p"])))
	elif khoi.has("phim"):
		_cot_noi_dung.add_child(_bang_phim(khoi["phim"]))
	elif khoi.has("anh"):
		_them_anh(String(khoi["anh"]), String(khoi.get("chu", "")))
	elif khoi.has("cong_thuc"):
		_them_cong_thuc(String(khoi["cong_thuc"]))
	elif khoi.has("moc_hang"):
		_them_moc_hang()


func _tieu_de_nho(chu: String) -> Control:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", MAU_TIEU_DE)
	return l


func _doan_van(chu: String) -> Control:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", 18)
	t.add_theme_font_size_override("bold_font_size", 18)
	t.add_theme_color_override("default_color", MAU_CHU)
	# Bề rộng tối thiểu là BẮT BUỘC với mọi nhãn có xuống dòng tự động: không
	# có nó thì Godot tính chiều cao ở bề rộng 0 — mỗi chữ một dòng — và ra
	# một chiều cao khổng lồ kéo cả trang dài ra vô tận.
	t.custom_minimum_size = Vector2(RONG_KHUNG - RONG_COT_TRAI - 160.0, 0)
	t.text = chu
	return t


func _bang_phim(ds: Array) -> Control:
	var luoi := GridContainer.new()
	luoi.columns = 2
	luoi.add_theme_constant_override("h_separation", 20)
	luoi.add_theme_constant_override("v_separation", 6)
	for d in ds:
		var cap: Array = d
		var a := Label.new()
		a.text = String(cap[0])
		a.add_theme_font_size_override("font_size", 18)
		a.add_theme_color_override("font_color", MAU_TIEU_DE)
		a.custom_minimum_size = Vector2(120, 0)
		luoi.add_child(a)

		var b := Label.new()
		b.text = String(cap[1])
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", MAU_CHU)
		luoi.add_child(b)
	return luoi


## Thiếu ảnh thì BỎ QUA cả khối, không để lại ô trống và không báo lỗi.
##
## Ảnh minh hoạ là thứ bổ sung dần: khai sẵn đường dẫn trong bảng nội dung rồi
## chụp ảnh sau lúc nào cũng được, và trang hướng dẫn vẫn đọc được ngay từ bây
## giờ. Nếu để một ô trống hay một dòng "thiếu ảnh" thì trang trông như hỏng.
func _them_anh(duong_dan: String, chu: String) -> void:
	if not ResourceLoader.exists(duong_dan):
		return
	var tex := load(duong_dan) as Texture2D
	if tex == null:
		return

	var anh := TextureRect.new()
	anh.texture = tex
	anh.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anh.custom_minimum_size = Vector2(0, 0)
	_cot_noi_dung.add_child(anh)

	if not chu.is_empty():
		var l := Label.new()
		l.text = chu
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", MAU_MO)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cot_noi_dung.add_child(l)


# ------------------------------------------------------ bảng tự sinh ---

## Bảng công thức dựng THẲNG từ DanhMuc, không gõ tay.
##
## Đây là điểm đáng nói nhất của cả menu này: trang hướng dẫn không thể nói sai
## được, vì nó đọc đúng cái bảng mà luật chơi đang dùng. Món bị khoá thì tự
## biến mất khỏi trang; thêm một công thức là trang tự có thêm một dòng.
func _them_cong_thuc(loai: String) -> void:
	var bang: Dictionary = {}
	match loai:
		"ban": bang = DanhMuc.CONG_THUC_BAN
		# (Đã bỏ) "noi": CONG_THUC_NOI. Bảng công thức nồi không còn tồn tại
		# — công thức nấu canh giờ nằm trong CONG_THUC_BAN như mọi món khác,
		# nên trang hướng dẫn tự có nó ở mục "ban".
		"lo": bang = DanhMuc.CONG_THUC_LO
		_: return

	for khoa in bang:
		var ra := String(bang[khoa])
		if DanhMuc.bi_khoa(ra):
			continue
		_cot_noi_dung.add_child(_dong_cong_thuc(String(khoa).split("+"), ra))


func _dong_cong_thuc(nguyen_lieu: PackedStringArray, ra: String) -> Control:
	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 6)

	for i in nguyen_lieu.size():
		if i > 0:
			hang.add_child(_dau("+"))
		hang.add_child(_o_vat(String(nguyen_lieu[i])))

	hang.add_child(_dau("→"))
	hang.add_child(_o_vat(ra))

	var ten := Label.new()
	var gia := DanhMuc.gia(ra)
	ten.text = DanhMuc.ten(ra) + ("  (%d)" % gia if gia > 0 else "")
	ten.add_theme_font_size_override("font_size", 18)
	ten.add_theme_color_override("font_color", MAU_CHU)
	ten.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hang.add_child(ten)
	return hang


## Một ô nguyên liệu: ảnh nếu có, không thì chữ.
##
## Lùi về CHỮ chứ không bỏ trống: bộ ảnh chưa đủ cho mọi id, mà một công thức
## thiếu mất một ô thì đọc thành công thức khác.
func _o_vat(id: String) -> Control:
	var dd := DanhMuc.duong_dan_anh(id)
	if ResourceLoader.exists(dd):
		var anh := TextureRect.new()
		anh.texture = load(dd)
		anh.custom_minimum_size = Vector2(CO_ANH_NL, CO_ANH_NL)
		anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		anh.tooltip_text = DanhMuc.ten(id)
		return anh

	var l := Label.new()
	l.text = DanhMuc.ten(id)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MAU_MO)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _dau(chu: String) -> Control:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", MAU_MO)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## Bảng mốc xếp hạng, cũng đọc thẳng từ GameData.
func _them_moc_hang() -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	var moc: Dictionary = GameData.MOC_MAC_DINH
	var mau := {
		"S": Color("f2c230"), "A": Color("e8823f"),
		"B": Color("e27ba0"), "C": Color("4f9d5d"),
	}
	var luoi := GridContainer.new()
	luoi.columns = 2
	luoi.add_theme_constant_override("h_separation", 20)
	luoi.add_theme_constant_override("v_separation", 6)
	for hang in GameData.THU_TU_HANG:
		var a := Label.new()
		a.text = String(hang)
		a.add_theme_font_size_override("font_size", 26)
		a.add_theme_color_override("font_color", mau.get(hang, MAU_CHU))
		a.custom_minimum_size = Vector2(120, 0)
		luoi.add_child(a)

		var b := Label.new()
		b.text = "từ %d trở lên" % int(moc.get(hang, 0))
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", MAU_CHU)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		luoi.add_child(b)
	_cot_noi_dung.add_child(luoi)


func _khoang(cao: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, cao)
	return c
