extends Control

@onready var _btn_close: Button = %BtnClose

## Node sẽ được trả lại focus khi đóng bảng — thường là nút đã mở nó ra.
var _focus_on_close: Control = null


func _ready() -> void:
	hide()
	_btn_close.pressed.connect(close)


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	show()
	_btn_close.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
