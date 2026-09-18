extends Control
## MỘT tấm vé đơn hàng trên HUD.
##
## Cấu trúc hai lớp, và đây là điểm quan trọng nhất của file này:
##
##     Ve (Control, clip_contents = true)   ← con của VBoxContainer
##       └── _the (PanelContainer)          ← KHÔNG do container xếp
##
## Vì sao phải tách hai lớp thay vì cho thẳng tấm thẻ vào VBox: hiệu ứng
## "trượt từ trái vào" cần đổi `position.x` của tấm thẻ, mà VBoxContainer thì
## GHI ĐÈ vị trí mọi node con của nó ở mỗi lần bố trí lại. Tween sẽ chạy được
## đúng một khung hình rồi bị container kéo về chỗ cũ. Lớp ngoài nhận việc bị
## container xếp; lớp trong tự do vì nó không phải con của container nào cả.
##
## `clip_contents` trên lớp ngoài chính là cái cắt phần thẻ còn thò ra ngoài
## lúc đang trượt, nên vé không đè lên vé bên cạnh trong lúc chạy hiệu ứng.
##
## Neo của lớp trong để nguyên góc trên-trái (mọi anchor = 0) và ta gán `size`
## bằng tay. KHÔNG dùng PRESET_FULL_RECT rồi tween position: neo full-rect tính
## lại rect từ anchor + offset mỗi lần bố trí, nên nó đánh nhau với position và
## cái rect phình ra thêm mỗi khung hình.

const RONG := 330.0
const CAO := 110.0
const GIAY_TRUOT := 0.30

## Bảng màu giấy: lấy tông vé giấy nâu-kem cho khớp phong cách quán ăn, không
## dùng panel xám mặc định của Godot.
const MAU_GIAY := Color("f3e6cd")
const MAU_VIEN := Color("c2a173")
const MAU_CHU := Color("4a3421")
const MAU_MO := Color("8a7355")

## Ba mức màu của thanh kiên nhẫn. Đổi màu THEO NGƯỠNG chứ không nội suy dần:
## chuyển màu mượt thì mắt không bắt được thời điểm "sắp mất khách", còn ba
## bậc rõ ràng thì đọc được bằng thị giác ngoại vi, lúc đang bận nhìn chỗ khác.
const MAU_XANH := Color("4f9d5d")
const MAU_VANG := Color("d9a520")
const MAU_DO := Color("c4433a")
const NGUONG_VANG := 0.5   # bằng đúng ngưỡng đơn hoàn hảo
const NGUONG_DO := 0.2

## Màu thanh khi khách còn ĐANG XẾP HÀNG: xám nhạt, đầy, đứng yên.
##
## Phải khác hẳn ba màu kia chứ không dùng màu xanh: xanh nghĩa là "còn nhiều
## thời gian", mà ở đây thì không có thời gian nào đang chạy cả. Một màu thứ
## tư, nhạt hơn, đọc ra đúng thứ nó là — chưa bắt đầu.
const MAU_CHO := Color("b9ab93")

## Chữ trên ô số bàn khi khách chưa có bàn.
const CHUA_CO_BAN := "—"

var don: RefCounted = null

var _the: PanelContainer
var _thanh: ProgressBar
var _sb_fill: StyleBoxFlat
## Ô số bàn — giữ lại để cập nhật lúc khách rời hàng đợi và ngồi xuống.
var _lbl_so: Label


func _init() -> void:
	custom_minimum_size = Vector2(RONG, CAO)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func dung(dh: RefCounted, anh_tien: Texture2D) -> void:
	don = dh

	_the = PanelContainer.new()
	_the.size = Vector2(RONG, CAO)
	_the.position = Vector2(-RONG - 12.0, 0.0)   # nằm sẵn ngoài mép trái
	_the.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_the.add_theme_stylebox_override("panel", _khung_giay())
	add_child(_the)

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 10)
	_the.add_child(hang)

	# --- ảnh món ---
	var anh := TextureRect.new()
	anh.custom_minimum_size = Vector2(72, 72)
	anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	anh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dd := String(dh.duong_dan_anh())
	if ResourceLoader.exists(dd):
		anh.texture = load(dd)
	else:
		push_warning("Vé đơn: thiếu ảnh %s" % dd)
	hang.add_child(anh)

	# --- tên món / giá / thanh kiên nhẫn ---
	var cot := VBoxContainer.new()
	cot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cot.add_theme_constant_override("separation", 4)
	hang.add_child(cot)

	var ten := Label.new()
	ten.text = String(dh.ten_mon())
	ten.add_theme_font_size_override("font_size", 22)
	ten.add_theme_color_override("font_color", MAU_CHU)
	# Cắt bằng dấu … chứ không xuống dòng: tấm vé cao cố định, cho phép xuống
	# dòng thì một cái tên dài đẩy thanh kiên nhẫn ra khỏi thẻ.
	ten.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cot.add_child(ten)

	var hang_gia := HBoxContainer.new()
	hang_gia.add_theme_constant_override("separation", 4)
	cot.add_child(hang_gia)

	if anh_tien != null:
		var icon := TextureRect.new()
		icon.texture = anh_tien
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hang_gia.add_child(icon)

	var gia := Label.new()
	gia.text = str(int(dh.gia))
	gia.add_theme_font_size_override("font_size", 17)
	gia.add_theme_color_override("font_color", MAU_MO)
	hang_gia.add_child(gia)

	_thanh = _tao_thanh()
	cot.add_child(_thanh)

	# --- số bàn ---
	#
	# Giữ tham chiếu chứ không gán một lần rồi thôi: vé giờ hiện từ lúc khách
	# còn ĐỨNG XẾP HÀNG, khi chưa có bàn nào. Số bàn chỉ có sau, nên ô này
	# phải đổi được giữa chừng.
	_lbl_so = Label.new()
	_lbl_so.add_theme_font_size_override("font_size", 40)
	_lbl_so.add_theme_color_override("font_color", MAU_CHU)
	_lbl_so.custom_minimum_size = Vector2(44, 0)
	_lbl_so.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_so.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hang.add_child(_lbl_so)

	_ve_so_ban()
	_ve_thanh()


