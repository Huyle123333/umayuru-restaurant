extends Control
## MỘT tấm vé đơn hàng trên HUD.
##
## Cấu trúc hai lớp, và đây là điểm quan trọng nhất của file này:
##
##     Ve (Control, clip_contents = true)   ← con của HBoxContainer
##       └── _card (PanelContainer)          ← KHÔNG do container xếp
##
## Vì sao phải tách hai lớp thay vì cho thẳng tấm thẻ vào VBox: hiệu ứng
## "thả từ trên xuống" cần đổi `position.y` của tấm thẻ, mà HBoxContainer thì
## GHI ĐÈ vị trí mọi node con của nó ở mỗi lần bố trí lại. Tween sẽ chạy được
## đúng một frame hình rồi bị container kéo về chỗ cũ. Lớp ngoài nhận việc bị
## container xếp; lớp trong tự do vì nó không phải con của container nào cả.
##
## `clip_contents` trên lớp ngoài chính là cái cắt phần thẻ còn thò ra ngoài
## lúc đang trượt, nên vé không đè lên vé bên cạnh trong lúc chạy hiệu ứng.
##
## Neo của lớp trong để nguyên góc trên-trái (mọi anchor = 0) và ta gán `size`
## bằng tay. KHÔNG dùng PRESET_FULL_RECT rồi tween position: neo full-rect tính
## lại rect từ anchor + offset mỗi lần bố trí, nên nó đánh nhau với position và
## cái rect phình ra thêm mỗi frame hình.

## (2/10/2026) Vé DỌC và hẹp: 148 × 112, thay cho vé ngang 330 × 110. Dải đơn
## hàng giờ nằm ngang ở mép trên, nên bề NGANG của một vé là thứ quyết định
## xếp được mấy vé — 148 thì vừa 10 vé, đúng số đơn tối đa của Ngày 3.
const WIDTH := 148.0
const HEIGHT := 112.0
const SLIDE_SECONDS := 0.30

## Bảng màu giấy: lấy tông vé giấy nâu-kem cho khớp phong cách quán ăn, không
## dùng panel xám mặc định của Godot.
const COLOR_PAPER := Color("f3e6cd")
const COLOR_BORDER := Color("c2a173")
const COLOR_TEXT := Color("4a3421")
const COLOR_DIM := Color("8a7355")

## Ba mức màu của bar kiên nhẫn. Đổi màu THEO NGƯỠNG chứ không nội suy dần:
## chuyển màu mượt thì mắt không bắt được thời điểm "sắp mất khách", còn ba
## bậc rõ ràng thì đọc được bằng thị giác ngoại vi, lúc đang bận nhìn chỗ khác.
const COLOR_GREEN := Color("4f9d5d")
const COLOR_YELLOW := Color("d9a520")
const COLOR_RED := Color("c4433a")
const YELLOW_THRESHOLD := 0.5   # bằng đúng ngưỡng đơn hoàn hảo
const RED_THRESHOLD := 0.2

## Màu bar khi khách còn ĐANG XẾP HÀNG: xám nhạt, đầy, đứng yên.
##
## Phải khác hẳn ba màu kia chứ không dùng màu xanh: xanh nghĩa là "còn nhiều
## thời gian", mà ở đây thì không có thời gian nào đang chạy cả. Một màu thứ
## tư, nhạt hơn, đọc ra đúng thứ nó là — chưa bắt đầu.
const COLOR_WAIT := Color("b9ab93")

## Chữ trên ô số bàn khi khách chưa có bàn.
const NO_TABLE_YET := "—"

var order: RefCounted = null

var _card: PanelContainer
var _bar: ProgressBar
var _fill_style: StyleBoxFlat
## Ô số bàn — giữ lại để cập nhật lúc khách rời hàng đợi và ngồi xuống.
var _lbl_number: Label


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(order_: RefCounted, coin_icon: Texture2D) -> void:
	order = order_

	_card = PanelContainer.new()
	_card.size = Vector2(WIDTH, HEIGHT)
	_card.position = Vector2(0.0, -HEIGHT - 12.0)   # nằm sẵn phía trên, ngoài khung
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override("panel", _paper_frame())
	add_child(_card)

	# Ba tầng từ trên xuống: [ảnh món | số bàn + giá] / tên món / bar kiên nhẫn.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_card.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	col.add_child(top)

	# --- ảnh món ---
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(56, 56)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path_ := String(order_.icon_path())
	if ResourceLoader.exists(path_):
		img.texture = load(path_)
	else:
		push_warning("Vé đơn: thiếu ảnh %s" % path_)
	top.add_child(img)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", -4)
	top.add_child(side)

	# --- số bàn ---
	#
	# Giữ tham chiếu chứ không gán một lần rồi thôi: vé hiện từ lúc khách còn
	# ĐỨNG XẾP HÀNG, khi chưa có bàn nào. Số bàn chỉ có sau, nên ô này phải
	# đổi được giữa chừng.
	_lbl_number = Label.new()
	_lbl_number.add_theme_font_size_override("font_size", 34)
	_lbl_number.add_theme_color_override("font_color", COLOR_TEXT)
	_lbl_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(_lbl_number)

	# --- giá ---
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 3)
	side.add_child(price_row)

	if coin_icon != null:
		var icon := TextureRect.new()
		icon.texture = coin_icon
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		price_row.add_child(icon)

	var price := Label.new()
	price.text = str(int(order_.price))
	price.add_theme_font_size_override("font_size", 15)
	price.add_theme_color_override("font_color", COLOR_DIM)
	price_row.add_child(price)

	# --- tên món ---
	var lbl_name := Label.new()
	lbl_name.text = String(order_.dish_name())
	lbl_name.add_theme_font_size_override("font_size", 15)
	lbl_name.add_theme_color_override("font_color", COLOR_TEXT)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Cắt bằng dấu … chứ không xuống dòng: tấm vé cao cố định, cho phép xuống
	# dòng thì một cái tên dài đẩy bar kiên nhẫn ra khỏi thẻ. Ảnh món ở ngay
	# trên đã nói đủ món nào; tên chỉ là phần xác nhận.
	lbl_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_name.clip_text = true
	col.add_child(lbl_name)

	_bar = _make_bar()
	col.add_child(_bar)

	_draw_table_no()
	_draw_bar()


