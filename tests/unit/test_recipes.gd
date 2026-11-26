extends "res://tests/test_case.gd"
## Kiểm thử công thức ở bàn chế tạo và các con số suy ra từ công thức.

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")


func test_steak_plate_makes_dish() -> void:
	assert_eq(ItemCatalog.combine_on_table(["bowl", "steak_cooked"]), "mon_steak")


func test_order_of_ingredients_does_not_matter() -> void:
	var a := ItemCatalog.combine_on_table(["bowl", "bun", "steak_cooked"])
	var b := ItemCatalog.combine_on_table(["steak_cooked", "bowl", "bun"])
	assert_eq(a, "burger_plain")
	assert_eq(b, a, "(reversed order)")


func test_chained_recipe_upgrades_burger_to_hamburger() -> void:
	# Lỗi Hamburger cũ: ráp sớm thành burger thường rồi kẹt. Công thức nối tiếp
	# phải cho nâng cấp tiếp, bằng cả hai đường.
	var cheese := ItemCatalog.combine_on_table(["burger_plain", "cheese_chopped"])
	assert_eq(cheese, "burger_cheese")
	assert_eq(ItemCatalog.combine_on_table([cheese, "lettuce_chopped"]), "hambuger")
	var lettuce := ItemCatalog.combine_on_table(["lettuce_chopped", "burger_plain"])
	assert_eq(ItemCatalog.combine_on_table(["cheese_chopped", lettuce]), "hambuger")


func test_wrong_combination_makes_nothing() -> void:
	assert_eq(ItemCatalog.combine_on_table(["bowl", "tomato"]), "")
	assert_eq(ItemCatalog.combine_on_table([]), "")


func test_combine_does_not_change_input_array() -> void:
	var parts := ["steak_cooked", "bowl"]
	ItemCatalog.combine_on_table(parts)
	assert_eq(parts, ["steak_cooked", "bowl"], "(must not sort the caller's array)")


func test_every_sellable_dish_has_price_and_is_unlocked() -> void:
	var dishes := ItemCatalog.sellable_dishes()
	assert_true(dishes.size() > 0, "(menu is empty)")
	for id in dishes:
		assert_true(ItemCatalog.price(id) > 0, "(%s has no price)" % id)
		assert_false(ItemCatalog.is_locked(id), "(%s is locked)" % id)


func test_every_sellable_dish_has_known_difficulty() -> void:
	for id in ItemCatalog.sellable_dishes():
		assert_true(ItemCatalog.DIFFICULTY_ORDER.has(ItemCatalog.difficulty(id)), "(%s)" % id)


func test_patience_never_below_minimum() -> void:
	for id in ItemCatalog.sellable_dishes():
		assert_true(ItemCatalog.patience(id) >= ItemCatalog.PATIENCE_MIN, "(%s)" % id)


func test_many_ingredients_get_patience_bonus() -> void:
	# Hamburger cần từ 3 nguyên liệu trở lên nên phải được +50% kiên nhẫn.
	assert_true(ItemCatalog.ingredient_count("hambuger") >= ItemCatalog.MANY_INGREDIENTS)
	assert_true(ItemCatalog.patience("hambuger") >= ItemCatalog.PATIENCE_MIN * ItemCatalog.MANY_INGREDIENTS_BONUS)


func test_bowl_is_not_counted_as_ingredient() -> void:
	assert_eq(ItemCatalog.ingredient_count("bowl"), 0)


func test_unknown_item_is_safe() -> void:
	assert_eq(ItemCatalog.price("khong_ton_tai"), 0)
	assert_almost_eq(ItemCatalog.patience("khong_ton_tai"), ItemCatalog.PATIENCE_MIN)


func test_recipe_parts_listed_for_hamburger() -> void:
	var parts := ItemCatalog.recipe_parts("hambuger")
	assert_true(parts.size() >= 3, "(recipe display is missing ingredients)")
