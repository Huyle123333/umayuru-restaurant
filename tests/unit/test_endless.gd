extends "res://tests/test_case.gd"
## Kiểm thử luật cộng/trừ giờ của Endless Mode bằng đồng hồ và đơn giả.

const EndlessMode := preload("res://scripts/modes/endless/endless_mode.gd")


class FakeClock extends Node:
	var duration := 150.0
	var time_left := 150.0
	var bar_full := 0.0
	func add_time(s: float) -> void:
		time_left += s


class FakeCustomers extends Node:
	signal order_finished(order_: RefCounted, reason: String)


class FakeOrder extends RefCounted:
	var was_perfect := false
	var in_queue := false


var _mode: CanvasLayer
var _clock: FakeClock
var _customers: FakeCustomers


func before_each() -> void:
	_clock = FakeClock.new()
	_customers = FakeCustomers.new()
	_mode = EndlessMode.new()
	add_child(_clock)
	add_child(_customers)
	add_child(_mode)
	_mode.setup(_customers, _clock)


func after_each() -> void:
	for n in [_mode, _clock, _customers]:
		n.queue_free()


func _finish(perfect: bool, in_queue: bool, reason: String) -> void:
	var o := FakeOrder.new()
	o.was_perfect = perfect
	o.in_queue = in_queue
	_customers.order_finished.emit(o, reason)


func test_served_order_adds_15_seconds() -> void:
	_finish(false, false, "served")
	assert_almost_eq(_clock.time_left, 165.0)


func test_perfect_order_adds_25_seconds() -> void:
	_finish(true, false, "served")
	assert_almost_eq(_clock.time_left, 175.0)


func test_seated_customer_leaving_costs_10_seconds() -> void:
	_finish(false, false, "left")
	assert_almost_eq(_clock.time_left, 140.0)


func test_customer_leaving_from_queue_costs_nothing() -> void:
	_finish(false, true, "left")
	assert_almost_eq(_clock.time_left, 150.0)


func test_penalty_never_pushes_time_below_zero() -> void:
	_clock.time_left = 4.0
	_finish(false, false, "left")
	assert_almost_eq(_clock.time_left, 0.0)


func test_no_bonus_after_time_ran_out() -> void:
	_clock.time_left = 0.0
	_finish(true, false, "served")
	assert_almost_eq(_clock.time_left, 0.0)


func test_survived_time_and_format() -> void:
	_clock.time_left = 30.0
	assert_almost_eq(_mode.survived_seconds(), 120.0)
	assert_eq(EndlessMode.format_time(125.0), "2:05")