func vao() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_the, "position:x", 0.0, GIAY_TRUOT)


## Trượt ngược ra rồi tự xoá. Trả về tween để bên gọi await nếu cần.
func ra() -> void:
	don = null
	# Hai thứ chạy SONG SONG: thẻ trượt ra, đồng thời ô chứa nó xẹp chiều cao
	# về 0. Chỉ trượt không thôi thì cái vé biến mất nhưng để lại một khoảng
	# trống, và những vé dưới nhảy cóc lên khi node bị xoá.
	var tw := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_the, "position:x", -RONG - 12.0, GIAY_TRUOT)
	tw.tween_property(self, "custom_minimum_size:y", 0.0, GIAY_TRUOT)
	tw.finished.connect(queue_free)


func _process(_delta: float) -> void:
	if don == null:
		return
	_ve_so_ban()
	_ve_thanh()


## Ô số bàn: dấu gạch khi khách còn đứng xếp hàng, số thật khi đã ngồi.
##
## So sánh trước khi gán: hàm này chạy mỗi khung hình, mà gán `text` bằng đúng
## chuỗi cũ vẫn bắt Label tính lại bố cục.
func _ve_so_ban() -> void:
	if don == null or _lbl_so == null:
		return
	var so := int(don.so_ban())
	var chu := CHUA_CO_BAN if so <= 0 else str(so)
	if _lbl_so.text != chu:
		_lbl_so.text = chu


## Thanh kiên nhẫn.
##
## KHÁCH ĐANG XẾP HÀNG thì thanh ĐẦY và ĐỨNG YÊN, màu chờ.
##
## Không vẽ kiên nhẫn hàng đợi lên đây dù đơn vẫn đang đếm nó: hai giai đoạn
## có hai ngân sách riêng và hai chỗ hiển thị riêng — thanh chờ nằm trong bong
## bóng trên đầu khách, thanh phục vụ nằm ở đây. Vẽ cả hai vào cùng một chỗ
## thì người chơi thấy thanh tụt rồi bỗng đầy lại lúc khách ngồi xuống, và họ
## sẽ tưởng là lỗi.
##
## Vé này hiện sớm CHỈ để người chơi biết trước phải nấu gì. Thứ nó hứa là
## "món kế tiếp", không phải "đang đếm giờ" — nên nó không được đếm giờ.
func _ve_thanh() -> void:
	if don == null or _thanh == null:
		return

	if bool(don.o_hang):
		_thanh.value = 100.0
		if _sb_fill.bg_color != MAU_CHO:
			_sb_fill.bg_color = MAU_CHO
		return

	var ti: float = float(don.ti_le())
	_thanh.value = ti * 100.0
	var mau := MAU_XANH
	if ti <= NGUONG_DO:
		mau = MAU_DO
	elif ti <= NGUONG_VANG:
		mau = MAU_VANG
	if _sb_fill.bg_color != mau:
		_sb_fill.bg_color = mau


func _khung_giay() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MAU_GIAY
	sb.border_color = MAU_VIEN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _tao_thanh() -> ProgressBar:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(0, 12)
	t.max_value = 100.0
	t.show_percentage = false

	var nen := StyleBoxFlat.new()
	nen.bg_color = Color("dccdae")
	nen.set_corner_radius_all(6)
	t.add_theme_stylebox_override("background", nen)

	# StyleBox riêng cho TỪNG vé, không dùng chung: đổi bg_color của một
	# StyleBox dùng chung thì mọi vé đổi màu theo, và cả sáu vé sẽ luôn mang
	# màu của vé cập nhật sau cùng.
	_sb_fill = StyleBoxFlat.new()
	_sb_fill.bg_color = MAU_XANH
	_sb_fill.set_corner_radius_all(6)
	t.add_theme_stylebox_override("fill", _sb_fill)

	# Vạch trắng ở đúng 50% — ngưỡng "đơn hoàn hảo".
	#
	# Luật cân bằng đã chốt: giao khi kiên nhẫn còn trên một nửa thì được
	# thưởng. Một luật mà người chơi không nhìn thấy mốc thì không nhắm vào
	# được, nên cái mốc phải nằm ngay trên thanh chứ không nằm trong tài liệu.
	var vach := ColorRect.new()
	vach.color = Color(1, 1, 1, 0.9)
	vach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vach.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	vach.anchor_left = 0.5
	vach.anchor_right = 0.5
	vach.offset_left = -1.0
	vach.offset_right = 1.0
	vach.offset_top = -1.0
	vach.offset_bottom = 1.0
	t.add_child(vach)
	return t
