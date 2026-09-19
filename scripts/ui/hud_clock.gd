extends CanvasLayer
## Đồng hồ màn chơi và ví tiền, góc TRÊN PHẢI.
##
## Vì sao góc trên phải: cột vé đã chiếm mép trái, bar nấu chiếm giữa đỉnh
## (x 740…1180), khối sức/tay/kĩ năng chiếm góc dưới trái. Đây là góc duy nhất
## còn trống, và nó hợp với vai trò của hai con số này — đọc THƯA, không phải
## nhìn liên tục, nên để xa vùng thao tác là đúng.
##
## Vì sao đồng hồ nằm ở node giao diện chứ không ở một "quản lý màn chơi":
## hiện chưa có node nào sở hữu vòng đời một màn (bắt đầu, hết giờ, bảng kết
## quả). Node này đếm giờ và PHÁT `time_up`, nên khi dựng màn kết thúc thì chỉ
## cần nghe tín hiệu đó — không phải đi tìm và sửa lại chỗ đếm.
##
## Đơn vị tiền là củ cà rốt cầu vồng. Ảnh nằm ở assets/ui/money/ chứ không ở
## assets/ui/nguyen_lieu/ vì empty đó ĐÃ CÓ carrot.png — củ cà rốt nguyên liệu
## thật, thứ người chơi thái slide_out để làm chả rau củ. Hai củ cà rốt, hai vai trò,
## hai thư mục; để chung một chỗ thì sớm muộn cũng có người nạp nhầm.

signal time_up

const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"

const MARGIN := 28.0
const WIDTH := 300.0

const COLOR_BG := Color(0.09, 0.08, 0.07, 0.72)
const COLOR_TEXT := Color(1, 1, 1)
const COLOR_DIM := Color(0.78, 0.74, 0.69)
const COLOR_ORANGE := Color("e8823f")
const COLOR_RUSH := Color("de6459")

## Dưới mức này thì đồng hồ chuyển đỏ và đập nhẹ.
const RUSH_THRESHOLD := 30.0

## Thời lượng một màn, giây. 420 = 7 phút, đúng con số empty bảng cân bằng.
@export var duration: float = 420.0
## Có đếm ngược không. Màn hướng dẫn tắt: học thì không nên bị đuổi.
##
## Có setter vì cờ này bị đổi LÚC ĐANG CHẠY (bộ dẫn dắt tắt lúc vào màn học,
## bật lại lúc học xong). Không vẽ lại ngay empty setter thì mặt đồng hồ giữ
## nguyên giá trị cũ cho tới lần đếm kế tiếp — mà khi đã tắt đếm thì không còn
## lần kế tiếp nào cả, và ô giờ đứng im ở con số cũ mãi mãi.
@export var counting_down: bool = true:
	set(v):
		counting_down = v
		if _lbl_clock != null:
			_draw_clock()

var time_left: float = 0.0
var money: int = 0

var _lbl_clock: Label
var _lbl_money: Label
var _bar: ProgressBar
var _fill_style: StyleBoxFlat
var _alerted := false


func _ready() -> void:
	layer = 5
	time_left = duration
	_build_ui()
	_draw_clock()
	_draw_money()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Neo góc phải nên offset ÂM tính ngược vào empty màn hình.
	frame.offset_right = -MARGIN
	frame.offset_left = -MARGIN - WIDTH
	frame.offset_top = MARGIN
	frame.offset_bottom = MARGIN + 132.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _bg_frame())
	root.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	frame.add_child(col)

	var label := Label.new()
	label.text = "CÒN LẠI"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_DIM)
	col.add_child(label)

	_lbl_clock = Label.new()
	_lbl_clock.add_theme_font_size_override("font_size", 44)
	_lbl_clock.add_theme_color_override("font_color", COLOR_TEXT)
	col.add_child(_lbl_clock)

	_bar = _make_bar()
	col.add_child(_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)

	if ResourceLoader.exists(COIN_ICON):
		var icon := TextureRect.new()
		icon.texture = load(COIN_ICON)
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
	else:
		push_warning("Thiếu ảnh tiền: %s" % COIN_ICON)

	_lbl_money = Label.new()
	_lbl_money.add_theme_font_size_override("font_size", 26)
	_lbl_money.add_theme_color_override("font_color", COLOR_TEXT)
	_lbl_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_lbl_money)


