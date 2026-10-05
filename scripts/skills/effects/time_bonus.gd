extends RefCounted
## HIỆU ỨNG: Sky-High Teio Step — kĩ năng chủ động của Tokai Teio.
##
## Từ lúc bật tới hết màn, mỗi đơn GIAO XONG nối dài màn chơi thêm một khoảng
## (khoá "bonus_seconds" trong teio.gd).
##
## Vì sao là file riêng: tác dụng không phải "vặn một con số" mà là PHẢN ỨNG
## với một sự kiện (đơn giao xong) trong suốt phần còn lại của màn — cần nối
## tín hiệu lúc bật và gỡ ra lúc tắt.

var _clock: Node = null
var _customers: Node = null
var _seconds := 0.0


func enable(ctx: Dictionary) -> void:
	_clock = ctx.get("clock")
	_customers = ctx.get("customers")
	_seconds = float((ctx.get("data", {}) as Dictionary).get("bonus_seconds", 0.0))
	if _customers != null and not _customers.order_finished.is_connected(_on_order_finished):
		_customers.order_finished.connect(_on_order_finished)


func disable(_ctx: Dictionary) -> void:
	if _customers != null and is_instance_valid(_customers) \
			and _customers.order_finished.is_connected(_on_order_finished):
		_customers.order_finished.disconnect(_on_order_finished)


func _on_order_finished(_order: Variant, reason: String) -> void:
	# Chỉ đơn ĐÃ PHỤC VỤ. Khách bỏ về mà cũng được cộng giờ thì để mất khách
	# thành một cách câu giờ.
	if reason != "served" or _clock == null or not is_instance_valid(_clock):
		return
	if _clock.has_method("add_time"):
		_clock.add_time(_seconds)
