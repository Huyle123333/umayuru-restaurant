extends Control
## Màn hình chọn màn.
## Bố cục: HAI KHUNG xếp chồng, cùng bề ngang, tiêu đề cùng căn trái. Khung
## trên "Màn chính" là các cột theo ngày, mỗi cột một nút "Ngày N", nối
## bằng mũi tên — bấm là vào thẳng. Khung dưới "Chế độ" là các chế độ chơi
## (Endless, Asian Mode) — bấm thì mở bảng mô tả lớn giữa màn hình.
## Nút của màn chưa mở khóa bị làm mờ — quy tắc mở khóa nằm trong GameData,
## màn hình này chỉ hỏi "màn này mở chưa" chứ không tự quyết định.

@export_file("*.tscn") var character_select_scene: String = "res://scenes/menu/character_select.tscn"
@export_file("*.tscn") var main_menu_scene: String = "res://scenes/menu/main_menu.tscn"

## Nối id màn (trong GameData.LEVELS) với nút tương ứng trên màn hình.
@onready var _buttons: Dictionary = {
	"prologue": %BtnPrologue,
	"tutorial": %BtnTutorial,
	"d1_sang": %BtnD1Morning,
	"d2_sang": %BtnD2Morning,
	"d3_sang": %BtnD3Morning,
	# Màn kết: một nút duy nhất cho cả kết thường lẫn kết ẩn. Màn hình này
	# KHÔNG hỏi GameData xem kết nào sẽ chiếu — kết ẩn không có gợi ý.
	"ending": %BtnEnding,
}

## Khoá dịch cho nút của từng ngày.
## Dùng KHOÁ chứ không gõ thẳng "Ngày 1": cả màn hình này chạy qua bảng dịch
## trong locale/translations.csv, gõ chữ Việt vào đây thì bản tiếng Anh mất.
const DAY_LABELS := {
	"d1_sang": "LEVEL_DAY_1",
	"d2_sang": "LEVEL_DAY_2",
	"d3_sang": "LEVEL_DAY_3",
}

## ── HAI KHUNG (1/10/2026) ──────────────────────────────────────────────
## Đã thử ba bố cục khác trước khi chốt cái này: hai vùng trên/dưới không
## khung (mỗi phần căn một kiểu, giữa màn hình trống), và hai tab (chế độ bị
## giấu sau một cú bấm). Hai khung cùng bề ngang cho mắt hai mép thẳng để
## bám vào, mà vẫn thấy cả hai nhóm cùng lúc. Bố cục nằm hết trong .tscn
## (StoryPanel / ModesPanel dùng chung StyleBox "SectionBox"), script không
## phải biết gì về nó.

## Các CHẾ ĐỘ chưa có nội dung. Nằm ngoài _buttons vì chúng không có trong
## GameData.LEVELS: hỏi is_unlocked("endless") là hỏi về một id không tồn
## tại. Chúng vẫn BẤM ĐƯỢC để mở bảng mô tả — người chơi thử thấy được game
## còn gì đang tới — chỉ có nút Bắt đầu là khoá.
@onready var _modes: Dictionary = {
	"endless": %BtnEndless,
	"asian": %BtnAsian,
}

## Bảng mô tả CHẾ ĐỘ — chỉ chế độ mới có, màn chính bấm là vào thẳng.
##
## Vì sao chỉ chế độ: màn chính là cốt truyện, người chơi đi lần lượt và nội
## dung từng ngày tự giới thiệu khi vào màn. Chế độ thì có LUẬT RIÊNG (Endless
## không có đồng hồ, Asian Mode đổi thực đơn...) — không đọc trước thì người
## chơi không biết mình đang chơi cái gì.
##
## Bảng to cỡ CODE No.7 (660 × 480) chứ không nhét dưới nút: một ô 250 px
## chỉ đủ hai ba dòng, không tả được luật chơi. Phủ nền tối lên cả màn hình
## như CODE No.7 để mắt dồn vào bảng, và để không bấm nhầm nút phía sau.
@onready var _detail: Control = %ModeDetail
@onready var _detail_dim: ColorRect = %Dim
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_desc: Label = %DetailDesc
@onready var _btn_start: Button = %BtnStart
@onready var _btn_close_detail: Button = %BtnCloseDetail

## Chế độ đang mở bảng. Rỗng = bảng đóng.
var _selected := ""

## Khoá dịch của đoạn mô tả từng chế độ. Nội dung viết trong
## locale/translations.csv — sửa chữ ở đó, không phải sửa file này.
const MODE_DESC := {
	"endless": "LEVEL_DESC_ENDLESS",
	"asian": "LEVEL_DESC_ASIAN",
}

@onready var _btn_back: Button = %BtnBack
## Bảng xếp hạng — nằm ở ĐÂY chứ không ở menu chính.
##
## Lý do đặt cạnh danh sách màn: bảng xếp hạng chia theo màn (Màn 1, Màn 2,
## Màn 3, Endless), nên nó trả lời cho đúng câu hỏi người chơi đang có lúc
## đứng ở màn hình này — "màn nào mình làm tốt rồi, màn nào chưa". Ở menu
## chính thì nó là một mục lạc lõng giữa Cài đặt với Credits, và muốn xem
## thành tích một màn phải quay ra menu chính rồi quay vào lại.
@onready var _btn_board: Button = %BtnBoard
@onready var _board: Control = %LeaderboardPanel
@onready var _btn_wipe: Button = %BtnWipe
@onready var _confirm_wipe: ConfirmationDialog = %ConfirmWipe


