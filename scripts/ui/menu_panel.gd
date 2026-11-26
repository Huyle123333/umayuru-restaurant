extends CanvasLayer

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

const ACTION := "toggle_menu"
const THEME := "res://ui/theme/menu_theme.tres"

const PANEL_WIDTH := 600.0
const PANEL_MARGIN := 24.0
const DISH_ICON := 46.0
const PART_ICON := 34.0
const SLIDE_SECONDS := 0.55
## Mép trên của bảng. Nằm DƯỚI bảng đồng hồ & ví ở góc trên phải (hud_clock:
const PANEL_TOP := 200.0
const TIER_LABELS := {"easy": "DỄ", "medium": "TRUNG BÌNH", "hard": "KHÓ"}
const TIER_COLORS := {
	"easy": Color("7fc97a"), "medium": Color("f0b24a"), "hard": Color("e8695a"),
}
const COLOR_PANEL := Color(0.13, 0.09, 0.07, 0.86)
const COLOR_PANEL_BORDER := Color(0.90, 0.68, 0.35, 0.75)
const COLOR_NAME := Color(1, 0.96, 0.89)
const COLOR_OUTLINE := Color(0.22, 0.12, 0.06)
const COLOR_DIM := Color(0.86, 0.79, 0.70)

var is_open := false

var _root: Control
var _menu_panel: PanelContainer
var _lbl_hint: Label
## Đã đo xong kích thước và đặt chỗ chưa. Trước đó mọi lệnh mở/đóng chỉ được
var _placed := false
var _tween: Tween


func _ready() -> void:
	layer = 6
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	SettingsManager.settings_changed.connect(_draw_hint)


## Dựng nội dung bảng. Mảng rỗng thì không có bảng, phím tắt không làm gì.
func setup(dishes: Array[String]) -> void:
	if dishes.is_empty():
		return
	_menu_panel = _build_menu_panel(dishes)
	_menu_panel.position = Vector2(100000, 0)
	_root.add_child(_menu_panel)
	_draw_hint()
	await get_tree().process_frame
	if not is_instance_valid(_menu_panel):
		return
	_place()
	_placed = true
	if is_open:
		_slide(true)


func toggle() -> void:
	set_open(not is_open)


func set_open(open: bool) -> void:
	if open == is_open:
		return
	is_open = open
	if _placed:
		_slide(open)


func _unhandled_key_input(event: InputEvent) -> void:
	if _menu_panel == null:
		return
	if event.is_action_pressed(ACTION) and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------ đặt chỗ ---

func _shown_size() -> Vector2:
	return _menu_panel.size * _menu_panel.scale


func _x_open() -> float:
	return _root.size.x - _shown_size().x - PANEL_MARGIN


func _x_closed() -> float:
	return _root.size.x + PANEL_MARGIN


## Treo từ PANEL_TOP xuống, nằm sẵn NGOÀI mép phải; thu nhỏ nếu không vừa
func _place() -> void:
	var screen := _root.size
	var wanted := _menu_panel.get_combined_minimum_size()
	_menu_panel.size = wanted
	var room := screen.y - PANEL_TOP - PANEL_MARGIN
	var scale_ := minf(1.0, room / maxf(wanted.y, 1.0))
	_menu_panel.scale = Vector2(scale_, scale_)
	_menu_panel.position = Vector2(_x_closed(), PANEL_TOP)


func _slide(open: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if open:
		_tween.tween_property(_menu_panel, "position:x", _x_open(), SLIDE_SECONDS) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_property(_menu_panel, "position:x", _x_closed(), SLIDE_SECONDS) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _draw_hint() -> void:
	if _lbl_hint != null:
		_lbl_hint.text = Lang.t("%s  ẩn/hiện") % SettingsManager.key_name(ACTION)


# ----------------------------------------------------------- dựng hình ---

func _build_menu_panel(dishes: Array[String]) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	if ResourceLoader.exists(THEME):
		panel.theme = load(THEME)
	var box := StyleBoxFlat.new()
	box.bg_color = COLOR_PANEL
	box.border_color = COLOR_PANEL_BORDER
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)

	var title := _text(Lang.t("THỰC ĐƠN HÔM NAY"), 30, COLOR_NAME, 6)
	col.add_child(title)
	_lbl_hint = _text("", 15, COLOR_DIM, 4)
	col.add_child(_lbl_hint)

	for tier in ItemCatalog.DIFFICULTY_ORDER:
		var in_tier: Array[String] = []
		for id in dishes:
			if ItemCatalog.difficulty(id) == String(tier):
				in_tier.append(id)
		if in_tier.is_empty():
			continue
		var head := _text(String(TIER_LABELS[tier]), 20, TIER_COLORS[tier], 5)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(head)
		for id in in_tier:
			col.add_child(_dish_row(id))
	return panel


## Một dòng: [ảnh món] tên món  =  ảnh từng thứ phải gom.
func _dish_row(id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.add_child(_icon(id, DISH_ICON))

	var name_ := _text(ItemCatalog.display_name(id), 19, COLOR_NAME, 4)
	name_.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_.custom_minimum_size = Vector2(190, 0)
	name_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_)

	var parts := ItemCatalog.recipe_parts(id)
	if parts.is_empty():
		var hint := _text(Lang.t("lấy ra là giao"), 16, COLOR_DIM, 4)
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hint)
		return row
	for part in parts:
		row.add_child(_icon(part, PART_ICON))
	return row


## Ảnh 2D của một món / nguyên liệu; thiếu ảnh thì lùi về CHỮ chứ không bỏ
func _icon(id: String, size_: float) -> Control:
	var path_ := ItemCatalog.icon_path(id)
	if ResourceLoader.exists(path_):
		var img := TextureRect.new()
		img.texture = load(path_)
		img.custom_minimum_size = Vector2(size_, size_)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return img
	var l := _text(ItemCatalog.display_name(id), 14, COLOR_DIM, 4)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _text(content: String, font_size: int, color: Color, border: int) -> Label:
	var l := Label.new()
	l.text = content
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	l.add_theme_constant_override("outline_size", border)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
