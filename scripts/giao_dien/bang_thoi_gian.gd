extends CanvasLayer
## Đồng hồ màn chơi và ví tiền, góc TRÊN PHẢI.
##
## Vì sao góc trên phải: cột vé đã chiếm mép trái, thanh nấu chiếm giữa đỉnh
## (x 740…1180), khối sức/tay/kĩ năng chiếm góc dưới trái. Đây là góc duy nhất
## còn trống, và nó hợp với vai trò của hai con số này — đọc THƯA, không phải
## nhìn liên tục, nên để xa vùng thao tác là đúng.
##
## Vì sao đồng hồ nằm ở node giao diện chứ không ở một "quản lý màn chơi":
## hiện chưa có node nào sở hữu vòng đời một màn (bắt đầu, hết giờ, bảng kết
## quả). Node này đếm giờ và PHÁT `het_gio`, nên khi dựng màn kết thúc thì chỉ
## cần nghe tín hiệu đó — không phải đi tìm và sửa lại chỗ đếm.
##
## Đơn vị tiền là củ cà rốt cầu vồng. Ảnh nằm ở assets/ui/tien/ chứ không ở
## assets/ui/nguyen_lieu/ vì trong đó ĐÃ CÓ carrot.png — củ cà rốt nguyên liệu
## thật, thứ người chơi thái ra để làm chả rau củ. Hai củ cà rốt, hai vai trò,
## hai thư mục; để chung một chỗ thì sớm muộn cũng có người nạp nhầm.

signal het_gio

const ANH_TIEN := "res://assets/ui/tien/carrot_tien.png"

const LE := 28.0
const RONG := 300.0

const MAU_NEN := Color(0.09, 0.08, 0.07, 0.72)
const MAU_CHU := Color(1, 1, 1)
const MAU_MO := Color(0.78, 0.74, 0.69)
const MAU_CAM := Color("e8823f")
const MAU_GAP := Color("de6459")

## Dưới mức này thì đồng hồ chuyển đỏ và đập nhẹ.
const NGUONG_GAP := 30.0

## Thời lượng một màn, giây. 420 = 7 phút, đúng con số trong bảng cân bằng.
@export var thoi_luong: float = 420.0
## Có đếm ngược không. Màn hướng dẫn tắt: học thì không nên bị đuổi.
##
## Có setter vì cờ này bị đổi LÚC ĐANG CHẠY (bộ dẫn dắt tắt lúc vào màn học,
## bật lại lúc học xong). Không vẽ lại ngay trong setter thì mặt đồng hồ giữ
## nguyên giá trị cũ cho tới lần đếm kế tiếp — mà khi đã tắt đếm thì không còn
## lần kế tiếp nào cả, và ô giờ đứng im ở con số cũ mãi mãi.
@export var dem_nguoc: bool = true:
	set(v):
		dem_nguoc = v
		if _lbl_gio != null:
			_ve_gio()

var con_lai: float = 0.0
var tien: int = 0

var _lbl_gio: Label
var _lbl_tien: Label
var _thanh: ProgressBar
var _sb_fill: StyleBoxFlat
var _da_bao := false


func _ready() -> void:
	layer = 5
	con_lai = thoi_luong
	_dung_giao_dien()
	_ve_gio()
	_ve_tien()


func _dung_giao_dien() -> void:
	var goc := Control.new()
	goc.set_anchors_preset(Control.PRESET_FULL_RECT)
	goc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(goc)

	var khung := PanelContainer.new()
	khung.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Neo góc phải nên offset ÂM tính ngược vào trong màn hình.
	khung.offset_right = -LE
	khung.offset_left = -LE - RONG
	khung.offset_top = LE
	khung.offset_bottom = LE + 132.0
	khung.mouse_filter = Control.MOUSE_FILTER_IGNORE
	khung.add_theme_stylebox_override("panel", _khung_nen())
	goc.add_child(khung)

	var cot := VBoxContainer.new()
	cot.add_theme_constant_override("separation", 2)
	khung.add_child(cot)

	var nhan := Label.new()
	nhan.text = "CÒN LẠI"
	nhan.add_theme_font_size_override("font_size", 14)
	nhan.add_theme_color_override("font_color", MAU_MO)
	cot.add_child(nhan)

	_lbl_gio = Label.new()
	_lbl_gio.add_theme_font_size_override("font_size", 44)
	_lbl_gio.add_theme_color_override("font_color", MAU_CHU)
	cot.add_child(_lbl_gio)

	_thanh = _tao_thanh()
	cot.add_child(_thanh)

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 8)
	cot.add_child(hang)

	if ResourceLoader.exists(ANH_TIEN):
		var icon := TextureRect.new()
		icon.texture = load(ANH_TIEN)
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hang.add_child(icon)
	else:
		push_warning("Thiếu ảnh tiền: %s" % ANH_TIEN)

	_lbl_tien = Label.new()
	_lbl_tien.add_theme_font_size_override("font_size", 26)
	_lbl_tien.add_theme_color_override("font_color", MAU_CHU)
	_lbl_tien.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hang.add_child(_lbl_tien)


