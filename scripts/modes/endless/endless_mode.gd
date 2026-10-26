extends CanvasLayer
## ENDLESS MODE — bộ điều phối của chế độ (user chốt luật 25/10/2026).
##
## Luật:
##   • Đồng hồ ĐẾM NGƯỢC, hết giờ là thua.
##   • Giao xong một đơn: cộng giờ (đơn hoàn hảo cộng nhiều hơn).
##   • Khách ĐÃ NGỒI BÀN mà bỏ về: trừ giờ. Khách bỏ hàng đợi thì không —
##     cùng lý do customer_manager không tính họ là "mất khách": người chơi
##     chưa được phép phục vụ họ.
##   • Mỗi 3 phút một mốc: món khó hơn + khách dày hơn. Phần đó nằm hết trong
##     GameData.RULES_ENDLESS["stages"] và do level_rules.gd áp — file này chỉ
##     BÁO cho người chơi biết vừa sang mốc mới.
##
## Vì sao là một node riêng (giống aaa_mode.gd) chứ không rải "if endless" vào
## customer_manager / hud_clock: luật cộng-trừ giờ là luật của CHẾ ĐỘ, không
## phải của nhà hàng. Gom một chỗ thì muốn chỉnh con số nào cũng chỉ mở một
## file, và các màn thường không bị đụng tới một dòng nào.
##
## Là CanvasLayer vì nó tự vẽ chữ "+15s" cạnh đồng hồ và chữ báo mốc mới.

## Giây cộng thêm khi giao xong một đơn thường / một đơn hoàn hảo.
@export var bonus_served := 15.0
@export var bonus_perfect := 25.0
## Giây bị trừ khi một khách đã ngồi bàn bỏ về.
@export var penalty_left := 10.0

const STAGE_SECONDS := 180.0
const COLOR_TEXT := Color(1, 1, 1)
const COLOR_DIM := Color(0.78, 0.74, 0.69)
const COLOR_GOOD := Color("8fe388")
const COLOR_BAD := Color("de6459")
const COLOR_STAGE := Color("ffd76a")

var _clock: Node
var _customers: Node
var _stage := 0


func setup(customers: Node, clock: Node) -> void:
	_customers = customers
	_clock = clock
	layer = 6
	if _clock != null:
		# Thanh thời gian đo theo số giây BAN ĐẦU chứ không theo `duration`:
		# duration lớn dần mỗi lần được cộng giờ, đo theo nó thì thanh cứ
		# ngắn dần dù người chơi đang giữ được nhiều giờ hơn lúc đầu.
		_clock.bar_full = float(_clock.duration)
	if _customers != null:
		_customers.order_finished.connect(_on_order_finished)


## Thời gian đã trụ được (giây). Cùng công thức level_rules dùng để chọn mốc.
func survived_seconds() -> float:
	if _clock == null:
		return 0.0
	return maxf(0.0, float(_clock.duration) - float(_clock.time_left))


func _on_order_finished(order_: RefCounted, reason: String) -> void:
	if _clock == null:
		return
	match reason:
		"served":
			_give_time(bonus_perfect if bool(order_.was_perfect) else bonus_served)
		"left":
			if not bool(order_.in_queue):
				_give_time(-penalty_left)


func _give_time(seconds: float) -> void:
	# Hết giờ rồi (bảng kết quả đang hiện) thì không cộng trừ gì nữa.
	if float(_clock.time_left) <= 0.0:
		return
	# Không trừ quá số giây còn lại: còn 4 giây mà trừ 10 thì về 0 là đủ
	# thua, để âm thì thanh thời gian vẽ ra giá trị âm.
	if seconds < 0.0:
		seconds = maxf(seconds, -float(_clock.time_left))
	# add_time() cộng vào CẢ duration lẫn time_left, nên "đã trụ" (hiệu hai
	# số) không đổi — giờ thưởng không kéo lùi mốc độ khó.
	_clock.add_time(seconds)
	_popup(("+%ds" % int(seconds)) if seconds > 0.0 else ("−%ds" % int(absf(seconds))),
		COLOR_GOOD if seconds > 0.0 else COLOR_BAD)


func _process(_delta: float) -> void:
	if _clock == null:
		return
	# (26/10/2026) Bỏ khung "Đã trụ / Mốc" dưới đồng hồ theo yêu cầu user —
	# thừa thông tin. Mốc mới vẫn được báo bằng chữ lớn giữa màn hình.
	var stage := int(survived_seconds() / STAGE_SECONDS)
	if stage != _stage:
		_stage = stage
		_announce_stage()


## "m:ss" — dùng chung cho HUD, bảng kết quả và bảng xếp hạng.
static func format_time(seconds: float) -> String:
	var s := int(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [s / 60, s % 60]


# ------------------------------------------------------------ giao diện ---

## "+15s" bay lên cạnh đồng hồ: người chơi phải thấy NGAY đơn vừa giao đổi
## thành bao nhiêu giây, ở đúng chỗ họ nhìn khi lo hết giờ.
func _popup(text: String, color: Color) -> void:
	var l := _label(text, 34, color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 8)
	l.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	l.offset_left = -440.0
	l.offset_right = -340.0
	l.offset_top = 70.0
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "offset_top", 30.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.finished.connect(l.queue_free)


## Chữ lớn giữa màn hình khi sang mốc mới: đổi độ khó mà không báo thì người
## chơi chỉ thấy tự dưng đông khách, không hiểu vì sao.
func _announce_stage() -> void:
	var l := _label(Lang.t("MỐC %d — món khó hơn, khách đông hơn!") % (_stage + 1), 44, COLOR_STAGE)
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	l.add_theme_constant_override("outline_size", 12)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.offset_left = -700.0
	l.offset_right = 700.0
	l.offset_top = 260.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate.a = 0.0
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.finished.connect(l.queue_free)
	AmThanh.play_sfx("perfect")


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
