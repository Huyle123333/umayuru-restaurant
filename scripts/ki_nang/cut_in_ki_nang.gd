extends CanvasLayer
## Đoạn cut-in chiếu khi người chơi kích hoạt kĩ năng chủ động.
##
## Dựng bằng CODE chứ không phải .tscn, cùng lý do với hud_tuong_tac.gd: cả
## màn này chỉ có bốn node và không có gì để căn bằng mắt trong trình chỉnh
## scene. Để trong một file thì đọc một lượt là hiểu, và không có file .tscn
## nào để editor ghi đè mất.
##
## BỎ QUA KHÔNG HUỶ KĨ NĂNG. Lượt kĩ năng đã bị trừ từ lúc bấm Space, và
## hiệu ứng (khi cài xong) cũng áp dụng ngay lúc đó — đoạn phim chỉ là phần
## trình diễn chạy song song. Bấm bỏ qua nghĩa là "tôi không cần xem", không
## phải "tôi đổi ý". Làm ngược lại thì mỗi lần lỡ tay là mất luôn lượt kĩ năng
## duy nhất của cả màn, một hình phạt quá nặng cho một cú bấm nhầm.
##
## Node này TỰ HUỶ khi chiếu xong. Người gọi chỉ cần `chieu(id_nhan_vat)` rồi
## quên nó đi; muốn biết lúc nào xong thì nghe tín hiệu `xong`.

## Phát khi đoạn phim kết thúc hoặc bị bỏ qua. Người gọi dùng nó để trả quyền
## điều khiển lại cho người chơi.
signal xong

## Tỉ lệ khung hình (rộng ÷ cao) của các file cut-in.
##
## Các đoạn này quay từ game điện thoại nên khung hình DỌC: 520 × 1080, tức
## khoảng 0.48 — cao hơn cả 9:16 (0.5625) vì màn hình điện thoại đời mới rất
## dài.
##
## Cảnh báo cho lần sau: file .mp4 gốc bị ffprobe báo là 2320 × 1116 (nằm
## ngang) vì khung hình được lưu ngang kèm metadata `rotation = -90`; trình
## phát mới là nơi xoay lại. Đọc con số thô rồi kết luận "video nằm ngang" là
## sai — phải xem cả trường rotation.

const TI_LE := 520.0 / 1080.0

## Tỉ lệ khung hình của viewport thiết kế (1920 × 1080).
##
## Hằng số chứ không đo lúc chạy: game bật stretch/mode = "canvas_items" với
## viewport thiết kế cố định 1920×1080, nên dù người chơi kéo cửa sổ cỡ nào
## thì toạ độ giao diện vẫn nằm trong khung 16:9 đó.
const TI_LE_MAN := 16.0 / 9.0

## Khung phim chiếm bao nhiêu phần CHIỀU CAO màn hình.
##
## Đo theo chiều cao vì đoạn phim là khung dọc: trên màn hình 16:9 thì chiều
## cao mới là cạnh chật, còn chiều rộng thừa rất nhiều.
##
## 0.86 chứ không phải 1.0: chừa một viền nền mờ quanh đoạn phim thì mắt hiểu
## ngay đây là một khung hình được LỒNG lên trên trò chơi, không phải game
## vừa chuyển sang cảnh khác. Đây cũng là lý do phải làm nền mờ chứ không phủ
## đen — thấy căn bếp nhoè phía sau thì người chơi biết mình vẫn đang ở trong
## màn.
const PHAN_CAO := 0.86

## Trần an toàn cho chiều rộng.
##
## Với tỉ lệ dọc hiện tại thì không bao giờ chạm tới (khung chỉ rộng ~23% màn
## hình). Nó tồn tại để nếu sau này có đoạn cut-in NẰM NGANG, khung không tràn
## ra khỏi mép màn hình — lúc đó chiều rộng thành cạnh chật và công thức tự
## đảo lại.
const PHAN_RONG_TOI_DA := 0.8

## Bán kính bo góc và độ dày viền của khung phim.
const BO_GOC := 14
const DAY_VIEN := 3

