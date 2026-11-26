extends RefCounted

const ICON_FMT := "res://assets/ui/nguyen_lieu/%s.png"
const MODEL_FMT := "res://assets/gltf/%s.gltf"

const ITEMS := {
	# ---- nguyên liệu lấy từ thùng ----
	"bun":        {"cost": 1, "name": "Bánh mì",   "model": "food_ingredient_bun",
		"layout": {"order": 10, "height": 0.20,
			"model": "food_ingredient_bun_bottom",
			"model_top": "food_ingredient_bun_top"}},
	"lettuce":    {"cost": 2, "name": "Xà lách",   "model": "food_ingredient_lettuce",
		"layout": {"order": 20, "height": 0.088, "y": 0.034,
			"model": "food_ingredient_lettuce_slice"}},
	"carrot":     {"cost": 4, "name": "Cà rốt",    "model": "food_ingredient_carrot",
		"layout": {"height": 1.27, "y": 0.585}},
	"potato":     {"cost": 4, "name": "Khoai tây", "model": "food_ingredient_potato",
		"layout": {"height": 0.78, "y": 0.394}},
	"tomato":     {"cost": 2, "name": "Cà chua",   "model": "food_ingredient_tomato",
		"layout": {"height": 0.70}},
	"onion":      {"cost": 4, "name": "Hành tây",  "model": "food_ingredient_onion",
		"layout": {"height": 0.86, "y": 0.011}},
	"mushroom":   {"cost": 4, "name": "Nấm",       "model": "food_ingredient_mushroom",
		"layout": {"height": 0.57, "y": 0.217}},
	"dough":      {"cost": 4, "name": "Bột",       "model": "food_ingredient_dough",
		"prep": "dough_pre"},
	"dough_pre":  {"name": "Bột đã cán", "model": "food_ingredient_dough_base",
		"layout": {"thickness": 0.14, "arrange": {"radius": 0.42, "scale": 0.55}}},

	# ---- nguyên liệu trong tủ lạnh ----
	"ham":        {"cost": 9, "name": "Ham", "model": "food_ingredient_ham",
		"icon": "ham_uncook", "cook": "ham_cooked", "burnt": "ham_cooked_fail"},
	"ham_cooked": {"name": "Ham đã nấu",  "model": "food_ingredient_ham_cooked",
		"layout": {"height": 0.83, "y": 0.415}},
	"ham_cooked_fail": {"name": "Ham cháy", "model": "food_ingredient_ham_trash"},

	"steak":        {"cost": 9, "name": "Steak", "model": "food_ingredient_steak",
		"prep": "steak_uncook"},
	"steak_uncook": {"name": "Steak đã thái", "layout": {"height": 0.20},
		"model": "food_ingredient_burger_uncooked",
		"cook": "steak_cooked", "burnt": "steak_cooked_fail"},
	"steak_cooked": {"name": "Steak đã nấu",
		"layout": {"order": 30, "height": 0.20},
		"model": "food_ingredient_burger_cooked"},
	"steak_cooked_fail": {"name": "Steak cháy",
		"model": "food_ingredient_burger_trash"},

	"cheese":      {"cost": 7, "name": "Phô mai",  "model": "food_ingredient_cheese",
		"layout": {"order": 40, "height": 0.105, "y": 0.087,
			"model": "food_ingredient_cheese_slice"}},
	"cookiestick": {"cost": 1, "name": "Bánh quế", "model": "icecream_bowl_cookiesticks",
		"layout": {"height": 0.52, "y": 0.258, "model": "icecream_cookiestick"}},

	"peperoni":     {"cost": 9, "name": "Xúc xích", "model": "food_ingredient_pepperoni",
		"prep": "peperoni_pre"},
	"peperoni_pre": {"name": "Xúc xích đã thái", "layout": {"height": 0.40},
		"model": "food_ingredient_pepperoni_chopped"},

	# ---- vật chứa ----
	"bowl": {"name": "Đĩa", "model": "plate", "layout": {"thickness": 0.08}},
	"noi": {"name": "Nồi", "model": "pot_A", "layout": {"thickness": 0.48}},
	"noi_canh": {"name": "Nồi canh (sống)", "model": "pot_A_stew",
		"cook": "stew", "layout": {"thickness": 0.48}},

	# ---- món hoàn chỉnh ----
	"hambuger":      {"name": "Hamburger",       "model": "food_burger",
		"price": 95, "seconds": 20.0},
	"vegetablebuger_uncook": {"name": "Steak rau củ (sống)",
		"model": "food_ingredient_vegetableburger_uncooked",
		"cook": "vegetablebuger_cooked", "burnt": "vegetablebuger_cooked_fail"},
	"vegetablebuger_cooked": {"name": "Steak rau củ (chín)",
		"layout": {"order": 30, "height": 0.216},
		"model": "food_ingredient_vegetableburger_cooked"},
	"vegetablebuger_cooked_fail": {"name": "Steak rau củ cháy",
		"icon": "steak_cooked_fail",
		"model": "food_ingredient_burger_trash"},
	"vegetablebuger": {"name": "Hamburger rau củ", "model": "food_vegetableburger",
		"price": 210, "seconds": 22.6},
	"dinner":        {"name": "Bữa tối",         "model": "food_dinner",
		"price": 250, "seconds": 30.6},
	"stew": {"name": "Canh rau củ", "model": "food_stew", "layout": {"height": 0.37},
		"price": 235, "seconds": 28.0},
	"pizza_cheese":   {"name": "Pizza phô mai",  "model": "food_pizza_cheese_plated",
		"scale": 0.5, "price": 105, "seconds": 23.0},
	"pizza_mushroom": {"name": "Pizza nấm",      "model": "food_pizza_mushroom_plated",
		"scale": 0.5, "price": 100, "seconds": 23.0},
	"pizza_peperoni": {"name": "Pizza xúc xích", "model": "food_pizza_pepperoni_plated",
		"scale": 0.5, "price": 100, "seconds": 23.0},
	"pizza_cheese_uncooked":   {"name": "Pizza phô mai (sống)", "icon": "pizza_cheese",
		"model": "food_pizza_cheese_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_cheese"},
	"pizza_mushroom_uncooked": {"name": "Pizza nấm (sống)", "icon": "pizza_mushroom",
		"model": "food_pizza_mushroom_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_mushroom"},
	"pizza_peperoni_uncooked": {"name": "Pizza xúc xích (sống)", "icon": "pizza_peperoni",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_peperoni"},
	"icecream_vani":       {"cost": 2, "name": "Kem vani",
		"model": "food_icecream_cone_vanilla",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_vanilla"},
		"price": 15, "seconds": 4.2},
	"icecream_chocolate":  {"cost": 2, "name": "Kem chocolate",
		"model": "food_icecream_cone_chocolate",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_chocolate"},
		"price": 15, "seconds": 4.2},
	"icecream_strawberry": {"cost": 2, "name": "Kem dâu",
		"model": "food_icecream_cone_strawberry",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_strawberry"},
		"price": 15, "seconds": 4.2},
	"kem_tam_hop": {"name": "Kem tam hợp",
		"model": "icecream_bowl_decorated_B", "layout": {"height": 0.73},
		"price": 40, "seconds": 8.9},
	"kem_tam_hop_que": {"name": "Kem tam hợp và bánh quế",
		"model": "icecream_bowl_decorated_A", "price": 55, "seconds": 12.2},

	# ---- món bày ra đĩa (dùng lại ảnh của nguyên liệu cuối) ----
	"mon_ham":  {"name": "Ham",
		"on_plate": {"model": "food_ingredient_ham_cooked", "y": 0.37, "scale": 0.75},
		"icon": "ham_cooked", "price": 60, "seconds": 14.9},
	"mon_steak": {"name": "Steak",
		"on_plate": {"model": "food_ingredient_burger_cooked", "y": 0.12},
		"icon": "steak_cooked", "price": 80, "seconds": 19.4},
	"vegetablesteak": {"name": "Steak rau củ",
		"on_plate": {"model": "food_ingredient_vegetableburger_cooked", "y": 0.12},
		"icon": "vegetablebuger_cooked", "price": 105, "seconds": 24.5},

	# ---- đồ hỏng ----
	"do_hong": {"name": "Đồ hỏng", "model": "food_ingredient_ham_trash"},
}

## Những nguyên liệu cho được vào NỒI.
const POT_ENABLED := true

## Những id chỉ tồn tại được khi có nồi: chính cái nồi, món nấu ra từ nồi, và
const POT_LOCKED_ITEMS := ["noi", "noi_canh", "stew", "dinner"]


## Id này hiện có bị khoá không. Hệ đơn hàng, bàn chế tạo và đôi tay đều hỏi
static func is_locked(id: String) -> bool:
	return not POT_ENABLED and POT_LOCKED_ITEMS.has(id)


## Những thứ cho được vào LÒ NƯỚNG sau khi đã có đế bánh.
const OVEN_TOPPINGS := ["cheese", "mushroom", "onion", "tomato", "peperoni_pre"]

## Đế bánh — thứ duy nhất bật được lò nướng.
const PIZZA_BASE := "dough_pre"

## Công thức lò nướng. Cùng quy ước khoá với TABLE_RECIPES: sắp xếp rồi nối
const OVEN_RECIPES := {
	"dough_pre+peperoni_pre+tomato": "pizza_peperoni",
	"dough_pre+mushroom+tomato": "pizza_mushroom",
	"cheese+dough_pre+onion+tomato": "pizza_cheese",
}


## Công thức ở BÀN CHẾ TẠO. Cùng quy ước khoá: sắp xếp rồi nối bằng "+".
const TABLE_RECIPES := {
	"bowl+ham_cooked": "mon_ham",
	"bowl+steak_cooked": "mon_steak",
	"bowl+vegetablebuger_cooked": "vegetablesteak",
	"carrot+onion+steak_uncook+tomato": "vegetablebuger_uncook",
	"carrot+lettuce+noi+onion+potato": "noi_canh",
	"bowl+bun+cheese+lettuce+steak_cooked": "hambuger",
	"bowl+bun+lettuce+vegetablebuger_cooked": "vegetablebuger",
	"bowl+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop",
	"bowl+cookiestick+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop_que",
	"dough_pre+peperoni_pre+tomato": "pizza_peperoni_uncooked",
	"dough_pre+mushroom+tomato": "pizza_mushroom_uncooked",
	"cheese+dough_pre+onion+tomato": "pizza_cheese_uncooked",

	# ---- CÔNG THỨC NỐI TIẾP: ghép thêm vào một MÓN đã ráp xong ----
	"cookiestick+kem_tam_hop": "kem_tam_hop_que",
	"ham_cooked+stew": "dinner",
}


static var plan_b := true

static var _items_b: Dictionary = {}

## Mục ĐÈ lên ITEMS. Giá trị null = XOÁ mục đó khỏi thực đơn B.
const PLAN_B_ITEMS := {
	"steak": {"cost": 9, "name": "Steak", "model": "food_ingredient_steak",
		"prep": "steak_uncook"},
	"cheese": {"cost": 7, "name": "Phô mai", "model": "food_ingredient_cheese",
		"prep": "cheese_chopped"},
	"lettuce": {"cost": 2, "name": "Xà lách", "model": "food_ingredient_lettuce",
		"prep": "lettuce_chopped"},
	"tomato": {"cost": 2, "name": "Cà chua", "model": "food_ingredient_tomato",
		"prep": "tomato_chopped"},
	"mushroom": {"cost": 4, "name": "Nấm", "model": "food_ingredient_mushroom",
		"prep": "mushroom_chopped"},
	"carrot": {"cost": 4, "name": "Cà rốt", "model": "food_ingredient_carrot",
		"prep": "carrot_chopped"},
	"onion": {"cost": 4, "name": "Hành tây", "model": "food_ingredient_onion",
		"prep": "onion_chopped"},
	"potato": {"cost": 4, "name": "Khoai tây", "model": "food_ingredient_potato",
		"prep": "potato_chopped"},

	"do_hong": {"name": "Đồ hỏng", "model": "food_ingredient_ham_trash",
		"icon": "steak_cooked_fail"},
	"ham": {"cost": 9, "name": "Đùi sống", "model": "food_ingredient_ham",
		"icon": "ham_uncook", "cook": "ham_cooked", "burnt": "ham_cooked_fail"},
	"ham_cooked": {"name": "Đùi nướng chín", "model": "food_ingredient_ham_cooked",
		"layout": {"height": 0.83, "y": 0.415}},
	"ham_cooked_fail": {"name": "Đùi cháy", "model": "food_ingredient_ham_trash"},

	# ---- bản đã thái ----
	"cheese_chopped": {"name": "Phô mai đã thái", "icon": "cheese",
		"model": "food_ingredient_cheese_slice",
		"layout": {"order": 40, "height": 0.105, "y": 0.087,
			"model": "food_ingredient_cheese_slice"}},
	"lettuce_chopped": {"name": "Xà lách đã thái", "icon": "lettuce",
		"model": "food_ingredient_lettuce_chopped",
		"layout": {"order": 20, "height": 0.088, "y": 0.034,
			"model": "food_ingredient_lettuce_slice"}},
	"tomato_chopped": {"name": "Cà chua đã thái", "icon": "tomato",
		"model": "food_ingredient_tomato_slices", "layout": {"height": 0.15}},
	"mushroom_chopped": {"name": "Nấm đã thái", "icon": "mushroom",
		"model": "food_ingredient_mushroom_chopped", "layout": {"height": 0.3}},
	"carrot_chopped": {"name": "Cà rốt đã thái", "icon": "carrot",
		"model": "food_ingredient_carrot_chopped", "layout": {"height": 0.3}},
	"onion_chopped": {"name": "Hành tây đã thái", "icon": "onion",
		"model": "food_ingredient_onion_chopped", "layout": {"height": 0.3}},
	"potato_chopped": {"name": "Khoai tây đã thái", "icon": "potato",
		"model": "food_ingredient_potato_chopped", "layout": {"height": 0.3}},

	"soup_carrot_raw": {"name": "Nồi soup cà rốt (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_carrot", "layout": {"thickness": 0.48}},
	"soup_onion_raw": {"name": "Nồi soup hành tây (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_onion", "layout": {"thickness": 0.48}},
	"soup_potato_raw": {"name": "Nồi soup khoai tây (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_potato", "layout": {"thickness": 0.48}},

	# Pizza sống có ảnh riêng (đế bột chưa nướng) thay cho ảnh pizza chín.
	"pizza_cheese_uncooked": {"name": "Pizza phô mai (sống)",
		"model": "food_pizza_cheese_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_cheese", "burnt": "pizza_cheese_burnt"},
	"pizza_mushroom_uncooked": {"name": "Pizza nấm (sống)",
		"model": "food_pizza_mushroom_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_mushroom", "burnt": "pizza_mushroom_burnt"},
	"pizza_peperoni_uncooked": {"name": "Pizza xúc xích (sống)",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_peperoni", "burnt": "pizza_peperoni_burnt"},

	"pizza_cheese_burnt": {"name": "Pizza cháy", "icon": "pizza_cheese",
		"model": "food_pizza_cheese_plated", "scale": 0.5, "burnt_look": true},
	"pizza_mushroom_burnt": {"name": "Pizza cháy", "icon": "pizza_mushroom",
		"model": "food_pizza_mushroom_plated", "scale": 0.5, "burnt_look": true},
	"pizza_peperoni_burnt": {"name": "Pizza cháy", "icon": "pizza_peperoni",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5, "burnt_look": true},

	# ---- món bán ----
	"mon_steak": {"name": "Steak",
		"on_plate": {"model": "food_ingredient_burger_cooked", "y": 0.12},
		"icon": "steak_cooked", "price": 80, "seconds": 19.4},
	"burger_plain": {"name": "Burger thường", "model": "food_burger",
		"stack": ["bowl", "bun", "steak_cooked"], "scale": 1.6,
		"price": 85, "seconds": 21.0},
	"burger_cheese": {"name": "Burger phô mai", "model": "food_burger",
		"stack": ["bowl", "bun", "steak_cooked", "cheese_chopped"], "scale": 1.6,
		"price": 100, "seconds": 24.0},
	"burger_lettuce": {"name": "Burger xà lách", "model": "food_burger",
		"stack": ["bowl", "bun", "lettuce_chopped", "steak_cooked"], "scale": 1.6,
		"price": 100, "seconds": 24.0},
	"hambuger": {"name": "Hamburger", "model": "food_burger",
		"stack": ["bowl", "bun", "lettuce_chopped", "steak_cooked", "cheese_chopped"],
		"scale": 1.6, "price": 115, "seconds": 27.0},
	"mon_ham": {"name": "Đùi nướng",
		"on_plate": {"model": "food_ingredient_ham_cooked", "y": 0.37, "scale": 0.75},
		"icon": "ham_cooked", "price": 60, "seconds": 14.9},
	"dinner": {"name": "Đùi nướng cà rốt", "model": "food_dinner",
		"price": 90, "seconds": 22.0},
	"soup_carrot": {"name": "Soup cà rốt", "model": "bowl", "liquid": "e8792b",
		"topping": {"model": "food_ingredient_carrot_pieces", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},
	"soup_onion": {"name": "Soup hành tây", "model": "bowl", "liquid": "c9973f",
		"topping": {"model": "food_ingredient_onion_rings", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},
	"soup_potato": {"name": "Soup khoai tây", "model": "bowl", "liquid": "efe0b0",
		"topping": {"model": "food_ingredient_potato_chopped", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},

	"vegetablesteak": null,
	"vegetablebuger": null, "stew": null, "noi_canh": null,
	"vegetablebuger_uncook": null,
	"vegetablebuger_cooked": null, "vegetablebuger_cooked_fail": null,
}

const PLAN_B_TABLE := {
	"bowl+steak_cooked": "mon_steak",
	"bowl+bun+steak_cooked": "burger_plain",
	"bowl+bun+cheese_chopped+steak_cooked": "burger_cheese",
	"bowl+bun+lettuce_chopped+steak_cooked": "burger_lettuce",
	"burger_plain+cheese_chopped": "burger_cheese",
	"burger_plain+lettuce_chopped": "burger_lettuce",
	"bowl+bun+cheese_chopped+lettuce_chopped+steak_cooked": "hambuger",
	"burger_cheese+lettuce_chopped": "hambuger",
	"burger_lettuce+cheese_chopped": "hambuger",
	"bowl+ham_cooked": "mon_ham",
	"bowl+carrot_chopped+ham_cooked": "dinner",
	"carrot_chopped+mon_ham": "dinner",
	"carrot_chopped+carrot_chopped+carrot_chopped+noi": "soup_carrot_raw",
	"noi+onion_chopped+onion_chopped+onion_chopped": "soup_onion_raw",
	"noi+potato_chopped+potato_chopped+potato_chopped": "soup_potato_raw",
	"dough_pre+mushroom_chopped+tomato_chopped": "pizza_mushroom_uncooked",
	"cheese_chopped+dough_pre+tomato_chopped": "pizza_cheese_uncooked",
	"dough_pre+peperoni_pre+tomato_chopped": "pizza_peperoni_uncooked",
	"bowl+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop",
	"bowl+cookiestick+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop_que",
	"cookiestick+kem_tam_hop": "kem_tam_hop_que",
}


static func items() -> Dictionary:
	if not plan_b:
		return ITEMS
	if _items_b.is_empty():
		_items_b = ITEMS.duplicate()
		for id in PLAN_B_ITEMS:
			if PLAN_B_ITEMS[id] == null:
				_items_b.erase(id)
			else:
				_items_b[id] = PLAN_B_ITEMS[id]
	return _items_b


static func table_recipes() -> Dictionary:
	return PLAN_B_TABLE if plan_b else TABLE_RECIPES


## B: lò KHÔNG còn công thức topping — chỉ nướng pizza sống ghép từ bàn.
static func oven_recipes() -> Dictionary:
	return {} if plan_b else OVEN_RECIPES


static func oven_toppings() -> Array:
	return [] if plan_b else OVEN_TOPPINGS


## Bỏ đế bánh trần vào lò để bật lò được không. B: không — một đường duy nhất.
static func oven_takes_base() -> bool:
	return not plan_b


## Id này có phải MỘT MÓN hoàn chỉnh không (thứ nhấc được khỏi bàn chế tạo).
static func price(id: String) -> int:
	return int(items().get(id, {}).get("price", 0))


## ═════════════════════════════════════════════ GIÁ VỐN NGUYÊN LIỆU
static func cost(id: String) -> int:
	return int(items().get(id, {}).get("cost", 0))


## Thời gian kiên nhẫn của khách gọi món này, tính bằng giây.
const PATIENCE_FACTOR := 3.75
const PATIENCE_MIN := 52.5

## 2/10/2026: món từ BA NGUYÊN LIỆU trở lên được thêm 50% kiên nhẫn.
const MANY_INGREDIENTS := 3
const MANY_INGREDIENTS_BONUS := 1.5

static func patience(id: String) -> float:
	var t := float(items().get(id, {}).get("seconds", 0.0))
	var base := PATIENCE_MIN
	if t > 0.0:
		base = maxf(PATIENCE_MIN, PATIENCE_FACTOR * t)
	if ingredient_count(id) >= MANY_INGREDIENTS:
		base *= MANY_INGREDIENTS_BONUS
	return base


## Đồ ĐỰNG: có mặt trong công thức nhưng không phải nguyên liệu (dùng lại
const CONTAINER_ITEMS := ["bowl", "noi"]

## Số nguyên liệu THÔ người chơi phải đi lấy để làm ra món này.
static func ingredient_count(id: String) -> int:
	return _count_raw(id, 0)


static func _count_raw(id: String, depth: int) -> int:
	if CONTAINER_ITEMS.has(id):
		return 0
	if depth > 8:
		return 1
	for table in [table_recipes(), oven_recipes()]:
		for key in table:
			if String(table[key]) != id:
				continue
			var total := 0
			for part in String(key).split("+"):
				total += _count_raw(part, depth + 1)
			return total
	for source in items():
		var info: Dictionary = items()[source]
		for step in ["prep", "cook", "bake"]:
			if String(info.get(step, "")) == id:
				return _count_raw(String(source), depth + 1)
	return 1


## ═════════════════════════════════════════════ ĐỘ KHÓ CỦA MÓN
const DIFFICULTY_ORDER := ["easy", "medium", "hard"]
const DISH_DIFFICULTY := {
	"icecream_vani": "easy", "icecream_chocolate": "easy", "icecream_strawberry": "easy",
	"mon_ham": "easy", "mon_steak": "easy",
	"kem_tam_hop": "medium", "kem_tam_hop_que": "medium", "hambuger": "hard",
	"pizza_mushroom": "medium", "pizza_peperoni": "medium", "pizza_cheese": "medium",
	"vegetablesteak": "medium",
	"vegetablebuger": "hard", "stew": "hard",
	"dinner": "medium",
	"burger_plain": "easy", "burger_cheese": "medium", "burger_lettuce": "medium",
	"soup_carrot": "hard", "soup_onion": "hard", "soup_potato": "hard",
}

static func difficulty(id: String) -> String:
	return String(DISH_DIFFICULTY.get(id, "medium"))


## Những thứ phải GOM LẠI để làm ra món này, để vẽ công thức cho người chơi.
static func recipe_parts(id: String) -> Array[String]:
	var out: Array[String] = []
	_expand_parts(id, out, 0, id)
	return display_order(out)


## Thứ tự VẼ nguyên liệu trong một dòng công thức, từ trái sang phải.
const DISPLAY_ORDER := [
	"bowl", "noi",
	"dough_pre", "bun",
	"stew",
	"tomato", "lettuce", "cheese", "onion", "carrot", "potato",
	"mushroom", "peperoni_pre",
	"steak_cooked", "steak_uncook", "ham_cooked", "vegetablebuger_cooked",
	"icecream_vani", "icecream_chocolate", "icecream_strawberry", "cookiestick",
]


## Xếp lại một công thức theo DISPLAY_ORDER. Chỉ đổi thứ tự VẼ — khoá công
static func display_order(parts: Array) -> Array[String]:
	var ranked: Array = []
	for i in parts.size():
		var id := String(parts[i])
		var rank := DISPLAY_ORDER.find(id)
		if rank < 0:
			rank = DISPLAY_ORDER.size()
		ranked.append([rank, i, id])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	var out: Array[String] = []
	for r in ranked:
		out.append(String(r[2]))
	return out


## Thứ này có phải là (lõi của) một món BÁN ĐƯỢC khác với `root` không: hoặc
static func _is_other_dish(id: String, root: String) -> bool:
	if id == root:
		return false
	if price(id) > 0:
		return true
	var plated := String(table_recipes().get("bowl+" + id, ""))
	return not plated.is_empty() and plated != root and price(plated) > 0


static func _expand_parts(id: String, out: Array[String], depth: int, root: String) -> void:
	var is_root := id == root and depth == 0
	if depth > 8:
		out.append(id)
		return
	if not is_root and _is_other_dish(id, root):
		out.append(id)
		return
	var key := _recipe_key_for(id)
	if not key.is_empty():
		for part in key.split("+"):
			_expand_parts(part, out, depth + 1, root)
		return
	var source := _source_of(id)
	if not source.is_empty() and not _recipe_key_for(source).is_empty():
		_expand_parts(source, out, depth + 1, root)
		return
	if not is_root:
		out.append(id)


## Khoá công thức ("a+b+c") sinh ra id này, hoặc rỗng. Bảng bàn chế tạo xét
static func _recipe_key_for(id: String) -> String:
	for table in [table_recipes(), oven_recipes()]:
		for key in table:
			if String(table[key]) == id:
				return String(key)
	return ""


## Thứ mà sơ chế / nấu / nướng lên thì ra id này, hoặc rỗng.
static func _source_of(id: String) -> String:
	for source in items():
		var info: Dictionary = items()[source]
		for step in ["prep", "cook", "bake"]:
			if String(info.get(step, "")) == id:
				return String(source)
	return ""


## Mọi món BÁN ĐƯỢC, tức có giá. Hệ đơn hàng bốc món từ đây.
static func sellable_dishes() -> Array[String]:
	var out: Array[String] = []
	for id in items():
		if is_locked(String(id)):
			continue
		if int(items()[id].get("price", 0)) > 0:
			out.append(String(id))
	return out


static func is_dish(id: String) -> bool:
	return table_recipes().values().has(id) or price(id) > 0


static func combine_on_table(ingredients: Array) -> String:
	var list_ := ingredients.duplicate()
	list_.sort()
	var dish := String(table_recipes().get("+".join(list_), ""))
	if is_locked(dish):
		return ""
	return dish


static func can_go_in_oven(id: String) -> bool:
	return oven_toppings().has(id)


static func bake_in_oven(ingredients: Array) -> String:
	if ingredients.size() == 1:
		var ready_ := bake_step(String(ingredients[0]))
		if not ready_.is_empty():
			return ready_
	var list_ := ingredients.duplicate()
	list_.sort()
	return String(oven_recipes().get("+".join(list_), ""))


## Kết quả khi đưa NGUYÊN MỘT vật vào lò nướng. Rỗng = không nướng thẳng được
static func bake_step(id: String) -> String:
	return String(items().get(id, {}).get("bake", ""))


## Dựng node model 3D của một vật phẩm, hoặc null nếu không có model.
const BOWL_MODEL := "bowl"
## Độ cao mặc định đặt thức ăn trong lòng bát. Bát cao 0,30; lòng bát bắt đầu
const BOWL_INNER_HEIGHT := 0.12

## `co_do` = vật này đang chứa thứ gì bên trong. Chỉ mục nào khai `model_day`
static func make_model(id: String, has_content: bool = false) -> Node3D:
	var entry: Dictionary = items().get(id, {})
	if entry.has("on_plate"):
		return _make_bowl_combo(entry["on_plate"])
	if entry.has("stack"):
		var parts: Array[String] = []
		for p in entry["stack"]:
			parts.append(String(p))
		var st := make_stack(parts)
		if st != null and entry.has("scale"):
			st.scale = Vector3.ONE * float(entry["scale"])
		return st

	var model_name := String(entry.get("model", ""))
	if has_content and entry.has("model_inner"):
		model_name = String(entry["model_inner"])
	var m := _load_model(model_name)
	if m != null:
		var scale_: float = float(entry.get("scale", 1.0))
		if not is_equal_approx(scale_, 1.0):
			m.scale = Vector3.ONE * scale_
		if bool(entry.get("raw_look", false)):
			_apply_raw_look(m)
		if bool(entry.get("burnt_look", false)):
			_apply_burnt_look(m)
		if entry.has("liquid"):
			var disc := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.40
			cyl.bottom_radius = 0.36
			cyl.height = 0.04
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(String(entry["liquid"]))
			mat.roughness = 0.35
			cyl.material = mat
			disc.mesh = cyl
			disc.position.y = 0.23
			m.add_child(disc)
		for piece in entry.get("combo", []):
			var pm := make_model(String(piece["id"]))
			if pm != null:
				pm.scale *= float(piece.get("scale", 1.0))
				pm.position = Vector3(float(piece.get("x", 0.0)),
					float(piece.get("y", 0.0)), float(piece.get("z", 0.0)))
				m.add_child(pm)
		if entry.has("topping"):
			var tp: Dictionary = entry["topping"]
			var t := _load_model(String(tp["model"]))
			if t != null:
				t.scale = Vector3.ONE * float(tp.get("scale", 1.0))
				t.position.y = float(tp.get("y", 0.0))
				m.add_child(t)
	return m


## Màu phủ lên đồ SỐNG (hiện chỉ pizza chưa nướng). Trắng, nửa trong suốt.
const RAW_TINT := Color(1.0, 1.0, 1.0, 0.45)

## Vật liệu phủ, tạo MỘT lần rồi dùng chung cho mọi chiếc pizza sống.
static var _raw_material: StandardMaterial3D = null


## Làm NHẠT một model bằng material_overlay: một lớp trắng mờ vẽ đè lên trên.
static func _apply_raw_look(root: Node) -> void:
	if _raw_material == null:
		_raw_material = StandardMaterial3D.new()
		_raw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_raw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_raw_material.albedo_color = RAW_TINT
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = _raw_material


## Phủ đen đồ CHÁY (pizza bộ B). Cùng kiểu với _apply_raw_look: overlay lên
static var _burnt_material: StandardMaterial3D = null

static func _apply_burnt_look(root: Node) -> void:
	if _burnt_material == null:
		_burnt_material = StandardMaterial3D.new()
		_burnt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_burnt_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_burnt_material.albedo_color = Color(0.06, 0.04, 0.03, 0.82)
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = _burnt_material


## Món kế tiếp nhích lên bao nhiêu, khi nó không tự khai "cao".
const STACK_STEP := 0.08

## Thu nhỏ bấy nhiêu khi nằm trong chồng trên bàn, nếu món đó không tự khai
const STACK_SCALE := 0.6

## Món không khai "thu_tu" thì nằm ở nấc này. Chọn 50 để còn chỗ cho cả thứ
const DEFAULT_ORDER := 50

## Vật đế mặc định cao bao nhiêu, khi nó không tự khai "day".
const DEFAULT_THICKNESS := 0.12

## Mỗi tầng xoay thêm bấy nhiêu độ quanh trục đứng.
const ROTATION_PER_LAYER := 37.0

## Thứ có thể làm ĐẾ cho những thứ khác chồng lên, xếp theo ĐỘ ƯU TIÊN.
const BASE_ITEMS := ["bowl", "noi", "noi_canh", "dough_pre"]


## Số liệu bày biện của một vật phẩm. Luôn trả Dictionary, rỗng là hợp lệ.
static func layout(id: String) -> Dictionary:
	return items().get(id, {}).get("layout", {})


## Dựng MỘT node gồm cả chồng đồ đang nằm trên bàn chế tạo.
static func make_stack(list_: Array[String]) -> Node3D:
	if list_.is_empty():
		return null
	if list_.size() == 1:
		return make_model(String(list_[0]))

	var parts: Array[String] = list_.duplicate()
	var origin: Node3D = null
	var height := 0.0
	var base_id := ""

	for base in BASE_ITEMS:
		var pos := parts.find(String(base))
		if pos < 0:
			continue
		origin = make_model(String(base))
		if origin == null:
			continue
		parts.remove_at(pos)
		base_id = String(base)
		height = float(layout(base_id).get("thickness", DEFAULT_THICKNESS))
		break

	if origin == null:
		origin = Node3D.new()

	var ordered: Array = []
	for i in parts.size():
		ordered.append({
			"id": String(parts[i]),
			"tt": int(layout(String(parts[i])).get("order", DEFAULT_ORDER)),
			"i": i,
		})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tt"]) != int(b["tt"]):
			return int(a["tt"]) < int(b["tt"])
		return int(a["i"]) < int(b["i"]))

	# ---- CÁCH BÀY THỨ HAI: VÒNG QUANH thay vì chồng lên nhau ----
	var ids: Array[String] = []
	for entry in ordered:
		ids.append(String(entry["id"]))

	var ring: Dictionary = {}
	if not base_id.is_empty():
		ring = layout(base_id).get("arrange", {})

	if base_id == "bowl" and _all_in(ids, ICECREAM_ITEMS):
		var cup := _load_model(ICECREAM_BOWL_MODEL)
		if cup != null:
			origin.free()
			origin = cup
			ring = ICECREAM_ARRANGE
			height = 0.0

	if not ring.is_empty():
		_arrange_ring(origin, ids, ring, height)
		return origin

	var layer := 0
	var top := ""
	var top_scale := 1.0

	for entry in ordered:
		var id := String(entry["id"])
		var b: Dictionary = layout(id)
		var m := _stack_model(id)
		if m == null:
			continue
		var scale_ := float(b.get("scale", STACK_SCALE))
		if not is_equal_approx(scale_, 1.0):
			m.scale = Vector3.ONE * scale_
		m.position.y = height + float(b.get("y", 0.0)) * scale_
		if not b.has("order"):
			m.rotate_y(deg_to_rad(ROTATION_PER_LAYER * float(layer)))
		origin.add_child(m)
		height += float(b.get("height", STACK_STEP)) * scale_
		layer += 1
		if top.is_empty() and b.has("model_top"):
			top = String(b["model_top"])
			top_scale = scale_

	if not top.is_empty():
		var lid := _load_model(top)
		if lid != null:
			if not is_equal_approx(top_scale, 1.0):
				lid.scale = Vector3.ONE * top_scale
			lid.position.y = height
			origin.add_child(lid)

	return origin


## Model bát kem rỗng (rộng 0,95, cao 0,30) — thay cái đĩa khi bày kem.
const ICECREAM_BOWL_MODEL := "icecream_bowl"

## Những thứ được phép nằm trong bát kem. Có một thứ khác lẫn vào (người chơi
const ICECREAM_ITEMS := ["icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"cookiestick"]

## Số bày kem trong bát. Viên kem (model bát-một-viên) rộng 0,45: ba viên ở
const ICECREAM_ARRANGE := {
	"radius": 0.19, "scale": 0.8, "y": 0.10,
	"center": ["cookiestick"], "center_y": 0.22, "center_scale": 1.1,
}

## Viên đầu tiên của vòng nằm ở góc này (độ). Không để 0: ở 0 độ viên đầu
const RING_START_ANGLE := 90.0


static func _all_in(ids: Array[String], allowed: Array) -> bool:
	for id in ids:
		if not allowed.has(id):
			return false
	return not ids.is_empty()


## Bày các món THÀNH VÒNG quanh tâm đế, cách đều nhau.
static func _arrange_ring(origin: Node3D, ids: Array[String], arr: Dictionary,
		base_height: float) -> void:
	var center: Array = arr.get("center", [])
	var around: Array[String] = []
	var middle: Array[String] = []
	for id in ids:
		if center.has(id):
			middle.append(id)
		else:
			around.append(id)

	var radius := float(arr.get("radius", 0.4))
	var scale_ := float(arr.get("scale", STACK_SCALE))
	var y0 := base_height + float(arr.get("y", 0.0))
	var n := around.size()

	for k in n:
		var id := around[k]
		var m := _stack_model(id)
		if m == null:
			continue
		var angle := TAU * float(k) / float(n) + deg_to_rad(RING_START_ANGLE)
		var r := radius if n > 1 else 0.0
		m.scale = Vector3.ONE * scale_
		m.rotation.y = -angle
		m.position = Vector3(cos(angle) * r,
				y0 + float(layout(id).get("y", 0.0)) * scale_,
				sin(angle) * r)
		origin.add_child(m)

	var c_scale := scale_ * float(arr.get("center_scale", 1.0))
	for id in middle:
		var m := _stack_model(id)
		if m == null:
			continue
		m.scale = Vector3.ONE * c_scale
		m.position = Vector3(0.0,
				y0 + float(arr.get("center_y", 0.0)) + float(layout(id).get("y", 0.0)) * c_scale,
				0.0)
		origin.add_child(m)


## Model của một vật phẩm KHI NÓ NẰM TRONG CHỒNG.
static func _stack_model(id: String) -> Node3D:
	var model_name := String(layout(id).get("model", ""))
	if model_name.is_empty():
		return make_model(id)
	return _load_model(model_name)


## Dựng "thức ăn nằm trong bát" = model bát + model thức ăn gắn vào trong.
static func _make_bowl_combo(piece: Dictionary) -> Node3D:
	var bowl := _load_model(BOWL_MODEL)
	if bowl == null:
		return null
	var hidden_ := _load_model(String(piece.get("model", "")))
	if hidden_ != null:
		hidden_.position.y = float(piece.get("y", BOWL_INNER_HEIGHT))
		var scale_ := float(piece.get("scale", 1.0))
		if not is_equal_approx(scale_, 1.0):
			hidden_.scale = Vector3.ONE * scale_
		bowl.add_child(hidden_)
	return bowl


## Nạp một file gltf theo TÊN MODEL (không phải id vật phẩm).
static func _load_model(model_name: String) -> Node3D:
	if model_name.is_empty():
		return null
	var path := MODEL_FMT % model_name
	if not ResourceLoader.exists(path):
		push_warning("Thiếu model: %s" % path)
		return null
	var edge := load(path) as PackedScene
	if edge == null:
		return null
	return edge.instantiate() as Node3D


static func has_item(id: String) -> bool:
	return items().has(id)


static func display_name(id: String) -> String:
	return Lang.t(String(items().get(id, {}).get("name", id)))


## Đường dẫn ảnh 2D. Mặc định tên file TRÙNG id — bớt một cột dữ liệu và bớt
static func icon_path(id: String) -> String:
	return ICON_FMT % String(items().get(id, {}).get("icon", id))


static func model_path(id: String) -> String:
	var m := String(items().get(id, {}).get("model", ""))
	return MODEL_FMT % m if not m.is_empty() else ""


## Kết quả sau khi thái ở thớt. Rỗng nghĩa là thứ này không thái được.
static func prep_step(id: String) -> String:
	return String(items().get(id, {}).get("prep", ""))


## Dấu con dao nhỏ ở góc icon: "món này phải qua thớt trước".
const KNIFE_BADGE := "res://assets/ui/icons/knife_badge.png"


static func needs_chop(id: String) -> bool:
	return not prep_step(id).is_empty()


## Mọi nguyên liệu cần thái, theo thứ tự khai trong ITEMS (cho trang F1).
static func chop_items() -> Array[String]:
	var out: Array[String] = []
	for id in items():
		if needs_chop(String(id)):
			out.append(String(id))
	return out


## Gắn dấu con dao vào góc dưới phải của một ô icon (TextureRect/Panel).
static func add_knife_badge(icon: Control, id: String) -> void:
	if not needs_chop(id) or not ResourceLoader.exists(KNIFE_BADGE):
		return
	var b := TextureRect.new()
	b.texture = load(KNIFE_BADGE)
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.anchor_left = 0.55
	b.anchor_top = 0.55
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	icon.add_child(b)


## Kết quả sau khi nấu lẻ trên bếp. Rỗng nghĩa là không nấu lẻ được.
static func cook_step(id: String) -> String:
	return String(items().get(id, {}).get("cook", ""))


## Trạng thái cháy nếu để quá lửa. Rỗng nghĩa là món này không cháy được.
static func burnt_state(id: String) -> String:
	return String(items().get(id, {}).get("burnt", ""))


# ------------------------------------------------- công thức trên vé đơn ---

const BADGE_FMT := "res://assets/ui/icons/%s_badge.png"

## Nguyên liệu in trên vé: các phần gốc của món, BỎ đĩa và nồi. Đĩa/nồi là đồ
static func ticket_parts(dish: String) -> Array[String]:
	var out: Array[String] = []
	for p in recipe_parts(dish):
		if not CONTAINER_ITEMS.has(p):
			out.append(p)
	return out


## Kí hiệu nơi nấu của một nguyên liệu trong một món: "pan" | "pot" | "oven" | "".
static func cook_badge(dish: String, part: String) -> String:
	if _pot_cooked(part):
		return "pot"
	var prepped := prep_step(part)
	var from := _source_of(part)
	if not cook_step(part).is_empty() \
			or (not prepped.is_empty() and not cook_step(prepped).is_empty()) \
			or (not from.is_empty() and cook_step(from) == part):
		return "pan"
	var src := _source_of(dish)
	if not src.is_empty():
		var info: Dictionary = items().get(src, {})
		if String(info.get("bake", "")) == dish:
			return "oven"
		if String(info.get("cook", "")) == dish and _recipe_key_for(src).split("+").has("noi"):
			return "pot"
	if oven_recipes().values().has(dish):
		return "oven"
	return ""


static func _pot_cooked(id: String) -> bool:
	var src := _source_of(id)
	return not src.is_empty() and cook_step(src) == id \
		and _recipe_key_for(src).split("+").has("noi")


static func badge_path(kind: String) -> String:
	return BADGE_FMT % kind
