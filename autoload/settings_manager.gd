extends Node
## SettingsManager — mọi tùy chọn của người chơi (Autoload).
##
## Giữ giá trị, áp dụng chúng vào engine, và lưu xuống user://settings.cfg.
## Cửa sổ Cài đặt chỉ đọc/ghi qua đây chứ không tự đụng vào AudioServer,
## nhờ vậy menu Pause sau này dùng lại được y nguyên mà không lặp code.

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"
## Bốn bus âm thanh của game.
##
## "Video" là bus RIÊNG cho tiếng của các đoạn phim (intro khởi động, intro
## trước prologue). Trước đây chúng phát chung bus "Music", nên kéo thanh
## Nhạc nền xuống để bớt ồn lúc chơi cũng làm tắt luôn lời thoại trong phim —
## hai thứ chẳng liên quan gì nhau bị buộc chung một cái núm.
##
## Vì sao là BUS RIÊNG chứ không phải đặt volume_db thẳng trên node video:
## đặt trên node thì mỗi scene video phải tự nhớ con số của mình, và thêm một
## đoạn phim mới là thêm một chỗ có thể quên. Bus thì khai một lần, mọi video
## trỏ vào đó, và sau này muốn có thanh trượt riêng cho lời thoại phim thì đã
## sẵn chỗ để cắm.
##
## Bus "Video" gửi thẳng vào Master nên vẫn chịu thanh Tổng — đúng ý: tắt
## tiếng cả game thì phim cũng phải im.
const BUSES := ["Master", "Music", "SFX", "Video"]

## Âm lượng 0.0 → 1.0 cho từng bus.
##
## Video mặc định 1.0 (nguyên bản): tiếng trong phim đã được trộn sẵn lúc dựng
## phim, game không có lý do gì để chỉnh lại.
var volumes := {"Master": 0.8, "Music": 0.7, "SFX": 0.9, "Video": 1.0}
## Độ sáng màn hình: 0.5 (tối) → 1.5 (sáng), 1.0 là nguyên bản.
var brightness := 1.0
## Hệ số nhân tốc độ chuột: 0.3 → 2.5, 1.0 là mặc định của nhân vật.
var mouse_sensitivity := 1.0
var fullscreen := false

## --- Ngôn ngữ ------------------------------------------------------------
## Danh sách ngôn ngữ game hỗ trợ. Tên hiển thị CỐ Ý viết bằng chính ngôn
## ngữ đó ("Tiếng Việt", "English") và KHÔNG cho dịch: người lỡ chọn nhầm
## ngôn ngữ mình không đọc được vẫn nhận ra dòng của mình mà quay lại.
const NGON_NGU := [
	{"ma": "vi", "ten": "Tiếng Việt"},
	{"ma": "en", "ten": "English"},
]
const NGON_NGU_MAC_DINH := "vi"

## Mã ngôn ngữ đang dùng ("vi" / "en").
var ngon_ngu := NGON_NGU_MAC_DINH

var _brightness_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_brightness_layer()
	load_settings()


## --- Độ sáng -------------------------------------------------------------
## Dựng một lớp phủ toàn màn hình bằng code, đặt ở CanvasLayer 200 để luôn
## nằm trên mọi thứ. Lớp này dùng shader đọc lại ảnh màn hình rồi nhân với
## hệ số sáng — nhờ vậy vừa làm tối được vừa làm sáng lên được. Nếu chỉ phủ
## một tấm đen mờ thì chỉ giảm sáng chứ không bao giờ tăng sáng được.
func _build_brightness_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	add_child(layer)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float brightness : hint_range(0.2, 2.0) = 1.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	COLOR = vec4(c * brightness, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader

	_brightness_rect = ColorRect.new()
	_brightness_rect.material = mat
	_brightness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Bắt buộc: nếu không Ignore thì tấm phủ này nuốt hết chuột của cả game.
	_brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_brightness_rect)


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	if _brightness_rect:
		# Bằng 1.0 thì tắt hẳn lớp phủ đi cho đỡ tốn một lượt vẽ mỗi khung hình.
		_brightness_rect.visible = not is_equal_approx(brightness, 1.0)
		(_brightness_rect.material as ShaderMaterial).set_shader_parameter("brightness", brightness)
	settings_changed.emit()


