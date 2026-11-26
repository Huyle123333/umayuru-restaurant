extends RefCounted

var _customers: Node = null
var _seconds := 0.0


func enable(ctx: Dictionary) -> void:
	_customers = ctx.get("customers")
	_seconds = float((ctx.get("data", {}) as Dictionary).get("bonus_patience", 0.0))
	if _customers != null and not _customers.order_finished.is_connected(_on_order_finished):
		_customers.order_finished.connect(_on_order_finished)


func disable(_ctx: Dictionary) -> void:
	if _customers != null and is_instance_valid(_customers) \
			and _customers.order_finished.is_connected(_on_order_finished):
		_customers.order_finished.disconnect(_on_order_finished)


func _on_order_finished(_order: Variant, reason: String) -> void:
	if reason != "served" or _customers == null or not is_instance_valid(_customers):
		return
	for o in _customers.active_orders():
		if bool(o.draining):
			o.patience_left = minf(float(o.patience_max), float(o.patience_left) + _seconds)
