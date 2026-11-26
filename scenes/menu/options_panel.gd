extends Control
## ─────────────────────────────────────────────── VÌ SAO GOM LẠI
## ─────────────────────────────────────── VÌ SAO DÙNG TÍN HIỆU, KHÔNG TỰ MỞ

signal guide_chosen
signal settings_chosen
signal credits_chosen

@onready var _btn_guide: Button = %BtnGuide
@onready var _btn_settings: Button = %BtnSettings
@onready var _btn_credits: Button = %BtnCredits
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null

## Trang báo cáo lỗi (Google Form: loại lỗi, mô tả, ảnh chụp màn hình).
const BUG_REPORT_URL := "https://docs.google.com/forms/d/1zMtnpmOHxI8myLD-acP5d5yIE2QB2FDSZXqiiimh8ow/viewform"
var _btn_report: Button


func _ready() -> void:
	hide()
	_btn_guide.pressed.connect(func() -> void: guide_chosen.emit())
	_btn_settings.pressed.connect(func() -> void: settings_chosen.emit())
	_btn_credits.pressed.connect(func() -> void: credits_chosen.emit())
	_btn_close.pressed.connect(close)
	_add_report_button()


## Nút "Báo cáo lỗi" — dựng bằng code, nhân bản nút Credits cho cùng kiểu
func _add_report_button() -> void:
	_btn_report = _btn_credits.duplicate(0) as Button
	_btn_report.unique_name_in_owner = false
	_btn_report.name = "BtnReport"
	_btn_report.text = Lang.t("Báo cáo lỗi")
	_btn_credits.add_sibling(_btn_report)
	if BUG_REPORT_URL.is_empty():
		_btn_report.disabled = true
		_btn_report.tooltip_text = Lang.t("Chưa có trang báo cáo")
		return
	_btn_report.pressed.connect(func() -> void: OS.shell_open(BUG_REPORT_URL))


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
