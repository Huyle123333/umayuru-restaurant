extends CanvasLayer

## Phát khi đoạn phim kết thúc hoặc bị bỏ qua. Người gọi dùng nó để trả quyền
signal finished


const VIDEO_ASPECT := 520.0 / 1080.0

## Tỉ lệ khung hình của viewport thiết kế (1920 × 1080).
const SCREEN_ASPECT := 16.0 / 9.0

## Khung phim chiếm bao nhiêu phần CHIỀU CAO màn hình.
const HEIGHT_RATIO := 0.86

## Trần an toàn cho chiều rộng.
const MAX_WIDTH_RATIO := 0.8

## Bán kính bo góc và độ dày viền của khung phim.
const CORNER_RADIUS := 14
const BORDER_WIDTH := 3

## Cỡ chữ dòng nhắc "bỏ qua".
const MUSIC_FONT_SIZE := 24

## Sau bao lâu thì cho phép bấm phím để bỏ qua.
@export var skip_lock_seconds := 0.4

## Có dừng cả game trong lúc chiếu không.
@export var pause_game := true

var _video: VideoStreamPlayer
var _lbl_music: Label
var _finished := false
var _uses_left := 0.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process(false)
	set_process_input(false)


func _build_ui() -> void:
	_build_dim()

	var h_ratio := HEIGHT_RATIO
	var w_ratio := h_ratio / SCREEN_ASPECT * VIDEO_ASPECT
	if w_ratio > MAX_WIDTH_RATIO:
		w_ratio = MAX_WIDTH_RATIO
		h_ratio = w_ratio * SCREEN_ASPECT / VIDEO_ASPECT
	var margin_h := (1.0 - w_ratio) * 0.5
	var margin_v := (1.0 - h_ratio) * 0.5

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
	frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.bus = "Music"
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_finish)
	frame.add_child(_video)

	_lbl_music = Label.new()
	_lbl_music.text = Lang.t("Space hoặc Esc — bỏ qua")
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
func _input(event: InputEvent) -> void:
	if _finished:
		return
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
	if _finished:
		return
	_finished = true
	if _video != null:
		_video.stop()
	if pause_game:
		get_tree().paused = false
	finished.emit()
	queue_free()