func _ready() -> void:
	# Nhạc menu: bốc ngẫu nhiên MỘT lần cho cả cụm menu.
	#
	# giu_lien_mach = true nghĩa là nếu bài đang phát đã thuộc nhóm "menu" thì
	# không đổi gì cả. Người chơi bấm Menu chính → Chọn màn → Chọn nhân vật →
	# quay lại, cả bốn màn hình dùng chung một bài đang chạy dở. Bốc lại ở mỗi
	# màn hình thì chỉ cần bấm qua lại vài lần là nhạc giật liên tục.
	AmThanh.play_random_music("menu", true)

	_name_day_buttons()

	for id in _buttons:
		var btn: Button = _buttons[id]
		# Nhớ lại chữ gốc để lát nữa gắn thêm dấu tick mà không bị cộng dồn.
		btn.set_meta("base_text", btn.text)
		btn.pressed.connect(_on_level_pressed.bind(id))

	for id in _modes:
		var mode_btn: Button = _modes[id]
		mode_btn.tooltip_text = tr("LEVEL_COMING_SOON")
		mode_btn.pressed.connect(_open_mode.bind(id))

	_btn_start.pressed.connect(_on_start_pressed)
	_btn_close_detail.pressed.connect(_close_detail)
	# Bấm ra vùng tối ngoài bảng cũng đóng — cách đóng người chơi thử trước tiên.
	_detail_dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_detail())

	_btn_back.pressed.connect(_on_back_pressed)
	_btn_board.pressed.connect(func() -> void: _board.open(_btn_board))
	_btn_wipe.pressed.connect(_confirm_wipe.popup_centered)
	_confirm_wipe.confirmed.connect(_on_wipe_confirmed)

	# Tiến trình đổi ở đâu thì màn hình này tự cập nhật, không phải gọi tay.
	GameData.progress_changed.connect(_refresh)
	_refresh()


## Đặt tên "Ngày N" cho nút của từng ngày và ẩn tiêu đề cột.
##
## Mỗi cột chỉ có đúng một nút, nên tiêu đề "Ngày 1" phía trên và nút phía
## dưới sẽ thành hai dòng nói về cùng một thứ. Gộp lại: bỏ tiêu đề, nút mang
## luôn tên ngày.
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

		# tr() TRƯỚC rồi mới nối dấu tick. base_text là KHOÁ dịch
		# ("LEVEL_DAY_1"), mà "LEVEL_DAY_1  ✔" thì không còn là khoá nào cả —
		# nối trước khi dịch thì màn đã hoàn thành hiện nguyên cái khoá ra
		# màn hình. Gán lại đúng khoá cho màn chưa xong để Godot tự dịch.
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
##   Prologue / Tutorial  — vào thẳng, như trước.
##   Ngày 1 / 2 / 3       — mở bảng YÊU CẦU (mốc doanh thu từng hạng + số
##                          khách bỏ về tối đa) rồi mới bấm Bắt đầu.
##
## Vì sao ngày chơi thật phải có bảng: mốc S của Ngày 1 là 1836, Ngày 3 là
## 3667 — người chơi cần biết mình đang nhắm con số nào TRƯỚC khi vào bếp,
## không phải đọc nó lần đầu trên bảng tổng kết lúc đã trượt.
func _on_level_pressed(id: String) -> void:
	if _has_requirements(id):
		_open_requirements(id)
		return
	_start_level(id)


## Màn có bảng yêu cầu = màn khai "rank_thresholds" trong luật của nó.
## Hỏi DỮ LIỆU chứ không liệt kê tay ba cái id: thêm mốc cho màn nào trong
## GameData thì màn đó tự có bảng.
func _has_requirements(id: String) -> bool:
	return GameData.rules_for_level(id).has("rank_thresholds")


func _start_level(id: String) -> void:
	# Prologue / Tutorial: không chọn nhân vật, vào thẳng bằng Kitasan.
	if not GameData.needs_character_select(id):
		get_tree().change_scene_to_file(GameData.start_story_level(id))
		return
	GameData.current_level = id
	# Chọn màn xong thì tới màn hình chọn nhân vật, chơi mới bắt đầu ở đó.
	GameData.return_scene = scene_file_path
	get_tree().change_scene_to_file(character_select_scene)


## Bảng yêu cầu của một ngày. Dùng lại đúng cái bảng lớn của chế độ — cùng
## kiểu thông tin ("đọc trước khi vào"), không dựng bảng thứ hai.
##
## Mọi con số đọc từ GameData (rank_thresholds_for / max_left_for), không gõ
## lại ở đây: bảng này, bảng tổng kết và trang hướng dẫn F1 cùng đọc một
## nguồn nên không thể lệch nhau.
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
## GameData.LEVELS và đã mở khoá — hiện cả hai chưa có nên đều khoá.
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
	# Trả focus về đúng nút chế độ vừa mở, để người chơi dùng tay cầm/bàn
	# phím không bị nhảy về đầu màn hình. Lấy nút TRƯỚC khi xoá _selected.
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
	# reset() phát tín hiệu progress_changed nên _refresh() tự chạy,
	# mọi nút lập tức khóa lại trừ Prologue.
