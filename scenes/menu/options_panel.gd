extends Control
## Bảng TUỲ CHỌN — một ngăn kéo gom ba mục ít dùng của menu chính:
## Hướng dẫn, Cài đặt, Credits.
##
## ─────────────────────────────────────────────── VÌ SAO GOM LẠI
##
## Menu chính trước đây có bảy dòng: Chơi mới, Chọn màn, Bảng xếp hạng, Hướng
## dẫn, Cài đặt, Credits, Thoát. Bảy dòng bằng nhau về kích thước và màu sắc
## thì mắt phải đọc hết cả bảy mới tìm ra dòng mình cần — trong khi thực tế
## người chơi mở game lên là bấm một trong hai dòng đầu.
##
## Ba mục gom vào đây đều là loại "mở một lần rồi thôi": xem hướng dẫn trước
## khi chơi, chỉnh âm lượng lần đầu, đọc credits một lần. Đẩy chúng xuống một
## tầng thì menu chính còn bốn dòng, và bốn dòng đó đúng là bốn việc người
## chơi thật sự làm.
##
## ─────────────────────────────────────── VÌ SAO DÙNG TÍN HIỆU, KHÔNG TỰ MỞ
##
## Bảng này KHÔNG giữ tham chiếu tới bảng Cài đặt hay Credits. Nó chỉ phát
## tín hiệu "người dùng chọn mục X", còn ai mở cái gì là việc của menu chính.
##
## Lý do: ba bảng kia là node CON CỦA MENU CHÍNH, không phải con của bảng này.
## Nếu bảng này tự đi tìm chúng thì nó phải biết cấu trúc cây scene của cha
## mình (get_parent().get_node("SettingsPanel")...) — kiểu phụ thuộc gãy im
## lặng ngay khi ai đó đổi tên hoặc di chuyển một node. Phát tín hiệu thì bảng
## này dùng lại được ở menu Pause mà không sửa một dòng nào.

signal guide_chosen
signal settings_chosen
signal credits_chosen

@onready var _btn_guide: Button = %BtnGuide
@onready var _btn_settings: Button = %BtnSettings
@onready var _btn_credits: Button = %BtnCredits
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null


func _ready() -> void:
	hide()
	_btn_guide.pressed.connect(func() -> void: guide_chosen.emit())
	_btn_settings.pressed.connect(func() -> void: settings_chosen.emit())
	_btn_credits.pressed.connect(func() -> void: credits_chosen.emit())
	_btn_close.pressed.connect(close)


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	show()
	_btn_guide.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
