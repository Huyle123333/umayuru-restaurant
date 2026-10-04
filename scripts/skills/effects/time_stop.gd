extends RefCounted
## HIỆU ỨNG: DỪNG THỜI GIAN — Triumphant Pulse của Oguri Cap.
##
## Khi bật: đồng hồ màn đứng, mọi khách hàng đứng im tại chỗ (không đi, không
## ăn, không trừ kiên nhẫn), không có khách mới. Nhân vật người chơi và khu
## bếp vẫn chạy bình thường — bếp vẫn nấu, và vẫn CHÁY nếu bỏ quên.
##
## Giao ước với skill_manager: enable(ctx) bật, disable(ctx) tắt. Ngân sách 30
## giây và việc bật/tắt do skill_manager lo; file này chỉ biết "đang dừng" hay
## "đang chạy".
##
## Vì sao là một FILE RIÊNG chứ không phải một nhánh trong skill_manager: nó
## đụng cùng lúc bốn hệ (đồng hồ, khách, nhạc, màn hình) và phải TRẢ LẠI đúng
## trạng thái cũ khi tắt. Cả cặp bật/tắt nằm cạnh nhau trong một file thì nhìn
## là thấy có trả đủ hay không.

const TINT_COLOR := Color(0.35, 0.55, 1.0, 0.16)
const TINT_FADE := 0.2

## Đồng hồ có đang chạy TRƯỚC khi dừng không. Nhớ lại để lúc tắt trả đúng
## trạng thái đó, chứ không ép thành "đang chạy" — đồng hồ có thể đã bị một
## thứ khác cho đứng (màn đếm ngược đầu màn).
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
	# Nhạc TẠM DỪNG cùng thời gian, không chỉ để tạo không khí: bài cao điểm
	# cuối màn dài đúng bằng quãng còn lại của đồng hồ. Đồng hồ đứng mà nhạc
	# vẫn chạy thì bài hát hết trước khi màn kết thúc, và đoạn cuối im lặng.
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
## nó thì dấu hiệu duy nhất là con số đồng hồ không nhảy — thứ người chơi
## không nhìn vào lúc đang chạy quanh bếp.
func _show_tint(level: Variant) -> void:
	if level == null or not (level is Node) or _tint_layer != null:
		return
	_tint_layer = CanvasLayer.new()
	_tint_layer.layer = 4   # dưới mọi HUD (đơn hàng 5, thực đơn 6)
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
