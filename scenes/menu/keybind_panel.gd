extends Control
## Bảng GÁN PHÍM — mở từ nút "Đổi phím..." trong bảng Cài đặt.
##
## Bảng này chỉ là GIAO DIỆN. Mọi luật (hành động nào đổi được, phím nào bị
## cấm, trùng phím thì đổi chỗ, lưu vào đâu) nằm ở SettingsManager — bảng chỉ
## hỏi và hiển thị. Nhờ vậy sau này muốn gán phím từ một chỗ khác (ví dụ ngay
## trong màn hướng dẫn) thì không phải chép lại luật.
##
## Dựng bằng CODE chứ không làm file .tscn: danh sách hàng sinh ra từ
## SettingsManager.REBINDABLE, thêm một hành động vào đó là bảng tự có thêm
## hàng. Dựng tay trong .tscn thì mỗi hành động mới phải thêm ba node.
##
## CÁCH DÙNG: bấm vào ô phím → ô chuyển sang "Bấm một phím..." → bấm phím mới.
## ESC lúc đang chờ = huỷ lần gán đó; ESC lúc không chờ = đóng bảng.

const PANEL_SIZE := Vector2(620, 0)
const LIST_HEIGHT := 380.0

## Hành động đang CHỜ phím mới. Rỗng = không chờ gì.
var _waiting_action := ""
## action -> Button hiện tên phím.
var _key_buttons: Dictionary = {}
var _lbl_hint: Label
var _focus_on_close: Control = null


func _ready() -> void:
	hide()
	# Dùng được cả khi game đang tạm dừng (bảng Cài đặt mở từ menu Pause).
	process_mode = Node.PROCESS_MODE_ALWAYS
	# set_anchors_AND_OFFSETS_preset, không phải set_anchors_preset: hàm sau
	# chỉ đổi neo mà giữ nguyên offset, nên một Control vừa tạo (cỡ 0×0) vẫn
	# là 0×0 dính ở góc trên-trái — đúng lỗi của bản đầu, bảng hiện lệch góc
	# và lớp nền tối không phủ màn hình.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var title := Label.new()
	title.text = "KEYBIND_TITLE"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_lbl_hint = Label.new()
	_lbl_hint.add_theme_font_size_override("font_size", 16)
	_lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_lbl_hint)

	# Danh sách CUỘN DỌC: mười một hàng không vừa màn hình 720p nếu để thẳng.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	for entry in SettingsManager.REBINDABLE:
		var action := String(entry["action"])

		var name_ := Label.new()
		name_.text = String(entry["label"])
		name_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(name_)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 0)
		btn.add_theme_font_size_override("font_size", 20)
		# Tên phím ("E", "Shift") không phải khoá dịch — tắt tự dịch để Godot
		# khỏi đi tra một phím tên "Space" trong bảng dịch.
		btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		btn.pressed.connect(_start_waiting.bind(action))
		grid.add_child(btn)
		_key_buttons[action] = btn

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	col.add_child(buttons)

	var btn_reset := Button.new()
	btn_reset.text = "KEYBIND_RESET"
	btn_reset.pressed.connect(_on_reset_pressed)
	buttons.add_child(btn_reset)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(gap)

	var btn_close := Button.new()
	btn_close.text = "COMMON_CLOSE"
	btn_close.pressed.connect(close)
	buttons.add_child(btn_close)


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	_waiting_action = ""
	_refresh()
	show()


func close() -> void:
	_waiting_action = ""
	SettingsManager.save_settings()
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


## Vẽ lại MỌI ô theo InputMap thật. Vẽ lại tất cả chứ không chỉ ô vừa đổi:
## gán trùng thì hai hành động đổi chỗ phím, tức là có HAI ô thay đổi.
func _refresh(hint_key: String = "KEYBIND_HINT") -> void:
	for action in _key_buttons:
		var btn: Button = _key_buttons[action]
		if String(action) == _waiting_action:
			btn.text = tr("KEYBIND_WAITING")
		else:
			btn.text = SettingsManager.key_name(String(action))
	_lbl_hint.text = hint_key


func _start_waiting(action: String) -> void:
	_waiting_action = action
	_refresh()
	# Nhả focus khỏi nút: nếu không thì phím Space / Enter vừa bấm để GÁN lại
	# kích luôn cái nút đang focus, và bảng quay lại trạng thái chờ lần nữa.
	(_key_buttons[action] as Button).release_focus()


func _on_reset_pressed() -> void:
	_waiting_action = ""
	SettingsManager.reset_keys()
	_refresh()


## Bắt phím ở _input (sớm nhất), không phải _unhandled_input: lúc đang chờ,
## phím vừa bấm KHÔNG được chạy tới bất kỳ ai khác — không tới nút đang focus,
## không tới bảng Cài đặt bên dưới, không tới màn chơi.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	if _waiting_action.is_empty():
		if key.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()
		return

	get_viewport().set_input_as_handled()
	if key.physical_keycode == KEY_ESCAPE:
		_waiting_action = ""
		_refresh()
		return

	var action := _waiting_action
	_waiting_action = ""
	if SettingsManager.set_key(action, int(key.physical_keycode)):
		_refresh()
	else:
		# Phím bị cấm (F1, 1, 0, P): giữ nguyên phím cũ và nói rõ lý do, thay
		# vì im lặng không đổi — im lặng thì người chơi tưởng bảng bị hỏng.
		_refresh("KEYBIND_RESERVED")
