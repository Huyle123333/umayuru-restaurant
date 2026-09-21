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
## Node này TỰ HUỶ khi chiếu xong. Người gọi chỉ cần `play(character_id)` rồi
## quên nó đi; muốn biết lúc nào xong thì nghe tín hiệu `finished`.

## Phát khi đoạn phim kết thúc hoặc bị bỏ qua. Người gọi dùng nó để trả quyền
## điều khiển lại cho người chơi.
signal finished

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

const VIDEO_ASPECT := 520.0 / 1080.0

## Tỉ lệ khung hình của viewport thiết kế (1920 × 1080).
##
## Hằng số chứ không đo lúc chạy: game bật stretch/mode = "canvas_items" với
## viewport thiết kế cố định 1920×1080, nên dù người chơi kéo cửa sổ cỡ nào
## thì toạ độ giao diện vẫn nằm trong khung 16:9 đó.
const SCREEN_ASPECT := 16.0 / 9.0

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
const HEIGHT_RATIO := 0.86

## Trần an toàn cho chiều rộng.
##
## Với tỉ lệ dọc hiện tại thì không bao giờ chạm tới (khung chỉ rộng ~23% màn
## hình). Nó tồn tại để nếu sau này có đoạn cut-in NẰM NGANG, khung không tràn
## ra khỏi mép màn hình — lúc đó chiều rộng thành cạnh chật và công thức tự
## đảo lại.
const MAX_WIDTH_RATIO := 0.8

## Bán kính bo góc và độ dày viền của khung phim.
const CORNER_RADIUS := 14
const BORDER_WIDTH := 3

## Cỡ chữ dòng nhắc "bỏ qua".
##
## Nhân sẵn hệ số 1.5 như mọi cỡ chữ khác trong game: viewport thiết kế
## 1920×1080 nhưng cửa sổ mặc định 1280×720, nên chữ bị thu còn 2/3.
const MUSIC_FONT_SIZE := 24

## Sau bao lâu thì cho phép bấm phím để bỏ qua.
##
## 0,4 giây để cú bấm Space vừa KÍCH HOẠT kĩ năng không bị đọc luôn thành cú
## bấm bỏ qua đoạn phim — cùng con số và cùng lý do với màn intro.
@export var skip_lock_seconds := 0.4

## Có dừng cả game trong lúc chiếu không.
##
## Mặc định BẬT. Cut-in là một khoảnh khắc nhấn mạnh: nếu bếp vẫn cháy và
## khách vẫn hết kiên nhẫn phía sau tấm phim thì người chơi không dám xem, và
## đoạn phim biến từ phần thưởng thành hình phạt.
##
## Để thành @export vì đây là quyết định CÂN BẰNG chứ không phải kĩ thuật:
## khi hệ đơn hàng xong, nếu thấy dừng game 11 giây là quá dài thì tắt cờ này
## đi (hoặc cắt ngắn video) mà không phải sửa một dòng logic nào.
@export var pause_game := true

var _video: VideoStreamPlayer
var _lbl_music: Label
var _finished := false
var _uses_left := 0.0


func _ready() -> void:
	# Trên mọi HUD khác (hud_tuong_tac layer 10, bang_chon layer 20).
	layer = 60
	# Phải chạy được KỂ CẢ khi cây scene đang bị dừng — nếu không thì bật
	# pause_game xong chính node này cũng đứng im và đoạn phim không bao giờ
	# kết thúc.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process(false)
	set_process_input(false)


