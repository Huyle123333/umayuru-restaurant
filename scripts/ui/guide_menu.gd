extends CanvasLayer

const GuideContent := preload("res://scripts/ui/guide_content.gd")
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const THEME := "res://ui/theme/menu_theme.tres"

const FRAME_WIDTH := 1440.0
const FRAME_HEIGHT := 860.0
const LEFT_COL_WIDTH := 300.0
const INGREDIENT_ICON_SIZE := 46.0

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)
const COLOR_TITLE := Color(0.72, 0.36, 0.12)

var is_open := false

var _bg: ColorRect
var _frame: PanelContainer
var _content_col: VBoxContainer
var _lbl_section: Label
var _buttons: Array[Button] = []
var _current_section := 0
var _was_paused := false
var _old_mouse_mode := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_day_row()


# ------------------------------------------------------------- đóng / mở ---

func _unhandled_key_input(event: InputEvent) -> void:
	var key_label := event as InputEventKey
	if key_label == null or not key_label.pressed or key_label.echo:
		return
	if key_label.keycode == KEY_F1:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if is_open and key_label.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true

	_was_paused = get_tree().paused
	_old_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_bg.show()
	_bg.modulate.a = 0.0
	_frame.scale = Vector2(0.97, 0.97)
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bg, "modulate:a", 1.0, 0.16)
	tween.tween_property(_frame, "scale", Vector2.ONE, 0.20)

	_select_section(_current_section)


## Phát khi bảng đóng — màn hướng dẫn chờ tín hiệu này rồi mới bắt đầu dạy.
signal closed


func close() -> void:
	if not is_open:
		return
	is_open = false
	closed.emit.call_deferred()
	_bg.hide()
	get_tree().paused = _was_paused
	if _old_mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _old_mouse_mode


func _day_row() -> void:
	is_open = false
	_bg.hide()


# ------------------------------------------------------------ dựng hình ---

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.62)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_frame = PanelContainer.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.custom_minimum_size = Vector2(FRAME_WIDTH, FRAME_HEIGHT)
	_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists(THEME):
		_frame.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s" % THEME)
	_bg.add_child(_frame)
	_frame.resized.connect(func() -> void:
		_frame.pivot_offset = _frame.size * 0.5)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_frame.add_child(row)

	row.add_child(_build_left_col())
	row.add_child(_build_right_col())


func _build_left_col() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(LEFT_COL_WIDTH, 0)
	col.add_theme_constant_override("separation", 8)

	var lbl_title := Label.new()
	lbl_title.text = "HƯỚNG DẪN"
	lbl_title.add_theme_font_size_override("font_size", 26)
	lbl_title.add_theme_color_override("font_color", COLOR_TITLE)
	col.add_child(lbl_title)

	var key_label := Label.new()
	key_label.text = "F1 hoặc ESC để đóng"
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", COLOR_DIM)
	col.add_child(key_label)

	col.add_child(_spacing(10))

	_buttons.clear()
	for i in GuideContent.SECTIONS.size():
		var b := Button.new()
		b.text = String(GuideContent.SECTIONS[i]["name"])
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_select_section.bind(i))
		col.add_child(b)
		_buttons.append(b)

	# Đẩy nút Đóng xuống đáy cột.
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var button_rows := Button.new()
	button_rows.text = "Đóng"
	button_rows.add_theme_font_size_override("font_size", 20)
	button_rows.pressed.connect(close)
	col.add_child(button_rows)
	return col


func _build_right_col() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)

	_lbl_section = Label.new()
	_lbl_section.add_theme_font_size_override("font_size", 30)
	_lbl_section.add_theme_color_override("font_color", COLOR_TITLE)
	col.add_child(_lbl_section)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_content_col = VBoxContainer.new()
	_content_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_col.add_theme_constant_override("separation", 12)
	scroll.add_child(_content_col)
	return col


# -------------------------------------------------------------- nội dung ---

func _select_section(i: int) -> void:
	if i < 0 or i >= GuideContent.SECTIONS.size():
		return
	_current_section = i

	for k in _buttons.size():
		_buttons[k].modulate = Color(1.25, 1.15, 1.0) if k == i else Color.WHITE

	var entry: Dictionary = GuideContent.SECTIONS[i]
	_lbl_section.text = String(entry["name"]).to_upper()

	for c in _content_col.get_children():
		c.queue_free()
	for block in entry["blocks"]:
		_build_block(block as Dictionary)


func _build_block(block: Dictionary) -> void:
	if block.has("h"):
		_content_col.add_child(_small_title(String(block["h"])))
	elif block.has("p"):
		_content_col.add_child(_paragraph(String(block["p"])))
	elif block.has("key_label"):
		_content_col.add_child(_key_hint(block["key_label"]))
	elif block.has("img"):
		_add_image(String(block["img"]), String(block.get("caption", "")))
	elif block.has("recipe"):
		_add_recipe(String(block["recipe"]))
	elif block.has("grade_marks"):
		_add_grade_marks()
	elif block.has("chop_list"):
		_add_chop_list()


## Hàng icon mọi nguyên liệu phải qua thớt, mỗi icon có dấu con dao — tự sinh
func _add_chop_list() -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 8)
	for id in ItemCatalog.chop_items():
		var cell := VBoxContainer.new()
		cell.add_child(_item_cells(id))
		var l := Label.new()
		l.text = ItemCatalog.display_name(id)
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", COLOR_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(l)
		row.add_child(cell)
	_content_col.add_child(row)


