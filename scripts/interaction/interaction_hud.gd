extends CanvasLayer
## HUD danh sách tương tác + tâm ngắm cho góc nhìn thứ 3.
##
## Dựng bằng CODE chứ không phải file .tscn. Lý do: đây là bản nháp của cơ chế
## đang thử, còn phải đổi nhiều; để nó nằm gọn trong một file thì sửa nhanh và
## không phải mở đi mở lại trình chỉnh scene. Khi cơ chế chốt rồi thì tách ra
## .tscn và gắn theme chung của game — lúc đó xoá hàm _dung_giao_dien().
##
## Cách đọc HUD: mục ĐANG CHỌN có mũi tên ▸ và chữ sáng; các mục còn lại mờ.
## Người chơi bình thường chỉ cần liếc mục sáng rồi bấm E.

## Cỡ chữ tính theo VIEWPORT THIẾT KẾ 1920×1080, không phải theo cửa sổ.
##
## Game chạy stretch/mode = "canvas_items" với cửa sổ mặc định 1280×720, tức
## mọi thứ bị thu nhỏ còn 2/3. Cỡ chữ 14 đặt ở đây hiện ra chỉ ~9 px trên
## màn hình thật — đọc được ở chế độ toàn màn hình nhưng gần như mù ở cửa sổ.
## Nên mọi con số dưới đây đã nhân sẵn cho hệ số đó: chia 1.5 ra mới là cỡ
## người chơi cửa sổ thật sự nhìn thấy.
const SIZE_SELECTED := 30
const SIZE_DIM := 24
const SIZE_KEY := 18
## Cạnh ô ảnh kĩ năng, cũng tính theo viewport 1920×1080 (chia 1.5 ra cỡ thật).
const SIZE_SKILL_ICON := 96.0

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

const COLOR_SELECTED := Color(1, 1, 1)
const COLOR_DIM := Color(0.62, 0.66, 0.63)
const COLOR_KEY := Color(0.88, 0.45, 0.2)
## Thanh điều kiện kĩ năng: xanh lam lúc đang gom, vàng lúc đã đủ.
##
## Đổi MÀU chứ không chỉ đổi độ dài: thanh đầy và thanh gần đầy trông rất
## giống nhau khi liếc nhanh giữa lúc bận, mà khoảnh khắc "đủ điều kiện" là
## thứ người chơi đang chờ. Vàng cũng là màu của hạng S ở bảng kết quả, nên
## nó đã mang sẵn nghĩa "đạt" trong game này.
const COLOR_SKILL_WAIT := Color(0.42, 0.62, 0.85)
const COLOR_SKILL_READY := Color("f2c230")

var _frame: PanelContainer
var _column: VBoxContainer
var _crosshair: Panel
var _stamina_bar: ProgressBar
var _lbl_hands: Label
var _skill_icon: TextureRect
var _skill_material: ShaderMaterial
## Thanh + chữ theo dõi ĐIỀU KIỆN của kĩ năng chủ động ("3/5" → "SPACE").
var _skill_column: VBoxContainer
var _skill_bar: ProgressBar
var _skill_fill: StyleBoxFlat
var _skill_label: Label
var _table_frame: PanelContainer
var _table_column: VBoxContainer
var _lbl_table_temp: Label
var _notice_tween: Tween = null
## Bàn chế tạo mà bảng đang mô tả.
var _table: Workstation = null

## Đứng cách bàn bao xa thì bảng còn hiện.
##
## 4.5 rộng hơn hẳn tầm với (chạm mới tính) để bảng không nhấp nháy mỗi khi
## người chơi nhích ra nhích vào — thứ gây khó chịu hơn nhiều so với việc
## bảng nán lại thêm một hai bước chân.
@export var table_note_range := 4.5
## Neo bảng ở độ cao nào so với gốc bàn.
@export var table_note_height := 1.3
## Đẩy bảng sang phải bàn bao nhiêu pixel.
@export var table_note_margin := 46.0


func _ready() -> void:
	layer = 10
	_build_ui()
	GameData.view_mode_changed.connect(_on_view_changed)
	_on_view_changed(GameData.third_person_active)


