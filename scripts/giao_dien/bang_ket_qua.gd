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
const ANH_TIEN := "res://assets/ui/tien/carrot_tien.png"
const MAN_CHON_MAN := "res://scenes/menu/level_select.tscn"

const RONG := 660.0

## Màu của từng hạng. Đúng bảng màu người dùng chốt: S vàng, A cam, B hồng,
## C xanh lá. Chưa đạt thì xám — không dùng đỏ, vì đỏ đọc thành "hỏng" trong
## khi thật ra chỉ là chưa đủ tiền.
const MAU_HANG := {
	"S": Color("f2c230"),
	"A": Color("e8823f"),
	"B": Color("e27ba0"),
	"C": Color("4f9d5d"),
	"": Color("9a8f84"),
}

const MAU_CHU := Color(0.29, 0.153, 0.071)
const MAU_MO := Color(0.52, 0.38, 0.22)

var _hop: PanelContainer


func _ready() -> void:
	layer = 20   # trên mọi HUD khác
	# Bảng phải chạy được TRONG LÚC cây scene bị tạm dừng, nếu không hai cái
	# nút bấm không ăn và hiệu ứng hiện ra đứng hình ở khung đầu.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dựng và hiện bảng.
##   tien        — doanh thu lượt này
##   xong, hoan_hao, bo_di — thống kê
##   ep_hang     — ép cứng một hạng (màn hướng dẫn luôn là "S"). Rỗng = tự xếp.
func hien(tien: int, xong: int, hoan_hao: int, bo_di: int,
		ep_hang: String = "") -> void:
	var id_man := ""
	if get_node_or_null("/root/GameData") != null:
		id_man = String(GameData.current_level)

	var hang := ep_hang
	if hang.is_empty():
		hang = GameData.xep_hang(id_man, tien) if not id_man.is_empty() else ""

	var ky_luc_cu := 0
	var dat := not hang.is_empty()
	if not id_man.is_empty():
		ky_luc_cu = GameData.get_best_money(id_man)
		# Chỉ ghi nhận hoàn thành khi ĐẠT ÍT NHẤT HẠNG C.
		#
		# complete_level cũng là chỗ cập nhật kỷ lục, nên phải đọc kỷ lục CŨ
		# trước rồi mới gọi — gọi trước thì kỷ lục đã bị ghi đè và dòng "kỷ lục
		# cũ" trên bảng luôn bằng đúng số vừa kiếm được.
		if dat:
			GameData.complete_level(id_man, tien)
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
			GameData.ghi_xep_hang(id_man, tien, hang)

	_dung_giao_dien(tien, xong, hoan_hao, bo_di, hang, ky_luc_cu, dat)

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AmThanh.stop_music()
	AmThanh.phat("tong_ket")

	# Tâm phóng to phải là TÂM BẢNG, không phải góc trên-trái (mặc định).
	#
	# Bám theo `resized` chứ không gán một lần: lúc này bảng vẫn đang được
	# container tính kích thước, `size` còn là 0 — gán ngay thì tâm phóng to
	# nằm ở góc và cái bảng bung ra từ góc trên-trái, lệch hẳn khỏi giữa trong
	# suốt 0,28 giây hiệu ứng.
	_hop.resized.connect(func() -> void:
		_hop.pivot_offset = _hop.size * 0.5)
	_hop.pivot_offset = _hop.size * 0.5

	# Hiện bằng cách phóng to nhẹ từ 0,9: bảng bật ra đột ngột giữa màn hình
	# thì giật mắt, còn trượt vào thì chậm quá cho một thứ kết thúc màn chơi.
	_hop.scale = Vector2(0.9, 0.9)
	_hop.modulate.a = 0.0
	var tw := create_tween().set_parallel(true) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hop, "scale", Vector2.ONE, 0.28)
	tw.tween_property(_hop, "modulate:a", 1.0, 0.20)


# ------------------------------------------------------------ dựng hình ---

