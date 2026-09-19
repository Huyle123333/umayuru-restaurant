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

const MAU_CHU := Color(0.29, 0.153, 0.071)
const MAU_MO := Color(0.52, 0.38, 0.22)
const MAU_VANG := Color("f2c230")

## Màu của từng hạng — GIỮ ĐÚNG bảng màu của bang_ket_qua.gd để người chơi
## thấy chữ "S" vàng ở đây và chữ "S" vàng ở bảng tổng kết là cùng một thứ.
const MAU_HANG := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"": Color("9a8f84"),
}

## Ba huy chương cho ba dòng đầu. Không dùng ảnh: ba ký tự này có sẵn trong
## font, không phải nạp thêm tài nguyên nào, và ở cỡ chữ 20 thì nhìn rõ hơn
## một cái icon 20×20 bị thu nhỏ.
const HUY_CHUONG: Array[String] = ["🥇", "🥈", "🥉"]

@onready var _tabs: HBoxContainer = %Tabs
@onready var _bang: VBoxContainer = %Bang
@onready var _lbl_trong: Label = %LblTrong
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null
var _nhom := ButtonGroup.new()
var _man_dang_xem: String = ""


func _ready() -> void:
	hide()
	_btn_close.pressed.connect(close)
	_dung_tab()


## Dựng bốn nút tab từ GameData.MAN_XEP_HANG.
##
## Vòng lặp trên bảng dữ liệu chứ không viết tay bốn nút: thêm chế độ chơi
## thứ năm là thêm một dòng trong GameData, màn hình này tự có thêm tab —
## không phải mở .tscn ra kéo node rồi nối tín hiệu.
func _dung_tab() -> void:
	for id in GameData.MAN_XEP_HANG:
		var ma := String(id)
		var nut := Button.new()
		nut.text = String(GameData.TEN_MAN_XEP_HANG.get(ma, ma))
		nut.toggle_mode = true
		nut.button_group = _nhom
		nut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nut.pressed.connect(_chon_man.bind(ma))
		_tabs.add_child(nut)


## Mở bảng. `focus_on_close` là nút sẽ được trả lại focus lúc đóng, để chơi
## bằng bàn phím không bị mất dấu con trỏ.
func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	show()
	# Luôn mở ở tab đầu tiên: người mở bảng đang muốn xem, không đang tiếp tục
	# một việc dở — nhớ tab cũ chỉ làm họ phải kiểm tra xem mình đang ở đâu.
	var dau := String(GameData.MAN_XEP_HANG[0])
	var nut_dau := _tabs.get_child(0) as Button
	nut_dau.button_pressed = true
	_chon_man(dau)
	nut_dau.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------- nội dung ---

func _chon_man(id_man: String) -> void:
	_man_dang_xem = id_man
	_ve_bang()


func _ve_bang() -> void:
	# Xoá sạch rồi dựng lại. queue_free() KHÔNG xoá ngay trong khung hình này
	# — node vẫn còn trong cây tới cuối khung — nên phải remove_child() trước,
	# nếu không mấy dòng cũ vẫn kịp hiện chồng lên dòng mới một nhịp.
	for con in _bang.get_children():
		_bang.remove_child(con)
		con.queue_free()

	var ds := GameData.xep_hang_cua_man(_man_dang_xem)
	if ds.is_empty():
		_lbl_trong.show()
		# Endless chưa làm nên nói rõ là "chưa có chế độ", chứ không nói
		# "chưa ai chơi" — hai câu đó dẫn người đọc đi hai hướng khác nhau.
		_lbl_trong.text = tr("RANK_ENDLESS_SOON") if _man_dang_xem == "endless" else tr("RANK_EMPTY")
		return

	_lbl_trong.hide()
	_bang.add_child(_hang_tieu_de())
	for i in ds.size():
		var ban_ghi: Dictionary = ds[i]
		_bang.add_child(_hang_du_lieu(i, ban_ghi))


func _hang_tieu_de() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(_o("#", 46, MAU_MO, 17, HORIZONTAL_ALIGNMENT_CENTER))
	h.add_child(_o(tr("RANK_COL_CHARACTER"), 0, MAU_MO, 17))
	h.add_child(_o(tr("RANK_COL_MONEY"), 130, MAU_MO, 17, HORIZONTAL_ALIGNMENT_RIGHT))
	h.add_child(_o(tr("RANK_COL_PLACE"), 60, MAU_MO, 17, HORIZONTAL_ALIGNMENT_CENTER))
	return h


func _hang_du_lieu(chi_so: int, ban_ghi: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)

	# Kiểu ghi rõ ràng, không dùng ":=": HUY_CHUONG là hằng mảng, và giá trị
	# lấy ra từ mảng hằng bị GDScript coi là Variant nên không suy ra được kiểu.
	var thu_tu: String = HUY_CHUONG[chi_so] if chi_so < HUY_CHUONG.size() \
		else str(chi_so + 1)
	h.add_child(_o(thu_tu, 46, MAU_CHU, 20, HORIZONTAL_ALIGNMENT_CENTER))

	var ten := GameData.ten_nhan_vat(String(ban_ghi.get("nv", "")))
	# Ba dòng đầu tô vàng: mắt phải bắt được "ai đang dẫn đầu" trước khi đọc
	# tới cột tiền.
	var mau_ten: Color = MAU_VANG if chi_so == 0 else MAU_CHU
	h.add_child(_o(ten, 0, mau_ten, 20))

	h.add_child(_o(str(int(ban_ghi.get("tien", 0))), 130, MAU_CHU, 20,
		HORIZONTAL_ALIGNMENT_RIGHT))

	var hang := String(ban_ghi.get("hang", ""))
	var o_hang: Label = _o(hang if not hang.is_empty() else "—", 60,
		Color(MAU_HANG.get(hang, MAU_HANG[""])), 20, HORIZONTAL_ALIGNMENT_CENTER)
	h.add_child(o_hang)
	return h


## Một ô chữ trong bảng. `rong` = 0 nghĩa là ô co giãn chiếm hết chỗ trống —
## đúng một ô như thế mỗi hàng (cột tên), nhờ vậy ba cột còn lại có bề rộng
## cố định và các hàng thẳng cột với nhau mà không cần GridContainer.
func _o(chu: String, rong: int, mau: Color, co: int,
		can: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = chu
	l.add_theme_font_size_override("font_size", co)
	l.add_theme_color_override("font_color", mau)
	l.horizontal_alignment = can
	if rong > 0:
		l.custom_minimum_size = Vector2(rong, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