func _build_ui() -> void:
	_frame = PanelContainer.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Neo giữa-dưới rồi tự đẩy lên: danh sách nằm ngay dưới nhân vật nên mắt
	# không phải rời khỏi chỗ đang thao tác để đọc.
	_frame.offset_left = -280.0
	_frame.offset_right = 280.0
	_frame.offset_top = -260.0
	_frame.offset_bottom = -50.0
	_frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.1, 0.09, 0.82)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(18)
	_frame.add_theme_stylebox_override("panel", bg)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 7)
	_frame.add_child(_column)
	_frame.hide()

	# Tâm ngắm: một chấm vuông nhỏ giữa màn hình, chỉ hiện ở góc nhìn thứ 3.
	_crosshair = Panel.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.custom_minimum_size = Vector2(6, 6)
	_crosshair.offset_left = -3.0
	_crosshair.offset_top = -3.0
	_crosshair.offset_right = 3.0
	_crosshair.offset_bottom = 3.0
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.85)
	style.set_corner_radius_all(3)
	_crosshair.add_theme_stylebox_override("panel", style)
	add_child(_crosshair)
	_crosshair.hide()
	_build_stamina_bar()
	_build_table_note()


## Thanh thể lực + dòng "đang cầm", neo ở góc dưới trái.
##
## Đặt DƯỚI TRÁI chứ không dưới giữa: danh sách tương tác đã chiếm chỗ giữa,
## và hai thứ chồng nhau thì lúc cần đọc gấp nhất lại là lúc không đọc được.
func _build_stamina_bar() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 28.0
	# Cao hơn bản trước để chừa chỗ cho ảnh kĩ năng ở trên cùng.
	#
	# 15/9/2026 nới thêm 40 px: dưới ảnh kĩ năng giờ có thanh theo dõi điều
	# kiện (10 px) và dòng chữ "3/5" (~24 px) cộng hai khoảng cách. Tính đủ:
	# ảnh 96 + thanh 10 + chữ 24 + "đang cầm" 24 + thể lực 16 + 4 khoảng
	# cách ≈ 188 px, nên 202 px của bản cũ vừa khít tới mức một lần đổi cỡ
	# chữ là tràn.
	box.offset_top = -270.0
	box.offset_right = 400.0
	box.offset_bottom = -28.0
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_build_skill_icon(box)

	_lbl_hands = Label.new()
	_lbl_hands.add_theme_color_override("font_color", COLOR_SELECTED)
	_lbl_hands.add_theme_font_size_override("font_size", SIZE_DIM)
	box.add_child(_lbl_hands)

	_stamina_bar = ProgressBar.new()
	_stamina_bar.custom_minimum_size = Vector2(0, 16)
	_stamina_bar.max_value = 1.0
	_stamina_bar.value = 1.0
	_stamina_bar.show_percentage = false
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stamina_bg := StyleBoxFlat.new()
	stamina_bg.bg_color = Color(0.09, 0.11, 0.10, 0.75)
	stamina_bg.set_corner_radius_all(5)
	var stamina_fill := StyleBoxFlat.new()
	stamina_fill.bg_color = COLOR_KEY
	stamina_fill.set_corner_radius_all(5)
	_stamina_bar.add_theme_stylebox_override("background", stamina_bg)
	_stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	box.add_child(_stamina_bar)