func _dung_giao_dien(tien: int, xong: int, hoan_hao: int, bo_di: int,
		hang: String, ky_luc_cu: int, dat: bool) -> void:
	var nen := ColorRect.new()
	nen.color = Color(0, 0, 0, 0.55)
	nen.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Chặn chuột: nền tối phải nuốt mọi cú bấm, không cho lọt xuống HUD phía
	# dưới. Bảng kết quả là một cửa sổ chặn, không phải một lớp trang trí.
	nen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(nen)

	_hop = PanelContainer.new()
	_hop.set_anchors_preset(Control.PRESET_CENTER)
	_hop.custom_minimum_size = Vector2(RONG, 0.0)

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
	_hop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hop.grow_vertical = Control.GROW_DIRECTION_BOTH
	if ResourceLoader.exists(THEME):
		_hop.theme = load(THEME)
	else:
		push_warning("Thiếu theme %s" % THEME)
	nen.add_child(_hop)

	var cot := VBoxContainer.new()
	cot.add_theme_constant_override("separation", 10)
	_hop.add_child(cot)

	# --- tiêu đề ---
	var tieu_de := Label.new()
	tieu_de.text = "HOÀN THÀNH" if dat else "CHƯA ĐẠT"
	tieu_de.add_theme_font_size_override("font_size", 24)
	tieu_de.add_theme_color_override("font_color", MAU_MO)
	tieu_de.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cot.add_child(tieu_de)

	# --- chữ hạng ---
	var chu_hang := Label.new()
	chu_hang.text = hang if dat else "—"
	chu_hang.add_theme_font_size_override("font_size", 96)
	chu_hang.add_theme_color_override("font_color", MAU_HANG.get(hang, MAU_HANG[""]))
	chu_hang.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.06))
	chu_hang.add_theme_constant_override("outline_size", 10)
	chu_hang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cot.add_child(chu_hang)

	cot.add_child(_duong_ke())

	# --- doanh thu ---
	var hang_tien := HBoxContainer.new()
	hang_tien.add_theme_constant_override("separation", 10)
	hang_tien.alignment = BoxContainer.ALIGNMENT_CENTER
	cot.add_child(hang_tien)

	if ResourceLoader.exists(ANH_TIEN):
		var icon := TextureRect.new()
		icon.texture = load(ANH_TIEN)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hang_tien.add_child(icon)

	var so_tien := Label.new()
	so_tien.text = str(tien)
	so_tien.add_theme_font_size_override("font_size", 44)
	so_tien.add_theme_color_override("font_color", MAU_CHU)
	so_tien.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hang_tien.add_child(so_tien)

	var ky_luc := Label.new()
	if tien > ky_luc_cu:
		ky_luc.text = "KỶ LỤC MỚI!  (cũ: %d)" % ky_luc_cu
		ky_luc.add_theme_color_override("font_color", MAU_HANG["A"])
	else:
		ky_luc.text = "Kỷ lục: %d" % ky_luc_cu
		ky_luc.add_theme_color_override("font_color", MAU_MO)
	ky_luc.add_theme_font_size_override("font_size", 17)
	ky_luc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cot.add_child(ky_luc)

	cot.add_child(_duong_ke())

	# --- thống kê ---
	cot.add_child(_dong("Đơn đã phục vụ", str(xong)))
	# Chỉ hiện SỐ, không kèm "+35%": tỉ lệ thưởng nằm ở quan_ly_khach và có thể
	# đổi, gõ lại ở đây là dựng thêm một nguồn sự thật thứ hai để sau này lệch.
	cot.add_child(_dong("Trong đó hoàn hảo", str(hoan_hao)))
	cot.add_child(_dong("Khách bỏ đi", str(bo_di)))

	# Chưa đạt thì nói rõ còn thiếu bao nhiêu. Chỉ hiện "CHƯA ĐẠT" mà không nói
	# thiếu gì thì người chơi không biết lần sau phải cố thêm bao nhiêu.
	if not dat and get_node_or_null("/root/GameData") != null:
		var moc: Dictionary = GameData.moc_xep_hang(String(GameData.current_level))
		var thieu := int(moc.get("C", 0)) - tien
		var nhac := Label.new()
		nhac.text = "Cần thêm %d nữa để đạt hạng C." % maxi(thieu, 0)
		nhac.add_theme_font_size_override("font_size", 17)
		nhac.add_theme_color_override("font_color", MAU_HANG["C"])
		nhac.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cot.add_child(nhac)

	# --- nút ---
	var hang_nut := HBoxContainer.new()
	hang_nut.add_theme_constant_override("separation", 16)
	hang_nut.alignment = BoxContainer.ALIGNMENT_CENTER
	cot.add_child(hang_nut)

	var lai := Button.new()
	lai.text = "Chơi lại"
	lai.pressed.connect(_choi_lai)
	hang_nut.add_child(lai)

	var ve := Button.new()
	ve.text = "Về chọn màn"
	ve.pressed.connect(_ve_chon_man)
	hang_nut.add_child(ve)

	lai.grab_focus()


func _dong(nhan: String, gia_tri: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var a := Label.new()
	a.text = nhan
	a.add_theme_font_size_override("font_size", 19)
	a.add_theme_color_override("font_color", MAU_MO)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)

	var b := Label.new()
	b.text = gia_tri
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", MAU_CHU)
	h.add_child(b)
	return h


func _duong_ke() -> Control:
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
func _choi_lai() -> void:
	_thoi_tam_dung()
	get_tree().reload_current_scene()


func _ve_chon_man() -> void:
	_thoi_tam_dung()
	get_tree().change_scene_to_file(MAN_CHON_MAN)


func _thoi_tam_dung() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
