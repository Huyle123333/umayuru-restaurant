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
## assets/ui/nguyen_lieu/ vì trong đó ĐÃ CÓ carrot.png — củ cà rốt nguyên liệu
## thật, thứ người chơi thái ra để làm chả rau củ. Hai củ cà rốt, hai vai trò,
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

## Thời lượng một màn, giây. 420 = 7 phút, đúng con số trong bảng cân bằng.
@export var duration: float = 420.0
## Có đếm ngược không. Màn hướng dẫn tắt: học thì không nên bị đuổi.
##
## Có setter vì cờ này bị đổi LÚC ĐANG CHẠY (bộ dẫn dắt tắt lúc vào màn học,
## bật lại lúc học xong). Không vẽ lại ngay trong setter thì mặt đồng hồ giữ
## nguyên giá trị cũ cho tới lần đếm kế tiếp — mà khi đã tắt đếm thì không còn
## lần kế tiếp nào cả, và ô giờ đứng im ở con số cũ mãi mãi.
@export var counting_down: bool = true:
	set(v):
		counting_down = v
		if _lbl_clock != null:
			_draw_clock()

var time_left: float = 0.0

## Số giây ứng với thanh thời gian ĐẦY. 0 = dùng `duration` như mọi màn.
## Endless đặt bằng số giây ban đầu, vì ở đó duration tăng mỗi lần được cộng
## giờ (xem endless_mode.gd). Vượt quá thì thanh đứng ở 100%.
var bar_full: float = 0.0

## Tốc độ đếm ngược. 1,0 = một giây thật là một giây màn.
## (Sakura Chiyono O — Made in haven: 1,25.)
var time_scale: float = 1.0
var money: int = 0

var _lbl_clock: Label
var _lbl_money: Label
## Dòng "Khách bỏ về 3 / 10". Chỉ hiện ở màn có giới hạn (xem set_lost()).
var _lbl_lost: Label
var _bar: ProgressBar

# ------------------------------------------------ chữ cái mốc hạng (2/10/2026)
## Mốc doanh thu của màn: hạng -> số tiền. Rỗng = màn không xếp hạng, ẩn chữ.
var _marks: Dictionary = {}
## Thứ tự hạng từ THẤP lên CAO (D, C, B, A, S).
var _ranks_low_to_high: Array = []
## Hạng cao nhất ĐÃ ĂN MỪNG trong lượt này (chỉ số trong mảng trên, -1 = chưa).
## Tiền có thể tụt (mua nguyên liệu) rồi vượt lại cùng một mốc; nhớ số này để
## mỗi mốc chỉ ăn mừng MỘT lần — nháy đi nháy lại thì hết còn là phần thưởng.
var _best_celebrated := -1
var _lbl_rank: Label
var _lbl_rank_target: Label
var _rank_tween: Tween
var _celebrating := false
## Đang ở hạng cao nhất: chữ chạy màu cầu vồng liên tục trong _process.
var _rainbow := false
var _flash: ColorRect

const RANK_COLORS := {
	"S": Color("f2c230"), "A": Color("e8823f"), "B": Color("e27ba0"),
	"C": Color("4f9d5d"), "D": Color("5b8fb0"),
}
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
	# Neo góc phải nên offset ÂM tính ngược vào trong màn hình.
	frame.offset_right = -MARGIN
	frame.offset_left = -MARGIN - WIDTH
	frame.offset_top = MARGIN
	# +28 cho dòng "Khách bỏ về". Dòng đó ẩn ở màn không có giới hạn, khi ấy
	# khung chỉ dư một dải trống nhỏ ở đáy — rẻ hơn là đổi cỡ khung lúc chạy.
	frame.offset_bottom = MARGIN + 160.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _bg_frame())
	root.add_child(frame)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	frame.add_child(col)

	var label := Label.new()
	label.text = Lang.t("CÒN LẠI")
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

	# Đẩy chữ cái mốc hạng sang LỀ PHẢI của hàng tiền.
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)

	_lbl_rank_target = Label.new()
	_lbl_rank_target.add_theme_font_size_override("font_size", 14)
	_lbl_rank_target.add_theme_color_override("font_color", COLOR_DIM)
	_lbl_rank_target.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lbl_rank_target.visible = false
	row.add_child(_lbl_rank_target)

	_lbl_rank = Label.new()
	_lbl_rank.add_theme_font_size_override("font_size", 30)
	_lbl_rank.add_theme_constant_override("outline_size", 6)
	_lbl_rank.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_lbl_rank.custom_minimum_size = Vector2(30, 0)
	_lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_rank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lbl_rank.visible = false
	row.add_child(_lbl_rank)

	# Lớp chớp sáng phủ cả màn hình, dùng từ hạng B trở lên. Nằm TRONG root
	# của HUD này nên không che bảng tạm dừng hay bảng tổng kết (lớp cao hơn).
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	root.add_child(_flash)

	_lbl_lost = Label.new()
	_lbl_lost.add_theme_font_size_override("font_size", 16)
	_lbl_lost.add_theme_color_override("font_color", COLOR_DIM)
	_lbl_lost.visible = false
	col.add_child(_lbl_lost)