## Cỡ chữ dòng nhắc "bỏ qua".
##
## Nhân sẵn hệ số 1.5 như mọi cỡ chữ khác trong game: viewport thiết kế
## 1920×1080 nhưng cửa sổ mặc định 1280×720, nên chữ bị thu còn 2/3.
const CO_NHAC := 24

## Sau bao lâu thì cho phép bấm phím để bỏ qua.
##
## 0,4 giây để cú bấm Space vừa KÍCH HOẠT kĩ năng không bị đọc luôn thành cú
## bấm bỏ qua đoạn phim — cùng con số và cùng lý do với màn intro.
@export var khoa_bo_qua_giay := 0.4

## Có dừng cả game trong lúc chiếu không.
##
## Mặc định BẬT. Cut-in là một khoảnh khắc nhấn mạnh: nếu bếp vẫn cháy và
## khách vẫn hết kiên nhẫn phía sau tấm phim thì người chơi không dám xem, và
## đoạn phim biến từ phần thưởng thành hình phạt.
##
## Để thành @export vì đây là quyết định CÂN BẰNG chứ không phải kĩ thuật:
## khi hệ đơn hàng xong, nếu thấy dừng game 11 giây là quá dài thì tắt cờ này
## đi (hoặc cắt ngắn video) mà không phải sửa một dòng logic nào.
@export var dung_game := true

var _phim: VideoStreamPlayer
var _lbl_nhac: Label
var _da_xong := false
var _con_lai := 0.0


func _ready() -> void:
	# Trên mọi HUD khác (hud_tuong_tac layer 10, bang_chon layer 20).
	layer = 60
	# Phải chạy được KỂ CẢ khi cây scene đang bị dừng — nếu không thì bật
	# dung_game xong chính node này cũng đứng im và đoạn phim không bao giờ
	# kết thúc.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dung_giao_dien()
	set_process(false)
	set_process_input(false)


