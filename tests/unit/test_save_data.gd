extends "res://tests/test_case.gd"
## Kiểm thử chuyển dữ liệu lưu game sang Dictionary và đọc lại.
## Chỉ gọi to_dict/from_dict, KHÔNG ghi file, và trả trạng thái về như cũ
## sau mỗi ca để không đụng vào save thật của người chơi.

var _backup: Dictionary


func before_each() -> void:
	_backup = GameData.to_dict().duplicate(true)


func after_each() -> void:
	GameData.from_dict(_backup)


func test_round_trip_keeps_data() -> void:
	var data := GameData.to_dict().duplicate(true)
	data["shop_coins"] = 321
	data["best_money"] = {"d1_sang": 1500}
	GameData.from_dict(data)
	assert_eq(GameData.to_dict(), data)


func test_round_trip_through_json() -> void:
	# File save là JSON: số nguyên đọc lại thành số thực, phải vẫn dùng được.
	var data := GameData.to_dict().duplicate(true)
	data["shop_coins"] = 42
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	GameData.from_dict(parsed)
	assert_eq(GameData.shop_coins, 42)


func test_negative_coins_clamped_to_zero() -> void:
	GameData.from_dict({"shop_coins": -99})
	assert_eq(GameData.shop_coins, 0)


func test_corrupt_fields_fall_back_to_empty() -> void:
	GameData.from_dict({"completed": "broken", "best_money": 5, "leaderboard": []})
	assert_eq(GameData.completed, {})
	assert_eq(GameData.best_money, {})
	assert_eq(GameData.leaderboard, {})


func test_old_vietnamese_keys_still_load() -> void:
	# Save từ bản cũ dùng khoá tiếng Việt trước khi đổi tên sang tiếng Anh.
	GameData.from_dict({"ki_nang_vo_han": true, "nhan_vat_mo": {"teio": true}})
	assert_true(GameData.infinite_skill)
	assert_true(GameData.unlocked_characters.has("teio"))


func test_old_golshi_flag_migrates() -> void:
	GameData.from_dict({"golshi_unlocked": true, "golshi_da_gioi_thieu": true})
	assert_true(GameData.unlocked_characters.has("golshi"))
	assert_true(GameData.intro_seen.has("golshi"))


func test_empty_save_gives_fresh_state() -> void:
	GameData.from_dict({})
	assert_eq(GameData.shop_coins, 0)
	assert_eq(GameData.completed, {})