func _process(delta: float) -> void:
	# Hạng cao nhất: chữ chạy vòng màu cầu vồng, kiểu đèn LED RGB. Đặt TRƯỚC
	# mọi lệnh return bên dưới — đồng hồ dừng (hết giờ, tutorial) thì chữ vẫn
	# phải chạy màu.
	if _rainbow and _lbl_rank != null and not _celebrating:
		var hue := fmod(Time.get_ticks_msec() / 1000.0 * 0.8, 1.0)
		_lbl_rank.add_theme_color_override("font_color", Color.from_hsv(hue, 0.85, 1.0))
		var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
		_lbl_rank.pivot_offset = _lbl_rank.size * 0.5
		_lbl_rank.scale = Vector2(pulse, pulse)

	if not counting_down or _alerted:
		return
	var before := time_left
	time_left = maxf(0.0, time_left - delta * time_scale)
	_draw_clock()

	# Kêu ĐÚNG MỘT LẦN ở khoảnh khắc vượt qua mốc, bằng cách num trước-sau chứ
	# không num `time_left <= 30`. Điều kiện kiểu đó đúng ở MỌI frame hình sau đó,
	# nên nó sẽ kêu sáu chục lần một giây suốt nửa phút cuối.
	if before > RUSH_THRESHOLD and time_left <= RUSH_THRESHOLD:
		AmThanh.play_sfx("time_warning")

	if time_left <= 0.0:
		_alerted = true
		# KHÔNG phát tiếng ở đây. Bảng kết quả hiện ra ngay trong cùng frame
		# hình và phát tiếng "tong_ket" của nó, nên hai tiếng đè lên nhau thành
		# một mớ.
		#
		# Bỏ tiếng nào: bỏ "time_up". Vì bảng kết quả CÒN hiện ở màn hướng dẫn
		# (ép hạng S khi học xong), mà màn đó không có đồng hồ nên không bao
		# giờ đi qua nhánh này — giữ "time_up" thay vì "tong_ket" thì kết thúc
		# màn hướng dẫn im lặng hoàn toàn.
		#
		# File time_up_buzzer.mp3 vẫn nằm trong thư mục và vẫn có tên trong
		# bảng FILE_NAMES, chỉ là chưa chỗ nào gọi.
		time_up.emit()


## Đặt thẳng số giây còn lại (cheat tua giờ của CODE No.7).
##
## Có hàm riêng thay vì để bên ngoài gán `time_left` trực tiếp, vì mặt đồng hồ
## chỉ được vẽ lại trong _process, mà _process lại thoát sớm khi `counting_down`
## đang tắt — tức đúng lúc màn hình mở đầu đang đếm 10 giây. Gán thẳng trong
## quãng đó thì thời gian đã nhảy nhưng mặt đồng hồ vẫn hiện 7:00, và người
## bấm tưởng cheat không ăn.
##
## clamp về [0, duration]: tua tới một con số âm thì phép chia trong _draw_clock
## cho ra bar tiến trình âm, còn tua vượt quá thời lượng thì bar vượt 100%.
## Nối dài màn chơi thêm `seconds` giây. (Tokai Teio — Sky-High Teio Step.)
##
## Cộng vào CẢ duration lẫn time_left chứ không chỉ time_left: luật màn tính
## "đã trôi bao lâu" bằng duration − time_left để chọn giai đoạn khách. Chỉ
## cộng time_left thì mỗi đơn giao xong kéo màn LÙI 10 giây về giai đoạn dễ
## hơn — kĩ năng vừa cho thêm giờ vừa làm khách thưa đi, lợi hai lần.
func add_time(seconds: float) -> void:
	duration += seconds
	time_left += seconds
	_draw_clock()


## Đưa đồng hồ về đầy như lúc vào màn. (Sakura Chiyono O — Ambition.)
func reset_time() -> void:
	time_left = duration
	_alerted = false
	_draw_clock()


