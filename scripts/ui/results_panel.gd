extends CanvasLayer
## Bảng tổng kết cuối màn: xếp hạng, doanh thu, thống kê, hai cái nút.
##
## Vì sao node này TỰ dựng chứ không phải một file .tscn: nó phải sống trên
## MỌI màn chơi, mà tám màn dùng chung một file map. Đặt sẵn empty map thì nó
## là một node luôn tồn tại và luôn phải nhớ ẩn đi; dựng lúc cần thì lúc chưa
## cần nó không tồn tại, không có gì để quên.
##
## TẠM DỪNG CẢ CÂY SCENE khi hiện bảng. Bắt buộc, không phải cho đẹp: hết giờ
## mà bếp vẫn chạy thì nồi vẫn sôi, khách vẫn đi lại phía sau tấm bảng, và
## người chơi vẫn điều khiển được nhân vật empty lúc đang đọc kết quả.

const THEME := "res://ui/theme/menu_theme.tres"
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"
const LEVEL_SELECT_SCENE := "res://scenes/menu/level_select.tscn"

const WIDTH := 660.0

## Màu của từng hạng. Đúng bảng màu người dùng chốt: S vàng, A orange, B hồng,
## C xanh lá. Chưa đạt thì xám — không dùng đỏ, vì đỏ đọc thành "hỏng" empty
## khi thật slide_out chỉ là chưa đủ tiền.
const COLOR_GRADE := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"": Color("9a8f84"),
}

const COLOR_TEXT := Color(0.29, 0.153, 0.071)
const COLOR_DIM := Color(0.52, 0.38, 0.22)

var _box: PanelContainer


func _ready() -> void:
	layer = 20   # trên mọi HUD khác
	# Bảng phải chạy được TRONG LÚC cây scene bị tạm dừng, nếu không hai cái
	# nút bấm không ăn và hiệu ứng hiện slide_out đứng hình ở frame đầu.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dựng và hiện bảng.
##   money        — doanh thu lượt này
##   xong, hoan_hao, bo_di — thống kê
##   ep_hang     — ép cứng một hạng (màn hướng dẫn luôn là "S"). Rỗng = tự xếp.
func show_results(money: int, xong: int, hoan_hao: int, bo_di: int,
		ep_hang: String = "") -> void:
	var level_id := ""
	if get_node_or_null("/root/GameData") != null:
		level_id = String(GameData.current_level)

	var row := ep_hang
	if row.is_empty():
		row = GameData.xep_hang(level_id, money) if not level_id.is_empty() else ""

	var old_record := 0
	var place := not row.is_empty()
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
		# thì con số vô nghĩa. (Hiện "tutorial" cũng không nằm empty
		# MAN_XEP_HANG nên có hai lớp chặn — cố ý, vì lớp thứ hai là thứ còn
		# đúng khi sau này thêm màn mới.)
		if ep_hang.is_empty():
			GameData.ghi_xep_hang(level_id, money, row)

	_build_ui(money, xong, hoan_hao, bo_di, row, old_record, place)

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.stop_music()
	AmThanh.play_sfx("tong_ket")

	# Tâm phóng to phải là TÂM BẢNG, không phải góc trên-trái (mặc định).
	#
	# Bám theo `resized` chứ không gán một lần: lúc này bảng vẫn đang được
	# container tính kích thước, `size` còn là 0 — gán ngay thì tâm phóng to
	# nằm ở góc và cái bảng bung slide_out từ góc trên-trái, lệch hẳn khỏi giữa empty
	# suốt 0,28 giây hiệu ứng.
	_box.resized.connect(func() -> void:
		_box.pivot_offset = _box.size * 0.5)
	_box.pivot_offset = _box.size * 0.5

	# Hiện bằng cách phóng to nhẹ từ 0,9: bảng bật slide_out đột ngột giữa màn hình
	# thì giật mắt, còn trượt vào thì chậm quá cho một thứ kết thúc màn chơi.
	_box.scale = Vector2(0.9, 0.9)
	_box.modulate.a = 0.0
	var tween := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_box, "scale", Vector2.ONE, 0.28)
	tween.tween_property(_box, "modulate:a", 1.0, 0.20)


