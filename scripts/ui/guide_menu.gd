extends CanvasLayer
## Menu hướng dẫn đầy đủ — phím F1. Cột nút bên trái, nội build cuộn ở giữa.
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
## TOÀN BỘ NỘI DUNG nằm ở guide_content.gd. File này chỉ biết VẼ.

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
	layer = 40   # trên mọi HUD và cả bảng tổng kết (20)
	# Phải chạy được TRONG LÚC cây scene bị tạm dừng — chính menu này là thứ
	# tạm dừng game, nên nếu nó cũng bị dừng thì không bấm được nút nào cả.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_day_row()


# ------------------------------------------------------------- đóng / mở ---

func _unhandled_key_input(su_kien: InputEvent) -> void:
	var key_label := su_kien as InputEventKey
	if key_label == null or not key_label.pressed or key_label.echo:
		return
	if key_label.keycode == KEY_F1:
		toggle()
		get_viewport().set_input_as_handled()
		return
	# ESC chỉ đóng menu khi menu ĐANG MỞ, và nuốt luôn phím đó.
	#
	# Không nuốt thì ESC vừa đóng menu vừa bật bảng tạm dừng phía sau — người
	# chơi bấm một lần mà nhận hai kết quả.
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

	# NHỚ trạng thái cũ rồi mới đổi, chứ không đặt cứng false lúc đóng.
	#
	# F1 bấm được cả khi đang ở bảng tạm dừng hoặc bảng tổng kết — hai thứ đó
	# cũng đang giữ get_tree().paused = true. Đóng menu mà đặt cứng false thì
	# game chạy tiếp phía sau một bảng lẽ value vẫn đang dừng.
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


func close() -> void:
	if not is_open:
		return
	is_open = false
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
	# Nở đều hai phía quanh điểm neo. PRESET_CENTER một mình chỉ ghim GÓC
	# TRÊN-TRÁI vào tâm màn hình, nên frame sẽ lệch xuống dưới-phải đúng nửa
	# kích thước của nó.
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

	var tieu := Label.new()
	tieu.text = "HƯỚNG DẪN"
	tieu.add_theme_font_size_override("font_size", 26)
	tieu.add_theme_color_override("font_color", COLOR_TITLE)
	col.add_child(tieu)

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
	var day := Control.new()
	day.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(day)

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
	# Cuộn DỌC thôi. Cho cuộn ngang thì một tấm ảnh rộng quá sẽ kéo cả trang
	# lệch sang phải, và chữ bị đẩy value ngoài frame nhìn.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_content_col = VBoxContainer.new()
	_content_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_col.add_theme_constant_override("separation", 12)
	scroll.add_child(_content_col)
	return col


# -------------------------------------------------------------- nội build ---

func _select_section(i: int) -> void:
	if i < 0 or i >= GuideContent.SECTIONS.size():
		return
	_current_section = i

	for k in _buttons.size():
		# Đánh dấu mục đang xem bằng ĐỘ SÁNG chứ không đổi StyleBox: nút gỗ
		# lấy từ theme chung, tự vẽ một style riêng cho trạng thái chọn thì
		# đổi theme một cái là cái nút này lạc lõng ngay.
		_buttons[k].modulate = Color(1.25, 1.15, 1.0) if k == i else Color.WHITE

	var entry: Dictionary = GuideContent.SECTIONS[i]
	_lbl_section.text = String(entry["name"]).to_upper()

	for c in _content_col.get_children():
		c.queue_free()
	for khoi in entry["khoi"]:
		_build_block(khoi as Dictionary)


func _build_block(khoi: Dictionary) -> void:
	if khoi.has("h"):
		_content_col.add_child(_small_title(String(khoi["h"])))
	elif khoi.has("p"):
		_content_col.add_child(_paragraph(String(khoi["p"])))
	elif khoi.has("key_label"):
		_content_col.add_child(_key_hint(khoi["key_label"]))
	elif khoi.has("img"):
		_add_image(String(khoi["img"]), String(khoi.get("chu", "")))
	elif khoi.has("cong_thuc"):
		_add_recipe(String(khoi["cong_thuc"]))
	elif khoi.has("moc_hang"):
		_add_grade_marks()