func _build_ui() -> void:
	_build_dim()

	# Khung phim: neo bằng TỈ LỆ ANCHOR chứ không phải offset pixel, nên đúng
	# ở mọi cỡ cửa sổ.
	#
	# Cách tính: lấy chiều cao trước (HEIGHT_RATIO), rồi suy ra chiều rộng sao cho
	# khung có ĐÚNG tỉ lệ đoạn phim:
	#     rộng/W = (cao/H) × (H/W) × VIDEO_ASPECT = HEIGHT_RATIO ÷ SCREEN_ASPECT × VIDEO_ASPECT
	# Nhờ vậy khung tự nó đã đúng tỉ lệ, AspectRatioContainer bên trong không
	# còn gì để cắt — không có dải đen thừa ở hai bên.
	#
	# Nhánh kiểm tra bên dưới đảo lại phép tính khi chiều rộng mới là cạnh
	# chật (đoạn phim nằm ngang). Viết sẵn cả hai chiều thay vì chỉ chiều đang
	# dùng: chi phí là ba dòng, còn nếu thiếu thì đoạn cut-in nằm ngang đầu
	# tiên sẽ tràn ra ngoài mép màn hình mà không ai đoán ra vì sao.
	var h_ratio := HEIGHT_RATIO
	var w_ratio := h_ratio / SCREEN_ASPECT * VIDEO_ASPECT
	if w_ratio > MAX_WIDTH_RATIO:
		w_ratio = MAX_WIDTH_RATIO
		h_ratio = w_ratio * SCREEN_ASPECT / VIDEO_ASPECT
	var margin_h := (1.0 - w_ratio) * 0.5
	var margin_v := (1.0 - h_ratio) * 0.5

	# Viền bo góc vẽ SAU LƯNG khung phim, hơi to hơn một chút, nên nhìn như
	# cái khung ảnh ôm lấy đoạn phim.
	var border := Panel.new()
	_anchor_ratio(border, margin_h, margin_v)
	border.offset_left = -float(BORDER_WIDTH)
	border.offset_top = -float(BORDER_WIDTH)
	border.offset_right = float(BORDER_WIDTH)
	border.offset_bottom = float(BORDER_WIDTH)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.06, 1.0)
	style.border_color = Color(1, 1, 1, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 24
	border.add_theme_stylebox_override("panel", style)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	var frame := AspectRatioContainer.new()
	_anchor_ratio(frame, margin_h, margin_v)
	frame.ratio = VIDEO_ASPECT
	# Vẫn để STRETCH_FIT làm lưới an toàn: nếu sau này có đoạn phim tỉ lệ hơi
	# khác, nó tự thu vào giữa chứ không kéo méo.
	frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	_video = VideoStreamPlayer.new()
	_video.expand = true
	# Cùng bus với nhạc nền để thanh trượt BGM trong Cài đặt điều khiển được
	# tiếng của cut-in — giống màn intro.
	_video.bus = "Music"
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_finish)
	frame.add_child(_video)

	# Dòng nhắc "bỏ qua", đặt ngay dưới khung phim.
	#
	# Có nhắc thì mới công bằng: không nói ra thì người chơi hoặc ngồi chịu
	# trận hết 11 giây, hoặc bấm loạn xạ để thử — mà bấm loạn xạ chính là
	# thứ sinh ra câu hỏi "vừa rồi mình có mất kĩ năng không?".
	_lbl_music = Label.new()
	_lbl_music.text = "Space hoặc Esc — bỏ qua"
	_lbl_music.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_music.add_theme_font_size_override("font_size", MUSIC_FONT_SIZE)
	_lbl_music.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	_lbl_music.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_lbl_music.add_theme_constant_override("outline_size", 6)
	_lbl_music.anchor_left = margin_h
	_lbl_music.anchor_right = 1.0 - margin_h
	_lbl_music.anchor_top = 1.0 - margin_v
	_lbl_music.anchor_bottom = 1.0 - margin_v
	_lbl_music.offset_top = 14.0
	_lbl_music.offset_bottom = 60.0
	_lbl_music.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ẩn cho tới khi hết khoảng khoá, vì trước đó bấm cũng không ăn thua.
	_lbl_music.hide()
	add_child(_lbl_music)


## Neo một Control vào giữa màn hình theo tỉ lệ phần trăm.
func _anchor_ratio(c: Control, margin_h: float, margin_v: float) -> void:
	c.anchor_left = margin_h
	c.anchor_right = 1.0 - margin_h
	c.anchor_top = margin_v
	c.anchor_bottom = 1.0 - margin_v
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
func _build_dim() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D man_hinh : hint_screen_texture, repeat_disable, filter_linear_mipmap;
// Mức mipmap dùng để làm mờ. Càng height_ càng nhoè.
uniform float do_mo : hint_range(0.0, 6.0) = 3.0;
// Tối thêm bao nhiêu sau khi đã làm mờ.
uniform float do_toi : hint_range(0.0, 1.0) = 0.45;
void fragment() {
	vec3 c = textureLod(man_hinh, SCREEN_UV, do_mo).rgb;
	COLOR = vec4(mix(c, vec3(0.0), do_toi), 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	bg.material = mat
	add_child(bg)


## Chiếu cut-in của một nhân vật. Trả về false nếu không có file để chiếu.
##
## Trả về bool thay vì âm thầm bỏ qua: người gọi cần biết để KHÔNG trừ lượt
## dùng kĩ năng khi đoạn phim không tồn tại. Special Week hiện chưa có file,
## nên trường hợp này là có thật chứ không phải phòng xa.
func play(character_id: String) -> bool:
	var path := GameData.skill_cutscene_path(character_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Chưa có cut-in kĩ năng cho '%s' (%s)." % [character_id, path])
		return false

	var stream := load(path) as VideoStream
	if stream == null:
		push_error("Không đọc được video '%s'." % path)
		return false

	_video.stream = stream
	_video.play()
	if not _video.is_playing():
		push_error("VideoStreamPlayer không phát được '%s'." % path)
		return false

	_uses_left = skip_lock_seconds
	set_process(true)
	set_process_input(true)
	if pause_game:
		get_tree().paused = true
	return true


func _process(delta: float) -> void:
	if _uses_left > 0.0:
		_uses_left -= delta
		if _uses_left <= 0.0 and _lbl_music != null:
			_lbl_music.show()


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
	if _finished:
		return
	# Chỉ quan tâm tới thao tác thật sự của người chơi. Bỏ qua chuyển động
	# chuột và các sự kiện lặp do giữ phím.
	if event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.echo:
		return

	get_viewport().set_input_as_handled()
	if _uses_left > 0.0:
		return
	if event.is_action_pressed("skill") or event.is_action_pressed("ui_cancel"):
		_finish()


func _finish() -> void:
	# Cờ chặn vào hai lần: tín hiệu `finished` và cú bấm bỏ qua có thể tới trong
	# cùng một khung, mà queue_free() hai lần thì Godot báo lỗi.
	if _finished:
		return
	_finished = true
	if _video != null:
		_video.stop()
	if pause_game:
		get_tree().paused = false
	finished.emit()
	queue_free()