func set_time_left(seconds: float) -> void:
	time_left = clampf(seconds, 0.0, duration)
	_draw_clock()


# ══════════════════════════════════════════ CHỮ CÁI MỐC HẠNG TRÊN HUD
#
# Bên phải số tiền luôn hiện MỐC KẾ TIẾP cần đạt (chữ mờ + số tiền của mốc).
# Tiền vượt mốc thì chữ đó bùng lên ăn mừng rồi đổi sang mốc sau. Mỗi mốc ăn
# mừng TO HƠN mốc trước — phần thưởng phải leo thang thì người chơi mới muốn
# với tới mốc sau. Ở hạng cao nhất, chữ chạy màu cầu vồng cho tới hết màn.

## level_base gọi một lần lúc vào màn. `order` là GameData.RANK_ORDER (cao
## xuống thấp); đảo lại để đi từ D lên S.
func set_rank_marks(marks: Dictionary, order: Array) -> void:
	_marks = marks
	_ranks_low_to_high = order.duplicate()
	_ranks_low_to_high.reverse()
	_best_celebrated = -1
	_update_rank(false)


## Số mốc mà số tiền HIỆN TẠI đã vượt (0 = chưa đạt hạng nào).
func _ranks_reached() -> int:
	var n := 0
	for rank in _ranks_low_to_high:
		if money >= int(_marks.get(rank, 0)):
			n += 1
	return n


func _update_rank(celebrate: bool) -> void:
	if _lbl_rank == null or _marks.is_empty():
		return
	var reached := _ranks_reached()
	if celebrate and reached - 1 > _best_celebrated:
		_best_celebrated = reached - 1
		_celebrate(_best_celebrated)
		return
	if not _celebrating:
		_draw_rank()


## Vẽ trạng thái tĩnh: mốc kế tiếp (mờ), hoặc hạng cao nhất (cầu vồng).
func _draw_rank() -> void:
	var reached := _ranks_reached()
	var top := _ranks_low_to_high.size()
	_lbl_rank.visible = true
	_lbl_rank.scale = Vector2.ONE
	_lbl_rank.modulate = Color.WHITE
	_rainbow = reached >= top
	if _rainbow:
		_lbl_rank.text = String(_ranks_low_to_high[top - 1])
		_lbl_rank_target.visible = false
		return
	var next_rank := String(_ranks_low_to_high[reached])
	_lbl_rank.text = next_rank
	# Mốc CHƯA đạt thì chữ NHẠT (pha về xám sáng): nó là đích đến, chưa phải
	# thành tích. Pha sáng chứ không làm tối — nền HUD màu đen, chữ tối thêm
	# là chìm mất (chụp thử: chữ D xanh đậm gần như không đọc được).
	_lbl_rank.add_theme_color_override("font_color",
		(RANK_COLORS.get(next_rank, COLOR_DIM) as Color).lerp(COLOR_DIM, 0.55))
	_lbl_rank_target.text = str(int(_marks.get(next_rank, 0)))
	_lbl_rank_target.visible = true