func _dung_giao_dien() -> void:
	_dung_nen_mo()

	# Khung phim: neo bằng TỈ LỆ ANCHOR chứ không phải offset pixel, nên đúng
	# ở mọi cỡ cửa sổ.
	#
	# Cách tính: lấy chiều cao trước (PHAN_CAO), rồi suy ra chiều rộng sao cho
	# khung có ĐÚNG tỉ lệ đoạn phim:
	#     rộng/W = (cao/H) × (H/W) × TI_LE = PHAN_CAO ÷ TI_LE_MAN × TI_LE
	# Nhờ vậy khung tự nó đã đúng tỉ lệ, AspectRatioContainer bên trong không
	# còn gì để cắt — không có dải đen thừa ở hai bên.
	#
	# Nhánh kiểm tra bên dưới đảo lại phép tính khi chiều rộng mới là cạnh
	# chật (đoạn phim nằm ngang). Viết sẵn cả hai chiều thay vì chỉ chiều đang
	# dùng: chi phí là ba dòng, còn nếu thiếu thì đoạn cut-in nằm ngang đầu
	# tiên sẽ tràn ra ngoài mép màn hình mà không ai đoán ra vì sao.
	var phan_cao := PHAN_CAO
	var phan_rong := phan_cao / TI_LE_MAN * TI_LE
	if phan_rong > PHAN_RONG_TOI_DA:
		phan_rong = PHAN_RONG_TOI_DA
		phan_cao = phan_rong * TI_LE_MAN / TI_LE
	var le_ngang := (1.0 - phan_rong) * 0.5
	var le_doc := (1.0 - phan_cao) * 0.5

	# Viền bo góc vẽ SAU LƯNG khung phim, hơi to hơn một chút, nên nhìn như
	# cái khung ảnh ôm lấy đoạn phim.
	var vien := Panel.new()
	_neo_ti_le(vien, le_ngang, le_doc)
	vien.offset_left = -float(DAY_VIEN)
	vien.offset_top = -float(DAY_VIEN)
	vien.offset_right = float(DAY_VIEN)
	vien.offset_bottom = float(DAY_VIEN)
	var kieu := StyleBoxFlat.new()
	kieu.bg_color = Color(0.05, 0.05, 0.06, 1.0)
	kieu.border_color = Color(1, 1, 1, 0.25)
	kieu.set_border_width_all(1)
	kieu.set_corner_radius_all(BO_GOC)
	kieu.shadow_color = Color(0, 0, 0, 0.55)
	kieu.shadow_size = 24
	vien.add_theme_stylebox_override("panel", kieu)
	vien.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vien)

	var khung := AspectRatioContainer.new()
	_neo_ti_le(khung, le_ngang, le_doc)
	khung.ratio = TI_LE
	# Vẫn để STRETCH_FIT làm lưới an toàn: nếu sau này có đoạn phim tỉ lệ hơi
	# khác, nó tự thu vào giữa chứ không kéo méo.
	khung.stretch_mode = AspectRatioContainer.STRETCH_FIT
	khung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(khung)

	_phim = VideoStreamPlayer.new()
	_phim.expand = true
	# Cùng bus với nhạc nền để thanh trượt BGM trong Cài đặt điều khiển được
	# tiếng của cut-in — giống màn intro.
	_phim.bus = "Music"
	_phim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phim.finished.connect(_ket_thuc)
	khung.add_child(_phim)

	# Dòng nhắc "bỏ qua", đặt ngay dưới khung phim.
	#
	# Có nhắc thì mới công bằng: không nói ra thì người chơi hoặc ngồi chịu
	# trận hết 11 giây, hoặc bấm loạn xạ để thử — mà bấm loạn xạ chính là
	# thứ sinh ra câu hỏi "vừa rồi mình có mất kĩ năng không?".
	_lbl_nhac = Label.new()
	_lbl_nhac.text = "Space hoặc Esc — bỏ qua"
	_lbl_nhac.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_nhac.add_theme_font_size_override("font_size", CO_NHAC)
	_lbl_nhac.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	_lbl_nhac.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_lbl_nhac.add_theme_constant_override("outline_size", 6)
	_lbl_nhac.anchor_left = le_ngang
	_lbl_nhac.anchor_right = 1.0 - le_ngang
	_lbl_nhac.anchor_top = 1.0 - le_doc
	_lbl_nhac.anchor_bottom = 1.0 - le_doc
	_lbl_nhac.offset_top = 14.0
	_lbl_nhac.offset_bottom = 60.0
	_lbl_nhac.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ẩn cho tới khi hết khoảng khoá, vì trước đó bấm cũng không ăn thua.
	_lbl_nhac.hide()
	add_child(_lbl_nhac)


## Neo một Control vào giữa màn hình theo tỉ lệ phần trăm.
func _neo_ti_le(c: Control, le_ngang: float, le_doc: float) -> void:
	c.anchor_left = le_ngang
	c.anchor_right = 1.0 - le_ngang
	c.anchor_top = le_doc
	c.anchor_bottom = 1.0 - le_doc
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


