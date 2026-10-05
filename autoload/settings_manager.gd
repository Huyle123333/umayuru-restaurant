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
const LANGUAGES := [
	{"code": "vi", "name": "Tiếng Việt"},
	{"code": "en", "name": "English"},
]
const DEFAULT_LANGUAGE := "vi"

## Mã ngôn ngữ đang dùng ("vi" / "en").
var language := DEFAULT_LANGUAGE

var _brightness_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_brightness_layer()
	# Chụp phím MẶC ĐỊNH trước khi load_settings() ghi đè bằng phím đã lưu.
	# Đảo hai dòng này là "mặc định" thành chính bộ phím người chơi đã đổi,
	# và nút Đặt lại mặc định không còn đặt lại được gì.
	_register_extra_actions()
	_remember_default_keys()
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
	var material_ := ShaderMaterial.new()
	material_.shader = shader

	_brightness_rect = ColorRect.new()
	_brightness_rect.material = material_
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

func has_language(code_: String) -> bool:
	for entry in LANGUAGES:
		if entry["code"] == code_:
			return true
	return false


func language_name(code_: String) -> String:
	for entry in LANGUAGES:
		if entry["code"] == code_:
			return String(entry["name"])
	return code_


## Đổi ngôn ngữ hiển thị của toàn game.
##
## Chỉ cần một dòng TranslationServer.set_locale() là đủ cho phần lớn giao
## diện: Godot gửi thông báo NOTIFICATION_TRANSLATION_CHANGED xuống cả cây
## scene, và mọi node Control có auto_translate (mặc định bật) tự dịch lại
## text của nó. Nghĩa là các nhãn/nút đặt sẵn trong file .tscn đổi ngay lập
## tức mà không cần chạy lại scene — chỉ những chuỗi do CODE gán vào .text
## mới phải tự vẽ lại, và đó là lý do vẫn phát signal settings_changed.
func set_language(code_: String) -> void:
	if not has_language(code_):
		push_warning("Không có ngôn ngữ '%s', giữ nguyên '%s'." % [code_, language])
		return
	language = code_
	TranslationServer.set_locale(code_)
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


# ══════════════════════════════════════════════ GÁN PHÍM (2/10/2026)
#
# Người chơi tự đổi phím cho các hành động trong REBINDABLE. Phím lưu trong
# settings.cfg (mục "keys") — cùng file với âm lượng, vì đây là thói quen của
# NGƯỜI NGỒI MÁY chứ không phải tiến trình chơi: xoá save không được làm mất
# bộ phím đã quen tay.
#
# Lưu và so bằng physical_keycode (VỊ TRÍ phím trên bàn phím), giống hệt cách
# project.godot đang khai: người dùng bàn phím AZERTY vẫn có cụm WASD nằm
# đúng chỗ tay trái.

## Các hành động cho phép đổi phím, theo thứ tự hiện trên bảng. "label" là
## khoá dịch trong locale/translations.csv.
##
## KHÔNG có "pause" (ESC) và "toggle_view" (P): ESC còn là phím đóng mọi
## bảng, đổi nó đi là có thể tự nhốt mình trong một cái bảng; P là phím cheat.
const REBINDABLE := [
	{"action": "move_up", "label": "KEY_MOVE_UP"},
	{"action": "move_down", "label": "KEY_MOVE_DOWN"},
	{"action": "move_left", "label": "KEY_MOVE_LEFT"},
	{"action": "move_right", "label": "KEY_MOVE_RIGHT"},
	{"action": "interact", "label": "KEY_INTERACT"},
	{"action": "assemble", "label": "KEY_ASSEMBLE"},
	{"action": "drop_item", "label": "KEY_DROP"},
	{"action": "dash", "label": "KEY_DASH"},
	{"action": "skill", "label": "KEY_SKILL"},
	{"action": "cycle_target", "label": "KEY_CYCLE_TARGET"},
	{"action": "cancel_menu", "label": "KEY_CANCEL_MENU"},
	{"action": "toggle_orders", "label": "KEY_TOGGLE_ORDERS"},
	{"action": "toggle_menu", "label": "KEY_TOGGLE_MENU"},
	{"action": "skill_alt", "label": "KEY_SKILL_ALT"},
]

## Hành động KHAI BẰNG CODE thay vì trong project.godot: action -> phím mặc định.
##
## Vì sao không khai trong project.godot như mười một hành động kia: mục input
## của file đó là các đối tượng InputEventKey tuần tự hoá, chỉ editor ghi cho
## đúng được — sửa tay sai một trường là cả bảng phím hỏng. Hai hành động này
## chỉ là phím tắt HUD, không node nào trong scene tham chiếu tới, nên đăng ký
## lúc khởi động là đủ và an toàn. Autoload này chạy trước mọi scene, nên tới
## lúc HUD hỏi thì hành động đã tồn tại.
const EXTRA_ACTIONS := {
	"toggle_orders": KEY_1,
	"toggle_menu": KEY_2,
	"skill_alt": KEY_3,
}

