extends Control
## Cửa hàng — mở từ nút "Cửa hàng" ở menu chính.
##
## DỰNG TOÀN BỘ BẰNG CODE, không có .tscn đi kèm. Danh sách món lấy từ
## GameData.SHOP_ITEMS: thêm một món bán là thêm một dòng dữ liệu ở đó, màn
## hình này tự có thêm một hàng.
##
## BỐ CỤC DANH SÁCH CUỘN DỌC (user chốt 29/10/2026) thay cho lưới thẻ ngang:
## mỗi món một hàng [ảnh | tên + mô tả | nút giá]. Thêm món chỉ làm danh sách
## dài ra và cuộn được, còn lưới ngang thì tới thẻ thứ năm là tràn màn hình.
##
## NỀN NÂU ĐẶC thay cho khung giấy sáng của theme: ảnh bóng nhân vật khoá và
## icon cà rốt đều nhạt màu, đặt trên nền giấy kem thì chìm; chữ kem trên nền
## nâu đậm thì tương phản cao, đọc dễ hơn.
##
## Màn hình này KHÔNG giữ tiền hay trạng thái "đã mua". Mỗi lần mở hoặc mua
## xong là hỏi lại GameData rồi vẽ lại danh sách, nên không thể lệch với file
## save (ví dụ vừa bật Teio bằng CODE No.7 thì shop tự hiện "Đã có").

const COLOR_BG := Color("4a2f1f")
const COLOR_ROW := Color("6b4530")
const COLOR_BORDER := Color("c8935a")
const COLOR_TEXT := Color("fbecd2")
const COLOR_DIM := Color("d6b996")
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"
const PANEL_SIZE := Vector2(900, 900)
const PIC_SIZE := Vector2(90, 120)

var _focus_on_close: Control = null
var _lbl_coins: Label
var _list: VBoxContainer
var _btn_close: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
	_build()


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	_refresh()
	show()
	_btn_close.grab_focus()


func close() -> void:
	hide()
	if _focus_on_close != null and is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


# ------------------------------------------------------------------ dựng ---

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _box_style(COLOR_BG, 4, 24))
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	col.add_child(_text(Lang.t("CỬA HÀNG"), 36, COLOR_TEXT, true))

	# Ví: icon cà rốt giống hệt HUD trong màn — người chơi nhận ra ngay đây
	# là thứ tiền họ vừa kiếm được ở bảng tổng kết.
	var wallet := HBoxContainer.new()
	wallet.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet.add_theme_constant_override("separation", 8)
	wallet.add_child(_coin_icon(30))
	_lbl_coins = _text("", 28, COLOR_TEXT, false)
	wallet.add_child(_lbl_coins)
	col.add_child(wallet)

	col.add_child(_text(Lang.t("Hoàn thành màn chơi để nhận 10% doanh thu vào ví."),
		16, COLOR_DIM, true))

	# ScrollContainer cần chiều cao cố định (SIZE_EXPAND_FILL trong panel có
	# custom_minimum_size) — không có thì nó giãn theo nội dung và không bao
	# giờ cuộn. Tắt cuộn ngang để hàng luôn vừa bề rộng.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_btn_close = Button.new()
	_btn_close.text = Lang.t("Đóng")
	_btn_close.pressed.connect(close)
	row.add_child(_btn_close)
	col.add_child(row)


## Vẽ lại ví và toàn bộ danh sách. Gọi lúc mở và sau mỗi lần mua.
func _refresh() -> void:
	_lbl_coins.text = str(GameData.shop_coins)
	for c in _list.get_children():
		c.queue_free()
	for id in GameData.SHOP_ORDER:
		_list.add_child(_item_row(String(id)))
	# Ngoại trang: tiêu đề nhóm rồi tới từng bộ. Skin của nhân vật CHƯA mở thì
	# ẩn hẳn chứ không hiện khoá — tên skin ghi tên thật nhân vật, hiện ra là
	# lộ bí mật mà shop vừa che bằng "Nhân tố T/C".
	_list.add_child(_text(Lang.t("NGOẠI TRANG"), 24, COLOR_DIM, true))
	# Hai lượt: skin mua được trước, skin đang khoá xuống cuối — để danh sách
	# không lẫn hàng khoá xen giữa hàng mua được.
	for pass_locked in [false, true]:
		for sid in GameData.SKIN_ORDER:
			var s := String(sid)
			if GameData.skin_visible(s) and GameData.skin_available(s) != pass_locked:
				_list.add_child(_skin_row(s))


