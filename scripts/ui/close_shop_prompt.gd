extends CanvasLayer

signal confirmed

const THEME_PATH := "res://ui/theme/menu_theme.tres"

var _was_paused := false
var _old_mouse_mode := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	_old_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(THEME_PATH):
		root.theme = load(THEME_PATH)
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	panel.add_child(col)

	var title := Label.new()
	title.text = "CLOSE_SHOP_ASK"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)

	var btn_yes := Button.new()
	btn_yes.text = "CLOSE_SHOP_YES"
	btn_yes.custom_minimum_size = Vector2(170, 0)
	btn_yes.pressed.connect(_on_yes)
	row.add_child(btn_yes)

	var btn_no := Button.new()
	btn_no.text = "CLOSE_SHOP_NO"
	btn_no.custom_minimum_size = Vector2(170, 0)
	btn_no.pressed.connect(_on_no)
	row.add_child(btn_no)

	btn_no.grab_focus()


## ESC = Chờ đã. Bắt ở _input và nuốt phím, để menu Tạm dừng phía dưới không
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_no()


func _restore() -> void:
	get_tree().paused = _was_paused
	Input.mouse_mode = _old_mouse_mode


func _on_no() -> void:
	_restore()
	queue_free()


func _on_yes() -> void:
	_restore()
	confirmed.emit()
	queue_free()