func _small_title(chu: String) -> Control:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", COLOR_TITLE)
	return l


func _paragraph(chu: String) -> Control:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", 18)
	t.add_theme_font_size_override("bold_font_size", 18)
	t.add_theme_color_override("default_color", COLOR_TEXT)
	# Bề rộng tối thiểu là BẮT BUỘC với mọi nhãn có xuống dòng tự động: không
	# có nó thì Godot tính chiều cao ở bề rộng 0 — mỗi chữ một dòng — và value
	# một chiều cao khổng lồ kéo cả trang dài value vô tận.
	t.custom_minimum_size = Vector2(FRAME_WIDTH - LEFT_COL_WIDTH - 160.0, 0)
	t.text = chu
	return t


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
##
## Ảnh minh hoạ là thứ bổ sung dần: khai sẵn đường dẫn trong bảng nội build rồi
## chụp ảnh sau lúc nào cũng được, và trang hướng dẫn vẫn đọc được ngay từ bây
## giờ. Nếu để một ô trống hay một dòng "thiếu ảnh" thì trang trông như hỏng.
func _add_image(duong_dan: String, chu: String) -> void:
	if not ResourceLoader.exists(duong_dan):
		return
	var texture := load(duong_dan) as Texture2D
	if texture == null:
		return

	var img := TextureRect.new()
	img.texture = texture
	img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(0, 0)
	_content_col.add_child(img)

	if not chu.is_empty():
		var l := Label.new()
		l.text = chu
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", COLOR_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_col.add_child(l)


# ------------------------------------------------------ bảng tự sinh ---

## Bảng công thức dựng THẲNG từ DanhMuc, không gõ tay.
##
## Đây là điểm đáng nói nhất của cả menu này: trang hướng dẫn không thể nói sai
## được, vì nó đọc đúng cái bảng mà luật chơi đang dùng. Món bị khoá thì tự
## biến mất khỏi trang; thêm một công thức là trang tự có thêm một dòng.
func _add_recipe(kind: String) -> void:
	var table_: Dictionary = {}
	match kind:
		"ban": table_ = ItemCatalog.TABLE_RECIPES
		# (Đã bỏ) "noi": CONG_THUC_NOI. Bảng công thức nồi không còn tồn tại
		# — công thức nấu canh giờ nằm trong CONG_THUC_BAN như mọi món khác,
		# nên trang hướng dẫn tự có nó ở mục "ban".
		"lo": table_ = ItemCatalog.OVEN_RECIPES
		_: return

	for key_ in table_:
		var value := String(table_[key_])
		if ItemCatalog.is_locked(value):
			continue
		_content_col.add_child(_recipe_row(String(key_).split("+"), value))


func _recipe_row(nguyen_lieu: PackedStringArray, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	for i in nguyen_lieu.size():
		if i > 0:
			row.add_child(_marker("+"))
		row.add_child(_item_cells(String(nguyen_lieu[i])))

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
##
## Lùi về CHỮ chứ không bỏ trống: bộ ảnh chưa đủ cho mọi id, mà một công thức
## thiếu mất một ô thì đọc thành công thức khác.
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


func _marker(chu: String) -> Control:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", COLOR_DIM)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## Bảng mốc xếp hạng, cũng đọc thẳng từ GameData.
func _add_grade_marks() -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	var mark: Dictionary = GameData.DEFAULT_THRESHOLDS
	var color := {
		"S": Color("f2c230"), "A": Color("e8823f"),
		"B": Color("e27ba0"), "C": Color("4f9d5d"),
	}
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 6)
	for row in GameData.RANK_ORDER:
		var a := Label.new()
		a.text = String(row)
		a.add_theme_font_size_override("font_size", 26)
		a.add_theme_color_override("font_color", color.get(row, COLOR_TEXT))
		a.custom_minimum_size = Vector2(120, 0)
		grid.add_child(a)

		var b := Label.new()
		b.text = "từ %d trở lên" % int(mark.get(row, 0))
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", COLOR_TEXT)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(b)
	_content_col.add_child(grid)


func _spacing(cao: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, cao)
	return c
