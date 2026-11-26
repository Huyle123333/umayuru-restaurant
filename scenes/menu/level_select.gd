extends Control

@export_file("*.tscn") var character_select_scene: String = "res://scenes/menu/character_select.tscn"
@export_file("*.tscn") var main_menu_scene: String = "res://scenes/menu/main_menu.tscn"

## Nối id màn (trong GameData.LEVELS) với nút tương ứng trên màn hình.
@onready var _buttons: Dictionary = {
	"prologue": %BtnPrologue,
	"tutorial": %BtnTutorial,
	"d1_sang": %BtnD1Morning,
	"d2_sang": %BtnD2Morning,
	"d3_sang": %BtnD3Morning,
	"ending": %BtnEnding,
}

## Khoá dịch cho nút của từng ngày.
const DAY_LABELS := {
	"d1_sang": "LEVEL_DAY_1",
	"d2_sang": "LEVEL_DAY_2",
	"d3_sang": "LEVEL_DAY_3",
}

## ── HAI KHUNG (1/10/2026) ──────────────────────────────────────────────

## Các CHẾ ĐỘ chưa có nội dung. Nằm ngoài _buttons vì chúng không có trong
@onready var _modes: Dictionary = {
	"endless": %BtnEndless,
	"asian": %BtnAsian,
	"aaa": %BtnAaa,
}

## Bảng mô tả CHẾ ĐỘ — chỉ chế độ mới có, màn chính bấm là vào thẳng.
@onready var _detail: Control = %ModeDetail
@onready var _detail_dim: ColorRect = %Dim
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_desc: Label = %DetailDesc
@onready var _btn_start: Button = %BtnStart
@onready var _btn_close_detail: Button = %BtnCloseDetail

## Chế độ đang mở bảng. Rỗng = bảng đóng.
var _selected := ""

## Khoá dịch của đoạn mô tả từng chế độ. Nội dung viết trong
const MODE_DESC := {
	"endless": "LEVEL_DESC_ENDLESS",
	"asian": "LEVEL_DESC_ASIAN",
	"aaa": "LEVEL_DESC_AAA",
	"plan_b": "Thử bộ công thức mới (phương án B): thực đơn chia theo họ món.\n\nKhông đếm ngược, không hết giờ, khách chỉ vào khi bạn gọi.\n\nPhím tắt trong màn:\n  F5  mở bảng chọn món (chọn xong khách vào ngay)\n  F6  về món ngẫu nhiên\n  F7  đổi loại khách\n  F8  gọi một khách vào ngay",
}

@onready var _btn_back: Button = %BtnBack
## Bảng xếp hạng — nằm ở ĐÂY chứ không ở menu chính.
@onready var _btn_board: Button = %BtnBoard
@onready var _board: Control = %LeaderboardPanel
@onready var _btn_wipe: Button = %BtnWipe
@onready var _confirm_wipe: ConfirmationDialog = %ConfirmWipe


func _ready() -> void:
	AmThanh.play_random_music("menu", true)

	_name_day_buttons()

	for id in _buttons:
		var btn: Button = _buttons[id]
		btn.set_meta("base_text", btn.text)
		btn.pressed.connect(_on_level_pressed.bind(id))

	_add_plan_b_button()
	for id in _modes:
		var mode_btn: Button = _modes[id]
		if not GameData.LEVELS.has(id):
			mode_btn.tooltip_text = tr("LEVEL_COMING_SOON")
		mode_btn.pressed.connect(_open_mode.bind(id))

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_close_detail.pressed.connect(_close_detail)
	_detail_dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_detail())

	_btn_back.pressed.connect(_on_back_pressed)
	_btn_board.pressed.connect(func() -> void: _board.open(_btn_board))
	_btn_wipe.pressed.connect(_confirm_wipe.popup_centered)
	_confirm_wipe.confirmed.connect(_on_wipe_confirmed)

	GameData.progress_changed.connect(_refresh)
	_refresh()


## Đặt tên "Ngày N" cho nút của từng ngày và ẩn tiêu đề cột.
func _name_day_buttons() -> void:
	for id in DAY_LABELS:
		var btn: Button = _buttons[id]
		btn.text = String(DAY_LABELS[id])
		var title := btn.get_parent().get_node_or_null("Header") as Control
		if title != null:
			title.hide()


