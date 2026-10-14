extends CanvasLayer
## Bảng tổng kết cuối màn: xếp hạng, doanh thu, thống kê, hai cái nút.
##
## Vì sao node này TỰ dựng chứ không phải một file .tscn: nó phải sống trên
## MỌI màn chơi, mà tám màn dùng chung một file map. Đặt sẵn trong map thì nó
## là một node luôn tồn tại và luôn phải nhớ ẩn đi; dựng lúc cần thì lúc chưa
## cần nó không tồn tại, không có gì để quên.
##
## TẠM DỪNG CẢ CÂY SCENE khi hiện bảng. Bắt buộc, không phải cho đẹp: hết giờ
## mà bếp vẫn chạy thì nồi vẫn sôi, khách vẫn đi lại phía sau tấm bảng, và
## người chơi vẫn điều khiển được nhân vật trong lúc đang đọc kết quả.

const THEME := "res://ui/theme/menu_theme.tres"
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"
const LEVEL_SELECT_SCENE := "res://scenes/menu/level_select.tscn"

const WIDTH := 660.0

## Màu của từng hạng. Đúng bảng màu người dùng chốt: S vàng, A orange, B hồng,
## C xanh lá. Chưa đạt thì xám — không dùng đỏ, vì đỏ đọc thành "hỏng" trong
## khi thật ra chỉ là chưa đủ tiền.
const COLOR_GRADE := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"D": Color("5b8fb0"),
	"": Color("9a8f84"),
}

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)

var _box: PanelContainer


func _ready() -> void:
	layer = 20   # trên mọi HUD khác
	# Bảng phải chạy được TRONG LÚC cây scene bị tạm dừng, nếu không hai cái
	# nút bấm không ăn và hiệu ứng hiện ra đứng hình ở frame đầu.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dựng và hiện bảng.
##   money        — doanh thu lượt này
##   xong, hoan_hao, bo_di — thống kê
##   ep_hang     — ép cứng một hạng (màn hướng dẫn luôn là "S"). Rỗng = tự xếp.
## Lý do THUA ÉP (ví dụ quá nhiều khách bỏ về). Khác rỗng thì lượt này trượt
## bất kể doanh thu, và câu này thay cho dòng "cần thêm N nữa". Gán TRƯỚC khi
## gọi show_results().
var fail_note := ""


func show_results(money: int, served: int, perfect: int, left_angry: int,
		ep_hang: String = "") -> void:
	var level_id := ""
	if get_node_or_null("/root/GameData") != null:
		level_id = String(GameData.current_level)

	var row := ep_hang
	if row.is_empty():
		row = GameData.rank_for(level_id, money) if not level_id.is_empty() else ""

	# Thua ép thắng mọi mốc điểm: đủ tiền hạng S mà để khách bỏ về quá giới
	# hạn thì vẫn là trượt. Xoá hạng ở ĐÂY, trước khi tính `place`, để mọi thứ
	# phía dưới (không đánh dấu hoàn thành, chữ CHƯA ĐẠT) tự đúng theo.
	if not fail_note.is_empty():
		row = ""

	var old_record := 0
	var place := not row.is_empty()
	# Đọc cờ TRƯỚC khi gọi record_rank(): hàm đó tắt cờ sau khi dùng.
	_skill_win = GameData.skill_win_pending
	if not level_id.is_empty():
		old_record = GameData.get_best_money(level_id)
		# Chỉ ghi nhận hoàn thành khi ĐẠT ÍT NHẤT HẠNG C.
		#
		# complete_level cũng là chỗ cập nhật kỷ lục, nên phải đọc kỷ lục CŨ
		# trước rồi mới gọi — gọi trước thì kỷ lục đã bị ghi đè và dòng "kỷ lục
		# cũ" trên bảng luôn bằng đúng số vừa kiếm được.
		if place:
			GameData.complete_level(level_id, money)
		# Bảng xếp hạng ghi MỌI lượt, kể cả lượt trượt hạng — xem giải thích
		# ở GameData.ghi_xep_hang(). Gọi SAU complete_level vì hàm kia mới là
		# nơi quyết định tiến trình; nếu có lỗi thì lỗi ở cái phụ, không phải
		# ở cái chính.
		#
		# Không ghi khi ep_hang có giá trị: đó là màn hướng dẫn tự ép hạng S
		# với vài chục đồng tiền học việc, đứng chung bảng với màn chơi thật
		# thì con số vô nghĩa. (Hiện "tutorial" cũng không nằm trong
		# MAN_XEP_HANG nên có hai lớp chặn — cố ý, vì lớp thứ hai là thứ còn
		# đúng khi sau này thêm màn mới.)
		if ep_hang.is_empty():
			GameData.record_rank(level_id, money, row)

	_build_ui(money, served, perfect, left_angry, row, old_record, place)

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.stop_music()
	AmThanh.play_sfx("results")

	# Tâm phóng to phải là TÂM BẢNG, không phải góc trên-trái (mặc định).
	#
	# Bám theo `resized` chứ không gán một lần: lúc này bảng vẫn đang được
	# container tính kích thước, `size` còn là 0 — gán ngay thì tâm phóng to
	# nằm ở góc và cái bảng bung ra từ góc trên-trái, lệch hẳn khỏi giữa trong
	# suốt 0,28 giây hiệu ứng.
	_box.resized.connect(func() -> void:
		_box.pivot_offset = _box.size * 0.5)
	_box.pivot_offset = _box.size * 0.5

	# Hiện bằng cách phóng to nhẹ từ 0,9: bảng bật ra đột ngột giữa màn hình
	# thì giật mắt, còn trượt vào thì chậm quá cho một thứ kết thúc màn chơi.
	_box.scale = Vector2(0.9, 0.9)
	_box.modulate.a = 0.0
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_box, "scale", Vector2.ONE, 0.28)
	tween.tween_property(_box, "modulate:a", 1.0, 0.20)