func _small_title(text_: String) -> Control:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", COLOR_TITLE)
	return l


func _paragraph(text_: String) -> Control:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", 18)
	t.add_theme_font_size_override("bold_font_size", 18)
	t.add_theme_color_override("default_color", COLOR_TEXT)
	t.add_theme_font_override("bold_font", _bold_font())
	t.custom_minimum_size = Vector2(FRAME_WIDTH - LEFT_COL_WIDTH - 160.0, 0)
	t.text = text_
	return t


var _bold_cache: FontVariation = null


func _bold_font() -> FontVariation:
	if _bold_cache == null:
		_bold_cache = FontVariation.new()
		_bold_cache.base_font = ThemeDB.fallback_font if ThemeDB.get_project_theme() == null \
				else ThemeDB.get_project_theme().default_font
		if _bold_cache.base_font == null:
			_bold_cache.base_font = ThemeDB.fallback_font
		_bold_cache.variation_embolden = 0.4
	return _bold_cache


func _key_hint(list: Array) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 6)
	for d in list:
		var pair: Array = d
		var a := Label.new()
		a.text = String(pair[0])
		a.add_theme_font_size_override("font_size", 18)
		a.add_theme_color_override("font_color", COLOR_TITLE)
		a.custom_minimum_size = Vector2(120, 0)
		grid.add_child(a)

		var b := Label.new()
		b.text = String(pair[1])
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", COLOR_TEXT)
		grid.add_child(b)
	return grid


## Thiếu ảnh thì BỎ QUA cả khối, không để lại ô trống và không báo lỗi.
func _add_image(path: String, text_: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return

	var img := TextureRect.new()
	img.texture = texture
	var max_w := FRAME_WIDTH - LEFT_COL_WIDTH - 200.0
	var w := minf(float(texture.get_width()), max_w)
	var h := w * float(texture.get_height()) / float(texture.get_width())
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(w, h)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content_col.add_child(img)

	if not text_.is_empty():
		var l := Label.new()
		l.text = text_
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", COLOR_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_col.add_child(l)


# ------------------------------------------------------ bảng tự sinh ---

## Bảng công thức dựng THẲNG từ ItemCatalog, không gõ tay.
func _add_recipe(kind: String) -> void:
	var table_: Dictionary = {}
	match kind:
		"table": table_ = ItemCatalog.table_recipes()
		"oven": table_ = ItemCatalog.oven_recipes()
		_: return

	for key_ in table_:
		var value := String(table_[key_])
		if ItemCatalog.is_locked(value):
			continue
		_content_col.add_child(_recipe_row(String(key_).split("+"), value))


func _recipe_row(ingredients: PackedStringArray, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	for i in ingredients.size():
		if i > 0:
			row.add_child(_marker("+"))
		row.add_child(_item_cells(String(ingredients[i])))

	row.add_child(_marker("→"))
	row.add_child(_item_cells(value))

	var lbl_name := Label.new()
	var price := ItemCatalog.price(value)
	lbl_name.text = ItemCatalog.display_name(value) + ("  (%d)" % price if price > 0 else "")
	lbl_name.add_theme_font_size_override("font_size", 18)
	lbl_name.add_theme_color_override("font_color", COLOR_TEXT)
	lbl_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl_name)
	return row


## Một ô nguyên liệu: ảnh nếu có, không thì chữ.
func _item_cells(id: String) -> Control:
	var path_ := ItemCatalog.icon_path(id)
	if ResourceLoader.exists(path_):
		var img := TextureRect.new()
		img.texture = load(path_)
		img.custom_minimum_size = Vector2(INGREDIENT_ICON_SIZE, INGREDIENT_ICON_SIZE)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.tooltip_text = ItemCatalog.display_name(id)
		return img

	var l := Label.new()
	l.text = ItemCatalog.display_name(id)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", COLOR_DIM)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _marker(text_: String) -> Control:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", COLOR_DIM)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## Bảng mốc xếp hạng, cũng đọc thẳng từ GameData.
func _add_grade_marks() -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	var days := ["d1_sang", "d2_sang", "d3_sang"]
	var day_names := ["Ngày 1", "Ngày 2", "Ngày 3"]
	var color := {
		"S": Color("f2c230"), "A": Color("e8823f"),
		"B": Color("e27ba0"), "C": Color("4f9d5d"), "D": Color("5b8fb0"),
	}
	var grid := GridContainer.new()
	grid.columns = 1 + days.size()
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 6)

	grid.add_child(_grade_cell("Hạng", COLOR_TEXT, 18))
	for name_ in day_names:
		grid.add_child(_grade_cell(name_, COLOR_TEXT, 18))

	for row in GameData.RANK_ORDER:
		grid.add_child(_grade_cell(String(row), color.get(row, COLOR_TEXT), 26))
		for id in days:
			var mark: Dictionary = GameData.rank_thresholds_for(id)
			grid.add_child(_grade_cell(str(int(mark.get(row, 0))), COLOR_TEXT, 18))

	grid.add_child(_grade_cell("Khách bỏ về", COLOR_TEXT, 18))
	for id in days:
		grid.add_child(_grade_cell("≤ %d" % GameData.max_left_for(id), COLOR_TEXT, 18))
	_content_col.add_child(grid)


func _grade_cell(text_: String, color_: Color, size_: int) -> Label:
	var cell := Label.new()
	cell.text = text_
	cell.add_theme_font_size_override("font_size", size_)
	cell.add_theme_color_override("font_color", color_)
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return cell


func _spacing(height_: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height_)
	return c