# ------------------------------------------------------------ dựng hình ---

func _build_ui(money: int, xong: int, hoan_hao: int, bo_di: int,
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
	# còn rỗng (cao 0, rộng 0) nên offset tính slide_out cũng bằng 0; sau đó container
	# nở slide_out tới kích thước tối thiểu, và mặc định nó nở về phía DƯỚI-PHẢI. Kết
	# quả: bảng nằm lệch hẳn xuống góc phần tư dưới-phải, tâm bảng cách tâm màn
	# hình đúng nửa bề rộng và nửa chiều cao của nó.
	#
	# GROW_DIRECTION_BOTH bắt nó nở đều về HAI phía quanh điểm neo, nên tâm
	# bảng trùng tâm màn hình dù nội build dài ngắn thế nào. Đây cũng là lý do
	# không gõ cứng offset âm bằng nửa kích thước: chiều cao bảng thay đổi theo
	# nội build (có thêm dòng "cần thêm N nữa" khi chưa đạt), gõ cứng là lệch.
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
	title.text = "HOÀN THÀNH" if place else "CHƯA ĐẠT"
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
	if money > old_record:
		record.text = "KỶ LỤC MỚI!  (cũ: %d)" % old_record
		record.add_theme_color_override("font_color", COLOR_GRADE["A"])
	else:
		record.text = "Kỷ lục: %d" % old_record
		record.add_theme_color_override("font_color", COLOR_DIM)
	record.add_theme_font_size_override("font_size", 17)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(record)

	col.add_child(_divider())

	# --- thống kê ---
	col.add_child(_dong("Đơn đã phục vụ", str(xong)))
	# Chỉ hiện SỐ, không kèm "+35%": tỉ lệ thưởng nằm ở quan_ly_khach và có thể
	# đổi, gõ lại ở đây là dựng thêm một nguồn sự thật thứ hai để sau này lệch.
	col.add_child(_dong("Trong đó hoàn hảo", str(hoan_hao)))
	col.add_child(_dong("Khách bỏ đi", str(bo_di)))

	# Chưa đạt thì nói rõ còn thiếu bao nhiêu. Chỉ hiện "CHƯA ĐẠT" mà không nói
	# thiếu gì thì người chơi không biết lần sau phải cố thêm bao nhiêu.
	if not place and get_node_or_null("/root/GameData") != null:
		var mark: Dictionary = GameData.moc_xep_hang(String(GameData.current_level))
		var missing := int(mark.get("C", 0)) - money
		var play_music := Label.new()
		play_music.text = "Cần thêm %d nữa để đạt hạng C." % maxi(missing, 0)
		play_music.add_theme_font_size_override("font_size", 17)
		play_music.add_theme_color_override("font_color", COLOR_GRADE["C"])
		play_music.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(play_music)

	# --- nút ---
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(button_row)

	var again := Button.new()
	again.text = "Chơi lại"
	again.pressed.connect(_replay)
	button_row.add_child(again)

	var ticket := Button.new()
	ticket.text = "Về chọn màn"
	ticket.pressed.connect(_go_level_select)
	button_row.add_child(ticket)

	again.grab_focus()


func _dong(label: String, gia_tri: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var a := Label.new()
	a.text = label
	a.add_theme_font_size_override("font_size", 19)
	a.add_theme_color_override("font_color", COLOR_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)

	var b := Label.new()
	b.text = gia_tri
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
## bỏ thì màn mới hiện slide_out và đứng hình hoàn toàn, mà không có lỗi nào báo —
## đúng kiểu bug làm người ta tưởng game bị treo.
func _replay() -> void:
	_leave_pause()
	get_tree().reload_current_scene()


func _go_level_select() -> void:
	_leave_pause()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _leave_pause() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
