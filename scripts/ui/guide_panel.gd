extends CanvasLayer
## Hộp thoại trainer của màn hướng dẫn, nằm ở mép PHẢI ngay dưới panel thời gian.
##
## Bố cục lấy theo tấm ảnh mẫu người dùng gửi: frame chữ bên trái, ảnh nhân vật
## bên phải, dưới ảnh là một dải nhãn nhỏ. Đọc từ trái sang phải thì mắt gặp
## CHỮ trước rồi mới tới mặt người nói — đúng thứ tự cần, vì cái phải làm nằm
## empty chữ chứ không nằm ở cái mặt.
##
## Vì sao ở góc phải dưới đồng hồ: hai khối HUD kia đều đã có chủ — mép trái là
## bảng đơn hàng, đáy giữa là danh sách trạm. Quan trọng hơn, hộp này KHÔNG
## được đè lên danh sách trạm: nó bảo người chơi "bấm E ở cái Thớt", mà cái
## danh sách chữ E nằm ở đáy giữa — che mất là câu hướng dẫn tự phủ định chính
## nó.
##
## Toàn bộ hình thức lấy từ theme cozy có sẵn (ui/theme/menu_theme.tres): panel
## gỗ, nút gỗ, màu chữ nâu. Không dựng StyleBox mới ở đây — đổi theme một lần
## là cả game đổi theo, còn tự vẽ riêng thì hộp này sẽ lạc lõng dần mỗi lần
## theme được chỉnh.

signal start_choice(dong_y: bool)

const THEME := "res://ui/theme/menu_theme.tres"
const TRAINER_IMAGE := "res://assets/ui/avatars/trainer_avt1.png"
const IMAGE_FRAME := "res://assets/ui/megacozy/Frames/EmptyWoodenFrame.png"
const RIBBON_LABEL := "res://assets/ui/megacozy/Labels/Label1_green.png"

const MARGIN := 28.0
const WIDTH := 560.0
## Panel thời gian chiếm y 28…160, chừa 20 px rồi tới hộp này.
const TOP := 180.0

const IMAGE_SIZE := 116.0
const SLIDE_SECONDS := 0.35

var _box: PanelContainer
var _lbl_step: Label
var _lbl_line: RichTextLabel
var _button_row: HBoxContainer
var _shown := false
var _old_mouse_mode := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 6   # trên bảng đơn hàng và panel thời gian (layer 5)
	_build_ui()
	# Bắt đầu ở ngoài mép phải; ai muốn hiện thì gọi open().
	_box.position.x = _x_hidden()


