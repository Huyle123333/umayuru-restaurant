extends RefCounted


func enable(ctx: Dictionary) -> void:
	var customers: Node = ctx.get("customers")
	if customers != null and customers.has_method("clear_all_customers"):
		customers.clear_all_customers()
	var clock: Node = ctx.get("clock")
	if GameData.is_asian_mode():
		return
	if clock != null and GameData.is_endless_mode() and float(clock.bar_full) > 0.0:
		clock.add_time(float(clock.bar_full) - float(clock.time_left))
		return
	if clock != null and clock.has_method("reset_time"):
		clock.reset_time()
