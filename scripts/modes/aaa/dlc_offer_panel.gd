extends CanvasLayer
## AAA MODE — BẢNG QUẢNG CÁO DLC (giả).
##
## Hai kiểu hiện:
##   • show_offer(kind)      — bảng giữa màn hình, chặn mọi thứ phía sau. Dùng
##     khi bấm vào thẻ nhân vật bị khoá, trạm bị khoá, phím kĩ năng, hoặc khi
##     trainer gạ "để tôi làm hộ".
##   • show_sale_banner(sec) — dải quảng cáo mép trái trong lúc đếm ngược đầu
##     màn, KHÔNG chặn gì: người chơi vẫn phải đi dạo bếp được (xem
##     level_intro.gd), quảng cáo chỉ được phép làm phiền chứ không được cản.
##
## Không có giao dịch thật nào. Nút "Mua ngay" chỉ đổi chữ trong bảng.
##
## Một script cho mọi gói thay vì mỗi gói một scene: các gói chỉ khác nhau
## chữ, nên chữ nằm trong bảng OFFERS — thêm gói mới là thêm một dòng.

signal closed

const DlcCatalog := preload("res://scripts/modes/aaa/dlc_catalog.gd")

## Quảng cáo nào trùng một gói trong DlcCatalog thì hiện bằng bảng của gói đó,
## để giá ở đây cũng nhảy theo số lần từ chối như mọi chỗ khác.
const OFFER_TO_PACK := {"kitchen": "cooking", "skill": "skill"}

const THEME := "res://ui/theme/menu_theme.tres"
const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_SALE := Color(0.82, 0.16, 0.12)

const OFFERS := {
	"deluxe": {
		"title": "DELUXE EDITION",
		"body": "Nhân vật này thuộc gói Deluxe Edition.",
		"price": "Mua gói Deluxe để mở khoá nhân vật: 3,6$",
	},
	"kitchen": {
		"title": "DLC EXTRA KITCHEN",
		"body": "Trạm này thuộc gói DLC Extra Kitchen: mở khoá thêm bếp, lò nướng, máy kem cùng toàn bộ công thức và nguyên liệu.",
		"price": "9,99$  →  2,99$  (−70%)",
	},
	"skill": {
		"title": "DLC SKILL PACK",
		"body": "Kĩ năng nhân vật thuộc gói DLC Skill Pack.",
		"price": "7,99$  →  3,19$  (−60%)",
	},
	"trainer": {
		"title": "DLC TRAINER PRO",
		"body": "Tính năng Tự Động Nấu có trong DLC Trainer Pro.",
		"price": "4,99$  →  1,99$  (−60%)",
	},
}

## Các gói hiện trên dải quảng cáo đầu màn.
const BANNER_LINES := [
	["DLC Extra Kitchen", "9,99$  →  2,99$  (−70%)"],
	["DLC Skill Pack", "7,99$  →  3,19$  (−60%)"],
	["Combo Ultimate", "17,98$  →  5,39$  (−70%)"],
]

var _modal := false
var _was_paused := false
var _old_mouse := Input.MOUSE_MODE_VISIBLE
var _body: Label
var _btn_buy: Button
var _btn_close: Button
var _banner_left := 0.0
var _banner_timer: Label
## Đã bấm "Mua ngay" chưa. Đóng bảng mà CHƯA bấm mua = một lần từ chối.
var _bought := false


func _ready() -> void:
	layer = 40
	# Phải chạy cả khi cây scene đang tạm dừng: bảng modal TỰ tạm dừng game.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Bảng giữa màn hình. Tạm dừng game cho tới khi đóng.
