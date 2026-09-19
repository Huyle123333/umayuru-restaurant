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
const CO_CHON := 30
const CO_MO := 24
const CO_PHIM := 18
## Cạnh ô ảnh kĩ năng, cũng tính theo viewport 1920×1080 (chia 1.5 ra cỡ thật).
const CO_ANH_KI_NANG := 96.0

const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")

const MAU_CHON := Color(1, 1, 1)
const MAU_MO := Color(0.62, 0.66, 0.63)
const MAU_PHIM := Color(0.88, 0.45, 0.2)
## Thanh điều kiện kĩ năng: xanh lam lúc đang gom, vàng lúc đã đủ.
##
## Đổi MÀU chứ không chỉ đổi độ dài: thanh đầy và thanh gần đầy trông rất
## giống nhau khi liếc nhanh giữa lúc bận, mà khoảnh khắc "đủ điều kiện" là
## thứ người chơi đang chờ. Vàng cũng là màu của hạng S ở bảng kết quả, nên
## nó đã mang sẵn nghĩa "đạt" trong game này.
const MAU_KN_CHO := Color(0.42, 0.62, 0.85)
const MAU_KN_DU := Color("f2c230")

var _khung: PanelContainer
var _cot: VBoxContainer
var _tam_ngam: Panel
var _thanh_suc: ProgressBar
var _lbl_tay: Label
var _anh_ki_nang: TextureRect
var _vlieu_ki_nang: ShaderMaterial
## Thanh + chữ theo dõi ĐIỀU KIỆN của kĩ năng chủ động ("3/5" → "SPACE").
var _cot_ki_nang: VBoxContainer
var _thanh_ki_nang: ProgressBar
var _day_ki_nang: StyleBoxFlat
var _lbl_ki_nang: Label
var _khung_ban: PanelContainer
var _cot_ban: VBoxContainer
var _lbl_ban_tam: Label
var _tween_bao: Tween = null
## Bàn chế tạo mà bảng đang mô tả.
var _ban: TramTuongTac = null

## Đứng cách bàn bao xa thì bảng còn hiện.
##
## 4.5 rộng hơn hẳn tầm với (chạm mới tính) để bảng không nhấp nháy mỗi khi
## người chơi nhích ra nhích vào — thứ gây khó chịu hơn nhiều so với việc
## bảng nán lại thêm một hai bước chân.
@export var tam_hien_bang := 4.5
## Neo bảng ở độ cao nào so với gốc bàn.
@export var cao_neo_bang := 1.3
## Đẩy bảng sang phải bàn bao nhiêu pixel.
@export var le_ngang_bang := 46.0


func _ready() -> void:
	layer = 10
	_dung_giao_dien()
	GameData.view_mode_changed.connect(_doi_goc_nhin)
	_doi_goc_nhin(GameData.third_person_active)


func _dung_giao_dien() -> void:
	_khung = PanelContainer.new()
	_khung.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Neo giữa-dưới rồi tự đẩy lên: danh sách nằm ngay dưới nhân vật nên mắt
	# không phải rời khỏi chỗ đang thao tác để đọc.
	_khung.offset_left = -280.0
	_khung.offset_right = 280.0
	_khung.offset_top = -260.0
	_khung.offset_bottom = -50.0
	_khung.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_khung.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_khung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_khung)

	var nen := StyleBoxFlat.new()
	nen.bg_color = Color(0.07, 0.1, 0.09, 0.82)
	nen.set_corner_radius_all(6)
	nen.set_content_margin_all(18)
	_khung.add_theme_stylebox_override("panel", nen)

	_cot = VBoxContainer.new()
	_cot.add_theme_constant_override("separation", 7)
	_khung.add_child(_cot)
	_khung.hide()

	# Tâm ngắm: một chấm vuông nhỏ giữa màn hình, chỉ hiện ở góc nhìn thứ 3.
	_tam_ngam = Panel.new()
	_tam_ngam.set_anchors_preset(Control.PRESET_CENTER)
	_tam_ngam.custom_minimum_size = Vector2(6, 6)
	_tam_ngam.offset_left = -3.0
	_tam_ngam.offset_top = -3.0
	_tam_ngam.offset_right = 3.0
	_tam_ngam.offset_bottom = 3.0
	_tam_ngam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kieu := StyleBoxFlat.new()
	kieu.bg_color = Color(1, 1, 1, 0.85)
	kieu.set_corner_radius_all(3)
	_tam_ngam.add_theme_stylebox_override("panel", kieu)
	add_child(_tam_ngam)
	_tam_ngam.hide()
	_dung_thanh_suc()
	_dung_ghi_chu_ban()


