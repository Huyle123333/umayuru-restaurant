extends RefCounted

const TINT_COLOR := Color(0.35, 0.55, 1.0, 0.16)
const TINT_FADE := 0.2

## Đồng hồ có đang chạy TRƯỚC khi dừng không. Nhớ lại để lúc tắt trả đúng
var _clock_was_counting := true
var _tint_layer: CanvasLayer = null


func enable(ctx: Dictionary) -> void:
	var clock: Node = ctx.get("clock")
	if clock != null:
		_clock_was_counting = bool(clock.counting_down)
		clock.counting_down = false
	var customers: Node = ctx.get("customers")
	if customers != null and customers.has_method("set_frozen"):
		customers.set_frozen(true)
	AmThanh.set_music_hushed(true)
	_show_tint(ctx.get("level"))


func disable(ctx: Dictionary) -> void:
	var clock: Node = ctx.get("clock")
	if clock != null and is_instance_valid(clock):
		clock.counting_down = _clock_was_counting
	var customers: Node = ctx.get("customers")
	if customers != null and is_instance_valid(customers) and customers.has_method("set_frozen"):
		customers.set_frozen(false)
	AmThanh.set_music_hushed(false)
	_hide_tint()


## Lớp phủ xanh nhạt toàn màn hình: tín hiệu "thời gian đang đứng". Không có
func _show_tint(level: Variant) -> void:
	if level == null or not (level is Node) or _tint_layer != null:
		return
	_tint_layer = CanvasLayer.new()
	_tint_layer.layer = 4
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(TINT_COLOR, 0.0)
	_tint_layer.add_child(rect)
	(level as Node).add_child(_tint_layer)
	rect.create_tween().tween_property(rect, "color:a", TINT_COLOR.a, TINT_FADE)


func _hide_tint() -> void:
	if _tint_layer == null or not is_instance_valid(_tint_layer):
		_tint_layer = null
		return
	_tint_layer.queue_free()
	_tint_layer = null