func show_offer(kind: String) -> void:
	if OFFER_TO_PACK.has(kind):
		show_pack(String(OFFER_TO_PACK[kind]))
		return
	var offer: Dictionary = OFFERS.get(kind, OFFERS["kitchen"])
	_modal = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	_old_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_theme(center)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	col.add_child(_label(Lang.t(String(offer["title"])), 34, COLOR_TEXT))
	_body = _label(Lang.t(String(offer["body"])), 22, COLOR_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_body)
	col.add_child(_label(Lang.t(String(offer["price"])), 28, COLOR_SALE))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	_btn_buy = Button.new()
	_btn_buy.text = Lang.t("Mua ngay")
	_btn_buy.pressed.connect(_on_buy)
	row.add_child(_btn_buy)
	_btn_close = Button.new()
	_btn_close.text = Lang.t("Để sau")
	_btn_close.pressed.connect(close)
	row.add_child(_btn_close)
	_btn_buy.grab_focus()


## Bảng mua của một gói trong DlcCatalog: ảnh, mô tả, giá gạch ngang + giá sale.
func show_pack(id: String) -> void:
	var pack: Dictionary = DlcCatalog.PACKS[id]
	_modal = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	_old_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_theme(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	col.add_child(_label(String(pack["title"]), 34, COLOR_TEXT))
	var img := TextureRect.new()
	img.texture = load(String(pack["image"]))
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(640, 400)
	col.add_child(img)
	_body = _label(Lang.t(String(pack["desc"])), 22, COLOR_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_body)
	var price := RichTextLabel.new()
	price.bbcode_enabled = true
	price.fit_content = true
	price.scroll_active = false
	price.add_theme_font_size_override("normal_font_size", 26)
	price.add_theme_font_size_override("bold_font_size", 30)
	price.add_theme_color_override("default_color", Color(0.4, 0.33, 0.27))
	price.text = "[center]%s[/center]" % DlcCatalog.price_text(id, true)
	col.add_child(price)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	_btn_buy = Button.new()
	_btn_buy.text = Lang.t("Mua ngay")
	_btn_buy.pressed.connect(_on_buy)
	row.add_child(_btn_buy)
	_btn_close = Button.new()
	_btn_close.text = Lang.t("Để sau")
	_btn_close.pressed.connect(close)
	row.add_child(_btn_close)
	_btn_buy.grab_focus()


func _on_buy() -> void:
	_bought = true
	_body.text = Lang.t("Thanh toán thất bại: đây là đồ án tốt nghiệp. Cảm ơn bạn đã ủng hộ tinh thần!")
	_btn_buy.hide()
	_btn_close.text = Lang.t("Đóng")
	_btn_close.grab_focus()


func close() -> void:
	# Từ chối (Để sau / Esc) thì lần quảng cáo sau giảm giá sâu hơn.
	if _modal and not _bought:
		DlcCatalog.refuse()
	if _modal:
		get_tree().paused = _was_paused
		Input.mouse_mode = _old_mouse
	closed.emit()
	queue_free()


## ESC đóng bảng modal, giống mọi bảng khác trong game.
func _unhandled_input(event: InputEvent) -> void:
	if _modal and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Dải quảng cáo mép trái, đếm ngược cùng màn hình mở đầu.
func show_sale_banner(seconds: float) -> void:
	_banner_left = seconds
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	margin.position = Vector2(28, 300)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme(margin)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	col.add_child(_label(Lang.t("SIÊU SALE DLC"), 30, COLOR_SALE))
	col.add_child(_label(Lang.t("Kĩ năng và bếp phụ đã được tách thành nội dung tải thêm."), 18, COLOR_TEXT))
	for pair in BANNER_LINES:
		col.add_child(_label(String(pair[0]), 22, COLOR_TEXT))
		col.add_child(_label(String(pair[1]), 22, COLOR_SALE))
	_banner_timer = _label("", 22, COLOR_TEXT)
	col.add_child(_banner_timer)
	_tick_banner(0.0)


func _process(delta: float) -> void:
	if _banner_timer != null:
		_tick_banner(delta)


func _tick_banner(delta: float) -> void:
	_banner_left = maxf(0.0, _banner_left - delta)
	_banner_timer.text = Lang.t("SALE KẾT THÚC SAU 00:%02d") % int(ceilf(_banner_left))


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _apply_theme(c: Control) -> void:
	if ResourceLoader.exists(THEME):
		c.theme = load(THEME)
