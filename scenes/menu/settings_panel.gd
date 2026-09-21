extends Control
## Cửa sổ Cài đặt. Dùng lại được ở menu chính và menu Pause sau này.
##
## Panel này KHÔNG tự đụng vào AudioServer hay DisplayServer — mọi thứ đi qua
## SettingsManager. Nhờ vậy chỉ có một nơi biết cách áp dụng cài đặt, và mở
## panel này ở đâu cũng cho kết quả giống nhau.

const ROW := {
	"Master": "SldMaster",
	"Music": "SldMusic",
	"SFX": "SldSfx",
}

@onready var _sld_master: HSlider = %SldMaster
@onready var _sld_music: HSlider = %SldMusic
@onready var _sld_sfx: HSlider = %SldSfx
@onready var _sld_bright: HSlider = %SldBrightness
@onready var _sld_mouse: HSlider = %SldMouse

@onready var _lbl_master: Label = %LblMaster
@onready var _lbl_music: Label = %LblMusic
@onready var _lbl_sfx: Label = %LblSfx
@onready var _lbl_bright: Label = %LblBrightness
@onready var _lbl_mouse: Label = %LblMouse

@onready var _chk_fullscreen: CheckButton = %ChkFullscreen
@onready var _opt_language: OptionButton = %OptNgonNgu
@onready var _btn_default: Button = %BtnDefault
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null


func _ready() -> void:
	hide()
	# Panel phải chạy được cả khi game đang tạm dừng, để dùng trong menu Pause.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_sld_master.value_changed.connect(_on_volume_changed.bind("Master"))
	_sld_music.value_changed.connect(_on_volume_changed.bind("Music"))
	_sld_sfx.value_changed.connect(_on_volume_changed.bind("SFX"))
	_sld_bright.value_changed.connect(_on_brightness_changed)
	_sld_mouse.value_changed.connect(_on_mouse_changed)
	_chk_fullscreen.toggled.connect(_on_fullscreen_toggled)

	_build_language_list()
	_opt_language.item_selected.connect(_on_language_selected)

	_btn_default.pressed.connect(_on_default_pressed)
	_btn_close.pressed.connect(close)


## Đổ danh sách ngôn ngữ vào OptionButton.
##
## Danh sách lấy từ SettingsManager.NGON_NGU chứ không gõ cứng ở đây: thêm
## một ngôn ngữ thứ ba sau này chỉ phải sửa đúng một chỗ, và cái chỗ đó nằm
## cạnh nơi thật sự biết cách áp dụng ngôn ngữ.
##
## set_item_metadata: nhét mã ngôn ngữ ("vi"/"en") vào từng mục thay vì dựa
## vào thứ tự index. Nếu dựa vào index, chỉ cần đảo thứ tự trong danh sách
## là file cài đặt cũ của người chơi trỏ sang ngôn ngữ khác.
func _build_language_list() -> void:
	_opt_language.clear()
	for i in SettingsManager.LANGUAGES.size():
		var entry: Dictionary = SettingsManager.LANGUAGES[i]
		_opt_language.add_item(String(entry["name"]))
		_opt_language.set_item_metadata(i, String(entry["code"]))


func _select_by_code(code_: String) -> void:
	for i in _opt_language.item_count:
		if String(_opt_language.get_item_metadata(i)) == code_:
			_opt_language.select(i)
			return


func _on_language_selected(index: int) -> void:
	SettingsManager.set_language(String(_opt_language.get_item_metadata(index)))


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	_pull_from_settings()
	show()
	_sld_master.grab_focus()


func close() -> void:
	# Lưu một lần lúc đóng, thay vì ghi file mỗi lần kéo thanh trượt.
	SettingsManager.save_settings()
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Nạp giá trị hiện tại vào giao diện.
## set_value_no_signal: đặt giá trị mà KHÔNG phát tín hiệu value_changed —
## nếu không, việc nạp giá trị lại tự kích hoạt hàm xử lý, ghi đè lung tung.
func _pull_from_settings() -> void:
	_sld_master.set_value_no_signal(SettingsManager.get_volume("Master"))
	_sld_music.set_value_no_signal(SettingsManager.get_volume("Music"))
	_sld_sfx.set_value_no_signal(SettingsManager.get_volume("SFX"))
	_sld_bright.set_value_no_signal(SettingsManager.brightness)
	_sld_mouse.set_value_no_signal(SettingsManager.mouse_sensitivity)
	_chk_fullscreen.set_pressed_no_signal(SettingsManager.fullscreen)
	_select_by_code(SettingsManager.language)
	_refresh_labels()


func _refresh_labels() -> void:
	_lbl_master.text = "%d%%" % roundi(_sld_master.value * 100.0)
	_lbl_music.text = "%d%%" % roundi(_sld_music.value * 100.0)
	_lbl_sfx.text = "%d%%" % roundi(_sld_sfx.value * 100.0)
	_lbl_bright.text = "%d%%" % roundi(_sld_bright.value * 100.0)
	_lbl_mouse.text = "%.2fx" % _sld_mouse.value


func _on_volume_changed(value: float, bus_name: String) -> void:
	SettingsManager.set_volume(bus_name, value)
	_refresh_labels()


func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_brightness(value)
	_refresh_labels()


func _on_mouse_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)
	_refresh_labels()


func _on_fullscreen_toggled(on: bool) -> void:
	SettingsManager.set_fullscreen(on)


func _on_default_pressed() -> void:
	SettingsManager.reset_to_default()
	_pull_from_settings()