# ------------------------------------------------------------ dựng hình ---

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_box = PanelContainer.new()
	# Neo góc trên-trái (mọi anchor = 0) rồi tự gán size và position. Không
	# dùng preset neo phải rồi tween offset: neo tính lại rect mỗi lần bố trí
	# nên nó đánh nhau với tween, và cái rect phình thêm sau mỗi frame hình.
	_box.size = Vector2(WIDTH, 0.0)
	_box.position = Vector2(_x_hidden(), TOP)
	_box.mouse_filter = Control.MOUSE_FILTER_STOP   # nút bên empty cần bấm được
	if ResourceLoader.exists(THEME):
		_box.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s — hộp hướng dẫn sẽ dùng giao diện mặc định." % THEME)
	root.add_child(_box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)

	# --- cột chữ ---
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)

	_lbl_step = Label.new()
	_lbl_step.add_theme_font_size_override("font_size", 15)
	_lbl_step.add_theme_color_override("font_color", Color(0.52, 0.38, 0.22))
	col.add_child(_lbl_step)

	_lbl_line = RichTextLabel.new()
	_lbl_line.bbcode_enabled = true
	_lbl_line.fit_content = true
	_lbl_line.scroll_active = false
	_lbl_line.add_theme_font_size_override("normal_font_size", 21)
	_lbl_line.add_theme_font_size_override("bold_font_size", 21)
	_lbl_line.add_theme_color_override("default_color", Color(0.29, 0.153, 0.071))
	# BẮT BUỘC có bề rộng tối thiểu.
	#
	# RichTextLabel/Label có xuống dòng tự động mà KHÔNG được cho bề rộng thì
	# Godot tính chiều cao tối thiểu ở bề rộng 0 — tức mỗi chữ một dòng — và slide_out
	# một chiều cao khổng lồ. Đây đúng là cái bẫy đã làm hỏng bảng info màn
	# chọn nhân vật (một Label đòi 5396 px chiều cao).
	_lbl_line.custom_minimum_size = Vector2(WIDTH - IMAGE_SIZE - 130.0, 92.0)
	col.add_child(_lbl_line)

	_button_row = HBoxContainer.new()
	_button_row.add_theme_constant_override("separation", 12)
	_button_row.visible = false
	col.add_child(_button_row)

	# --- cột ảnh trainer ---
	var image_col := VBoxContainer.new()
	image_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image_col.add_theme_constant_override("separation", 4)
	row.add_child(image_col)

	# Khung gỗ làm NỀN, ảnh nằm đè lên trên — không dùng NinePatch bọc ngoài vì
	# frame này là ảnh có tỉ lệ cố định, kéo giãn sẽ méo phần vân gỗ.
	var image_cell := Control.new()
	image_cell.custom_minimum_size = Vector2(IMAGE_SIZE, IMAGE_SIZE)
	image_col.add_child(image_cell)

	if ResourceLoader.exists(IMAGE_FRAME):
		var frame := TextureRect.new()
		frame.texture = load(IMAGE_FRAME)
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image_cell.add_child(frame)

	var img := TextureRect.new()
	if ResourceLoader.exists(TRAINER_IMAGE):
		img.texture = load(TRAINER_IMAGE)
	else:
		push_warning("Thiếu ảnh trainer %s" % TRAINER_IMAGE)
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# GIỮ TỈ LỆ, canh giữa: ảnh trainer gần vuông và đã tự gọn empty frame tròn
	# xanh của nó, nên không cần cắt. Dùng COVERED thì cắt mất hai bên vai.
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_cell.add_child(img)

	# --- dải nhãn dưới ảnh ---
	var label := Control.new()
	label.custom_minimum_size = Vector2(IMAGE_SIZE, 26.0)
	image_col.add_child(label)

	if ResourceLoader.exists(RIBBON_LABEL):
		var vien := NinePatchRect.new()
		vien.texture = load(RIBBON_LABEL)
		# Ảnh gốc 34×11: chừa 6 px hai đầu làm mép, phần giữa kéo dài slide_out.
		vien.patch_margin_left = 6
		vien.patch_margin_right = 6
		vien.patch_margin_top = 3
		vien.patch_margin_bottom = 3
		vien.set_anchors_preset(Control.PRESET_FULL_RECT)
		vien.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_child(vien)

	var label_text := Label.new()
	label_text.text = "HƯỚNG DẪN"
	label_text.add_theme_font_size_override("font_size", 14)
	label_text.add_theme_color_override("font_color", Color(1, 0.98, 0.92))
	label_text.add_theme_color_override("font_outline_color", Color(0.16, 0.32, 0.16))
	label_text.add_theme_constant_override("outline_size", 5)
	label_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(label_text)


# ------------------------------------------------------------- slide_out / vào ---

func _x_hidden() -> float:
	return 1920.0 + 20.0


func _x_shown() -> float:
	return 1920.0 - MARGIN - WIDTH


func open() -> void:
	if _shown:
		return
	_shown = true
	_slide_to(_x_shown())


func close() -> void:
	if not _shown:
		return
	_shown = false
	_slide_to(_x_hidden())


func _slide_to(dich: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_box, "position:x", dich, SLIDE_SECONDS)


# -------------------------------------------------------------- nội build ---

## Đặt nội build một bước. `num` và `tong` để hiện "BƯỚC 3 / 10".
func set_step(loi: String, num: int, tong: int) -> void:
	_lbl_step.text = "BƯỚC %d / %d" % [num, tong]
	_lbl_line.text = loi
	_hide_buttons()


## Hiện hai nút lựa chọn. Bấm xong phát start_choice(true/false).
func ask(loi: String, chu_co: String, chu_khong: String) -> void:
	_lbl_step.text = "HƯỚNG DẪN"
	_lbl_line.text = loi
	_hide_buttons()

	var yes_text := Button.new()
	yes_text.text = chu_co
	yes_text.add_theme_font_size_override("font_size", 20)
	yes_text.pressed.connect(_on_choice.bind(true))
	_button_row.add_child(yes_text)

	var no_text := Button.new()
	no_text.text = chu_khong
	no_text.add_theme_font_size_override("font_size", 20)
	no_text.pressed.connect(_on_choice.bind(false))
	_button_row.add_child(no_text)

	_button_row.visible = true

	# Trả con trỏ chuột về cho người chơi rồi NHỚ lại chế độ cũ.
	#
	# Màn chơi khoá con trỏ (pause_menu đặt lại MOUSE_MODE_CAPTURED mỗi lần
	# thoát tạm dừng), mà chuột bị khoá thì hai cái nút này bấm không được.
	# Phải nhớ chế độ cũ chứ không đặt cứng CAPTURED lúc trả lại: nếu sau này
	# có màn nào chơi bằng chuột thì đặt cứng sẽ khoá mất chuột của màn đó.
	_old_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	yes_text.grab_focus()


func _on_choice(dong_y: bool) -> void:
	_hide_buttons()
	if _old_mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _old_mouse_mode
	start_choice.emit(dong_y)


func _hide_buttons() -> void:
	_button_row.visible = false
	for n in _button_row.get_children():
		n.queue_free()
