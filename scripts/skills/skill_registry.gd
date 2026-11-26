extends RefCounted
## ─────────────────────────────────── VÌ SAO MỖI NHÂN VẬT MỘT FILE
## ────────────────────────────────────────── BA KIỂU FILE TRONG THƯ MỤC NÀY


## Đếm số ĐƠN HOÀN HẢO đã giao. (Kita — Victory Cheer!)
const COND_PERFECT_ORDERS := "perfect_orders"
## Đếm số đơn đã hoàn thành, hoàn hảo hay không. (Mambo, Chiyono O)
const COND_ORDERS_DONE := "orders_done"
## Đếm số đơn ĐÃ GIAO mà món khách gọi thuộc một nhóm món. Nhóm khai ở khoá
const COND_ORDERS_WITH_DISHES := "orders_with_dishes"
## Đếm số MÓN đã nấu xong thuộc một nhóm. (Mambo — chưa cài)
const COND_DISHES_COOKED := "dishes_cooked"
## Đếm giây đã trôi của màn chơi. (Oguri Cap — Triumphant Pulse)
const COND_TIME_ELAPSED := "time_elapsed"
## Số tiền đang có trong ví. (Tokai Teio — Sky-High Teio Step)
const COND_MONEY_EARNED := "money_earned"
## Mọi món trong thực đơn đã hoàn hảo ít nhất một lần. Ngưỡng tự lấy bằng số
const COND_MENU_COVERED := "menu_covered"


## Mọi đơn giao ra tính là hoàn hảo bất kể thanh kiên nhẫn. (Kita)
const FX_FORCE_PERFECT := "force_perfect"
## Các món khai ở khoá "wildcard_dishes" giao được cho MỌI đơn; tiền tính theo
const FX_WILDCARD_DISHES := "wildcard_dishes"


const ACTIVE_EXTRAS := {
	"perfect_payout_multiplier": 1.0,
}


const DEFAULTS := {
	"patience_factor": 1.0,
	"perfect_bonus_add": 0.0,
	"burn_time_cut": 0.0,
	"cook_time_cut": 0.0,
	"cook_time_cut_items": [],
	"bonus_payout_chance": 0.0,
	"bonus_payout_multiplier": 3.0,
	"dish_price_factors": {},
	"bake_time_cut": 0.0,
	"dish_weight_factors": {},
	"refill_stamina_on_order": false,
	"force_perfect": false,
	"cook_fail_chance": 0.0,
	"all_price_factor": 1.0,
	"time_scale": 1.0,
}


const SKILL_FILES := {
	"kitamoi": preload("res://scripts/skills/characters/kita.gd"),
	"tuandb": preload("res://scripts/skills/characters/spe.gd"),
	"oui": preload("res://scripts/skills/characters/oguri.gd"),
	"mambo": preload("res://scripts/skills/characters/mambo.gd"),
	"hachimi": preload("res://scripts/skills/characters/teio.gd"),
	"chiyo": preload("res://scripts/skills/characters/chiyono.gd"),
	"golshi": preload("res://scripts/skills/characters/golshi.gd"),
}


## Bộ số bị động của một nhân vật, đã trộn sẵn với DEFAULTS.
static func passive(character_id: String) -> Dictionary:
	var out := DEFAULTS.duplicate()
	var script_class: GDScript = SKILL_FILES.get(character_id, null)
	if script_class == null:
		return out
	var constants: Dictionary = script_class.get_script_constant_map()
	var entry: Dictionary = constants.get("PASSIVE", {})
	for key in entry:
		out[key] = entry[key]
	_merge_asian(out, constants, "passive")
	return out


## Asian Mode: trộn đè bản chỉnh (hằng ASIAN trong file nhân vật) lên bản
static func _merge_asian(out: Dictionary, constants: Dictionary, part: String) -> void:
	if not GameData.is_asian_mode():
		return
	var patch: Dictionary = (constants.get("ASIAN", {}) as Dictionary).get(part, {})
	for key in patch:
		out[key] = patch[key]


## Mô tả kĩ năng chủ động của một nhân vật, hoặc Dictionary RỖNG nếu nhân vật
static func active(character_id: String) -> Dictionary:
	var script_class: GDScript = SKILL_FILES.get(character_id, null)
	if script_class == null:
		return {}
	var constants: Dictionary = script_class.get_script_constant_map()
	var out: Dictionary = (constants.get("ACTIVE", {}) as Dictionary).duplicate()
	if not out.is_empty():
		_merge_asian(out, constants, "active")
	return out


## Kĩ năng chủ động THỨ HAI của một nhân vật (hằng SECONDARY trong file của
static func secondary(character_id: String) -> Dictionary:
	var script_class: GDScript = SKILL_FILES.get(character_id, null)
	if script_class == null:
		return {}
	var constants: Dictionary = script_class.get_script_constant_map()
	var out: Dictionary = (constants.get("SECONDARY", {}) as Dictionary).duplicate()
	if not out.is_empty():
		_merge_asian(out, constants, "secondary")
	return out
