extends Control
## Màn hình chọn màn.
## Bố cục: các cột theo ngày, mỗi cột có màn Sáng và màn Tối, nối bằng mũi tên.
## Khi GameData.HIEN_MAN_TOI = false thì mỗi ngày rút lại còn MỘT nút "Ngày N",
## xem _rut_gon_theo_ngay().
## Nút của màn chưa mở khóa bị làm mờ — quy tắc mở khóa nằm trong GameData,
## màn hình này chỉ hỏi "màn này mở chưa" chứ không tự quyết định.

@export_file("*.tscn") var character_select_scene: String = "res://scenes/menu/character_select.tscn"
@export_file("*.tscn") var main_menu_scene: String = "res://scenes/menu/main_menu.tscn"

## Nối id màn (trong GameData.LEVELS) với nút tương ứng trên màn hình.
@onready var _buttons: Dictionary = {
	"prologue": %BtnPrologue,
	"tutorial": %BtnTutorial,
	"d1_sang": %BtnD1Sang,
	"d1_toi": %BtnD1Toi,
	"d2_sang": %BtnD2Sang,
	"d2_toi": %BtnD2Toi,
	"d3_sang": %BtnD3Sang,
	"d3_toi": %BtnD3Toi,
}

## Khoá dịch cho nút gộp của từng ngày, khi giai đoạn buổi tối đang tắt.
## Dùng KHOÁ chứ không gõ thẳng "Ngày 1": cả màn hình này chạy qua bảng dịch
## trong locale/translations.csv, gõ chữ Việt vào đây thì bản tiếng Anh mất.
const DAY_LABELS := {
	"d1_sang": "LEVEL_DAY_1",
	"d2_sang": "LEVEL_DAY_2",
	"d3_sang": "LEVEL_DAY_3",
}

const EVENING_LEVELS := ["d1_toi", "d2_toi", "d3_toi"]

## Chế độ Vô tận — nút đã có chỗ, nội dung làm sau.
##
## Vì sao dựng nút trước khi có chế độ, mà không đợi làm xong rồi mới thêm:
## bố cục màn hình này là một hàng ngang các cột nối bằng mũi tên, và một cột
## thêm vào sau sẽ đẩy lại toàn bộ chiều rộng — tức phải căn lại từ đầu. Đặt
## sẵn thì hình dạng cuối cùng của màn hình đã đúng ngay từ bây giờ, và người
## chơi thử cũng thấy được game còn gì đang tới.
##
## Nút KHOÁ CỨNG (disabled trong .tscn), không đi qua GameData.is_unlocked():
## "endless" chưa có trong bảng LEVELS, nên hàm đó sẽ trả về false và ghi log
## một id không tồn tại. Khoá thẳng ở giao diện thì ý nghĩa đúng với sự thật —
## đây không phải màn chưa mở khoá, mà là màn chưa tồn tại.
@onready var _btn_endless: Button = %BtnEndless

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

	if not GameData.SHOW_EVENING:
		_group_by_day()

	for id in _buttons:
		var btn: Button = _buttons[id]
		# Nhớ lại chữ gốc để lát nữa gắn thêm dấu tick mà không bị cộng dồn.
		btn.set_meta("base_text", btn.text)
		btn.pressed.connect(_on_level_pressed.bind(id))

	_btn_endless.tooltip_text = tr("LEVEL_COMING_SOON")

	_btn_back.pressed.connect(_on_back_pressed)
	_btn_board.pressed.connect(func() -> void: _board.open(_btn_board))
	_btn_wipe.pressed.connect(_confirm_wipe.popup_centered)
	_confirm_wipe.confirmed.connect(_on_wipe_confirmed)

	# Tiến trình đổi ở đâu thì màn hình này tự cập nhật, không phải gọi tay.
	GameData.progress_changed.connect(_refresh)
	_refresh()


## Rút mỗi cột ngày từ hai nút (Sáng / Tối) xuống còn một nút "Ngày N".
##
## Ẩn nút Tối rồi để nguyên nút "Sáng" thì sai theo cả hai nghĩa: quán mở cửa
## lúc bảy giờ kém mười TỐI, nên chữ "Sáng" tả sai giờ chơi; mà một cột chỉ
## còn đúng một nút thì cái tiêu đề "Ngày 1" phía trên và nút "Sáng" phía dưới
## thành hai dòng nói về cùng một thứ. Gộp lại: bỏ tiêu đề, nút mang luôn tên
## ngày.
##
## hide() chứ không queue_free(): nút Tối vẫn nằm trong _buttons và vẫn nhận
## đủ trạng thái khoá/mở như cũ. Bật GameData.HIEN_MAN_TOI lên là chúng hiện
## lại nguyên vẹn, không phải dựng lại node nào.
func _group_by_day() -> void:
	for id in EVENING_LEVELS:
		(_buttons[id] as Button).hide()

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
			btn.tooltip_text = "Doanh thu tốt nhất: %d" % GameData.get_best_money(id)
			if first_open == null:
				first_open = btn
		else:
			btn.tooltip_text = "Chưa mở khóa"

	# Nút Xóa dữ liệu chỉ có nghĩa khi thực sự có gì để xóa.
	_btn_wipe.disabled = not SaveSystem.has_save()

	if first_open:
		first_open.grab_focus()


func _on_level_pressed(id: String) -> void:
	GameData.current_level = id
	# Chọn màn xong thì tới màn hình chọn nhân vật, chơi mới bắt đầu ở đó.
	GameData.return_scene = scene_file_path
	get_tree().change_scene_to_file(character_select_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_scene)


func _on_wipe_confirmed() -> void:
	SaveSystem.delete_save()
	GameData.reset()
	# reset() phát tín hiệu progress_changed nên _refresh() tự chạy,
	# mọi nút lập tức khóa lại trừ Prologue.