func _register_extra_actions() -> void:
	for action in EXTRA_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = EXTRA_ACTIONS[action]
		InputMap.action_add_event(action, ev)

## Phím KHÔNG được gán vì game đang bắt cứng ở chỗ khác: ESC (tạm dừng / đóng
## bảng), F1 (hướng dẫn), 0 và P (cheat).
##
## Phím 1 đã ra khỏi danh sách này: bảng đơn hàng giờ đọc hành động
## "toggle_orders" chứ không bắt cứng KEY_1, nên nó đổi được như mọi phím khác.
const RESERVED_KEYS := [KEY_ESCAPE, KEY_F1, KEY_0, KEY_P]

## Phím mặc định: action -> physical_keycode. Chụp lúc khởi động.
var _default_keys: Dictionary = {}


func _remember_default_keys() -> void:
	for entry in REBINDABLE:
		var action := String(entry["action"])
		_default_keys[action] = key_of(action)


## Phím CHÍNH của một hành động (phím bàn phím đầu tiên trong InputMap).
## 0 = hành động không có phím nào.
func key_of(action: String) -> int:
	if not InputMap.has_action(action):
		return 0
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return int((ev as InputEventKey).physical_keycode)
	return 0


## Tên phím để hiện trên nút, ví dụ "E", "Shift", "Space".
func key_name(action: String) -> String:
	var code_ := key_of(action)
	return OS.get_keycode_string(code_) if code_ != 0 else "—"


func is_reserved_key(code_: int) -> bool:
	return RESERVED_KEYS.has(code_)


## Gán phím mới cho một hành động. Trả về false nếu phím bị cấm.
##
## Phím đó đang thuộc hành động KHÁC thì hai hành động ĐỔI CHỖ phím cho nhau.
## Đổi chỗ chứ không từ chối và cũng không để trùng: từ chối thì muốn hoán
## hai phím phải đi qua một phím thứ ba; để trùng thì một lần bấm làm hai
## việc (vừa nhặt đồ vừa vứt đồ) — lỗi mà người chơi không hiểu tại sao.
func set_key(action: String, code_: int) -> bool:
	if is_reserved_key(code_) or code_ == 0:
		return false
	var old := key_of(action)
	if old == code_:
		return true
	for entry in REBINDABLE:
		var other := String(entry["action"])
		if other != action and key_of(other) == code_:
			_write_key(other, old)
	_write_key(action, code_)
	settings_changed.emit()
	return true


func reset_keys() -> void:
	for action in _default_keys:
		_write_key(String(action), int(_default_keys[action]))
	settings_changed.emit()
	save_settings()


## Thay phím CHÍNH của hành động, giữ nguyên các phím phụ (mũi tên của bốn
## hướng đi). Xoá hết rồi thêm lại theo thứ tự "phím mới trước" để key_of()
## — vốn lấy phím đầu tiên — luôn trả về đúng phím vừa gán.
func _write_key(action: String, code_: int) -> void:
	if not InputMap.has_action(action) or code_ == 0:
		return
	var keep: Array[InputEvent] = []
	var skipped_primary := false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and not skipped_primary:
			skipped_primary = true
			continue
		keep.append(ev)
	InputMap.action_erase_events(action)
	var fresh := InputEventKey.new()
	fresh.physical_keycode = code_ as Key
	InputMap.action_add_event(action, fresh)
	for ev in keep:
		# Phím phụ trùng phím mới thì bỏ, khỏi khai một phím hai lần.
		if ev is InputEventKey and int((ev as InputEventKey).physical_keycode) == code_:
			continue
		InputMap.action_add_event(action, ev)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for entry in REBINDABLE:
		cfg.set_value("keys", String(entry["action"]), key_of(String(entry["action"])))
	for bus_name in BUSES:
		cfg.set_value("audio", bus_name, volumes[bus_name])
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("locale", "language", language)
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
	# Khoá cũ "ngon_ngu" vẫn đọc được để không mất lựa chọn ngôn ngữ đã lưu.
	language = String(cfg.get_value("locale", "language",
		cfg.get_value("locale", "ngon_ngu", DEFAULT_LANGUAGE)))
	# Phím đã lưu. Chỉ đọc những hành động CÒN trong REBINDABLE và bỏ qua phím
	# bị cấm: file cấu hình là thứ người chơi sửa tay được, và bản game sau có
	# thể đổi danh sách.
	for entry in REBINDABLE:
		var action := String(entry["action"])
		if cfg.has_section_key("keys", action):
			var code_ := int(cfg.get_value("keys", action, 0))
			if code_ != 0 and not is_reserved_key(code_):
				_write_key(action, code_)
	_apply_all()


func _apply_all() -> void:
	for bus_name in BUSES:
		set_volume(bus_name, volumes[bus_name])
	set_brightness(brightness)
	set_mouse_sensitivity(mouse_sensitivity)
	set_fullscreen(fullscreen)
	set_language(language)