## Ảnh biểu tượng kĩ năng chủ động, nằm ngay trên thanh thể lực.
##
## Đặt cùng cột với thanh thể lực chứ không tìm một góc khác: cả hai đều là
## "tài nguyên của riêng nhân vật" và cả hai đều điều khiển bằng tay trái
## (Shift, Space). Gom vào một chỗ thì người chơi chỉ phải liếc một điểm.
##
## MỘT tấm ảnh + shader, chứ không phải hai file ảnh màu và xám.
## Lý do: hai file là hai thứ phải nhớ cập nhật cùng nhau, và với bảy nhân vật
## thì thành mười bốn file. Đổ xám bằng shader thì thêm nhân vật chỉ tốn đúng
## một file ảnh, và mức xám chỉnh được liên tục nếu sau này muốn làm hiệu ứng
## sáng dần lúc kĩ năng vừa đủ điều kiện.
func _build_skill_icon(box: VBoxContainer) -> void:
	_skill_icon = TextureRect.new()
	_skill_icon.custom_minimum_size = Vector2(SIZE_SKILL_ICON, SIZE_SKILL_ICON)
	_skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_skill_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ảnh gốc chỉ 64×64 mà hiển thị ở 96 — dùng lọc điểm ảnh thì viền răng
	# cưa, nên để mặc định (tuyến tính). Không đặt texture_filter ở đây.

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
// muc_xam = 0: ảnh gốc. = 1: xám và tối đi.
uniform float muc_xam : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Hệ số 0.299 / 0.587 / 0.114 là công thức độ sáng cảm nhận (luma) của
	// chuẩn ITU-R BT.601. Lấy trung bình cộng ba kênh thì màu vàng cam của
	// biểu tượng sẽ ra xám sáng gần bằng lúc đang bật — không phân biệt được.
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(g), muc_xam);
	// Tối thêm khi xám: chỉ khử màu thôi vẫn còn khá nổi trên nền tối.
	c.rgb *= mix(1.0, 0.5, muc_xam);
	COLOR = c * COLOR;
}
"""
	_skill_material = ShaderMaterial.new()
	_skill_material.shader = shader
	_skill_material.set_shader_parameter("muc_xam", 1.0)
	_skill_icon.material = _skill_material

	var path := GameData.skill_icon_path(str(GameData.selected_character))
	if ResourceLoader.exists(path):
		_skill_icon.texture = load(path)
	else:
		push_warning("Thiếu ảnh kĩ năng: %s" % path)

	# Ảnh + thanh + chữ gói trong một cột RIÊNG, rộng đúng bằng ảnh.
	#
	# Không thả thẳng vào `hop`: cột đó rộng 372 px cho dòng "đang cầm", nên
	# một ProgressBar bỏ vào sẽ kéo dài hết 372 và trông như thanh thể lực thứ
	# hai. Thanh này thuộc về CÁI ẢNH, nên nó phải rộng đúng bằng cái ảnh —
	# chỗ đứng đã nói nó đo cái gì, không cần thêm nhãn giải thích.
	_skill_column = VBoxContainer.new()
	_skill_column.custom_minimum_size = Vector2(SIZE_SKILL_ICON, 0)
	_skill_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_skill_column.add_theme_constant_override("separation", 3)
	_skill_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_skill_column)
	_skill_column.add_child(_skill_icon)

	_skill_bar = ProgressBar.new()
	_skill_bar.custom_minimum_size = Vector2(SIZE_SKILL_ICON, 10)
	_skill_bar.max_value = 1.0
	_skill_bar.value = 0.0
	_skill_bar.show_percentage = false
	_skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skill_bg := StyleBoxFlat.new()
	skill_bg.bg_color = Color(0.09, 0.11, 0.10, 0.75)
	skill_bg.set_corner_radius_all(4)
	_skill_fill = StyleBoxFlat.new()
	_skill_fill.bg_color = COLOR_SKILL_WAIT
	_skill_fill.set_corner_radius_all(4)
	_skill_bar.add_theme_stylebox_override("background", skill_bg)
	_skill_bar.add_theme_stylebox_override("fill", _skill_fill)
	_skill_column.add_child(_skill_bar)

	_skill_label = Label.new()
	_skill_label.add_theme_font_size_override("font_size", SIZE_KEY)
	_skill_label.add_theme_color_override("font_color", COLOR_SKILL_WAIT)
	_skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_column.add_child(_skill_label)


## Nối với node quản lý kĩ năng. level_base gọi sau khi tạo cả hai.
func listen_to_skills(skills: Node) -> void:
	skills.ready_changed.connect(_on_skill_ready)
	skills.progress_changed.connect(_on_skill_progress)


## Vẽ lại thanh theo dõi điều kiện.
##
## HUD chỉ NHẬN hai con số đã tính sẵn; nó không biết "5 đơn hoàn hảo" nghĩa
## là gì và cũng không đếm gì cả. Luật đếm nằm trọn trong quan_ly_ki_nang —
## nhờ vậy thêm một kiểu điều kiện mới (đếm món nấu, đếm giây) không phải sửa
## một dòng nào ở đây.
func _on_skill_progress(ratio: float, text: String) -> void:
	if _skill_bar == null:
		return
	# Chữ rỗng = nhân vật này chưa có kĩ năng chủ động. Ẩn cả thanh lẫn chữ,
	# nhưng GIỮ cái ảnh xám: ảnh nói "có một ô kĩ năng ở đây", còn một thanh
	# tiến trình đứng im ở 0 suốt màn thì nói dối rằng người chơi đang không
	# tiến bộ.
	var co := not text.is_empty()
	_skill_bar.visible = co
	_skill_label.visible = co
	if not co:
		return

	_skill_bar.value = ratio
	_skill_label.text = text
	var enough := ratio >= 1.0
	_skill_fill.bg_color = COLOR_SKILL_READY if enough else COLOR_SKILL_WAIT
	_skill_label.add_theme_color_override("font_color",
		COLOR_SKILL_READY if enough else COLOR_SKILL_WAIT)


func _on_skill_ready(available: bool) -> void:
	if _skill_material == null:
		return
	# Xám khi chưa dùng được, màu khi đã dùng được. Không ẩn hẳn ảnh lúc chưa
	# dùng được: người chơi cần biết mình CÓ một kĩ năng đang chờ, chứ không
	# phải bất ngờ thấy một biểu tượng lạ hiện ra giữa màn.
	_skill_material.set_shader_parameter("muc_xam", 0.0 if available else 1.0)
	_skill_icon.modulate.a = 1.0 if available else 0.75


## Bảng "trên bàn chế tạo đang có gì", BÁM THEO cái bàn trong không gian.
##
## Vì sao không neo cố định ở góc màn hình như bản trước: bếp có nhiều mặt
## bàn, và một bảng ở góc thì không nói được nó đang tả cái bàn nào. Chiếu
## vị trí cái bàn ra toạ độ màn hình rồi đặt bảng ngay bên phải nó thì câu
## hỏi đó không tồn tại — bảng ở cạnh cái gì là đang nói về cái đó.
##
## Bảng chỉ hiện khi người chơi đứng trong tầm, và tự ẩn khi đi ra xa: nó là
## thông tin của MỘT thao tác đang làm dở, không phải bảng điều khiển thường
## trực.
func _build_table_note() -> void:
	_table_frame = PanelContainer.new()
	_table_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bảng tự co theo nội dung, và ta tự đặt vị trí mỗi frame nên không dùng
	# anchor preset nào cả.
	_table_frame.custom_minimum_size = Vector2(210, 0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.1, 0.09, 0.82)
	bg.border_color = Color(COLOR_KEY.r, COLOR_KEY.g, COLOR_KEY.b, 0.5)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(10)
	_table_frame.add_theme_stylebox_override("panel", bg)
	add_child(_table_frame)

	_table_column = VBoxContainer.new()
	_table_column.add_theme_constant_override("separation", 4)
	_table_frame.add_child(_table_column)
	_table_frame.hide()

	# Dòng thông báo ngắn (nấu xong / nấu hỏng).
	_lbl_table_temp = Label.new()
	_lbl_table_temp.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lbl_table_temp.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lbl_table_temp.offset_top = 92.0
	_lbl_table_temp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_table_temp.add_theme_font_size_override("font_size", SIZE_SELECTED)
	_lbl_table_temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lbl_table_temp)
	_lbl_table_temp.hide()


## Đặt bảng cạnh phải cái bàn, và ẩn đi khi người chơi đi xa.
func _follow_table() -> void:
	if _table_frame == null or _table == null or _character == null:
		return
	if _table.contents.is_empty() \
			or _character.global_position.distance_to(_table.global_position) > table_note_range:
		_table_frame.hide()
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var point := _table.global_position + Vector3(0.0, table_note_height, 0.0)
	# Bàn nằm sau lưng camera thì unproject trả về toạ độ vô nghĩa.
	if cam.is_position_behind(point):
		_table_frame.hide()
		return

	_table_frame.show()
	var screen := cam.unproject_position(point)
	# Kẹp trong khung hình để bảng không trôi ra ngoài khi bàn ở sát mép.
	var co := _table_frame.size
	var area := get_viewport().get_visible_rect().size
	_table_frame.position = Vector2(
		clampf(screen.x + table_note_margin, 8.0, area.x - co.x - 8.0),
		clampf(screen.y - co.y * 0.5, 8.0, area.y - co.y - 8.0))


## (Đã bỏ 17/9/2026) Thanh tiến trình chung neo giữa-trên màn hình.
##
## Một thanh cho bốn trạm hỏng ngay khi hai trạm cùng chạy — mà bật bếp rồi
## chạy sang thớt đã là hai trạm, tức cách chơi bình thường chứ không phải
## trường hợp hiếm. Thanh chỉ vẽ được một giá trị nên nó nhảy qua nhảy lại,
## và dòng chữ "Đang nấu — Bep 1" đổi theo; người chơi không đọc được gì.
##
## Thay bằng thanh RIÊNG cho từng trạm, nổi ngay trên trạm đó — xem
## `scripts/ui/station_bars.gd`. HUD này không còn vẽ tiến trình nữa.


## Nối vào hệ bếp. Giờ chỉ còn nghe MỘT tín hiệu: câu báo "nấu xong / nấu
## hỏng" ở giữa màn hình. Phần thanh tiến trình đã chuyển sang ThanhTram.
##
## Vì sao câu báo Ở LẠI đây chứ không đi theo: nó dùng chung `_lbl_ban_tam`
## với câu báo ghép hụt ở bàn chế tạo. Một chỗ hiện duy nhất cho mọi nguồn
## tin — hai câu báo cùng lúc ở hai chỗ thì người chơi đọc câu nào cũng lỡ
## câu kia.
func listen_to_cooking(system: Node) -> void:
	system.cook_finished.connect(_on_cook_finished)


func _on_cook_finished(_cooking: Node, dish: String, success: bool) -> void:
	show_notice(("Nấu xong: " + ItemCatalog.display_name(dish)) if success else "Nấu hỏng!",
		success)


## Câu báo ngắn giữa màn hình. Dùng chung cho mọi nguồn tin: bếp nấu xong, bàn
## chế tạo ghép được hay ghép hụt.
##
## Một chỗ hiện duy nhất chứ không mỗi hệ một dòng chữ riêng: hai câu báo cùng
## lúc ở hai chỗ khác nhau thì người chơi đọc câu nào cũng lỡ câu kia, mà trong
## một game 7 phút thì họ chỉ liếc được đúng một lần.
func show_notice(text: String, good: bool) -> void:
	_lbl_table_temp.text = text
	_lbl_table_temp.modulate = Color(0.7, 0.95, 0.7) if good \
		else Color(1.0, 0.5, 0.45)
	_lbl_table_temp.show()
	# Tự tắt sau 2 giây: thông báo tồn tại để BÁO một sự kiện, không phải để
	# ở lại làm nền. Để mãi thì lần sau người chơi không phân biệt được đó là
	# tin mới hay tin cũ.
	#
	# Giữ tween vào một biến để cú báo SAU huỷ được cú báo trước: hai lần báo
	# cách nhau một giây thì cái hẹn tắt của lần đầu sẽ tắt luôn câu thứ hai
	# khi nó mới hiện được một giây.
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.0)
	_notice_tween.tween_callback(_lbl_table_temp.hide)


## Nối vào tín hiệu của bộ chọn. level_base.gd gọi hàm này sau khi tạo cả hai.
func listen_to_picker(picker: TargetPicker) -> void:
	picker.candidates_changed.connect(_redraw)


func listen_to_hands(hands: Node) -> void:
	hands.held_name_changed.connect(_on_held_changed)
	if hands.has_signal("notice"):
		hands.notice.connect(show_notice)


## Theo dõi thanh thể lực của nhân vật.
##
## HUD tự HỎI mỗi frame thay vì bắt nhân vật phát tín hiệu mỗi lần thanh
## đổi: thanh này đổi liên tục từng frame, phát tín hiệu cho một giá trị
## như vậy chỉ tốn thêm chi phí mà không được gì.
func follow_character(character: Node) -> void:
	_character = character
	set_process(true)


var _character: Node = null


func _process(_delta: float) -> void:
	if _character == null or _stamina_bar == null:
		return
	_stamina_bar.value = _character.ti_le_stamina()
	# Thanh đầy và không chạy thì mờ đi cho đỡ chiếm mắt; chỉ sáng lên khi
	# đang thật sự tiêu hoặc chưa hồi xong.
	var needs_attention: bool = _character.dang_nuoc_rut() or _stamina_bar.value < 0.999
	_stamina_bar.modulate.a = 1.0 if needs_attention else 0.35
	_follow_table()


## Nghe các bàn có chứa đồ. level_base gọi cho từng bàn chế tạo.
## Bảng chỉ theo dõi BÀN CHẾ TẠO. Thớt, bếp và lò giờ đã bày model thật lên
## mặt bàn nên tự nói được trạng thái của mình; nhân đôi thông tin đó ra một
## bảng chữ nữa chỉ làm màn hình đông thêm.
func listen_to_table(table: Workstation) -> void:
	_table = table
	table.contents_changed.connect(_redraw_table)


func _on_held_changed(item_name: String) -> void:
	# Nhắc phím Q ngay trên dòng "đang cầm" chứ không nhét vào bảng hướng
	# dẫn riêng: nhắc đúng lúc người chơi CÓ THỂ dùng nó thì họ đọc, còn
	# một bảng phím tắt mở ra lúc đầu màn thì không ai nhớ.
	_lbl_hands.text = "Đang cầm: %s   (Q: bỏ xuống)" % item_name if not item_name.is_empty() else ""


func _redraw_table(table: Workstation) -> void:
	for child in _table_column.get_children():
		child.queue_free()
	if table.contents.is_empty():
		_table_frame.hide()
		return
	_table_frame.show()

	var title := Label.new()
	title.text = table.display_name
	title.add_theme_color_override("font_color", COLOR_KEY)
	title.add_theme_font_size_override("font_size", SIZE_KEY)
	_table_column.add_child(title)

	for item_name in table.contents:
		_table_column.add_child(_build_icon_row(str(item_name)))

	# Nhắc lối thoát ngay trên cái bảng liệt kê nguyên liệu, vì đó đúng là chỗ
	# người chơi đang nhìn lúc nhận ra mình bỏ nhầm. Nhắc ở bảng phím tắt đầu
	# màn thì tới lúc cần chẳng ai nhớ.
	var lift := Label.new()
	lift.text = "E (tay không): lấy lại thứ vừa bỏ"
	lift.add_theme_color_override("font_color", COLOR_KEY)
	lift.add_theme_font_size_override("font_size", SIZE_KEY)
	_table_column.add_child(lift)


## Một dòng: ảnh nhỏ + tên. Có ảnh thì người chơi đối chiếu được ngay với
## bảng chọn ở tủ lạnh và với vé đơn hàng, cùng một hình cho cùng một thứ.
func _build_icon_row(id: String) -> Control:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 8)

	var path := ItemCatalog.icon_path(id)
	if ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.texture = load(path)
		icon.custom_minimum_size = Vector2(38, 38)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row_box.add_child(icon)

	var label := Label.new()
	label.text = ItemCatalog.display_name(id)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_SELECTED)
	label.add_theme_font_size_override("font_size", SIZE_DIM)
	row_box.add_child(label)
	return row_box


func _on_view_changed(is_third_person: bool) -> void:
	_crosshair.visible = is_third_person


func _redraw(candidates: Array, selected_index: int) -> void:
	for child in _column.get_children():
		child.queue_free()

	if candidates.is_empty():
		_frame.hide()
		return
	_frame.show()

	for i in candidates.size():
		var row := Label.new()
		var selected := i == selected_index
		row.text = ("▸ " if selected else "   ") + str(candidates[i]["label"])
		row.add_theme_color_override("font_color", COLOR_SELECTED if selected else COLOR_DIM)
		row.add_theme_font_size_override("font_size", SIZE_SELECTED if selected else SIZE_DIM)
		_column.add_child(row)

	# Chỉ nhắc phím Tab khi thật sự có nhiều hơn một lựa chọn. Nhắc thừa thì
	# người chơi tưởng lúc nào cũng phải bấm Tab, mà đó là điều mình muốn
	# tránh nhất.
	var hint := Label.new()
	hint.add_theme_color_override("font_color", COLOR_KEY)
	hint.add_theme_font_size_override("font_size", SIZE_KEY)
	if candidates.size() > 1:
		hint.text = "E: chọn     Tab: đổi mục tiêu"
	else:
		hint.text = "E: chọn"
	_column.add_child(hint)