## Nền: LÀM MỜ chính hình ảnh trò chơi đang hiện, rồi tối đi.
##
## Vì sao làm mờ chứ không phủ một lớp đen phẳng: lớp đen phẳng cắt đứt hoàn
## toàn mạch nhìn, người chơi mất phương hướng và phải định vị lại căn bếp sau
## khi đoạn phim kết thúc. Nền mờ giữ nguyên bố cục và màu sắc quen thuộc,
## chỉ hạ nó xuống nền sau — đúng cách các trò chơi làm mờ nền khi mở menu.
##
## Kỹ thuật: shader lấy mẫu ảnh màn hình đã dựng xong (hint_screen_texture)
## bằng textureLod ở mức mipmap cao. Dùng mipmap thay vì tự lấy mẫu nhiều điểm
## rồi cộng lại: GPU đã dựng sẵn chuỗi mipmap, đọc một lần là xong, gần như
## không tốn gì; còn làm mờ kiểu Gauss thủ công tốn hàng chục lần lấy mẫu mỗi
## điểm ảnh.
func _dung_nen_mo() -> void:
	var nen := ColorRect.new()
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	nen.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D man_hinh : hint_screen_texture, repeat_disable, filter_linear_mipmap;
// Mức mipmap dùng để làm mờ. Càng cao càng nhoè.
uniform float do_mo : hint_range(0.0, 6.0) = 3.0;
// Tối thêm bao nhiêu sau khi đã làm mờ.
uniform float do_toi : hint_range(0.0, 1.0) = 0.45;
void fragment() {
	vec3 c = textureLod(man_hinh, SCREEN_UV, do_mo).rgb;
	COLOR = vec4(mix(c, vec3(0.0), do_toi), 1.0);
}
"""
	var vl := ShaderMaterial.new()
	vl.shader = sh
	nen.material = vl
	add_child(nen)


## Chiếu cut-in của một nhân vật. Trả về false nếu không có file để chiếu.
##
## Trả về bool thay vì âm thầm bỏ qua: người gọi cần biết để KHÔNG trừ lượt
## dùng kĩ năng khi đoạn phim không tồn tại. Special Week hiện chưa có file,
## nên trường hợp này là có thật chứ không phải phòng xa.
func chieu(id_nhan_vat: String) -> bool:
	var duong_dan := GameData.duong_dan_cutscene_ki_nang(id_nhan_vat)
	if duong_dan.is_empty() or not ResourceLoader.exists(duong_dan):
		push_warning("Chưa có cut-in kĩ năng cho '%s' (%s)." % [id_nhan_vat, duong_dan])
		return false

	var luong := load(duong_dan) as VideoStream
	if luong == null:
		push_error("Không đọc được video '%s'." % duong_dan)
		return false

	_phim.stream = luong
	_phim.play()
	if not _phim.is_playing():
		push_error("VideoStreamPlayer không phát được '%s'." % duong_dan)
		return false

	_con_lai = khoa_bo_qua_giay
	set_process(true)
	set_process_input(true)
	if dung_game:
		get_tree().paused = true
	return true


func _process(delta: float) -> void:
	if _con_lai > 0.0:
		_con_lai -= delta
		if _con_lai <= 0.0 and _lbl_nhac != null:
			_lbl_nhac.show()


## Trong lúc chiếu, lớp này NUỐT toàn bộ bàn phím và chuột.
##
## Vì sao phải nuốt hết chứ không chỉ bắt phím bỏ qua: cut-in dừng cây scene
## nên nhân vật không nhận input, NHƯNG các node đặt PROCESS_MODE_ALWAYS thì
## vẫn nhận. Không chặn ở đây thì một cú bấm lạc có thể chạy trúng thứ khác
## trong lúc màn hình đang bị che — người chơi không nhìn thấy hậu quả và
## không có cách nào lần ra.
##
## Và KHÁC với màn intro, ở đây KHÔNG cho "bấm phím nào cũng bỏ qua".
## Lý do: lúc intro chạy thì tay người chơi đang rảnh; còn giữa màn chơi thì
## tay họ đặt sẵn trên WASD, E, Q, Shift và bấm theo phản xạ. "Phím nào cũng
## được" biến một cú gõ W theo quán tính thành lệnh tắt đoạn phim, rồi để lại
## đúng câu hỏi "vừa rồi mình có mất kĩ năng không?".
##
## Chỉ hai phím bỏ qua được, và cả hai đều là lựa chọn CÓ Ý THỨC:
##   Space — chính phím vừa dùng để bật kĩ năng, bấm tiếp là "tôi biết rồi".
##   Esc   — phím thoát/huỷ theo quy ước chung của cả game.
func _input(event: InputEvent) -> void:
	if _da_xong:
		return
	# Chỉ quan tâm tới thao tác thật sự của người chơi. Bỏ qua chuyển động
	# chuột và các sự kiện lặp do giữ phím.
	if event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.echo:
		return

	get_viewport().set_input_as_handled()
	if _con_lai > 0.0:
		return
	if event.is_action_pressed("ki_nang") or event.is_action_pressed("ui_cancel"):
		_ket_thuc()


func _ket_thuc() -> void:
	# Cờ chặn vào hai lần: tín hiệu finished và cú bấm bỏ qua có thể tới trong
	# cùng một frame, mà queue_free() hai lần thì Godot báo lỗi.
	if _da_xong:
		return
	_da_xong = true
	if _phim != null:
		_phim.stop()
	if dung_game:
		get_tree().paused = false
	xong.emit()
	queue_free()
