extends "res://tests/test_case.gd"
## Kiểm thử vòng đời kiên nhẫn của một đơn hàng.

const Order := preload("res://scripts/restaurant/order.gd")
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

var _order: RefCounted


func before_each() -> void:
	_order = Order.new(null, "mon_steak")


func test_price_taken_from_catalog() -> void:
	assert_eq(_order.price, ItemCatalog.price("mon_steak"))


func test_queue_patience_uses_given_seconds() -> void:
	_order.wait_in_queue(30.0)
	assert_true(_order.in_queue)
	assert_almost_eq(_order.patience_max, 30.0)


func test_sitting_refills_patience_from_dish() -> void:
	_order.wait_in_queue(10.0)
	_order.tick(9.0)
	_order.sit_at_table(null)
	assert_false(_order.in_queue)
	assert_almost_eq(_order.patience_left, ItemCatalog.patience("mon_steak"))


func test_patience_factor_scales_budget() -> void:
	_order.patience_factor = 1.5
	_order.wait_in_queue(20.0)
	assert_almost_eq(_order.patience_max, 30.0)


func test_tick_reports_empty_exactly_once() -> void:
	_order.wait_in_queue(2.0)
	assert_false(_order.tick(1.0))
	assert_true(_order.tick(1.5), "(first time empty)")
	assert_false(_order.tick(1.0), "(must not report twice)")
	assert_almost_eq(_order.patience_left, 0.0)


func test_no_drain_when_paused() -> void:
	_order.wait_in_queue(5.0)
	_order.draining = false
	_order.tick(3.0)
	assert_almost_eq(_order.patience_left, 5.0)


func test_perfect_above_half_patience() -> void:
	_order.wait_in_queue(10.0)
	_order.tick(4.0)
	assert_true(_order.is_perfect(), "(60% left)")


func test_not_perfect_at_exactly_half() -> void:
	# Ngưỡng là TRÊN 50%, đúng 50% thì không tính hoàn hảo.
	_order.wait_in_queue(10.0)
	_order.tick(5.0)
	assert_false(_order.is_perfect())


func test_ratio_safe_when_no_budget() -> void:
	assert_almost_eq(_order.patience_ratio(), 0.0)