# ------------------------------------------------------------ dựng hình ---

var _skill_win := false


func _build_ui(money: int, served: int, perfect: int, left_angry: int,
		row: String, old_record: int, place: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Chặn chuột: nền tối phải nuốt mọi cú bấm, không cho lọt xuống HUD phía
	# dưới. Bảng kết quả là một cửa sổ chặn, không phải một lớp trang trí.
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER)
	_box.custom_minimum_size = Vector2(WIDTH, 0.0)

	# HAI DÒNG NÀY MỚI LÀ THỨ ĐẶT BẢNG VÀO GIỮA.
	#
	# PRESET_CENTER chỉ đưa bốn cái neo về 0,5 — tức ghim GÓC TRÊN-TRÁI của
	# bảng vào tâm màn hình, chứ không phải tâm bảng. Lúc gọi preset thì bảng
	# còn rỗng (cao 0, rộng 0) nên offset tính ra cũng bằng 0; sau đó container
	# nở ra tới kích thước tối thiểu, và mặc định nó nở về phía DƯỚI-PHẢI. Kết
	# quả: bảng nằm lệch hẳn xuống góc phần tư dưới-phải, tâm bảng cách tâm màn
	# hình đúng nửa bề rộng và nửa chiều cao của nó.
	#
	# GROW_DIRECTION_BOTH bắt nó nở đều về HAI phía quanh điểm neo, nên tâm
	# bảng trùng tâm màn hình dù nội dung dài ngắn thế nào. Đây cũng là lý do
	# không gõ cứng offset âm bằng nửa kích thước: chiều cao bảng thay đổi theo
	# nội dung (có thêm dòng "cần thêm N nữa" khi chưa đạt), gõ cứng là lệch.
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists(THEME):
		_box.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s" % THEME)
	bg.add_child(_box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_box.add_child(col)

	# --- tiêu đề ---
	var title := Label.new()
	title.text = Lang.t("HOÀN THÀNH") if place else Lang.t("CHƯA ĐẠT")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	# --- chữ hạng ---
	var grade_text := Label.new()
	grade_text.text = row if place else "—"
	grade_text.add_theme_font_size_override("font_size", 96)
	grade_text.add_theme_color_override("font_color", COLOR_GRADE.get(row, COLOR_GRADE[""]))
	grade_text.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.06))
	grade_text.add_theme_constant_override("outline_size", 10)
	grade_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(grade_text)

	col.add_child(_divider())

	# --- doanh thu ---
	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 10)
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(money_row)

	if ResourceLoader.exists(COIN_ICON):
		var icon := TextureRect.new()
		icon.texture = load(COIN_ICON)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		money_row.add_child(icon)

	var amount := Label.new()
	amount.text = str(money)
	amount.add_theme_font_size_override("font_size", 44)
	amount.add_theme_color_override("font_color", COLOR_TEXT)
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money_row.add_child(amount)

	var record := Label.new()
	# Chỉ khoe kỷ lục khi lượt này ĐẠT: kỷ lục chỉ được lưu trong
	# complete_level(), mà lượt trượt thì không gọi hàm đó. Không có vế
	# `place` thì một lượt thua vì khách bỏ về vẫn hiện "KỶ LỤC MỚI!" cho một
	# con số không hề được lưu.
	# Lượt thắng bằng kĩ năng không ghi kỷ lục (xem GameData.complete_level),
	# nên cũng không được khoe "kỷ lục mới".
	if money > old_record and place and not _skill_win:
		record.text = Lang.t("KỶ LỤC MỚI!  (cũ: %d)") % old_record
		record.add_theme_color_override("font_color", COLOR_GRADE["A"])
	else:
		record.text = Lang.t("Kỷ lục: %d") % old_record
		record.add_theme_color_override("font_color", COLOR_DIM)
	record.add_theme_font_size_override("font_size", 17)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(record)

	col.add_child(_divider())

	# --- thống kê ---
	col.add_child(_row(Lang.t("Đơn đã phục vụ"), str(served)))
	# Chỉ hiện SỐ, không kèm "+35%": tỉ lệ thưởng nằm ở customer_manager và có thể
	# đổi, gõ lại ở đây là dựng thêm một nguồn sự thật thứ hai để sau này lệch.
	col.add_child(_row(Lang.t("Trong đó hoàn hảo"), str(perfect)))
	col.add_child(_row(Lang.t("Khách bỏ đi"), str(left_angry)))

	# Chưa đạt thì nói rõ còn thiếu bao nhiêu. Chỉ hiện "CHƯA ĐẠT" mà không nói
	# thiếu gì thì người chơi không biết lần sau phải cố thêm bao nhiêu.
	if not place and get_node_or_null("/root/GameData") != null:
		var mark: Dictionary = GameData.rank_thresholds_for(String(GameData.current_level))
		var missing := int(mark.get(GameData.MIN_RANK, 0)) - money
		var note := Label.new()
		note.text = Lang.t("Cần thêm %d nữa để đạt hạng %s.") % [maxi(missing, 0), GameData.MIN_RANK]
		if not fail_note.is_empty():
			note.text = fail_note
		note.add_theme_font_size_override("font_size", 17)
		note.add_theme_color_override("font_color", COLOR_GRADE[GameData.MIN_RANK])
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(note)

	# --- nút ---
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)

	var again := Button.new()
	again.text = Lang.t("Chơi lại")
	again.pressed.connect(_replay)
	button_row.add_child(again)

	var ticket := Button.new()
	ticket.text = Lang.t("Về chọn màn")
	ticket.pressed.connect(_go_level_select)
	button_row.add_child(ticket)

	# Vừa QUA màn cuối cùng trước màn kết (Ngày 3): thêm nút sang thẳng Ending
	# và đặt focus vào nó. Hỏi GameData "màn kết cần màn nào" chứ không so cứng
	# với "d3_sang" — đổi điều kiện mở màn kết ở LEVELS là nút này tự theo.
	# Nút y hệt nhau cho cả hai kết: không lộ kết ẩn.
	var ending_needs := ""
	var here := ""
	if get_node_or_null("/root/GameData") != null:
		ending_needs = String(GameData.LEVELS.get(GameData.ENDING_LEVEL, {}).get("needs", ""))
		here = String(GameData.current_level)
	if place and not here.is_empty() and here == ending_needs:
		var ending := Button.new()
		ending.text = "Ending"
		ending.pressed.connect(_go_ending)
		button_row.add_child(ending)
		ending.grab_focus()
	else:
		again.grab_focus()


func _row(label: String, value: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var a := Label.new()
	a.text = label
	a.add_theme_font_size_override("font_size", 19)
	a.add_theme_color_override("font_color", COLOR_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)

	var b := Label.new()
	b.text = value
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	h.add_child(b)
	return h


func _divider() -> Control:
	var d := ColorRect.new()
	d.color = Color(0.29, 0.153, 0.071, 0.22)
	d.custom_minimum_size = Vector2(0, 2)
	return d


# ---------------------------------------------------------------- nút ---

## Bỏ tạm dừng TRƯỚC khi đổi màn.
##
## get_tree().paused là cờ TOÀN CỤC, nó không tự tắt khi scene bị thay. Quên
## bỏ thì màn mới hiện ra và đứng hình hoàn toàn, mà không có lỗi nào báo —
## đúng kiểu bug làm người ta tưởng game bị treo.
func _replay() -> void:
	_leave_pause()
	get_tree().reload_current_scene()


func _go_ending() -> void:
	_leave_pause()
	get_tree().change_scene_to_file(GameData.start_story_level(GameData.ENDING_LEVEL))


func _go_level_select() -> void:
	_leave_pause()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _leave_pause() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