func _refresh() -> void:
	var first_open: Button = null
	for id in _buttons:
		var btn: Button = _buttons[id]
		var unlocked := GameData.is_unlocked(id)
		btn.disabled = not unlocked
		btn.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE

		var base := str(btn.get_meta("base_text"))
		btn.text = tr(base) + "  ✔" if GameData.is_completed(id) else base

		if unlocked:
			btn.tooltip_text = Lang.t("Doanh thu tốt nhất: %d") % GameData.get_best_money(id)
			if first_open == null:
				first_open = btn
		else:
			btn.tooltip_text = Lang.t("Chưa mở khóa")

	# Nút Xóa dữ liệu chỉ có nghĩa khi thực sự có gì để xóa.
	_btn_wipe.disabled = not SaveSystem.has_save()

	if first_open:
		first_open.grab_focus()


## Bấm một màn chính.
func _on_level_pressed(id: String) -> void:
	if _has_requirements(id):
		_open_requirements(id)
		return
	_start_level(id)


## Màn có bảng yêu cầu = màn khai "rank_thresholds" trong luật của nó.
func _has_requirements(id: String) -> bool:
	return GameData.rules_for_level(id).has("rank_thresholds")


func _start_level(id: String) -> void:
	if not GameData.needs_character_select(id):
		get_tree().change_scene_to_file(GameData.start_story_level(id))
		return
	GameData.current_level = id
	GameData.return_scene = scene_file_path
	get_tree().change_scene_to_file(character_select_scene)


## Bảng yêu cầu của một ngày. Dùng lại đúng cái bảng lớn của chế độ — cùng
func _open_requirements(id: String) -> void:
	_selected = id
	var btn: Button = _buttons[id]
	_detail_title.text = tr(str(btn.get_meta("base_text", btn.text)))

	var marks := GameData.rank_thresholds_for(id)
	var lines: Array[String] = [tr("LEVEL_REQ_TITLE")]
	for rank in GameData.RANK_ORDER:
		lines.append("    %s  —  %d" % [String(rank), int(marks.get(rank, 0))])
	var limit := GameData.max_left_for(id)
	if limit > 0:
		lines.append("")
		lines.append("%s %d" % [tr("LEVEL_REQ_LEFT"), limit])
	_detail_desc.text = "\n".join(lines)

	var ready_ := GameData.is_unlocked(id)
	_btn_start.disabled = not ready_
	_btn_start.text = "LEVEL_START"
	_detail.show()
	if ready_:
		_btn_start.grab_focus()
	else:
		_btn_close_detail.grab_focus()


## Chế độ: mở bảng mô tả. Nút Bắt đầu chỉ sáng khi chế độ đó đã có trong
func _open_mode(id: String) -> void:
	_selected = id
	var btn: Button = _modes[id]
	_detail_title.text = tr(btn.text)
	_detail_desc.text = tr(String(MODE_DESC.get(id, "LEVEL_SOON_SHORT")))
	var ready_ := GameData.LEVELS.has(id) and GameData.is_unlocked(id)
	_btn_start.disabled = not ready_
	_btn_start.text = "LEVEL_START" if ready_ else "LEVEL_SOON_SHORT"
	_detail.show()
	_btn_close_detail.grab_focus()


func _close_detail() -> void:
	var back_to := _modes.get(_selected, _buttons.get(_selected, _btn_back)) as Button
	_selected = ""
	_detail.hide()
	back_to.grab_focus()


func _on_start_pressed() -> void:
	if _selected.is_empty():
		return
	_start_level(_selected)


## ESC đóng bảng trước, không thoát khỏi màn hình.
func _unhandled_input(event: InputEvent) -> void:
	if _detail.visible and event.is_action_pressed("ui_cancel"):
		_close_detail()
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_scene)


func _on_wipe_confirmed() -> void:
	SaveSystem.delete_save()
	GameData.reset()


## Nút "Thử nghiệm B" — chế độ thử bộ công thức theo họ món (16/11/2026).
func _add_plan_b_button() -> void:
	var src: Button = _modes["aaa"]
	var btn := src.duplicate(0) as Button
	btn.unique_name_in_owner = false
	btn.name = "BtnPlanB"
	btn.text = "Thử nghiệm B"
	src.add_sibling(btn)
	_modes["plan_b"] = btn
