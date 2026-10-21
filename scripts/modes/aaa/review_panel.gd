extends CanvasLayer
## AAA MODE — BẢNG ĐIỂM CUỐI MÀN, kiểu trang tổng hợp đánh giá.
##
## Thay cho results_panel.gd của màn thường. Không xếp hạng, KHÔNG ghi gì vào
## file lưu (không hoàn thành màn, không kỷ lục, không bảng xếp hạng): đây là
## chế độ chơi cho vui, chơi xong là thôi.
##
## Con số thật duy nhất là doanh thu và số lần bị trainer nhắc. Điểm "nhà phê
## bình" cố định 9,6 — đó chính là câu đùa.

const THEME := "res://ui/theme/menu_theme.tres"
const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_GOOD := Color(0.20, 0.55, 0.25)
const COLOR_BAD := Color(0.82, 0.16, 0.12)

var _col: VBoxContainer


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_review(money: int, served: int, nags: int) -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(THEME):
		center.theme = load(THEME)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 12)
	panel.add_child(_col)

	_col.add_child(_label(Lang.t("ĐÁNH GIÁ"), 36, COLOR_TEXT))
	_col.add_child(_label(Lang.t("Nhà phê bình: 9,6/10"), 28, COLOR_GOOD))
	_col.add_child(_label(Lang.t("“Một tuyệt tác. Không ai bị lạc dù chỉ một giây.”"), 20, COLOR_TEXT))
	_col.add_child(_label(Lang.t("Người chơi: 1,2/10"), 28, COLOR_BAD))
	_col.add_child(_label(_player_quote(nags), 20, COLOR_TEXT))
	_col.add_child(_label(Lang.t("Số lần được trainer nhắc: %d") % nags, 22, COLOR_TEXT))
	_col.add_child(_label(Lang.t("Đơn đã phục vụ: %d") % served, 22, COLOR_TEXT))
	_col.add_child(_label(Lang.t("Doanh thu: %d") % money, 22, COLOR_TEXT))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	_col.add_child(row)
	var again := Button.new()
	again.text = Lang.t("Chơi lại")
	again.pressed.connect(_replay)
	row.add_child(again)
	var leave := Button.new()
	leave.text = Lang.t("Về chọn màn")
	leave.pressed.connect(_shutdown)
	row.add_child(leave)
	again.grab_focus()


## Câu bình luận người chơi theo số lần bị nhắc: bị nhắc càng nhiều thì càng
## thấy mình không được chơi.
func _player_quote(nags: int) -> String:
	if nags < 3:
		return Lang.t("“Hướng dẫn hơi nhiều.”")
	if nags <= 8:
		return Lang.t("“Tôi có được chơi không vậy?”")
	return Lang.t("“Game tự chơi giỏi hơn tôi.”")


func _replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


## Rời màn: chiếu đoạn kết "đóng máy" (aaa_outro.tscn). Thông báo của nhà
## phát triển nằm ở câu cuối đoạn đó; kể xong nó tự về màn chọn màn.
func _shutdown() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GameData.AAA_OUTRO_SCENE)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