func _process(delta: float) -> void:
	if not counting_down or _alerted:
		return
	var before := time_left
	time_left = maxf(0.0, time_left - delta)
	_draw_clock()

	# Kêu ĐÚNG MỘT LẦN ở khoảnh khắc vượt qua mốc, bằng cách num trước-sau chứ
	# không num `time_left <= 30`. Điều kiện kiểu đó đúng ở MỌI frame hình sau đó,
	# nên nó sẽ kêu sáu chục lần một giây suốt nửa phút cuối.
	if before > RUSH_THRESHOLD and time_left <= RUSH_THRESHOLD:
		AmThanh.play_sfx("sap_het_gio")

	if time_left <= 0.0:
		_alerted = true
		# KHÔNG phát tiếng ở đây. Bảng kết quả hiện slide_out ngay empty cùng frame
		# hình và phát tiếng "tong_ket" của nó, nên hai tiếng đè lên nhau thành
		# một mớ.
		#
		# Bỏ tiếng nào: bỏ "time_up". Vì bảng kết quả CÒN hiện ở màn hướng dẫn
		# (ép hạng S khi học xong), mà màn đó không có đồng hồ nên không bao
		# giờ đi qua nhánh này — giữ "time_up" thay vì "tong_ket" thì kết thúc
		# màn hướng dẫn im lặng hoàn toàn.
		#
		# File time_up_buzzer.mp3 vẫn nằm empty thư mục và vẫn có tên empty
		# bảng FILE_NAMES, chỉ là chưa chỗ nào gọi.
		time_up.emit()


## Đặt thẳng số giây còn lại (cheat tua giờ của CODE No.7).
##
## Có hàm riêng thay vì để bên ngoài gán `time_left` trực tiếp, vì mặt đồng hồ
## chỉ được vẽ lại empty _process, mà _process lại thoát sớm khi `counting_down`
## đang tắt — tức đúng lúc màn hình mở đầu đang đếm 10 giây. Gán thẳng empty
## quãng đó thì thời gian đã nhảy nhưng mặt đồng hồ vẫn hiện 7:00, và người
## bấm tưởng cheat không ăn.
##
## clamp về [0, duration]: tua tới một con số âm thì phép chia empty _draw_clock
## cho slide_out bar tiến trình âm, còn tua vượt quá thời lượng thì bar vượt 100%.
func set_time_left(seconds: float) -> void:
	time_left = clampf(seconds, 0.0, duration)
	_draw_clock()


## Nối vào hệ khách để ví tự cập nhật.
func listen_to_orders(ql: Node) -> void:
	if ql != null and ql.has_signal("tien_thay_doi"):
		ql.tien_thay_doi.connect(_on_money_changed)


func _on_money_changed(tong: int, _them: int, _cho: Vector3) -> void:
	money = tong
	_draw_money()
	# Nảy nhẹ con số: phần thưởng phải có phản hồi, nhưng ở góc màn hình thì
	# một cú nảy 1,15 lần empty 0,18 giây là đủ thấy mà không kéo mắt khỏi bếp.
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lbl_money.pivot_offset = _lbl_money.size * 0.5
	tween.tween_property(_lbl_money, "scale", Vector2(1.15, 1.15), 0.09)
	tween.tween_property(_lbl_money, "scale", Vector2.ONE, 0.09)


func _draw_clock() -> void:
	if _lbl_clock == null:
		return
	# Đồng hồ tắt (màn hướng dẫn): vẫn giữ nguyên panel nhưng hiện "--:--".
	#
	# Không ẩn hẳn panel: người chơi phải LÀM QUEN với chỗ này ngay từ màn học,
	# để lúc vào màn thật cái đồng hồ không phải một thứ mới xuất hiện. Hiện
	# gạch ngang thì họ biết ô đó có tồn tại và biết nó chưa chạy.
	if not counting_down:
		_lbl_clock.text = "--:--"
		_lbl_clock.add_theme_color_override("font_color", COLOR_DIM)
		_bar.value = 100.0
		_fill_style.bg_color = COLOR_ORANGE
		return

	var seconds := int(ceilf(time_left))
	# Chia lấy nguyên là CHỦ Ý ở đây (phút), không phải quên ép kiểu.
	@warning_ignore("integer_division")
	var minutes := seconds / 60
	_lbl_clock.text = "%d:%02d" % [minutes, seconds % 60]
	var rushing := time_left <= RUSH_THRESHOLD
	_lbl_clock.add_theme_color_override("font_color", COLOR_RUSH if rushing else COLOR_TEXT)
	if duration > 0.0:
		_bar.value = time_left / duration * 100.0
	_fill_style.bg_color = COLOR_RUSH if rushing else COLOR_ORANGE


func _draw_money() -> void:
	if _lbl_money != null:
		_lbl_money.text = str(money)


func _bg_frame() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _make_bar() -> ProgressBar:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(0, 6)
	t.max_value = 100.0
	t.value = 100.0
	t.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.14)
	bg.set_corner_radius_all(3)
	t.add_theme_stylebox_override("background", bg)
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = COLOR_ORANGE
	_fill_style.set_corner_radius_all(3)
	t.add_theme_stylebox_override("fill", _fill_style)
	return t