func _item_row(id: String) -> Control:
	var info: Dictionary = GameData.SHOP_ITEMS[id]
	var price := int(info["price"])
	var owned := GameData.shop_owned(id)

	# Chưa mua: tên và ảnh giả ("Nhân tố T" + bóng đen). Đã mua: lộ mặt thật.
	# Món không có bản giả (góc nhìn thứ 3) thì luôn hiện thật.
	var name_ := String(info["name"])
	var icon_path := String(info.get("icon", ""))
	if not owned and info.has("hidden_name"):
		name_ = String(info["hidden_name"])
		icon_path = String(info["hidden_icon"])

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 52)
	if owned:
		btn.text = Lang.t("Đã có")
		btn.disabled = true
	else:
		# Giá nằm ngay trên nút. Không đủ tiền thì nút xám nhưng VẪN hiện giá
		# — người chơi biết còn thiếu bao nhiêu.
		btn.text = "%d" % price
		if ResourceLoader.exists(COIN_ICON):
			btn.icon = load(COIN_ICON)
		btn.add_theme_constant_override("icon_max_width", 26)
		btn.disabled = GameData.shop_coins < price
		btn.pressed.connect(_on_buy.bind(id))

	var tex: Texture2D = null
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		tex = load(icon_path)
	return _row_shell(tex, Lang.t(name_), Lang.t(String(info["desc"])), btn, false)


func _skin_row(sid: String) -> Control:
	var info: Dictionary = GameData.SKINS[sid]
	var ch := String(info["character"])
	var owned := GameData.owned_skins.has(sid)
	var worn := String(GameData.equipped_skins.get(ch, "")) == sid
	var locked := not GameData.skin_available(sid)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 52)
	if locked:
		# Nhân vật chưa mở: bóng đen + tên giả, nút xám nói rõ phải làm gì.
		btn.text = Lang.t(String(info["need"]))
		btn.disabled = true
	elif not owned:
		btn.text = "%d" % GameData.SKIN_PRICE
		if ResourceLoader.exists(COIN_ICON):
			btn.icon = load(COIN_ICON)
		btn.add_theme_constant_override("icon_max_width", 26)
		btn.disabled = GameData.shop_coins < GameData.SKIN_PRICE
		btn.pressed.connect(_on_buy_skin.bind(sid))
	else:
		# Đã mua: nút thành công tắc mặc/cởi, để quay về đồ gốc lúc nào cũng được.
		btn.text = Lang.t("Đang mặc") if worn else Lang.t("Mặc")
		btn.pressed.connect(_on_toggle_skin.bind(sid))
	var tex: Texture2D = null
	var pic := "res://assets/ui/skins/%s%s.png" % [sid, "_hidden" if locked else ""]
	if not ResourceLoader.exists(pic):
		# Dự phòng khi ảnh chưa import: nhân vật khoá thì dùng thẻ bóng đen,
		# tuyệt đối không rơi về thẻ mặt thật.
		pic = "res://assets/ui/characters/%s.png" % (
			GameData.HIDDEN_CHARACTERS.get(ch, ch) if locked else ch)
	if ResourceLoader.exists(pic):
		tex = load(pic)
	var title := String(info["hidden_name"]) if locked else String(info["name"])
	var desc := "Mở khoá nhân vật này để mua." if locked else "Ngoại trang — mặc khi chọn nhân vật này."
	return _row_shell(tex, Lang.t(title), Lang.t(desc), btn, false)


func _on_buy_skin(sid: String) -> void:
	if GameData.buy_skin(sid):
		AmThanh.play_sfx("coin")
	_refresh()
	_btn_close.grab_focus()


func _on_toggle_skin(sid: String) -> void:
	GameData.toggle_skin(sid)
	_refresh()
	_btn_close.grab_focus()


## Một hàng: [ảnh | tên + mô tả | nút]. `tex` null thì vẽ ô chữ thay ảnh.
func _row_shell(tex: Texture2D, title: String, desc: String, btn: Button,
		faded: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box_style(COLOR_ROW, 2, 12))
	if faded:
		card.modulate = Color(1, 1, 1, 0.55)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)

	if tex != null:
		var pic := TextureRect.new()
		pic.texture = tex
		pic.custom_minimum_size = PIC_SIZE
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(pic)
	else:
		var glyph := _text("3D" if not faded else "?", 40, COLOR_DIM, true)
		glyph.custom_minimum_size = PIC_SIZE
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(glyph)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(_text(title, 24, COLOR_TEXT, false))
	var d := _text(desc, 16, COLOR_DIM, false)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(d)
	h.add_child(mid)

	if btn != null:
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(btn)
	return card


func _box_style(bg: Color, border: int, pad: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(pad)
	return sb


func _text(t: String, size_: int, color_: Color, centered: bool) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", color_)
	# Theme chung đặt viền chữ nâu đậm; trên nền nâu thì viền đó làm chữ bết.
	l.add_theme_constant_override("outline_size", 0)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _coin_icon(px: int) -> Control:
	var icon := TextureRect.new()
	if ResourceLoader.exists(COIN_ICON):
		icon.texture = load(COIN_ICON)
	icon.custom_minimum_size = Vector2(px, px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _on_buy(id: String) -> void:
	if GameData.buy_shop_item(id):
		AmThanh.play_sfx("coin")
	_refresh()
	_btn_close.grab_focus()
