extends CanvasLayer
## Menu Pause, dùng chung cho MỌI màn chơi.
##
## Không đặt sẵn trong file map. level_base.gd tự sinh ra nó khi màn chơi khởi
## động, nên thêm một màn mới không phải nhớ kéo menu Pause vào — thiếu một cái
## là màn đó không thoát ra được, mà lỗi kiểu đó rất khó nhớ.
##
## Dùng CanvasLayer chứ không phải Control: CanvasLayer vẽ tách khỏi camera 3D
## và khỏi HUD của nhân vật, đặt layer 100 là chắc chắn nằm trên cùng.

@onready var _root: Control = %Root
@onready var _lbl_level: Label = %LblLevel
@onready var _btn_resume: Button = %BtnResume
@onready var _btn_settings: Button = %BtnSettings
@onready var _btn_menu: Button = %BtnMenu
@onready var _settings: Control = %SettingsPanel
@onready var _confirm: ConfirmationDialog = %ConfirmQuit

## Đích của nút vừa bấm, chờ người chơi xác nhận trong hộp thoại.
var _pending_scene := ""


func _ready() -> void:
	# Cả cây game bị đóng băng khi tạm dừng, nên bản thân menu phải được
	# miễn trừ — nếu không thì mở ra rồi không bấm được nút nào để thoát.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_btn_resume.pressed.connect(resume)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_menu.pressed.connect(_ask_leave.bind("res://scenes/menu/main_menu.tscn"))
	_confirm.confirmed.connect(_on_leave_confirmed)

	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	# Khi bảng Cài đặt đang mở thì Esc thuộc về nó (đóng bảng), không phải
	# của menu Pause. Bỏ qua ở đây để tránh đóng luôn cả menu.
	if _settings.visible:
		return
	if _root.visible:
		resume()
	else:
		pause()
	get_viewport().set_input_as_handled()


func pause() -> void:
	_lbl_level.text = _level_label()
	_root.visible = true
	# Thả chuột ra, nếu không người chơi thấy con trỏ biến mất, không bấm được.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_btn_resume.grab_focus()


func resume() -> void:
	_root.visible = false
	_settings.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_settings_pressed() -> void:
	# Dùng lại đúng scene Cài đặt của menu chính — một bản duy nhất, sửa một
	# lần là cả hai nơi cùng đổi. Đó là lý do settings_panel.gd không tự đụng
	# vào AudioServer mà đi qua SettingsManager.
	_settings.open(_btn_settings)


func _ask_leave(target_scene: String) -> void:
	_pending_scene = target_scene
	_confirm.popup_centered()


func _on_leave_confirmed() -> void:
	# Bỏ tạm dừng TRƯỚC khi đổi scene: scene mới thừa hưởng trạng thái paused
	# của cây, quên dòng này thì menu chính hiện ra nhưng bấm gì cũng không ăn.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(_pending_scene)


## Tên màn đang chơi, lấy từ bảng LEVELS để không phải chép tên ra chỗ khác.
func _level_label() -> String:
	var id := GameData.current_level
	if id.is_empty():
		return ""
	var info: Dictionary = GameData.LEVELS.get(id, {})
	var label := str(info.get("label", id))
	var who := GameData.selected_character
	if who.is_empty():
		return label
	var person: Dictionary = GameData.CHARACTERS.get(who, {})
	return "%s  —  %s" % [label, str(person.get("label", who))]
