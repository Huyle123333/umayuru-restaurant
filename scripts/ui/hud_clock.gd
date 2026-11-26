extends CanvasLayer

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
@export var counting_down: bool = true:
	set(v):
		counting_down = v
		if _lbl_clock != null:
			_draw_clock()

var time_left: float = 0.0

## Số giây ứng với thanh thời gian ĐẦY. 0 = dùng `duration` như mọi màn.
var bar_full: float = 0.0

## Tốc độ đếm ngược. 1,0 = một giây thật là một giây màn.
var time_scale: float = 1.0
var money: int = 0

var _lbl_clock: Label
var _lbl_money: Label
## Dòng "Khách bỏ về 3 / 10". Chỉ hiện ở màn có giới hạn (xem set_lost()).
var _lbl_lost: Label
var _bar: ProgressBar

# ------------------------------------------------ chữ cái mốc hạng (2/10/2026)
var _marks: Dictionary = {}
## Thứ tự hạng từ THẤP lên CAO (D, C, B, A, S).
var _ranks_low_to_high: Array = []
## Hạng cao nhất ĐÃ ĂN MỪNG trong lượt này (chỉ số trong mảng trên, -1 = chưa).
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
	frame.offset_right = -MARGIN
	frame.offset_left = -MARGIN - WIDTH
	frame.offset_top = MARGIN
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

	if before > RUSH_THRESHOLD and time_left <= RUSH_THRESHOLD:
		AmThanh.play_sfx("time_warning")

	if time_left <= 0.0:
		_alerted = true
		time_up.emit()


## Đặt thẳng số giây còn lại (cheat tua giờ của CODE No.7).
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


## level_base gọi một lần lúc vào màn. `order` là GameData.RANK_ORDER (cao
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
	_lbl_rank.add_theme_color_override("font_color",
		(RANK_COLORS.get(next_rank, COLOR_DIM) as Color).lerp(COLOR_DIM, 0.55))
	_lbl_rank_target.text = str(int(_marks.get(next_rank, 0)))
	_lbl_rank_target.visible = true


## Ăn mừng vừa đạt mốc thứ `level` (0 = D ... 4 = S). Bốn thứ cùng leo thang:
func _celebrate(level: int) -> void:
	var rank := String(_ranks_low_to_high[level])
	var color: Color = RANK_COLORS.get(rank, COLOR_TEXT)
	var is_top := level >= _ranks_low_to_high.size() - 1

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
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lbl_money.pivot_offset = _lbl_money.size * 0.5
	tween.tween_property(_lbl_money, "scale", Vector2(1.15, 1.15), 0.09)
	tween.tween_property(_lbl_money, "scale", Vector2.ONE, 0.09)


func _draw_clock() -> void:
	if _lbl_clock == null:
		return
	if not counting_down:
		_lbl_clock.text = "--:--"
		_lbl_clock.add_theme_color_override("font_color", COLOR_DIM)
		_bar.value = 100.0
		_fill_style.bg_color = COLOR_ORANGE
		return

	var seconds := int(ceilf(time_left))
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