## Thanh thể lực + dòng "đang cầm", neo ở góc dưới trái.
##
## Đặt DƯỚI TRÁI chứ không dưới giữa: danh sách tương tác đã chiếm chỗ giữa,
## và hai thứ chồng nhau thì lúc cần đọc gấp nhất lại là lúc không đọc được.
func _dung_thanh_suc() -> void:
	var hop := VBoxContainer.new()
	hop.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hop.offset_left = 28.0
	# Cao hơn bản trước để chừa chỗ cho ảnh kĩ năng ở trên cùng.
	#
	# 15/9/2026 nới thêm 40 px: dưới ảnh kĩ năng giờ có thanh theo dõi điều
	# kiện (10 px) và dòng chữ "3/5" (~24 px) cộng hai khoảng cách. Tính đủ:
	# ảnh 96 + thanh 10 + chữ 24 + "đang cầm" 24 + thể lực 16 + 4 khoảng
	# cách ≈ 188 px, nên 202 px của bản cũ vừa khít tới mức một lần đổi cỡ
	# chữ là tràn.
	hop.offset_top = -270.0
	hop.offset_right = 400.0
	hop.offset_bottom = -28.0
	hop.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hop.add_theme_constant_override("separation", 6)
	hop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hop)

	_dung_anh_ki_nang(hop)

	_lbl_tay = Label.new()
	_lbl_tay.add_theme_color_override("font_color", MAU_CHON)
	_lbl_tay.add_theme_font_size_override("font_size", CO_MO)
	hop.add_child(_lbl_tay)

	_thanh_suc = ProgressBar.new()
	_thanh_suc.custom_minimum_size = Vector2(0, 16)
	_thanh_suc.max_value = 1.0
	_thanh_suc.value = 1.0
	_thanh_suc.show_percentage = false
	_thanh_suc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nen_suc := StyleBoxFlat.new()
	nen_suc.bg_color = Color(0.09, 0.11, 0.10, 0.75)
	nen_suc.set_corner_radius_all(5)
	var day_suc := StyleBoxFlat.new()
	day_suc.bg_color = MAU_PHIM
	day_suc.set_corner_radius_all(5)
	_thanh_suc.add_theme_stylebox_override("background", nen_suc)
	_thanh_suc.add_theme_stylebox_override("fill", day_suc)
	hop.add_child(_thanh_suc)


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
func _dung_anh_ki_nang(hop: VBoxContainer) -> void:
	_anh_ki_nang = TextureRect.new()
	_anh_ki_nang.custom_minimum_size = Vector2(CO_ANH_KI_NANG, CO_ANH_KI_NANG)
	_anh_ki_nang.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_anh_ki_nang.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anh_ki_nang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ảnh gốc chỉ 64×64 mà hiển thị ở 96 — dùng lọc điểm ảnh thì viền răng
	# cưa, nên để mặc định (tuyến tính). Không đặt texture_filter ở đây.

	var sh := Shader.new()
	sh.code = """
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
	_vlieu_ki_nang = ShaderMaterial.new()
	_vlieu_ki_nang.shader = sh
	_vlieu_ki_nang.set_shader_parameter("muc_xam", 1.0)
	_anh_ki_nang.material = _vlieu_ki_nang

	var duong_dan := GameData.duong_dan_anh_ki_nang(str(GameData.selected_character))
	if ResourceLoader.exists(duong_dan):
		_anh_ki_nang.texture = load(duong_dan)
	else:
		push_warning("Thiếu ảnh kĩ năng: %s" % duong_dan)

	# Ảnh + thanh + chữ gói trong một cột RIÊNG, rộng đúng bằng ảnh.
	#
	# Không thả thẳng vào `hop`: cột đó rộng 372 px cho dòng "đang cầm", nên
	# một ProgressBar bỏ vào sẽ kéo dài hết 372 và trông như thanh thể lực thứ
	# hai. Thanh này thuộc về CÁI ẢNH, nên nó phải rộng đúng bằng cái ảnh —
	# chỗ đứng đã nói nó đo cái gì, không cần thêm nhãn giải thích.
	_cot_ki_nang = VBoxContainer.new()
	_cot_ki_nang.custom_minimum_size = Vector2(CO_ANH_KI_NANG, 0)
	_cot_ki_nang.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_cot_ki_nang.add_theme_constant_override("separation", 3)
	_cot_ki_nang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hop.add_child(_cot_ki_nang)
	_cot_ki_nang.add_child(_anh_ki_nang)

	_thanh_ki_nang = ProgressBar.new()
	_thanh_ki_nang.custom_minimum_size = Vector2(CO_ANH_KI_NANG, 10)
	_thanh_ki_nang.max_value = 1.0
	_thanh_ki_nang.value = 0.0
	_thanh_ki_nang.show_percentage = false
	_thanh_ki_nang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nen_kn := StyleBoxFlat.new()
	nen_kn.bg_color = Color(0.09, 0.11, 0.10, 0.75)
	nen_kn.set_corner_radius_all(4)
	_day_ki_nang = StyleBoxFlat.new()
	_day_ki_nang.bg_color = MAU_KN_CHO
	_day_ki_nang.set_corner_radius_all(4)
	_thanh_ki_nang.add_theme_stylebox_override("background", nen_kn)
	_thanh_ki_nang.add_theme_stylebox_override("fill", _day_ki_nang)
	_cot_ki_nang.add_child(_thanh_ki_nang)

	_lbl_ki_nang = Label.new()
	_lbl_ki_nang.add_theme_font_size_override("font_size", CO_PHIM)
	_lbl_ki_nang.add_theme_color_override("font_color", MAU_KN_CHO)
	_lbl_ki_nang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_ki_nang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cot_ki_nang.add_child(_lbl_ki_nang)


## Nối với node quản lý kĩ năng. level_base gọi sau khi tạo cả hai.
func listen_to_skills(skills: Node) -> void:
	skills.ready_changed.connect(_doi_trang_thai_ki_nang)
	skills.progress_changed.connect(_doi_tien_do_ki_nang)


## Vẽ lại thanh theo dõi điều kiện.
##
## HUD chỉ NHẬN hai con số đã tính sẵn; nó không biết "5 đơn hoàn hảo" nghĩa
## là gì và cũng không đếm gì cả. Luật đếm nằm trọn trong quan_ly_ki_nang —
## nhờ vậy thêm một kiểu điều kiện mới (đếm món nấu, đếm giây) không phải sửa
## một dòng nào ở đây.
func _doi_tien_do_ki_nang(ti_le: float, chu: String) -> void:
	if _thanh_ki_nang == null:
		return
	# Chữ rỗng = nhân vật này chưa có kĩ năng chủ động. Ẩn cả thanh lẫn chữ,
	# nhưng GIỮ cái ảnh xám: ảnh nói "có một ô kĩ năng ở đây", còn một thanh
	# tiến trình đứng im ở 0 suốt màn thì nói dối rằng người chơi đang không
	# tiến bộ.
	var co := not chu.is_empty()
	_thanh_ki_nang.visible = co
	_lbl_ki_nang.visible = co
	if not co:
		return

	_thanh_ki_nang.value = ti_le
	_lbl_ki_nang.text = chu
	var du := ti_le >= 1.0
	_day_ki_nang.bg_color = MAU_KN_DU if du else MAU_KN_CHO
	_lbl_ki_nang.add_theme_color_override("font_color",
		MAU_KN_DU if du else MAU_KN_CHO)


func _doi_trang_thai_ki_nang(san_sang: bool) -> void:
	if _vlieu_ki_nang == null:
		return
	# Xám khi chưa dùng được, màu khi đã dùng được. Không ẩn hẳn ảnh lúc chưa
	# dùng được: người chơi cần biết mình CÓ một kĩ năng đang chờ, chứ không
	# phải bất ngờ thấy một biểu tượng lạ hiện ra giữa màn.
	_vlieu_ki_nang.set_shader_parameter("muc_xam", 0.0 if san_sang else 1.0)
	_anh_ki_nang.modulate.a = 1.0 if san_sang else 0.75


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
func _dung_ghi_chu_ban() -> void:
	_khung_ban = PanelContainer.new()
	_khung_ban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bảng tự co theo nội dung, và ta tự đặt vị trí mỗi frame nên không dùng
	# anchor preset nào cả.
	_khung_ban.custom_minimum_size = Vector2(210, 0)
	var nen := StyleBoxFlat.new()
	nen.bg_color = Color(0.07, 0.1, 0.09, 0.82)
	nen.border_color = Color(MAU_PHIM.r, MAU_PHIM.g, MAU_PHIM.b, 0.5)
	nen.set_border_width_all(2)
	nen.set_corner_radius_all(8)
	nen.set_content_margin_all(10)
	_khung_ban.add_theme_stylebox_override("panel", nen)
	add_child(_khung_ban)

	_cot_ban = VBoxContainer.new()
	_cot_ban.add_theme_constant_override("separation", 4)
	_khung_ban.add_child(_cot_ban)
	_khung_ban.hide()

	# Dòng thông báo ngắn (nấu xong / nấu hỏng).
	_lbl_ban_tam = Label.new()
	_lbl_ban_tam.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lbl_ban_tam.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lbl_ban_tam.offset_top = 92.0
	_lbl_ban_tam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_ban_tam.add_theme_font_size_override("font_size", CO_CHON)
	_lbl_ban_tam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lbl_ban_tam)
	_lbl_ban_tam.hide()


## Đặt bảng cạnh phải cái bàn, và ẩn đi khi người chơi đi xa.
func _bam_theo_ban() -> void:
	if _khung_ban == null or _ban == null or _nhan_vat == null:
		return
	if _ban.chua.is_empty() \
			or _nhan_vat.global_position.distance_to(_ban.global_position) > tam_hien_bang:
		_khung_ban.hide()
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var diem := _ban.global_position + Vector3(0.0, cao_neo_bang, 0.0)
	# Bàn nằm sau lưng camera thì unproject trả về toạ độ vô nghĩa.
	if cam.is_position_behind(diem):
		_khung_ban.hide()
		return

	_khung_ban.show()
	var man := cam.unproject_position(diem)
	# Kẹp trong khung hình để bảng không trôi ra ngoài khi bàn ở sát mép.
	var co := _khung_ban.size
	var vung := get_viewport().get_visible_rect().size
	_khung_ban.position = Vector2(
		clampf(man.x + le_ngang_bang, 8.0, vung.x - co.x - 8.0),
		clampf(man.y - co.y * 0.5, 8.0, vung.y - co.y - 8.0))


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
func nghe_he_bep(he: Node) -> void:
	he.nau_xong.connect(_bao_nau_xong)


func _bao_nau_xong(_bep: Node, mon: String, thanh_cong: bool) -> void:
	hien_bao(("Nấu xong: " + DanhMuc.ten(mon)) if thanh_cong else "Nấu hỏng!",
		thanh_cong)


## Câu báo ngắn giữa màn hình. Dùng chung cho mọi nguồn tin: bếp nấu xong, bàn
## chế tạo ghép được hay ghép hụt.
##
## Một chỗ hiện duy nhất chứ không mỗi hệ một dòng chữ riêng: hai câu báo cùng
## lúc ở hai chỗ khác nhau thì người chơi đọc câu nào cũng lỡ câu kia, mà trong
## một game 7 phút thì họ chỉ liếc được đúng một lần.
func hien_bao(chu: String, tot: bool) -> void:
	_lbl_ban_tam.text = chu
	_lbl_ban_tam.modulate = Color(0.7, 0.95, 0.7) if tot \
		else Color(1.0, 0.5, 0.45)
	_lbl_ban_tam.show()
	# Tự tắt sau 2 giây: thông báo tồn tại để BÁO một sự kiện, không phải để
	# ở lại làm nền. Để mãi thì lần sau người chơi không phân biệt được đó là
	# tin mới hay tin cũ.
	#
	# Giữ tween vào một biến để cú báo SAU huỷ được cú báo trước: hai lần báo
	# cách nhau một giây thì cái hẹn tắt của lần đầu sẽ tắt luôn câu thứ hai
	# khi nó mới hiện được một giây.
	if _tween_bao != null and _tween_bao.is_valid():
		_tween_bao.kill()
	_tween_bao = create_tween()
	_tween_bao.tween_interval(2.0)
	_tween_bao.tween_callback(_lbl_ban_tam.hide)


## Nối vào tín hiệu của bộ chọn. level_base.gd gọi hàm này sau khi tạo cả hai.
func nghe_bo_chon(bo_chon: BoChonMucTieu) -> void:
	bo_chon.danh_sach_thay_doi.connect(_ve_lai)


func nghe_tay_cam(tay: Node) -> void:
	tay.do_tren_tay_doi.connect(_doi_do_tren_tay)
	if tay.has_signal("bao"):
		tay.bao.connect(hien_bao)


## Theo dõi thanh thể lực của nhân vật.
##
## HUD tự HỎI mỗi frame thay vì bắt nhân vật phát tín hiệu mỗi lần thanh
## đổi: thanh này đổi liên tục từng frame, phát tín hiệu cho một giá trị
## như vậy chỉ tốn thêm chi phí mà không được gì.
func theo_doi_nhan_vat(nv: Node) -> void:
	_nhan_vat = nv
	set_process(true)


var _nhan_vat: Node = null


func _process(_delta: float) -> void:
	if _nhan_vat == null or _thanh_suc == null:
		return
	_thanh_suc.value = _nhan_vat.ti_le_stamina()
	# Thanh đầy và không chạy thì mờ đi cho đỡ chiếm mắt; chỉ sáng lên khi
	# đang thật sự tiêu hoặc chưa hồi xong.
	var can_chu_y: bool = _nhan_vat.dang_nuoc_rut() or _thanh_suc.value < 0.999
	_thanh_suc.modulate.a = 1.0 if can_chu_y else 0.35
	_bam_theo_ban()


## Nghe các bàn có chứa đồ. level_base gọi cho từng bàn chế tạo.
## Bảng chỉ theo dõi BÀN CHẾ TẠO. Thớt, bếp và lò giờ đã bày model thật lên
## mặt bàn nên tự nói được trạng thái của mình; nhân đôi thông tin đó ra một
## bảng chữ nữa chỉ làm màn hình đông thêm.
func nghe_ban(ban: TramTuongTac) -> void:
	_ban = ban
	ban.noi_dung_thay_doi.connect(_ve_lai_ban)


func _doi_do_tren_tay(ten: String) -> void:
	# Nhắc phím Q ngay trên dòng "đang cầm" chứ không nhét vào bảng hướng
	# dẫn riêng: nhắc đúng lúc người chơi CÓ THỂ dùng nó thì họ đọc, còn
	# một bảng phím tắt mở ra lúc đầu màn thì không ai nhớ.
	_lbl_tay.text = "Đang cầm: %s   (Q: bỏ xuống)" % ten if not ten.is_empty() else ""


func _ve_lai_ban(ban: TramTuongTac) -> void:
	for con in _cot_ban.get_children():
		con.queue_free()
	if ban.chua.is_empty():
		_khung_ban.hide()
		return
	_khung_ban.show()

	var tieu_de := Label.new()
	tieu_de.text = ban.ten_hien_thi
	tieu_de.add_theme_color_override("font_color", MAU_PHIM)
	tieu_de.add_theme_font_size_override("font_size", CO_PHIM)
	_cot_ban.add_child(tieu_de)

	for ten in ban.chua:
		_cot_ban.add_child(_dong_co_anh(str(ten)))

	# Nhắc lối thoát ngay trên cái bảng liệt kê nguyên liệu, vì đó đúng là chỗ
	# người chơi đang nhìn lúc nhận ra mình bỏ nhầm. Nhắc ở bảng phím tắt đầu
	# màn thì tới lúc cần chẳng ai nhớ.
	var nhac := Label.new()
	nhac.text = "E (tay không): lấy lại thứ vừa bỏ"
	nhac.add_theme_color_override("font_color", MAU_PHIM)
	nhac.add_theme_font_size_override("font_size", CO_PHIM)
	_cot_ban.add_child(nhac)


## Một dòng: ảnh nhỏ + tên. Có ảnh thì người chơi đối chiếu được ngay với
## bảng chọn ở tủ lạnh và với vé đơn hàng, cùng một hình cho cùng một thứ.
func _dong_co_anh(id: String) -> Control:
	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 8)

	var duong_dan := DanhMuc.duong_dan_anh(id)
	if ResourceLoader.exists(duong_dan):
		var anh := TextureRect.new()
		anh.texture = load(duong_dan)
		anh.custom_minimum_size = Vector2(38, 38)
		anh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		anh.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hang.add_child(anh)

	var nhan := Label.new()
	nhan.text = DanhMuc.ten(id)
	nhan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nhan.add_theme_color_override("font_color", MAU_CHON)
	nhan.add_theme_font_size_override("font_size", CO_MO)
	hang.add_child(nhan)
	return hang


func _doi_goc_nhin(la_goc_thu_3: bool) -> void:
	_tam_ngam.visible = la_goc_thu_3


func _ve_lai(ung_vien: Array, chi_so_chon: int) -> void:
	for con in _cot.get_children():
		con.queue_free()

	if ung_vien.is_empty():
		_khung.hide()
		return
	_khung.show()

	for i in ung_vien.size():
		var dong := Label.new()
		var dang_chon := i == chi_so_chon
		dong.text = ("▸ " if dang_chon else "   ") + str(ung_vien[i]["nhan"])
		dong.add_theme_color_override("font_color", MAU_CHON if dang_chon else MAU_MO)
		dong.add_theme_font_size_override("font_size", CO_CHON if dang_chon else CO_MO)
		_cot.add_child(dong)

	# Chỉ nhắc phím Tab khi thật sự có nhiều hơn một lựa chọn. Nhắc thừa thì
	# người chơi tưởng lúc nào cũng phải bấm Tab, mà đó là điều mình muốn
	# tránh nhất.
	var goi_y := Label.new()
	goi_y.add_theme_color_override("font_color", MAU_PHIM)
	goi_y.add_theme_font_size_override("font_size", CO_PHIM)
	if ung_vien.size() > 1:
		goi_y.text = "E: chọn     Tab: đổi mục tiêu"
	else:
		goi_y.text = "E: chọn"
	_cot.add_child(goi_y)