## --- Âm lượng ------------------------------------------------------------

func get_volume(bus_name: String) -> float:
	return float(volumes.get(bus_name, 1.0))


## value 0.0 → 1.0. Tai người nghe theo thang logarit nên phải đổi sang
## decibel bằng linear_to_db, không gán thẳng số của thanh trượt.
func set_volume(bus_name: String, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	volumes[bus_name] = value
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("Chưa có audio bus tên '%s'." % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	# value = 0 thì linear_to_db trả về -inf; tắt tiếng hẳn cho chắc.
	AudioServer.set_bus_mute(idx, is_zero_approx(value))
	settings_changed.emit()


## --- Ngôn ngữ ------------------------------------------------------------

func co_ngon_ngu(ma: String) -> bool:
	for muc in NGON_NGU:
		if muc["ma"] == ma:
			return true
	return false


func ten_ngon_ngu(ma: String) -> String:
	for muc in NGON_NGU:
		if muc["ma"] == ma:
			return String(muc["ten"])
	return ma


## Đổi ngôn ngữ hiển thị của toàn game.
##
## Chỉ cần một dòng TranslationServer.set_locale() là đủ cho phần lớn giao
## diện: Godot gửi thông báo NOTIFICATION_TRANSLATION_CHANGED xuống cả cây
## scene, và mọi node Control có auto_translate (mặc định bật) tự dịch lại
## text của nó. Nghĩa là các nhãn/nút đặt sẵn trong file .tscn đổi ngay lập
## tức mà không cần chạy lại scene — chỉ những chuỗi do CODE gán vào .text
## mới phải tự vẽ lại, và đó là lý do vẫn phát signal settings_changed.
func set_ngon_ngu(ma: String) -> void:
	if not co_ngon_ngu(ma):
		push_warning("Không có ngôn ngữ '%s', giữ nguyên '%s'." % [ma, ngon_ngu])
		return
	ngon_ngu = ma
	TranslationServer.set_locale(ma)
	settings_changed.emit()


## --- Chuột & màn hình ----------------------------------------------------

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.3, 2.5)
	settings_changed.emit()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	)
	settings_changed.emit()


## --- Lưu / nạp -----------------------------------------------------------

## Trả mọi tùy chọn về mặc định — TRỪ ngôn ngữ.
##
## Cố ý bỏ ngôn ngữ ra ngoài: người chơi bấm "Mặc định" là để sửa lại âm
## lượng / độ sáng mình vừa kéo hỏng, không ai mong giao diện đột ngột nhảy
## sang tiếng Việt. Nút reset mà đổi cả ngôn ngữ thì với người chơi tiếng
## Anh nó biến thành một cái bẫy chứ không phải nút cứu.
func reset_to_default() -> void:
	set_volume("Master", 0.8)
	set_volume("Music", 0.7)
	set_volume("SFX", 0.9)
	set_volume("Video", 1.0)
	set_brightness(1.0)
	set_mouse_sensitivity(1.0)
	set_fullscreen(false)
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for bus_name in BUSES:
		cfg.set_value("audio", bus_name, volumes[bus_name])
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("locale", "ngon_ngu", ngon_ngu)
	cfg.save(CONFIG_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		# Lần chạy đầu chưa có file: áp giá trị mặc định rồi tạo file luôn.
		_apply_all()
		save_settings()
		return
	for bus_name in BUSES:
		volumes[bus_name] = float(cfg.get_value("audio", bus_name, volumes[bus_name]))
	brightness = float(cfg.get_value("video", "brightness", 1.0))
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	mouse_sensitivity = float(cfg.get_value("input", "mouse_sensitivity", 1.0))
	ngon_ngu = String(cfg.get_value("locale", "ngon_ngu", NGON_NGU_MAC_DINH))
	_apply_all()


func _apply_all() -> void:
	for bus_name in BUSES:
		set_volume(bus_name, volumes[bus_name])
	set_brightness(brightness)
	set_mouse_sensitivity(mouse_sensitivity)
	set_fullscreen(fullscreen)
	set_ngon_ngu(ngon_ngu)