func slide_in() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "position:y", 0.0, SLIDE_SECONDS)


## Trượt ngược ra rồi tự xoá. Trả về tween để bên gọi await nếu cần.
func slide_out() -> void:
	order = null
	# Hai thứ chạy SONG SONG: thẻ rút lên trên, đồng thời ô chứa nó xẹp bề
	# NGANG về 0. Chỉ rút không thôi thì cái vé biến mất nhưng để lại một
	# khoảng trống, và những vé bên phải nhảy cóc sang khi node bị xoá.
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_card, "position:y", -HEIGHT - 12.0, SLIDE_SECONDS)
	tween.tween_property(self, "custom_minimum_size:x", 0.0, SLIDE_SECONDS)
	tween.finished.connect(queue_free)


func _process(_delta: float) -> void:
	if order == null:
		return
	_draw_table_no()
	_draw_bar()


## Ô số bàn: dấu gạch khi khách còn đứng xếp hàng, số thật khi đã ngồi.
##
## So sánh trước khi gán: hàm này chạy mỗi frame hình, mà gán `text` bằng đúng
## chuỗi cũ vẫn bắt Label tính lại bố cục.
func _draw_table_no() -> void:
	if order == null or _lbl_number == null:
		return
	var num := int(order.table_number())
	var text_ := NO_TABLE_YET if num <= 0 else str(num)
	if _lbl_number.text != text_:
		_lbl_number.text = text_


## Thanh kiên nhẫn.
##
## KHÁCH ĐANG XẾP HÀNG thì bar ĐẦY và ĐỨNG YÊN, màu chờ.
##
## Không vẽ kiên nhẫn hàng đợi lên đây dù đơn vẫn đang đếm nó: hai giai đoạn
## có hai ngân sách riêng và hai chỗ hiển thị riêng — bar chờ nằm trong bong
## bóng trên đầu khách, bar phục vụ nằm ở đây. Vẽ cả hai vào cùng một chỗ
## thì người chơi thấy bar tụt rồi bỗng đầy lại lúc khách ngồi xuống, và họ
## sẽ tưởng là lỗi.
##
## Vé này hiện sớm CHỈ để người chơi biết trước phải nấu gì. Thứ nó hứa là
## "món kế tiếp", không phải "đang đếm giờ" — nên nó không được đếm giờ.
func _draw_bar() -> void:
	if order == null or _bar == null:
		return

	if bool(order.in_queue):
		_bar.value = 100.0
		if _fill_style.bg_color != COLOR_WAIT:
			_fill_style.bg_color = COLOR_WAIT
		return

	var ratio: float = float(order.patience_ratio())
	_bar.value = ratio * 100.0
	var color := COLOR_GREEN
	if ratio <= RED_THRESHOLD:
		color = COLOR_RED
	elif ratio <= YELLOW_THRESHOLD:
		color = COLOR_YELLOW
	if _fill_style.bg_color != color:
		_fill_style.bg_color = color


func _paper_frame() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PAPER
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 7
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _make_bar() -> ProgressBar:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(0, 12)
	t.max_value = 100.0
	t.show_percentage = false

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("dccdae")
	bg.set_corner_radius_all(6)
	t.add_theme_stylebox_override("background", bg)

	# StyleBox riêng cho TỪNG vé, không dùng chung: đổi bg_color của một
	# StyleBox dùng chung thì mọi vé đổi màu theo, và cả sáu vé sẽ luôn mang
	# màu của vé cập nhật sau cùng.
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = COLOR_GREEN
	_fill_style.set_corner_radius_all(6)
	t.add_theme_stylebox_override("fill", _fill_style)

	# Vạch trắng ở đúng 50% — ngưỡng "đơn hoàn hảo".
	#
	# Luật cân bằng đã chốt: giao khi kiên nhẫn còn trên một nửa thì được
	# thưởng. Một luật mà người chơi không nhìn thấy mốc thì không nhắm vào
	# được, nên cái mốc phải nằm ngay trên bar chứ không nằm trong tài liệu.
	var tick := ColorRect.new()
	tick.color = Color(1, 1, 1, 0.9)
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	tick.anchor_left = 0.5
	tick.anchor_right = 0.5
	tick.offset_left = -1.0
	tick.offset_right = 1.0
	tick.offset_top = -1.0
	tick.offset_bottom = 1.0
	t.add_child(tick)
	return t