func _process(delta: float) -> void:
	if not dem_nguoc or _da_bao:
		return
	var truoc := con_lai
	con_lai = maxf(0.0, con_lai - delta)
	_ve_gio()

	# Kêu ĐÚNG MỘT LẦN ở khoảnh khắc vượt qua mốc, bằng cách so trước-sau chứ
	# không so `con_lai <= 30`. Điều kiện kiểu đó đúng ở MỌI khung hình sau đó,
	# nên nó sẽ kêu sáu chục lần một giây suốt nửa phút cuối.
	if truoc > NGUONG_GAP and con_lai <= NGUONG_GAP:
		AmThanh.phat("sap_het_gio")

	if con_lai <= 0.0:
		_da_bao = true
		# KHÔNG phát tiếng ở đây. Bảng kết quả hiện ra ngay trong cùng khung
		# hình và phát tiếng "tong_ket" của nó, nên hai tiếng đè lên nhau thành
		# một mớ.
		#
		# Bỏ tiếng nào: bỏ "het_gio". Vì bảng kết quả CÒN hiện ở màn hướng dẫn
		# (ép hạng S khi học xong), mà màn đó không có đồng hồ nên không bao
		# giờ đi qua nhánh này — giữ "het_gio" thay vì "tong_ket" thì kết thúc
		# màn hướng dẫn im lặng hoàn toàn.
		#
		# File time_up_buzzer.mp3 vẫn nằm trong thư mục và vẫn có tên trong
		# bảng TEN_FILE, chỉ là chưa chỗ nào gọi.
		het_gio.emit()


## Đặt thẳng số giây còn lại (cheat tua giờ của CODE No.7).
##
## Có hàm riêng thay vì để bên ngoài gán `con_lai` trực tiếp, vì mặt đồng hồ
## chỉ được vẽ lại trong _process, mà _process lại thoát sớm khi `dem_nguoc`
## đang tắt — tức đúng lúc màn hình mở đầu đang đếm 10 giây. Gán thẳng trong
## quãng đó thì thời gian đã nhảy nhưng mặt đồng hồ vẫn hiện 7:00, và người
## bấm tưởng cheat không ăn.
##
## clamp về [0, thoi_luong]: tua tới một con số âm thì phép chia trong _ve_gio
## cho ra thanh tiến trình âm, còn tua vượt quá thời lượng thì thanh vượt 100%.
func dat_con_lai(giay: float) -> void:
	con_lai = clampf(giay, 0.0, thoi_luong)
	_ve_gio()


## Nối vào hệ khách để ví tự cập nhật.
func nghe_don_hang(ql: Node) -> void:
	if ql != null and ql.has_signal("tien_thay_doi"):
		ql.tien_thay_doi.connect(_khi_tien_doi)


func _khi_tien_doi(tong: int, _them: int, _cho: Vector3) -> void:
	tien = tong
	_ve_tien()
	# Nảy nhẹ con số: phần thưởng phải có phản hồi, nhưng ở góc màn hình thì
	# một cú nảy 1,15 lần trong 0,18 giây là đủ thấy mà không kéo mắt khỏi bếp.
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lbl_tien.pivot_offset = _lbl_tien.size * 0.5
	tw.tween_property(_lbl_tien, "scale", Vector2(1.15, 1.15), 0.09)
	tw.tween_property(_lbl_tien, "scale", Vector2.ONE, 0.09)


func _ve_gio() -> void:
	if _lbl_gio == null:
		return
	# Đồng hồ tắt (màn hướng dẫn): vẫn giữ nguyên panel nhưng hiện "--:--".
	#
	# Không ẩn hẳn panel: người chơi phải LÀM QUEN với chỗ này ngay từ màn học,
	# để lúc vào màn thật cái đồng hồ không phải một thứ mới xuất hiện. Hiện
	# gạch ngang thì họ biết ô đó có tồn tại và biết nó chưa chạy.
	if not dem_nguoc:
		_lbl_gio.text = "--:--"
		_lbl_gio.add_theme_color_override("font_color", MAU_MO)
		_thanh.value = 100.0
		_sb_fill.bg_color = MAU_CAM
		return

	var giay := int(ceilf(con_lai))
	# Chia lấy nguyên là CHỦ Ý ở đây (phút), không phải quên ép kiểu.
	@warning_ignore("integer_division")
	var phut := giay / 60
	_lbl_gio.text = "%d:%02d" % [phut, giay % 60]
	var gap := con_lai <= NGUONG_GAP
	_lbl_gio.add_theme_color_override("font_color", MAU_GAP if gap else MAU_CHU)
	if thoi_luong > 0.0:
		_thanh.value = con_lai / thoi_luong * 100.0
	_sb_fill.bg_color = MAU_GAP if gap else MAU_CAM


func _ve_tien() -> void:
	if _lbl_tien != null:
		_lbl_tien.text = str(tien)


func _khung_nen() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = MAU_NEN
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _tao_thanh() -> ProgressBar:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(0, 6)
	t.max_value = 100.0
	t.value = 100.0
	t.show_percentage = false
	var nen := StyleBoxFlat.new()
	nen.bg_color = Color(1, 1, 1, 0.14)
	nen.set_corner_radius_all(3)
	t.add_theme_stylebox_override("background", nen)
	_sb_fill = StyleBoxFlat.new()
	_sb_fill.bg_color = MAU_CAM
	_sb_fill.set_corner_radius_all(3)
	t.add_theme_stylebox_override("fill", _sb_fill)
	return t
