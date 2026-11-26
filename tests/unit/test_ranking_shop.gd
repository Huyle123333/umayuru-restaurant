extends "res://tests/test_case.gd"
## Kiểm thử xếp hạng cuối màn và tiền shop (10% doanh thu).

const STORY_LEVELS := ["d1_sang", "d2_sang", "d3_sang"]


func test_exact_threshold_gives_that_rank() -> void:
	for level in STORY_LEVELS:
		var marks: Dictionary = GameData.rank_thresholds_for(level)
		for rank in GameData.RANK_ORDER:
			var need := int(marks.get(rank, GameData.DEFAULT_THRESHOLDS[rank]))
			assert_eq(GameData.rank_for(level, need), rank, "(%s, %d)" % [level, need])


func test_one_below_threshold_drops_a_rank() -> void:
	for level in STORY_LEVELS:
		var marks: Dictionary = GameData.rank_thresholds_for(level)
		var s := int(marks.get("S", GameData.DEFAULT_THRESHOLDS["S"]))
		assert_eq(GameData.rank_for(level, s - 1), "A", "(%s)" % level)


func test_below_d_is_fail() -> void:
	for level in STORY_LEVELS:
		var marks: Dictionary = GameData.rank_thresholds_for(level)
		var d := int(marks.get("D", GameData.DEFAULT_THRESHOLDS["D"]))
		assert_eq(GameData.rank_for(level, d - 1), "", "(%s)" % level)


func test_thresholds_increase_with_rank() -> void:
	for level in STORY_LEVELS:
		var marks: Dictionary = GameData.rank_thresholds_for(level)
		var prev := 1 << 30
		for rank in GameData.RANK_ORDER:
			var v := int(marks.get(rank, GameData.DEFAULT_THRESHOLDS[rank]))
			assert_true(v < prev, "(%s: %s must be below the rank above)" % [level, rank])
			prev = v


func test_later_days_are_harder() -> void:
	var s1 := int(GameData.rank_thresholds_for("d1_sang").get("S", 0))
	var s3 := int(GameData.rank_thresholds_for("d3_sang").get("S", 0))
	assert_true(s3 > s1, "(day 3 S threshold must exceed day 1)")


func test_shop_reward_is_ten_percent_rounded_down() -> void:
	assert_eq(GameData.shop_reward_for(1000), 100)
	assert_eq(GameData.shop_reward_for(1999), 199)
	assert_eq(GameData.shop_reward_for(9), 0)


func test_shop_reward_never_negative() -> void:
	assert_eq(GameData.shop_reward_for(-500), 0)
