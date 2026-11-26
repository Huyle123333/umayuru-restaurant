extends Control

## (2/10/2026) Vé DỌC và hẹp: 148 × 112, thay cho vé ngang 330 × 110. Dải đơn
const WIDTH := 148.0
## Chiều cao vé CÓ hàng công thức (16/11/2026). Dải đơn hàng dùng số này để
const HEIGHT := 190.0
## Vé không in công thức (Asian): giữ đúng chiều cao cũ, khỏi chừa ô trống.
const HEIGHT_PLAIN := 112.0
## Ô ảnh nguyên liệu và kí hiệu nơi nấu bên dưới nó.
const PART_SIZE := 50.0
const BADGE_SIZE := 40.0
const PART_GAP := 4.0
## Số nguyên liệu nhiều nhất của một món (Hamburger, kem tam hợp que = 4) cộng
const MAX_PARTS := 5
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const SLIDE_SECONDS := 0.30

## Bảng màu giấy: lấy tông vé giấy nâu-kem cho khớp phong cách quán ăn, không
const COLOR_PAPER := Color("f3e6cd")
const COLOR_BORDER := Color("c2a173")
const COLOR_TEXT := Color("4a3421")
const COLOR_DIM := Color("8a7355")

## Ba mức màu của bar kiên nhẫn. Đổi màu THEO NGƯỠNG chứ không nội suy dần:
const COLOR_GREEN := Color("4f9d5d")
const COLOR_YELLOW := Color("d9a520")
const COLOR_RED := Color("c4433a")
const YELLOW_THRESHOLD := 0.5
const RED_THRESHOLD := 0.2

## Màu bar khi khách còn ĐANG XẾP HÀNG: xám nhạt, đầy, đứng yên.
const COLOR_WAIT := Color("b9ab93")

## Chữ trên ô số bàn khi khách chưa có bàn.
const NO_TABLE_YET := "—"

var order: RefCounted = null
## Chiều cao thật của vé này — HEIGHT hoặc HEIGHT_PLAIN.
var _h := HEIGHT
var _w := WIDTH

var _card: PanelContainer
var _bar: ProgressBar
var _fill_style: StyleBoxFlat
## Ô số bàn — giữ lại để cập nhật lúc khách rời hàng đợi và ngồi xuống.
var _lbl_number: Label


## Asian: không in công thức — chế độ khó bắt người chơi tự nhớ (tài liệu
static func _shows_recipe() -> bool:
	var gd = Engine.get_main_loop().root.get_node_or_null("/root/GameData") \
		if Engine.get_main_loop() is SceneTree else null
	return gd == null or not gd.is_asian_mode()


## Bề ngang vé cho món có `n` nguyên liệu.
static func width_for(n: int) -> float:
	return maxf(WIDTH, n * (PART_SIZE + PART_GAP) + 20.0)


func _init() -> void:
	_h = HEIGHT if _shows_recipe() else HEIGHT_PLAIN
	custom_minimum_size = Vector2(WIDTH, _h)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(order_: RefCounted, coin_icon: Texture2D) -> void:
	order = order_
	if _h == HEIGHT:
		_w = width_for(ItemCatalog.ticket_parts(String(order_.dish)).size())
		custom_minimum_size.x = _w

	_card = PanelContainer.new()
	_card.size = Vector2(_w, _h)
	_card.position = Vector2(0.0, -_h - 12.0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override("panel", _paper_frame())
	add_child(_card)

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
	lbl_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_name.clip_text = true
	if _h != HEIGHT:
		col.add_child(lbl_name)
	else:
		lbl_name.free()

	_bar = _make_bar()
	col.add_child(_bar)

	if _h == HEIGHT:
		col.add_child(_recipe_row(String(order_.dish)))

	_draw_table_no()
	_draw_bar()


func slide_in() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "position:y", 0.0, SLIDE_SECONDS)


## Trượt ngược ra rồi tự xoá. Trả về tween để bên gọi await nếu cần.
func slide_out() -> void:
	order = null
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_card, "position:y", -_h - 12.0, SLIDE_SECONDS)
	tween.tween_property(self, "custom_minimum_size:x", 0.0, SLIDE_SECONDS)
	tween.finished.connect(queue_free)


func _process(_delta: float) -> void:
	if order == null:
		return
	_draw_table_no()
	_draw_bar()


## Ô số bàn: dấu gạch khi khách còn đứng xếp hàng, số thật khi đã ngồi.
func _draw_table_no() -> void:
	if order == null or _lbl_number == null:
		return
	var num := int(order.table_number())
	var text_ := NO_TABLE_YET if num <= 0 else str(num)
	if _lbl_number.text != text_:
		_lbl_number.text = text_


## Thanh kiên nhẫn.
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

	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = COLOR_GREEN
	_fill_style.set_corner_radius_all(6)
	t.add_theme_stylebox_override("fill", _fill_style)

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


## Hàng công thức kiểu Overcooked: mỗi nguyên liệu một ô [ảnh / kí hiệu nơi
func _recipe_row(dish: String) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(PART_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parts := ItemCatalog.ticket_parts(dish)
	if parts.is_empty():
		return row
	var room := _w - 16.0
	var size_ := minf(PART_SIZE, room / parts.size() - PART_GAP)
	for part in parts:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(_icon(ItemCatalog.icon_path(part), size_))
		var badge := ItemCatalog.cook_badge(dish, part)
		cell.add_child(_icon("" if badge.is_empty() else ItemCatalog.badge_path(badge),
			minf(BADGE_SIZE, size_)))
		row.add_child(cell)
	return row


func _icon(path_: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not path_.is_empty() and ResourceLoader.exists(path_):
		t.texture = load(path_)
	return t
