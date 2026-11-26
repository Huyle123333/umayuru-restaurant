extends CanvasLayer

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
	process_mode = Node.PROCESS_MODE_ALWAYS

	_btn_resume.pressed.connect(resume)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_menu.pressed.connect(_ask_leave.bind("res://scenes/menu/main_menu.tscn"))
	_add_restart_button()
	_add_unstuck_button()
	_confirm.confirmed.connect(_on_leave_confirmed)

	_root.visible = false


## Nút "Chơi lại" (16/11/2026) — chơi lại ĐÚNG màn này với ĐÚNG nhân vật
func _add_restart_button() -> void:
	var btn := _btn_resume.duplicate(0) as Button
	btn.unique_name_in_owner = false
	btn.name = "BtnRestart"
	btn.text = Lang.t("Chơi lại")
	_btn_resume.add_sibling(btn)
	btn.pressed.connect(_ask_leave.bind(""))


## Nút "Bị kẹt?" — đưa nhân vật về chỗ xuất phát rồi chơi tiếp, không mất tiến trình.
func _add_unstuck_button() -> void:
	var btn := _btn_resume.duplicate(0) as Button
	btn.unique_name_in_owner = false
	btn.name = "BtnUnstuck"
	btn.text = Lang.t("Bị kẹt? Về chỗ xuất phát")
	_btn_menu.add_sibling(btn)
	_btn_menu.get_parent().move_child(btn, _btn_menu.get_index())
	btn.pressed.connect(_on_unstuck_pressed)


func _on_unstuck_pressed() -> void:
	var level := get_parent()
	if level != null and level.has_method("unstuck_player"):
		level.unstuck_player()
	resume()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_btn_resume.grab_focus()


func resume() -> void:
	_root.visible = false
	_settings.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_settings_pressed() -> void:
	_settings.open(_btn_settings)


func _ask_leave(target_scene: String) -> void:
	_pending_scene = target_scene
	if not _confirm.has_meta("leave_text"):
		_confirm.set_meta("leave_text", _confirm.dialog_text)
		_confirm.set_meta("leave_ok", _confirm.ok_button_text)
	if target_scene.is_empty():
		_confirm.dialog_text = Lang.t("Chơi lại từ đầu? Tiến trình màn đang chơi sẽ mất.")
		_confirm.ok_button_text = Lang.t("Chơi lại")
	else:
		_confirm.dialog_text = String(_confirm.get_meta("leave_text"))
		_confirm.ok_button_text = String(_confirm.get_meta("leave_ok"))
	_confirm.popup_centered()


func _on_leave_confirmed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _pending_scene.is_empty():
		get_tree().reload_current_scene()
		return
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
		return Lang.t(label)
	var person: Dictionary = GameData.CHARACTERS.get(who, {})
	return "%s  —  %s" % [Lang.t(label), Lang.t(str(person.get("label", who)))]
