extends Control
## Bảng xếp hạng — bốn tab (Màn 1, Màn 2, Màn 3, Endless), mỗi tab là danh
## sách các lượt chơi đã ghi: nhân vật, doanh thu, hạng.
##
## ─────────────────────────────────────────────── VÌ SAO LÀM NHƯ THẾ NÀY
##
## Dữ liệu nằm ở GameData.bang_xep_hang chứ không ở đây. Màn hình này KHÔNG
## tự nhớ gì cả: mở ra thì hỏi, đóng lại thì quên. Nhờ vậy nó không thể lệch
## với file save, và về sau muốn hiện bảng xếp hạng ở chỗ khác (cuối màn
## chẳng hạn) thì chỉ việc hỏi cùng một hàm.
##
## CÁC DÒNG DỰNG BẰNG CODE, không đặt sẵn trong .tscn. Số dòng thay đổi theo
## dữ liệu (0 đến 10), mà mười hàng đặt sẵn rồi ẩn bớt thì lúc nào cũng phải
## nhớ ẩn đúng số còn thừa — một việc dễ quên và khó nhìn ra khi sai. Dựng
## lại từ đầu mỗi lần đổi tab thì trạng thái trên màn hình luôn đúng bằng dữ
## liệu, không có đường nào sai.
##
## TAB DÙNG ButtonGroup: bốn nút cùng nhóm thì Godot tự lo phần "bấm cái này
## thì cái kia nhả ra". Tự viết bằng tay là bốn dòng set_pressed_no_signal
## rải rác, và chỉ cần thêm tab thứ năm là quên một dòng.

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)
const COLOR_GOLD := Color("f2c230")

## Màu của từng hạng — GIỮ ĐÚNG bảng màu của bang_ket_qua.gd để người chơi
## thấy chữ "S" vàng ở đây và chữ "S" vàng ở bảng tổng kết là cùng một thứ.
const COLOR_RANK := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"": Color("9a8f84"),
}

## Ba huy chương cho ba dòng đầu. Không dùng ảnh: ba ký tự này có sẵn trong
## font, không phải nạp thêm tài nguyên nào, và ở cỡ chữ 20 thì nhìn rõ hơn
## một cái icon 20×20 bị thu nhỏ.
const MEDALS: Array[String] = ["🥇", "🥈", "🥉"]

@onready var _tabs: HBoxContainer = %Tabs
@onready var _table: VBoxContainer = %Table
@onready var _lbl_empty: Label = %LblEmpty
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null
var _group := ButtonGroup.new()
var _level_shown: String = ""


func _ready() -> void:
	hide()
	_btn_close.pressed.connect(close)
	_build_tabs()


## Dựng bốn nút tab từ GameData.MAN_XEP_HANG.
##
## Vòng lặp trên bảng dữ liệu chứ không viết tay bốn nút: thêm chế độ chơi
## thứ năm là thêm một dòng trong GameData, màn hình này tự có thêm tab —
## không phải mở .tscn ra kéo node rồi nối tín hiệu.
func _build_tabs() -> void:
	for id in GameData.RANKED_LEVELS:
		var code_ := String(id)
		var btn := Button.new()
		btn.text = String(GameData.RANKED_LEVEL_NAMES.get(code_, code_))
		btn.toggle_mode = true
		btn.button_group = _group
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_select_level.bind(code_))
		_tabs.add_child(btn)


## Mở bảng. `focus_on_close` là nút sẽ được trả lại focus lúc đóng, để chơi
## bằng bàn phím không bị mất dấu con trỏ.
func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	show()
	# Luôn mở ở tab đầu tiên: người mở bảng đang muốn xem, không đang tiếp tục
	# một việc dở — nhớ tab cũ chỉ làm họ phải kiểm tra xem mình đang ở đâu.
	var first := String(GameData.RANKED_LEVELS[0])
	var first_btn := _tabs.get_child(0) as Button
	first_btn.button_pressed = true
	_select_level(first)
	first_btn.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------- nội dung ---

func _select_level(level_id: String) -> void:
	_level_shown = level_id
	_draw_table()


func _draw_table() -> void:
	# Xoá sạch rồi dựng lại. queue_free() KHÔNG xoá ngay trong khung hình này
	# — node vẫn còn trong cây tới cuối khung — nên phải remove_child() trước,
	# nếu không mấy dòng cũ vẫn kịp hiện chồng lên dòng mới một nhịp.
	for child in _table.get_children():
		_table.remove_child(child)
		child.queue_free()

	var list_ := GameData.level_leaderboard(_level_shown)
	if list_.is_empty():
		_lbl_empty.show()
		# Endless chưa làm nên nói rõ là "chưa có chế độ", chứ không nói
		# "chưa ai chơi" — hai câu đó dẫn người đọc đi hai hướng khác nhau.
		_lbl_empty.text = tr("RANK_ENDLESS_SOON") if _level_shown == "endless" else tr("RANK_EMPTY")
		return

	_lbl_empty.hide()
	_table.add_child(_header_row())
	for i in list_.size():
		var record: Dictionary = list_[i]
		_table.add_child(_data_row(i, record))


func _header_row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(_cell("#", 46, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	h.add_child(_cell(tr("RANK_COL_CHARACTER"), 0, COLOR_DIM, 17))
	h.add_child(_cell(tr("RANK_COL_MONEY"), 130, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_RIGHT))
	h.add_child(_cell(tr("RANK_COL_PLACE"), 60, COLOR_DIM, 17, HORIZONTAL_ALIGNMENT_CENTER))
	return h


func _data_row(index: int, record: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)

	# Kiểu ghi rõ ràng, không dùng ":=": HUY_CHUONG là hằng mảng, và giá trị
	# lấy ra từ mảng hằng bị GDScript coi là Variant nên không suy ra được kiểu.
	var place: String = MEDALS[index] if index < MEDALS.size() \
		else str(index + 1)
	h.add_child(_cell(place, 46, COLOR_TEXT, 20, HORIZONTAL_ALIGNMENT_CENTER))

	var name_ := GameData.character_name(String(record.get("character", record.get("nv", ""))))
	# Ba dòng đầu tô vàng: mắt phải bắt được "ai đang dẫn đầu" trước khi đọc
	# tới cột tiền.
	var name_color: Color = COLOR_GOLD if index == 0 else COLOR_TEXT
	h.add_child(_cell(name_, 0, name_color, 20))

	h.add_child(_cell(str(int(record.get("money", record.get("tien", 0)))), 130, COLOR_TEXT, 20,
		HORIZONTAL_ALIGNMENT_RIGHT))

	var rank := String(record.get("rank", record.get("hang", "")))
	var rank_cell: Label = _cell(rank if not rank.is_empty() else "—", 60,
		Color(COLOR_RANK.get(rank, COLOR_RANK[""])), 20, HORIZONTAL_ALIGNMENT_CENTER)
	h.add_child(rank_cell)
	return h


## Một ô chữ trong bảng. `rong` = 0 nghĩa là ô co giãn chiếm hết chỗ trống —
## đúng một ô như thế mỗi hàng (cột tên), nhờ vậy ba cột còn lại có bề rộng
## cố định và các hàng thẳng cột với nhau mà không cần GridContainer.
func _cell(text_: String, width: int, color_: Color, size_: int,
		can: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", color_)
	l.horizontal_alignment = can
	if width > 0:
		l.custom_minimum_size = Vector2(width, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
