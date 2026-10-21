extends PanelContainer
## AAA MODE — một thẻ quảng cáo gói DLC: ảnh, tên gói, giá đang sale.
##
## Di chuột vào → hiện bảng mô tả bên cạnh thẻ. Bấm → mở bảng mua.
## Dùng chung ở ba nơi (màn chọn nhân vật, đếm ngược, bật lên trong màn), nên
## thẻ tự lo hết, nơi dùng chỉ cần new() + setup(id).
##
## Giá tự cập nhật khi số lần từ chối đổi (xem _process): bấm "Để sau" ở một
## thẻ thì mọi thẻ đang hiện đều nhảy sang mức sale mới ngay — người chơi
## THẤY rằng làm ngơ thì giá tụt.

const DlcCatalog := preload("res://scripts/modes/aaa/dlc_catalog.gd")
const DlcOfferPanel := preload("res://scripts/modes/aaa/dlc_offer_panel.gd")
const THEME := "res://ui/theme/menu_theme.tres"

## Bảng mô tả hiện bên nào của thẻ: "right", "left" hoặc "below".
var desc_side := "right"
## Thẻ nằm ngang (ảnh trái, chữ phải). Đặt TRƯỚC setup().
var compact := false

var pack_id := ""
var _price: RichTextLabel
var _desc_panel: PanelContainer
var _shown_refusals := -1


func setup(id: String, width: float) -> void:
	pack_id = id
	var pack: Dictionary = DlcCatalog.PACKS[id]
	# Viền tự vẽ chứ không dùng khung gỗ của menu_theme: khung đó có lề trong
	# rất dày (vẽ cho bảng to), áp lên thẻ nhỏ thì ảnh co lại còn bằng con tem.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.96, 0.86)
	style.border_color = Color(0.85, 0.55, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(width, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# compact: ảnh bên trái, chữ bên phải — dùng cho dải nằm ngang ở màn chọn
	# nhân vật, nơi chỉ còn chỗ cho một hàng thấp.
	var box: BoxContainer = HBoxContainer.new() if compact else VBoxContainer.new()
	box.add_theme_constant_override("separation", 6 if compact else 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var img := TextureRect.new()
	img.texture = load(String(pack["image"]))
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.custom_minimum_size = Vector2(96, 72) if compact else Vector2(width - 12, (width - 12) * 0.72)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(img)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)

	var title := Label.new()
	title.text = String(pack["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.29, 0.153, 0.071))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)

	_price = RichTextLabel.new()
	_price.bbcode_enabled = true
	_price.fit_content = true
	_price.scroll_active = false
	# Không tự xuống dòng: trong cột hẹp, RichTextLabel tự xuống dòng sẽ tính
	# chiều rộng gần bằng 0 lúc dựng, rồi bẻ từng chữ một và kéo thẻ dài ngoằng.
	_price.autowrap_mode = TextServer.AUTOWRAP_OFF
	_price.add_theme_font_size_override("normal_font_size", 14)
	_price.add_theme_font_size_override("bold_font_size", 15)
	_price.add_theme_color_override("default_color", Color(0.4, 0.33, 0.27))
	_price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_price)
	_refresh_price()

	mouse_entered.connect(_show_desc)
	mouse_exited.connect(_hide_desc)


func _process(_delta: float) -> void:
	if DlcCatalog.refusals != _shown_refusals:
		_refresh_price()


func _refresh_price() -> void:
	_shown_refusals = DlcCatalog.refusals
	if _price != null:
		_price.text = "[center]%s[/center]" % DlcCatalog.price_text(pack_id, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_hide_desc()
		var panel := DlcOfferPanel.new()
		get_tree().root.add_child(panel)
		panel.show_pack(pack_id)


## Bảng mô tả gắn vào cây gốc (không làm con của thẻ) để không bị container
## của thẻ ép kích thước, và đứng trên mọi lớp giao diện khác.
func _show_desc() -> void:
	if _desc_panel != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 45
	_desc_panel = PanelContainer.new()
	if ResourceLoader.exists(THEME):
		_desc_panel.theme = load(THEME)
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.custom_minimum_size = Vector2(320, 0)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(col)
	var pack: Dictionary = DlcCatalog.PACKS[pack_id]
	var title := Label.new()
	title.text = String(pack["title"])
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.29, 0.153, 0.071))
	col.add_child(title)
	var desc := Label.new()
	desc.text = Lang.t(String(pack["desc"]))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(300, 0)
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.29, 0.153, 0.071))
	col.add_child(desc)
	var hint := Label.new()
	hint.text = Lang.t("Bấm để mua")
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.82, 0.16, 0.12))
	col.add_child(hint)
	layer.add_child(_desc_panel)
	get_tree().root.add_child(layer)
	_desc_panel.reset_size()
	var r := get_global_rect()
	# Toạ độ thẻ tính trong khung 1920×1080 (canvas_items stretch) — CanvasLayer
	# dùng cùng hệ toạ độ đó nên đặt thẳng được.
	match desc_side:
		"left":
			_desc_panel.position = Vector2(r.position.x - _desc_panel.size.x - 10, r.position.y)
		"below":
			_desc_panel.position = Vector2(r.position.x, r.end.y + 8)
		"above":
			_desc_panel.position = Vector2(r.position.x, r.position.y - _desc_panel.size.y - 8)
		_:
			_desc_panel.position = Vector2(r.end.x + 10, r.position.y)
	_desc_panel.position.y = clampf(_desc_panel.position.y, 10, 1070 - _desc_panel.size.y)
	_desc_panel.position.x = clampf(_desc_panel.position.x, 10, 1910 - _desc_panel.size.x)


func _hide_desc() -> void:
	if _desc_panel != null and is_instance_valid(_desc_panel):
		_desc_panel.get_parent().queue_free()
	_desc_panel = null


func _exit_tree() -> void:
	_hide_desc()