## Ăn mừng vừa đạt mốc thứ `level` (0 = D ... 4 = S). Bốn thứ cùng leo thang:
##   - chữ phóng to hơn       (1,4 lần ở D → 2,6 lần ở S)
##   - nháy nhiều lần hơn     (1 lần → 5 lần)
##   - tiếng reo riêng cho từng hạng (rank_d … rank_s)
##   - từ hạng B: cả màn hình chớp màu của hạng, càng cao càng đậm
## Riêng hạng cao nhất: màn hình chớp lần lượt đủ bảy màu, rồi chữ S chạy cầu
## vồng liên tục (xem _process).
##
## Dùng MỘT công thức theo `level` chứ không viết năm đoạn riêng: thêm hạng
## thứ sáu thì hiệu ứng của nó tự to hơn hạng thứ năm, không phải viết thêm.
func _celebrate(level: int) -> void:
	var rank := String(_ranks_low_to_high[level])
	var color: Color = RANK_COLORS.get(rank, COLOR_TEXT)
	var is_top := level >= _ranks_low_to_high.size() - 1

	# Mốc sau tới khi mốc trước còn đang nháy (một đơn lớn vượt hai mốc): bỏ
	# hiệu ứng cũ, chạy luôn cái to hơn.
	if _rank_tween != null and _rank_tween.is_valid():
		_rank_tween.kill()
	_celebrating = true
	_rainbow = false

	_lbl_rank.visible = true
	_lbl_rank_target.visible = false
	_lbl_rank.text = rank
	_lbl_rank.add_theme_color_override("font_color", color)
	_lbl_rank.pivot_offset = _lbl_rank.size * 0.5

	var peak := 1.4 + 0.3 * float(level)
	var blinks := level + 1
	# Mỗi hạng một file tiếng riêng: assets/sfx/game/rank_<chữ>.mp3. Ghép tên
	# khoá từ chữ cái hạng chứ không viết năm nhánh — thêm hạng mới chỉ cần
	# thả thêm một file đúng tên. Không đổi cao độ: đây là giọng người, vặn
	# pitch lên là méo tiếng. Thiếu file thì hệ âm thanh im lặng bỏ qua.
	AmThanh.play_sfx("rank_" + rank.to_lower())

	_rank_tween = create_tween()
	_rank_tween.tween_property(_lbl_rank, "scale", Vector2(peak, peak), 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in blinks:
		_rank_tween.tween_property(_lbl_rank, "modulate", Color(3, 3, 3), 0.07)
		_rank_tween.tween_property(_lbl_rank, "modulate", Color.WHITE, 0.09)
	_rank_tween.tween_property(_lbl_rank, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_rank_tween.tween_interval(0.5)
	_rank_tween.tween_callback(func() -> void:
		_celebrating = false
		_draw_rank())

	# Chớp cả màn hình — chạy SONG SONG với chữ, trên một tween riêng.
	if is_top:
		var rgb := create_tween()
		for i in 14:
			var hue := Color.from_hsv(float(i % 7) / 7.0, 0.9, 1.0)
			rgb.tween_property(_flash, "color", Color(hue.r, hue.g, hue.b, 0.30), 0.06)
			rgb.tween_property(_flash, "color", Color(hue.r, hue.g, hue.b, 0.0), 0.08)
	elif level >= 2:
		var strength := 0.10 + 0.08 * float(level - 2)
		_flash.color = Color(color.r, color.g, color.b, 0.0)
		var fl := create_tween()
		fl.tween_property(_flash, "color:a", strength, 0.08)
		fl.tween_property(_flash, "color:a", 0.0, 0.35)


## Cập nhật dòng đếm khách bỏ về. limit <= 0 nghĩa là màn không giới hạn —
## ẩn hẳn dòng này, không hiện "0 / 0".
##
## Vì sao phải có trên HUD: vượt giới hạn là THUA NGAY. Một luật thua mà
## người chơi không nhìn thấy đang tới gần thì khi nó xảy ra họ chỉ thấy bị
## đá khỏi màn vô cớ. Chữ đổi sang màu báo động từ lúc còn đúng 2 người.
func set_lost(count: int, limit: int) -> void:
	if _lbl_lost == null:
		return
	_lbl_lost.visible = limit > 0
	if limit <= 0:
		return
	_lbl_lost.text = Lang.t("Khách bỏ về  %d / %d") % [count, limit]
	_lbl_lost.add_theme_color_override("font_color",
		COLOR_RUSH if count >= limit - 2 else COLOR_DIM)


## Nối vào hệ khách để ví tự cập nhật.
func listen_to_orders(orders: Node) -> void:
	if orders != null and orders.has_signal("money_changed"):
		orders.money_changed.connect(_on_money_changed)


func _on_money_changed(total: int, _added: int, _at: Vector3) -> void:
	money = total
	_draw_money()
	_update_rank(true)
	# Nảy nhẹ con số: phần thưởng phải có phản hồi, nhưng ở góc màn hình thì
	# một cú nảy 1,15 lần trong 0,18 giây là đủ thấy mà không kéo mắt khỏi bếp.
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
	var full := bar_full if bar_full > 0.0 else duration
	if full > 0.0:
		_bar.value = minf(time_left / full, 1.0) * 100.0
	_fill_style.bg_color = COLOR_RUSH if rushing else COLOR_ORANGE


func _draw_money() -> void:
	if _lbl_money == null:
		return
	_lbl_money.text = str(money)
	# Âm thì tô đỏ. Tiền âm là trạng thái BÌNH THƯỜNG mấy giây đầu màn (đã mua
	# nguyên liệu, chưa giao được món nào), nên không cảnh báo gì thêm — chỉ đổi
	# màu để người chơi biết mình đang âm mà không phải đọc dấu trừ bé tí.
	_lbl_money.add_theme_color_override("font_color",
		COLOR_RUSH if money < 0 else COLOR_TEXT)


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
