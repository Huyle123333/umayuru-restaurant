extends Node

signal progress_changed

## Phát khi đổi qua lại giữa top-down và góc nhìn thứ 3. Camera màn chơi và
signal view_mode_changed(is_third_person: bool)

## Map của quán, dùng chung cho cả ba ngày.
const MAP_RESTAURANT := "res://restaurant_map_planb.tscn"

## Scene kể chuyện mở đầu. Không phải map 3D mà là một màn hội thoại 1 chạm:
const SCENE_PROLOGUE := "res://scenes/story/intro_prologue.tscn"
const SCENE_ENDING_NORMAL := "res://scenes/story/ending_normal.tscn"
const SCENE_ENDING_SECRET := "res://scenes/story/ending_secret.tscn"

## ĐOẠN RA MẮT của từng nhân vật ẩn: id nhân vật -> file scene.
const INTRO_SCENES := {
	"hachimi": "res://scenes/story/teio_intro.tscn",
	"chiyo": "res://scenes/story/chiyono_intro.tscn",
	"golshi": "res://scenes/story/golshi_intro.tscn",
}

## ─────────────────────────────── LUẬT RIÊNG CỦA TỪNG MÀN ──────────────────

## ══════════════════════════════════════════════════════════════════════════
const RULES_D1 := {
	"duration": 300.0,
	"price_factor": 0.95,
	"max_customers": 6,
	"max_tables": 3,
	"max_queue": 2,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "burger_plain",
		"pizza_mushroom",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 3, "mon_steak": 4, "burger_plain": 3,
		"pizza_mushroom": 2,
	},
	"stages": [
		{"until": 86.0, "interval": 18.0, "interval_range": [10.0, 20.0], "tier_weights": {"easy": 8, "medium": 2}},
		{"until": 214.0, "interval": 12.0, "interval_range": [7.0, 15.0], "tier_weights": {"easy": 6, "medium": 4}},
		{"until": 300.0, "interval": 8.0, "interval_range": [5.0, 13.0], "tier_weights": {"easy": 5, "medium": 5}},
	],
	"rank_thresholds": {"S": 2026, "A": 1534, "B": 1000, "C": 777, "D": 555},
	"max_left": 10,
}

## NGÀY 2 — thực đơn Ngày 1 CỘNG DỒN thêm năm món mới.
const RULES_D2 := {
	"duration": 360.0,
	"price_factor": 1.0,
	"max_customers": 8,
	"max_tables": 4,
	"max_queue": 2,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "burger_plain",
		"burger_cheese", "burger_lettuce", "dinner", "soup_carrot",
		"pizza_mushroom", "kem_tam_hop",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 2, "mon_steak": 3, "burger_plain": 2,
		"burger_cheese": 3, "burger_lettuce": 2, "dinner": 3, "soup_carrot": 1,
		"pizza_mushroom": 3, "kem_tam_hop": 2,
	},
	"stages": [
		{"until": 103.0, "interval": 15.0, "interval_range": [8.0, 18.0], "tier_weights": {"easy": 67, "medium": 28, "hard": 5}},
		{"until": 257.0, "interval": 10.0, "interval_range": [5.0, 15.0], "tier_weights": {"easy": 45, "medium": 45, "hard": 10}},
		{"until": 360.0, "interval": 7.0, "interval_range": [4.0, 12.0], "tier_weights": {"easy": 35, "medium": 50, "hard": 15}},
	],
	"rank_thresholds": {"S": 2829, "A": 1971, "B": 1420, "C": 1050, "D": 800},
	"max_left": 7,
}

## NGÀY 3 — toàn bộ thực đơn, đủ sáu bàn. Món rẻ (kem lẻ) vẫn có mặt nhưng
const RULES_D3 := {
	"duration": 420.0,
	"price_factor": 1.15,
	"max_customers": 10,
	"max_tables": 6,
	"max_queue": 3,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "dinner",
		"burger_plain", "burger_cheese", "burger_lettuce", "hambuger",
		"soup_carrot", "soup_onion", "soup_potato",
		"pizza_mushroom", "pizza_cheese", "pizza_peperoni",
		"kem_tam_hop", "kem_tam_hop_que",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 1, "mon_steak": 2, "dinner": 2,
		"burger_plain": 1, "burger_cheese": 2, "burger_lettuce": 2, "hambuger": 3,
		"soup_carrot": 2, "soup_onion": 2, "soup_potato": 2,
		"pizza_mushroom": 2, "pizza_cheese": 2, "pizza_peperoni": 2,
		"kem_tam_hop": 1, "kem_tam_hop_que": 2,
	},
	"stages": [
		{"until": 120.0, "interval": 12.0, "interval_range": [6.0, 15.0], "tier_weights": {"easy": 53, "medium": 42, "hard": 5}},
		{"until": 300.0, "interval": 8.0, "interval_range": [4.0, 13.0], "tier_weights": {"easy": 25, "medium": 55, "hard": 20}},
		{"until": 420.0, "interval": 6.0, "interval_range": [3.0, 11.0], "tier_weights": {"easy": 15, "medium": 60, "hard": 25}},
	],
	"rank_thresholds": {"S": 3667, "A": 2501, "B": 1836, "C": 1357, "D": 1000},
	"max_left": 5,
}

## AAA MODE — chế độ phụ nhại game AAA (xem thiet_ke_aaa_mode_v0.2.docx).
const RULES_AAA := {
	"duration": 240.0,
	"price_factor": 1.0,
	"max_customers": 5,
	"max_tables": 3,
	"max_queue": 2,
	"first_wait": 4.0,
	"menu": ["mon_ham", "mon_steak", "hambuger"],
	"weights": {"mon_ham": 3, "mon_steak": 3, "hambuger": 2},
	"stages": [
		{"until": 240.0, "interval": 16.0, "interval_range": [10.0, 20.0]},
	],
}

## ENDLESS MODE (user chốt 25/10/2026).
const RULES_ENDLESS := {
	"duration": 150.0,
	"price_factor": 1.0,
	"max_customers": 10,
	"max_tables": 6,
	"max_queue": 3,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "dinner",
		"burger_plain", "burger_cheese", "burger_lettuce", "hambuger",
		"soup_carrot", "soup_onion", "soup_potato",
		"pizza_mushroom", "pizza_cheese", "pizza_peperoni",
		"kem_tam_hop", "kem_tam_hop_que",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 1, "mon_steak": 2, "dinner": 2,
		"burger_plain": 1, "burger_cheese": 2, "burger_lettuce": 2, "hambuger": 3,
		"soup_carrot": 2, "soup_onion": 2, "soup_potato": 2,
		"pizza_mushroom": 2, "pizza_cheese": 2, "pizza_peperoni": 2,
		"kem_tam_hop": 1, "kem_tam_hop_que": 2,
	},
	"stages": [
		{"until": 180.0, "interval": 14.0, "interval_range": [9.0, 18.0], "tier_weights": {"easy": 100}},
		{"until": 360.0, "interval": 11.0, "interval_range": [7.0, 15.0], "tier_weights": {"easy": 55, "medium": 45}},
		{"until": 540.0, "interval": 9.0, "interval_range": [5.0, 13.0], "tier_weights": {"easy": 35, "medium": 50, "hard": 15}},
		{"until": 720.0, "interval": 7.0, "interval_range": [4.0, 11.0], "tier_weights": {"easy": 20, "medium": 55, "hard": 25}},
		{"until": 999999.0, "interval": 6.0, "interval_range": [3.0, 9.0], "tier_weights": {"easy": 15, "medium": 50, "hard": 35}},
	],
}

## ASIAN MODE — đợt 2 (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx
const RULES_ASIAN := {
	"duration": 600.0,
	"price_factor": 1.0,
	"max_customers": 10,
	"max_tables": 6,
	"max_queue": 3,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "dinner",
		"burger_plain", "burger_cheese", "burger_lettuce", "hambuger",
		"soup_carrot", "soup_onion", "soup_potato",
		"pizza_mushroom", "pizza_cheese", "pizza_peperoni",
		"kem_tam_hop", "kem_tam_hop_que",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 1, "mon_steak": 2, "dinner": 2,
		"burger_plain": 1, "burger_cheese": 2, "burger_lettuce": 2, "hambuger": 3,
		"soup_carrot": 2, "soup_onion": 2, "soup_potato": 2,
		"pizza_mushroom": 2, "pizza_cheese": 2, "pizza_peperoni": 2,
		"kem_tam_hop": 1, "kem_tam_hop_que": 2,
	},
	"stages": [
		{"until": 120.0, "interval": 10.0, "interval_range": [6.0, 14.0], "tier_weights": {"easy": 60, "medium": 40}},
		{"until": 300.0, "interval": 7.5, "interval_range": [4.0, 11.0], "tier_weights": {"easy": 40, "medium": 45, "hard": 15}},
		{"until": 480.0, "interval": 6.0, "interval_range": [3.0, 9.0], "tier_weights": {"easy": 25, "medium": 45, "hard": 30}},
		{"until": 600.0, "interval": 4.5, "interval_range": [2.0, 7.0], "tier_weights": {"easy": 15, "medium": 45, "hard": 40}},
	],
}

## Id của Asian Mode trong LEVELS. Hỏi qua is_asian_mode().
const ASIAN_LEVEL := "asian"

## Id của Endless Mode trong LEVELS. Hỏi qua is_endless_mode().
const ENDLESS_LEVEL := "endless"

## Id của AAA Mode trong LEVELS. Hỏi qua is_aaa_mode(), đừng so chuỗi tay.
const AAA_LEVEL := "aaa"

## Hai đoạn kể chuyện của AAA Mode (kịch bản v4). Không bỏ qua được.
const AAA_INTRO_SCENE := "res://scenes/story/aaa_intro.tscn"
const AAA_OUTRO_SCENE := "res://scenes/story/aaa_outro.tscn"

## Toàn bộ màn chơi của game.
const LEVELS := {
	"prologue": {"label": "Prologue", "needs": "", "scene": SCENE_PROLOGUE, "story_only": true},
	"tutorial": {"label": "Tutorial", "needs": "prologue", "scene": MAP_RESTAURANT},
	"d1_sang": {"label": "Sáng", "needs": "tutorial", "scene": MAP_RESTAURANT, "rules": RULES_D1},
	"d2_sang": {"label": "Sáng", "needs": "d1_sang", "scene": MAP_RESTAURANT, "rules": RULES_D2},
	"d3_sang": {"label": "Sáng", "needs": "d2_sang", "scene": MAP_RESTAURANT, "rules": RULES_D3},
	"ending": {"label": "Ending", "needs": "d3_sang", "scene": SCENE_ENDING_NORMAL, "story_only": true},
	"aaa": {"label": "AAA Mode", "needs": "", "scene": MAP_RESTAURANT, "rules": RULES_AAA},
	"endless": {"label": "Endless Mode", "needs": "", "scene": MAP_RESTAURANT, "rules": RULES_ENDLESS},
	"asian": {"label": "Asian Mode", "needs": "", "scene": MAP_RESTAURANT, "rules": RULES_ASIAN},
	"plan_b": {"label": "Thử nghiệm B", "needs": "", "scene": "res://scenes/test/recipe_plan_b_test.tscn"},
}

## Các nhân vật. Khóa là id, cũng là tên file ảnh đại diện trong
const CHARACTERS := {
	"kitamoi": {
		"label": "Kitasan Black",
		"player": "res://scenes/characters/player_kitamoi.tscn",
		"skills": [
			{"name": "Victory Cheer!", "level": 18, "desc": "Điều kiện: hoàn thành 5 đơn hoàn hảo.\nĐến hết màn, mọi đơn đều tính là hoàn hảo. Đơn giao khi kiên nhẫn còn trên một nửa được nhân đôi tiền.", "icon": "mac_dinh"},
			{"name": "Kiên nhẫn là một đức tính", "level": 0, "desc": "Kiên nhẫn của khách +30%.", "icon": "skill2"},
			{"name": "Dòng tiền mờ ám", "level": 0, "desc": "Thưởng đơn hoàn hảo tăng từ 35% lên 55%. Đổi lại, món trên bếp cháy sớm hơn 2 giây.", "icon": "skill3"},
		],
		"desc": "Nụ cười của cô làm sáng cả căn phòng. Một khối nắng mê lễ hội.",
		"tagline": "Nụ cười của cô làm sáng cả căn phòng. Một khối nắng mê lễ hội.",
		"intro": "Tôi là Kitasan Black! Mỗi lần chạy tôi đều cố hết sức tạo không khí lễ hội để ai cũng thấy vui!",
		"measure": {
			"Height": "162 cm",
			"Weight": "Tôi vẫn đang lớn mà!",
			"Shoe size": "Trái & phải: 23,0 cm",
		},
		"profile": {
			"Strong points": "Đấm bóp",
			"Weak points": "Nhắm mắt cho qua",
			"Ears": "Cảm âm cực chuẩn",
			"Tail": "Đuôi cũng khiêng được vật nặng",
			"Family": "Tính cả học trò của bố thì nhà cô có ba mươi người",
		},
		"secrets": [
			"Cô hay phải lòng ngay từ cái nhìn đầu tiên",
			"Đã ăn kẹo là không dừng lại được",
		],
		"hint": "",
		"sizes": ["85", "56", "88"],
	},
	"hachimi": {
		"label": "Tokai Teio",
		"player": "res://scenes/characters/player_hachimi.tscn",
		"skills": [
			{"name": "Sky-High Teio Step", "level": 3, "desc": "Điều kiện: có từ 1.500 tiền.\nĐến hết màn, mỗi đơn giao xong cộng 10 giây vào đồng hồ.", "icon": "mac_dinh"},
			{"name": "Fan tê liệt", "level": 0, "desc": "Phím 3: chọn một món trong thực đơn hôm nay và nhận ngay trên tay. Tối đa 6 lần mỗi màn.", "icon": "skill2"},
			{"name": "Tưởng tày nhưng không", "level": 0, "desc": "Món kem tăng 60% giá trị, nhưng khách gọi kem ít hơn một nửa.", "icon": "skill3"},
		],
		"desc": "Bất bại và đáng yêu! Một tay đua tưng tưng lúc nào cũng vui.",
		"tagline": "Bất bại và đáng yêu! Một tay đua tưng tưng lúc nào cũng vui.",
		"intro": "Này này! Tokai Teio đây! Nhớ để mắt tới tớ nhé — sắp có một nhà vô địch Tam Miện bất bại mới rồi đấy!",
		"measure": {
			"Height": "150 cm",
			"Weight": "Không đổi",
			"Shoe size": "Trái & phải: 22,0 cm",
		},
		"profile": {
			"Strong points": "Kết bạn",
			"Weak points": "Bác sĩ",
			"Ears": "Không bao giờ bỏ lỡ một lời khen hay giọng của Hội trưởng",
			"Tail": "Ve vẩy phấn khích mỗi khi được chú ý",
			"Family": "Cả nhà đã khóc khi cô thôi gọi 'Mama' và 'Papa'",
		},
		"secrets": [
			"Giữ kỷ lục gập người của trường",
			"Hồi bé chơi ngoài biển suốt, ai cũng gọi cô là 'Bá vương bãi biển'",
		],
		"hint": "",
		"sizes": ["77", "54", "76"],
	},
	"chiyo": {
		"label": "Sakura Chiyono O",
		"player": "res://scenes/characters/player_chiyo.tscn",
		"skills": [
			{"name": "Ambition to Surpass the Sakura", "level": 76, "desc": "Điều kiện: hoàn thành 10 đơn (đếm lại sau mỗi lần dùng).\nĐặt lại đồng hồ màn, mọi khách ra về, giữ nguyên số tiền. Không giới hạn số lần.", "icon": "mac_dinh"},
			{"name": "Cute puppy", "level": 0, "desc": "Mọi món tăng 50% giá trị.", "icon": "skill2"},
			{"name": "Made in haven", "level": 0, "desc": "Đồng hồ, thời gian nấu, nhịp khách đến và thanh kiên nhẫn đều nhanh hơn 25%.", "icon": "skill3"},
		],
		"desc": "Theo đuổi giấc mơ! Một Umamusume thật thà và chăm chỉ.",
		"tagline": "Theo đuổi giấc mơ! Một Umamusume thật thà và chăm chỉ.",
		"intro": "T-tôi là Sakura Chiyono O! Giấc mơ của tôi là được đứng chung sân khấu với thần tượng. Và tôi sẽ làm giấc mơ ấy nở hoa!",
		"measure": {
			"Height": "156 cm",
			"Weight": "Giảm nhẹ",
			"Shoe size": "Cả hai chân: 22,0 cm",
		},
		"profile": {
			"Strong points": "Làm bánh kẹo Nhật, dọn dẹp",
			"Weak points": "Ô tô, máy bay... (say tàu xe)",
			"Ears": "Rung lên mỗi khi cô nghĩ ra một câu châm ngôn hay",
			"Tail": "Cô dưỡng đuôi bằng đúng loại dầu Maruzensky dùng",
			"Family": "Cả nhà hay quây quần quanh một nồi lẩu lớn",
		},
		"secrets": [
			"Xe hơi màu đỏ luôn hút mắt cô",
			"Ăn wasabi thì được, nhưng mù tạt vàng thì chịu",
		],
		"hint": "",
		"sizes": ["80", "55", "83"],
	},
	"mambo": {
		"label": "Matikanetannhauser",
		"player": "res://scenes/characters/player_mambo.tscn",
		"skills": [
			{"name": "Go, Go, Mun!", "level": 120, "desc": "Điều kiện: hoàn thành 15 đơn.\nĐến hết màn, mỗi đơn pizza hoàn hảo có 36% được nhân ba tiền, 18% được nhân đôi. Đổi lại, khi di chuyển mỗi giây có 3% bị choáng 2 giây.", "icon": "mac_dinh"},
			{"name": "Mambo tongye", "level": 0, "desc": "Thời gian nấu trên bếp và trong lò giảm 4 giây (bếp 8 → 4, lò 11 → 7).", "icon": "skill2"},
			{"name": "Vua làm nền", "level": 0, "desc": "Khách gọi pizza nhiều hơn 20%.", "icon": "skill3"},
		],
		"desc": "Viên ngọc thô ai cũng quý. Hôm nay là ngày của cô ấy!",
		"tagline": "Viên ngọc thô ai cũng quý. Hôm nay là ngày của cô ấy!",
		"intro": "Chào chào, Matikanetannhauser đây. Tôi phải tập thật chăm để không thua... Hả? Hôm nay không có buổi tập à?!",
		"measure": {
			"Height": "155 cm",
			"Weight": "Tăng nhẹ (dạo này hay ăn vặt)",
			"Shoe size": "Trái 24,5 cm / Phải 25,5 cm",
		},
		"profile": {
			"Strong points": "Kéo co, tư vấn chuyện tình cảm",
			"Weak points": "Nhện thật, nước ép cà chua",
			"Ears": "Nghe rõ từng âm thanh riêng lẻ giữa chỗ ồn ào",
			"Tail": "Tự cắt lấy nên lúc nào cũng lệch",
			"Family": "Cô về nhà là quán ăn của gia đình lại treo băng rôn đón",
		},
		"secrets": [
			"Đây đã là chiếc mũ thứ ba của cô",
			"Có khiếu đặt tên rất riêng",
		],
		"hint": "",
		"sizes": ["80", "55", "80"],
	},
	"oui": {
		"label": "Oguri Cap",
		"player": "res://scenes/characters/player_oui.tscn",
		"skills": [
			{"name": "Triumphant Pulse", "level": 11, "desc": "Điều kiện: màn chơi trôi qua 4 phút.\nPhím Space bật/tắt: đồng hồ, khách và thanh kiên nhẫn đứng yên, bếp vẫn hoạt động. Tổng cộng 30 giây mỗi màn.", "icon": "mac_dinh"},
			{"name": "Alo vũ à vũ", "level": 0, "desc": "Món pizza tăng 60% giá trị.", "icon": "skill2"},
			{"name": "Hốc trưởng", "level": 0, "desc": "Mỗi đơn giao xong hồi đầy thanh chạy nhanh.", "icon": "skill3"},
		],
		"desc": "Một cô gái quê điềm tĩnh mà nhiều mơ mộng.",
		"tagline": "Một cô gái quê điềm tĩnh mà nhiều mơ mộng.",
		"intro": "Tôi là Oguri Cap. Tôi sẽ cố hết sức giành chiến thắng cho bà con quê nhà. Cảm ơn mọi người đã ủng hộ.",
		"measure": {
			"Height": "167 cm",
			"Weight": "Tăng nhẹ (ăn hơi quá tay)",
			"Shoe size": "Cả hai chân: 27,0 cm",
		},
		"profile": {
			"Strong points": "Ăn đồ ngon",
			"Weak points": "Bơi lội",
			"Ears": "Chỉ nghe tiếng cổ vũ là nhận ra người cùng quê",
			"Tail": "Dẻo tới mức chải được mọi chỗ",
			"Family": "Hay đi nghỉ suối nước nóng; biết ít nhất một suối chưa ai tìm ra",
		},
		"secrets": [
			"Cắt móng cực khéo",
			"Ước mơ hồi bé là... món hầm",
		],
		"hint": "",
		"sizes": ["82", "57", "82"],
	},
	"tuandb": {
		"label": "Special Week",
		"player": "res://scenes/characters/player_tuandb.tscn",
		"skills": [
			{"name": "Shooting Star", "level": 24, "desc": "Điều kiện: giao xong 5 đơn món thịt (Steak, Đùi nướng, Đùi nướng cà rốt, các loại burger).\nĐến hết màn, các món đó giao được cho mọi đơn. Tiền tính theo giá món được giao.", "icon": "mac_dinh"},
			{"name": "Độc tày Spe-chan", "level": 0, "desc": "Steak và đùi nướng nấu trên bếp nhanh hơn 4 giây (8 → 4 giây).", "icon": "skill2"},
			{"name": "Hốc phó", "level": 0, "desc": "Mỗi đơn có 20% được trả gấp 3.", "icon": "skill3"},
		],
		"desc": "Sẵn sàng lao đi! Một cô gái trong veo chỉ hướng về giấc mơ.",
		"tagline": "Sẵn sàng lao đi! Một cô gái trong veo chỉ hướng về giấc mơ.",
		"intro": "Tôi tên là Special Week! Giấc mơ của tôi là trở thành Umamusume số một Nhật Bản! Tôi phải cố lên để hai người mẹ được tự hào!",
		"measure": {
			"Height": "158 cm",
			"Weight": "Giảm nhẹ (hồi hộp trước giờ đua)",
			"Shoe size": "Trái 23,5 cm / Phải 23,0 cm",
		},
		"profile": {
			"Strong points": "Viết cảm nhận đồ ăn cực chi tiết",
			"Weak points": "Dùng vé tàu tháng",
			"Ears": "Vểnh lên và dịch chuyển tức thời xuống bếp mỗi khi nghe tiếng nấu nướng",
			"Tail": "Động theo cảm xúc, nên chơi bài là thua",
			"Family": "Màu mắt thừa hưởng từ mẹ ruột",
		},
		"secrets": [
			"Nếm là phân biệt được từng hãng sữa",
			"Cõng rất giỏi — ai được cõng cũng ngủ gật ngay",
		],
		"hint": "",
		"sizes": ["81", "56", "81"],
	},
	"golshi": {
		"label": "Gold Ship",
		"player": "res://scenes/characters/player_golshi.tscn",
		"skills": [
			{"name": "Anchors Aweigh!", "level": 999, "desc": "Điều kiện: mỗi món trong thực đơn hôm nay đã được giao hoàn hảo ít nhất một lần.\nNhận ngay 9.999.999 tiền và kết thúc màn.", "icon": "mac_dinh"},
			{"name": "Aura farming", "level": 0, "desc": "Mọi đơn giao ra đều được tính là hoàn hảo.", "icon": "skill2"},
			{"name": "Everything but cooking", "level": 0, "desc": "Mỗi lần nấu, nướng hay ráp món có 20% thất bại, ra đồ hỏng và mất nguyên liệu.", "icon": "skill3"},
		],
		"an_khi_khoa": true,
		"desc": "Hoang dã và khó đoán, tay đua vàng không giống bất kỳ ai!",
		"tagline": "Hoang dã và khó đoán, tay đua vàng không giống bất kỳ ai!",
		"intro": "Quỳ xuống! Gold Ship đã tới! Dù là biển lửa, mặt cỏ nát bét hay tận ngoài vũ trụ, ta luôn sẵn sàng phiêu lưu! ☆",
		"measure": {
			"Height": "170 cm",
			"Weight": "Không đo được",
			"Shoe size": "Cả hai chân: 26,5 cm",
		},
		"profile": {
			"Strong points": "Làm mặt",
			"Weak points": "Ngồi yên",
			"Ears": "Bịt tai người khác rồi hỏi 'Đoán xem ai nào?'",
			"Tail": "Thi thoảng bỏ quên trong phòng",
			"Family": "Nghe đâu là bí mật quốc gia",
		},
		"secrets": [
			"Cực giỏi thi đố vui",
			"Hay nói dối vặt, nhưng chuyện quan trọng thì luôn thật thà",
		],
		"hint": "Nhân tố G chỉ xuất hiện khi được gọi tên đúng chỗ.",
		"sizes": ["88", "55", "88"],
	},
}

## Chuỗi dùng để che mọi thông tin của nhân vật chưa mở khoá.
const MASK_STRING := "????????????"

## Những nhân vật BỊ GIẤU cho tới khi mở khoá bằng bảng CODE No.7.
const HIDDEN_CHARACTERS := {
	"hachimi": "thidden",
	"chiyo": "chidden",
	"golshi": "ghidden",
}

## Thứ tự các nhân vật hiện trên màn hình chọn nhân vật.
const CHARACTER_ORDER := ["kitamoi", "hachimi", "chiyo", "mambo",
	"oui", "tuandb", "golshi"]


## Nhân vật này có đang khoá không.
func is_character_locked(id: String) -> bool:
	if HIDDEN_CHARACTERS.has(id):
		return not is_character_unlocked(id)
	return bool(CHARACTERS.get(id, {}).get("locked", false))


## Nhân vật ẩn này đã được mở khoá chưa.
func is_character_unlocked(id: String) -> bool:
	return bool(unlocked_characters.get(id, false))


## Ảnh thẻ hiện trên màn chọn nhân vật.
func card_image(id: String) -> String:
	if HIDDEN_CHARACTERS.has(id) and not is_character_unlocked(id):
		return "res://assets/ui/characters/%s.png" % HIDDEN_CHARACTERS[id]
	return "res://assets/ui/characters/%s.png" % id


## Thông tin hiện trên bảng bên phải màn chọn nhân vật.
const ASIAN_SKILL_DESC := {
	"kitamoi": ["Điều kiện: Hoàn thành 8 đơn hoàn hảo.\nTrong thời gian còn lại của màn chơi, mọi đơn giao ra đều được tính là hoàn hảo bất kể thanh kiên nhẫn. Riêng đơn giao khi kiên nhẫn còn trên một nửa thì được nhân đôi tiền. Đơn được tính hoàn hảo nhờ kĩ năng không tính vào chuỗi hồi mạng.", "Thời gian kiên nhẫn của khách hàng +15%.", "Tiền thưởng từ đơn hoàn hảo +10% (35% → 45%). Đổi lại: món ăn trên bếp hỏng sớm hơn 2 giây."],
	"hachimi": ["Điều kiện: Đang có 1500 tiền trở lên.\nTừ đó tới hết màn, mỗi đơn giao xong cộng thêm 5 giây kiên nhẫn cho mọi khách đang có mặt.", "Phím 3: mở bảng chọn một món trong thực đơn hôm nay và nhận ngay món đó trên tay. Tối đa 2 lần mỗi màn.", "Các món kem tăng 30% giá trị, nhưng khách gọi kem ít đi một nửa."],
	"chiyo": ["Điều kiện: Hoàn thành 15 đơn.\nCho toàn bộ khách ra về mà không mất mạng; khách đang ăn vẫn trả tiền. Dùng một lần mỗi màn.", "Giá trị của tất cả món ăn tăng 25%.", null],
	"mambo": ["Điều kiện: Hoàn thành 20 đơn.\nTrong thời gian còn lại của màn chơi, mỗi đơn pizza hoàn hảo có 36% được nhân ba tiền, 18% được nhân đôi, còn lại giá thường. Đổi lại: trong lúc di chuyển, mỗi giây có 3% bị choáng đứng yên 2 giây.", "Thời gian nấu trên bếp và trong lò nướng giảm 2 giây (bếp 8 → 6, lò 11 → 9).", null],
	"oui": ["Điều kiện: Màn chơi trôi qua 6 phút.\nBật/tắt bằng phím Space. Khi bật: đồng hồ màn, khách hàng và thanh kiên nhẫn đứng im; nhân vật và khu bếp vẫn hoạt động. Tổng cộng 15 giây cho cả màn. Sự kiện và cơn đói của Doro vẫn chạy.", "Các món pizza tăng 30% giá trị.", null],
	"tuandb": ["Điều kiện: Giao xong 8 đơn có ham hoặc steak (Ham, Steak, Hamburger, Steak rau củ, Hamburger rau củ, Bữa tối).\nTrong thời gian còn lại của màn chơi, sáu món đó giao được cho MỌI đơn và không tính là giao nhầm. Tiền nhận tính theo giá của món bạn giao.", "Ham, steak và chả rau củ nấu trên bếp nhanh hơn 2 giây (8 → 6 giây).", "Mỗi đơn giao ra có 10% cơ hội được trả gấp 3."],
	"golshi": ["Điều kiện: Mỗi món trong thực đơn hôm nay đã được giao hoàn hảo ít nhất một lần.\nNhận 1000 tiền và hồi 3 mạng.", "Chỉ bắt đầu với 1 mạng. Mọi đơn giao ra đều được tính là hoàn hảo. Mạng hồi vượt quá tối đa đổi thành 250 tiền mỗi mạng.", "Mỗi lần nấu trên bếp, nướng trong lò hay ghép ở bàn chế tạo có 30% thất bại: ra đồ hỏng và mất nguyên liệu. Đồ cháy vứt vào thùng rác bị trừ gấp đôi tiền nguyên liệu."],
}

func card_info(id: String) -> Dictionary:
	var info: Dictionary = CHARACTERS.get(id, {})
	if is_asian_mode() and ASIAN_SKILL_DESC.has(id) and not is_character_locked(id):
		info = info.duplicate(true)
		var descs: Array = ASIAN_SKILL_DESC[id]
		var slots: Array = info.get("skills", [])
		for i in mini(descs.size(), slots.size()):
			if descs[i] != null:
				(slots[i] as Dictionary)["desc"] = String(descs[i])
	if not is_character_locked(id):
		return info
	if not (HIDDEN_CHARACTERS.has(id) or bool(info.get("an_khi_khoa", false))):
		return info

	var masked := info.duplicate(true)
	masked["label"] = MASK_STRING
	masked["desc"] = MASK_STRING
	masked["tagline"] = MASK_STRING
	masked["intro"] = " ".join([MASK_STRING, MASK_STRING, MASK_STRING, MASK_STRING])
	for board_name in ["measure", "profile"]:
		var board: Dictionary = masked.get(board_name, {})
		for label in board:
			board[label] = MASK_STRING
	var secrets: Array = masked.get("secrets", [])
	for i in secrets.size():
		secrets[i] = MASK_STRING
	masked["sizes"] = ["??", "??", "??"]
	for slot in masked["skills"]:
		slot["name"] = MASK_STRING
		slot["level"] = 0
		slot["desc"] = MASK_STRING
		slot["icon"] = ""
	return masked


## Màn đã hoàn thành. Khóa là id màn (chuỗi), giá trị true.
var completed: Dictionary = {}
## Doanh thu tốt nhất từng màn, cùng kiểu khóa.
var best_money: Dictionary = {}
## Nhân vật người chơi đã chọn ở cửa sổ chọn nhân vật.
var selected_character: String = ""
## Màn đang chơi, do màn hình chọn màn ghi vào trước khi đổi scene.
var current_level: String = ""
## Scene sẽ quay về khi bấm "Trở lại" ở màn hình chọn nhân vật.
var return_scene: String = "res://scenes/menu/main_menu.tscn"
## Cheat CODE No.7: bỏ qua mọi điều kiện mở khóa. Có lưu vào file save
var unlock_all: bool = false

## Cheat CODE No.7 thứ hai: cho phép đổi sang góc nhìn thứ 3 bằng phím P.
var third_person_unlocked: bool = false

## Đang thực sự ở góc nhìn thứ 3 hay không. KHÔNG lưu vào save: mỗi lần vào
var third_person_active: bool = false

## Cheat CODE No.7 thứ ba: mở khoá "nhân tố G" (Gold Ship) ở màn chọn nhân
var unlocked_characters: Dictionary = {}

## Cheat CODE No.7: dùng kĩ năng chủ động mà KHÔNG cần điều kiện, không giới
var infinite_skill: bool = false

## Đã xem màn ra mắt của Gold Ship chưa. Lưu vào save.
var intro_seen: Dictionary = {}

## Cheat CODE No.7: bật phím 0 để TUA GIỜ trong màn chơi. Lưu vào file save.
var cheat_time_skip: bool = false

## Cheat: nguyên liệu MIỄN PHÍ. false = trừ tiền như bình thường.
var cheat_free_ingredients: bool = false

## ───────────────────────────── BẢNG XẾP HẠNG ──────────────────────────────
var leaderboard: Dictionary = {}

## Các màn có bảng xếp hạng, đúng thứ tự tab trên giao diện.
const RANKED_LEVELS := ["d1_sang", "d2_sang", "d3_sang", "endless", "asian"]

## Nhãn tab. "endless" và "asian" chưa phải màn thật trong LEVELS — chúng là
const RANKED_LEVEL_NAMES := {
	"d1_sang": "Màn 1",
	"d2_sang": "Màn 2",
	"d3_sang": "Màn 3",
	"endless": "Endless Mode",
	"asian": "Asian Mode",
}

## Giữ bao nhiêu dòng mỗi màn. Cắt bớt chứ không giữ hết: file save là JSON
const LEADERBOARD_ROWS := 10

## true = lượt chơi vừa xong THẮNG BẰNG KĨ NĂNG chứ không bằng tiền kiếm được
var skill_win_pending: bool = false


## Ghi một lượt chơi vào bảng xếp hạng.
func record_rank(level_id: String, money: int, rank: String, seconds: float = -1.0) -> void:
	if not RANKED_LEVELS.has(level_id):
		return
	last_rank[level_id] = rank
	var list_: Array = leaderboard.get(level_id, [])
	var entry := {
		"character": selected_character,
		"money": money,
		"rank": rank,
	}
	if seconds >= 0.0:
		entry["time"] = snappedf(seconds, 0.1)
	var skill_win := skill_win_pending
	skill_win_pending = false
	if skill_win:
		for old in list_:
			if bool((old as Dictionary).get("pinned", false)):
				SaveSystem.save_game()
				return
		entry["pinned"] = true
	list_.append(entry)
	list_.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_pinned := bool(a.get("pinned", false))
		if a_pinned != bool(b.get("pinned", false)):
			return a_pinned
		if level_id == ASIAN_LEVEL:
			var a_won := String(a.get("rank", "")) == "WIN"
			if a_won != (String(b.get("rank", "")) == "WIN"):
				return a_won
			if not a_won:
				return float(a.get("time", 0.0)) > float(b.get("time", 0.0))
		return int(a.get("money", a.get("tien", 0))) \
			> int(b.get("money", b.get("tien", 0))))
	if list_.size() > LEADERBOARD_ROWS:
		list_.resize(LEADERBOARD_ROWS)
	leaderboard[level_id] = list_
	progress_changed.emit()
	SaveSystem.save_game()


## Bảng xếp hạng của một màn — mảng bản ghi đã sắp sẵn, có thể rỗng.
func level_leaderboard(level_id: String) -> Array:
	var list_: Variant = leaderboard.get(level_id, [])
	return list_ if list_ is Array else []


## Tên hiển thị của nhân vật trong một bản ghi xếp hạng.
func character_name(id: String) -> String:
	if id.is_empty():
		return "—"
	return String(CHARACTERS.get(id, {}).get("label", id))


## Bật/tắt cheat tua giờ.
func reset_intro_seen() -> void:
	intro_seen.clear()
	progress_changed.emit()
	SaveSystem.save_game()


func set_cheat_free_ingredients(value: bool) -> void:
	if cheat_free_ingredients == value:
		return
	cheat_free_ingredients = value
	progress_changed.emit()
	SaveSystem.save_game()


func set_cheat_time_skip(value: bool) -> void:
	cheat_time_skip = value
	progress_changed.emit()
	SaveSystem.save_game()


## Đang chơi AAA Mode không. Mọi chỗ cần đối xử khác (bỏ qua cheat, khoá nhân
func is_aaa_mode() -> bool:
	return current_level == AAA_LEVEL


func is_endless_mode() -> bool:
	return current_level == ENDLESS_LEVEL


func is_asian_mode() -> bool:
	return current_level == ASIAN_LEVEL


## Ghi một lượt Asian. `rank` = "WIN" nếu thắng, rỗng nếu thua — dùng lại ô
func record_asian(won: bool, money: int, seconds: float) -> void:
	record_rank(ASIAN_LEVEL, money, "WIN" if won else "", seconds)


## Ghi một lượt Endless vào bảng xếp hạng.
func record_endless(money: int, seconds: float) -> bool:
	var is_best := money > get_best_money(ENDLESS_LEVEL) and not skill_win_pending
	if is_best:
		best_money[ENDLESS_LEVEL] = money
	record_rank(ENDLESS_LEVEL, money, "", seconds)
	return is_best


func is_completed(id: String) -> bool:
	return bool(completed.get(id, false))


## Quy tắc mở khóa: hoàn thành ngày N sẽ mở ngày N+1.
func is_unlocked(id: String) -> bool:
	var info: Dictionary = LEVELS.get(id, {})
	if info.is_empty():
		return false
	if unlock_all:
		return true
	var needs := str(info.get("needs", ""))
	return needs.is_empty() or is_completed(needs)


## Đường dẫn file map của một màn, lấy từ bảng LEVELS.
func scene_path(id: String) -> String:
	var info: Dictionary = LEVELS.get(id, {})
	return str(info.get("scene", ""))


## Đường dẫn scene NHÂN VẬT ĐIỀU KHIỂN ĐƯỢC của một id, lấy từ bảng CHARACTERS.
func character_scene_path(id: String) -> String:
	var info: Dictionary = CHARACTERS.get(id, {})
	return str(info.get("player", ""))


## ─────────────────────────────── XẾP HẠNG CUỐI MÀN ────────────────────────
const DEFAULT_THRESHOLDS := {"S": 1650, "A": 1300, "B": 950, "C": 600, "D": 400}

## Thứ tự xét, cao xuống thấp. Không lấy MOC_MAC_DINH.keys() vì thứ tự khoá
const RANK_ORDER := ["S", "A", "B", "C", "D"]

## Hạng thấp nhất coi là qua màn. (2/10/2026: C → D, khi thêm hạng D.)
const MIN_RANK := "D"


## Số khách bỏ về TỐI ĐA của một màn. 0 = màn không đặt giới hạn.
func max_left_for(level_id: String) -> int:
	return int(rules_for_level(level_id).get("max_left", 0))


## Xếp hạng một lượt chơi. Trả về "S"/"A"/"B"/"C"/"D", hoặc "" nếu chưa đạt.
func rank_for(level_id: String, money: int) -> String:
	var marks := rank_thresholds_for(level_id)
	for rank in RANK_ORDER:
		if money >= int(marks.get(rank, DEFAULT_THRESHOLDS[rank])):
			return rank
	return ""


## Mốc điểm của một màn, để bảng kết quả hiện "còn thiếu bao nhiêu nữa".
func rank_thresholds_for(level_id: String) -> Dictionary:
	return rules_for_level(level_id).get("rank_thresholds", DEFAULT_THRESHOLDS)


## Luật riêng của một màn, hoặc Dictionary rỗng nếu màn đó chưa có luật.
func rules_for_level(level_id: String) -> Dictionary:
	return LEVELS.get(level_id, {}).get("rules", {})


## Tên màn hiện ở màn hình mở đầu, ví dụ "NGÀY 1".
const DAY_NAMES := {
	"d1_sang": "NGÀY 1",
	"d2_sang": "NGÀY 2",
	"d3_sang": "NGÀY 3",
}

func level_name(id: String) -> String:
	if id == "tutorial":
		return Lang.t("HƯỚNG DẪN")
	if DAY_NAMES.has(id):
		return String(DAY_NAMES[id])
	return String(LEVELS.get(id, {}).get("label", "")).to_upper()


func get_best_money(id: String) -> int:
	return int(best_money.get(id, 0))


## Gọi khi người chơi hoàn thành một màn. Tự lưu game ngay.
func complete_level(id: String, earned: int = 0) -> void:
	if id == AAA_LEVEL:
		return
	completed[id] = true
	if earned > get_best_money(id) and not skill_win_pending:
		best_money[id] = earned
	progress_changed.emit()
	SaveSystem.save_game()


## Ghi lại nhân vật người chơi vừa chọn ở màn hình chọn nhân vật.
func set_selected_character(id: String) -> void:
	if not CHARACTERS.has(id):
		push_error("Không có nhân vật id '%s'." % id)
		return
	if is_character_locked(id):
		push_warning("Nhân vật '%s' đang khóa, không chọn được." % id)
		return
	selected_character = id
	progress_changed.emit()


## Bật/tắt cheat mở khóa toàn bộ màn chơi.
func set_unlock_all(value: bool) -> void:
	unlock_all = value
	progress_changed.emit()
	SaveSystem.save_game()


## Bật/tắt cheat dùng kĩ năng không cần điều kiện.
func set_infinite_skill(value: bool) -> void:
	infinite_skill = value
	progress_changed.emit()
	SaveSystem.save_game()


## Đường dẫn đoạn cut-in kĩ năng của một nhân vật.
func skill_cutscene_path(id: String) -> String:
	if id.is_empty():
		return ""
	return "res://assets/video/ki_nang/%s.ogv" % id


## Đường dẫn ảnh biểu tượng kĩ năng hiện trên HUD trong màn chơi.
func skill_icon_path(id: String) -> String:
	var list_: Array = CHARACTERS.get(id, {}).get("skills", [])
	if not list_.is_empty():
		var name_ := str((list_[0] as Dictionary).get("icon", ""))
		if not name_.is_empty():
			var path := "res://assets/ui/ki_nang/%s.png" % name_
			if ResourceLoader.exists(path):
				return path
			push_warning("Thiếu ảnh kĩ năng: %s" % path)
	return "res://assets/ui/ki_nang/mac_dinh.png"


## Bật/tắt quyền dùng góc nhìn thứ 3.
func set_third_person_unlocked(value: bool) -> void:
	third_person_unlocked = value
	if not value and third_person_active:
		set_third_person_active(false)
	progress_changed.emit()
	SaveSystem.save_game()


## Bật/tắt một nhân vật ẩn.
func set_character_unlocked(id: String, value: bool) -> void:
	if not HIDDEN_CHARACTERS.has(id):
		return
	unlocked_characters[id] = value
	if not value and selected_character == id:
		selected_character = ""
	if not value:
		intro_seen.erase(id)
	progress_changed.emit()
	SaveSystem.save_game()


## Giữ tên cũ cho bảng CODE No.7 khỏi phải đổi.
func set_golshi_unlocked(value: bool) -> void:
	set_character_unlocked("golshi", value)


## Đổi góc nhìn. Không có quyền thì không làm gì — kiểm tra ở đây một lần
func toggle_view_mode() -> void:
	if not third_person_unlocked:
		return
	set_third_person_active(not third_person_active)


func set_third_person_active(value: bool) -> void:
	third_person_active = value
	view_mode_changed.emit(value)


## ── MÀN KHÔNG CHỌN NHÂN VẬT (1/10/2026) ─────────────────────────────────
const STORY_CHARACTER := "kitamoi"
const LEVELS_WITHOUT_CHARACTER_SELECT := ["prologue", "tutorial", "ending"]

## Màn đầu tiên sau phần giới thiệu — nơi người chơi chọn nhân vật lần đầu.
const FIRST_REAL_LEVEL := "d1_sang"


func needs_character_select(id: String) -> bool:
	return not LEVELS_WITHOUT_CHARACTER_SELECT.has(id)


## Vào thẳng một màn giới thiệu: gán nhân vật dẫn truyện rồi trả scene cần nạp.
func start_story_level(id: String) -> String:
	current_level = id
	if id != ENDING_LEVEL:
		selected_character = STORY_CHARACTER
	return enter_level(id)


# ══════════════════════════════════════════════ HAI KẾT (2/10/2026)
const ENDING_LEVEL := "ending"

## Ba ngày phải đạt hạng S ở LƯỢT GẦN NHẤT thì mới ra kết ẩn.
const SECRET_ENDING_LEVELS := ["d1_sang", "d2_sang", "d3_sang"]
const SECRET_ENDING_RANK := "S"

## Hạng của lượt chơi GẦN NHẤT ở từng màn: id -> "S"/"A"/.../"" (trượt).
var last_rank: Dictionary = {}


## Kết ẩn có đủ điều kiện không: lượt gần nhất của CẢ ba ngày đều hạng S.
func secret_ending_unlocked() -> bool:
	for id in SECRET_ENDING_LEVELS:
		if String(last_rank.get(id, "")) != SECRET_ENDING_RANK:
			return false
	return true


## Scene của màn kết sẽ chiếu NGAY BÂY GIỜ. Xét lúc bấm chứ không lưu sẵn
func ending_scene() -> String:
	if cheat_force_secret_ending or secret_ending_unlocked():
		return SCENE_ENDING_SECRET
	return SCENE_ENDING_NORMAL


## CHEAT: ép nút Ending luôn chiếu kết ẩn, không cần ba chữ S. Chỉ để kiểm
var cheat_force_secret_ending: bool = false


## Những nhân vật ẩn ĐÃ RA MẮT (đoạn giới thiệu của họ đã chiếu), theo thứ tự
func hidden_cast_seen() -> Array[String]:
	var cast: Array[String] = []
	for id in HIDDEN_CHARACTERS:
		if bool(intro_seen.get(String(id), false)):
			cast.append(String(id))
	return cast


## Màn này có phải chỉ để kể chuyện không (không có gameplay).
func is_story_level(id: String) -> bool:
	return bool(LEVELS.get(id, {}).get("story_only", false))


## Scene cần nạp để VÀO màn `id` — tự chen đoạn cắt cảnh nếu tới lượt.
func enter_level(id: String) -> String:
	if id == ENDING_LEVEL:
		return ending_scene()
	var target := scene_path(id)
	if target.is_empty():
		return ""
	if id == AAA_LEVEL:
		if _meeting_shown_for != id:
			_meeting_shown_for = id
			return AAA_INTRO_SCENE
		_meeting_shown_for = ""
		return target

	var who := String(selected_character)
	if INTRO_SCENES.has(who) \
			and is_character_unlocked(who) \
			and not bool(intro_seen.get(who, false)) \
			and not is_story_level(id):
		intro_seen[who] = true
		SaveSystem.save_game()
		_meeting_shown_for = id
		return String(INTRO_SCENES[who])

	if needs_character_select(id) and not is_story_level(id) \
			and id != ENDLESS_LEVEL and id != ASIAN_LEVEL and _meeting_shown_for != id:
		_meeting_shown_for = id
		return KITCHEN_MEETING_SCENE

	_meeting_shown_for = ""
	return target


## Đoạn hội ý "ai đứng bếp" chiếu trước mỗi ngày. Xem enter_level().
const KITCHEN_MEETING_SCENE := "res://scenes/story/kitchen_meeting.tscn"

## Màn vừa được chiếu đoạn hội ý (hoặc đoạn ra mắt nhân vật ẩn). Rỗng = chưa.
var _meeting_shown_for := ""


signal shop_coins_changed(total: int)

## 10% doanh thu trên bảng tổng kết, bỏ phần lẻ (user chốt 29/10/2026).
const SHOP_RATE := 0.1

## Giá tạm chốt 29/10/2026. Mốc giá bám theo tiến trình: góc nhìn thứ 3 mua
const SHOP_ITEMS := {
	"third_person": {"price": 150, "name": "Góc nhìn thứ 3", "icon": "",
		"desc": "Bấm P trong màn chơi để đổi sang camera bám sau lưng nhân vật."},
	"hachimi": {"price": 400, "name": "Tokai Teio", "icon": "res://assets/ui/characters/hachimi.png",
		"hidden_name": "Nhân tố T", "hidden_icon": "res://assets/ui/characters/thidden.png",
		"desc": "Một thành viên bí ẩn của team 0rca."},
	"chiyo": {"price": 600, "name": "Sakura Chiyono O", "icon": "res://assets/ui/characters/chiyo.png",
		"hidden_name": "Nhân tố C", "hidden_icon": "res://assets/ui/characters/chidden.png",
		"desc": "Một thành viên bí ẩn khác của team 0rca."},
}
const SHOP_ORDER := ["third_person", "hachimi", "chiyo"]

var shop_coins: int = 0

# ── Ngoại trang (skin) ──────────────────────────────────────────────────
const SKIN_PRICE := 250
const SKINS := {
	"kita_white": {"character": "kitamoi", "name": "Kitasan Black — Trắng"},
	"teio_anime": {"character": "hachimi", "name": "Tokai Teio — Anime",
		"hidden_name": "Ngoại trang Nhân tố T", "need": "Cần mở Nhân tố T"},
	"chiyono_dress": {"character": "chiyo", "name": "Sakura Chiyono O — Váy",
		"hidden_name": "Ngoại trang Nhân tố C", "need": "Cần mở Nhân tố C"},
	"mambo_race": {"character": "mambo", "name": "Matikanetannhauser — Đua"},
	"oguri_xmas": {"character": "oui", "name": "Oguri Cap — Giáng sinh"},
	"spe_commander": {"character": "tuandb", "name": "Special Week — Chỉ huy"},
	"golshi_summer": {"character": "golshi", "name": "Gold Ship — Mùa hè"},
}
const SKIN_ORDER := ["kita_white", "teio_anime", "chiyono_dress", "mambo_race",
	"oguri_xmas", "spe_commander", "golshi_summer"]
const SKIN_DIR := "res://assets/models/skins/"

## skin_id -> true khi đã mua.
var owned_skins: Dictionary = {}
## character_id -> skin_id đang mặc. Không có khoá = mặc đồ gốc.
var equipped_skins: Dictionary = {}


func skin_model_path(skin_id: String) -> String:
	return SKIN_DIR + skin_id + ".glb"


## Skin chỉ mua được khi đã có nhân vật: mua đồ cho nhân vật còn khoá thì
func skin_available(skin_id: String) -> bool:
	return not is_character_locked(String(SKINS[skin_id]["character"]))


## Skin có HIỆN trong shop không. Skin của nhân vật đang khoá vẫn hiện (dạng
func skin_visible(skin_id: String) -> bool:
	return skin_available(skin_id) or SKINS[skin_id].has("hidden_name")


func buy_skin(skin_id: String) -> bool:
	if not SKINS.has(skin_id) or owned_skins.has(skin_id) or not skin_available(skin_id):
		return false
	if shop_coins < SKIN_PRICE:
		return false
	shop_coins -= SKIN_PRICE
	owned_skins[skin_id] = true
	equipped_skins[String(SKINS[skin_id]["character"])] = skin_id
	shop_coins_changed.emit(shop_coins)
	SaveSystem.save_game()
	return true


## Bật/tắt skin cho nhân vật của nó. Gọi lại với skin đang mặc = cởi ra.
func toggle_skin(skin_id: String) -> void:
	if not owned_skins.has(skin_id):
		return
	var ch := String(SKINS[skin_id]["character"])
	if String(equipped_skins.get(ch, "")) == skin_id:
		equipped_skins.erase(ch)
	else:
		equipped_skins[ch] = skin_id
	SaveSystem.save_game()


## Đường dẫn model nhân vật sẽ mặc; "" = dùng model gốc trong scene nhân vật.
func equipped_model_for(character_id: String) -> String:
	var skin := String(equipped_skins.get(character_id, ""))
	if skin.is_empty() or not owned_skins.has(skin):
		return ""
	return skin_model_path(skin)


## Số tiền shop nhận được từ một doanh thu. floori chứ không int(): doanh thu
func shop_reward_for(money: int) -> int:
	return floori(float(maxi(money, 0)) * SHOP_RATE)


## Cộng tiền shop từ một lượt chơi, lưu ngay, trả về số vừa cộng để bảng tổng
func award_shop_coins(money: int) -> int:
	var gain := shop_reward_for(money)
	if gain <= 0:
		return 0
	shop_coins += gain
	shop_coins_changed.emit(shop_coins)
	SaveSystem.save_game()
	return gain


## Cộng thẳng một số tiền shop (không qua tỉ lệ 10%). Chỉ bảng CODE No.7 gọi,
func add_shop_coins(amount: int) -> void:
	shop_coins = maxi(shop_coins + amount, 0)
	shop_coins_changed.emit(shop_coins)
	SaveSystem.save_game()


func shop_owned(item: String) -> bool:
	if item == "third_person":
		return third_person_unlocked
	return is_character_unlocked(item)


## Trả về true nếu mua thành công. Kiểm tra đủ ba điều kiện Ở ĐÂY chứ không
func buy_shop_item(item: String) -> bool:
	if not SHOP_ITEMS.has(item) or shop_owned(item):
		return false
	var price := int(SHOP_ITEMS[item]["price"])
	if shop_coins < price:
		return false
	shop_coins -= price
	if item == "third_person":
		set_third_person_unlocked(true)
	else:
		set_character_unlocked(item, true)
	shop_coins_changed.emit(shop_coins)
	SaveSystem.save_game()
	return true


## Xóa sạch tiến trình, quay về trạng thái mới cài.
func reset() -> void:
	shop_coins = 0
	owned_skins.clear()
	equipped_skins.clear()
	completed.clear()
	best_money.clear()
	current_level = ""
	selected_character = ""
	unlock_all = false
	third_person_unlocked = false
	third_person_active = false
	infinite_skill = false
	unlocked_characters.clear()
	intro_seen.clear()
	leaderboard.clear()
	last_rank.clear()
	cheat_time_skip = false
	cheat_free_ingredients = false
	progress_changed.emit()


func to_dict() -> Dictionary:
	return {
		"completed": completed,
		"best_money": best_money,
		"selected_character": selected_character,
		"unlock_all": unlock_all,
		"third_person_unlocked": third_person_unlocked,
		"infinite_skill": infinite_skill,
		"unlocked_characters": unlocked_characters,
		"intro_seen": intro_seen,
		"leaderboard": leaderboard,
		"last_rank": last_rank,
		"cheat_time_skip": cheat_time_skip,
		"cheat_free_ingredients": cheat_free_ingredients,
		"shop_coins": shop_coins,
		"owned_skins": owned_skins,
		"equipped_skins": equipped_skins,
	}


## Đọc khoá TIẾNG ANH trước, nếu không có thì đọc khoá TIẾNG VIỆT cũ.
func from_dict(data: Dictionary) -> void:
	var c: Variant = data.get("completed", {})
	completed = c if c is Dictionary else {}
	var b: Variant = data.get("best_money", {})
	best_money = b if b is Dictionary else {}
	selected_character = str(data.get("selected_character", ""))
	unlock_all = bool(data.get("unlock_all", false))
	third_person_unlocked = bool(data.get("third_person_unlocked", false))
	infinite_skill = bool(data.get("infinite_skill", data.get("ki_nang_vo_han", false)))
	var unlocked_raw: Variant = data.get("unlocked_characters", data.get("nhan_vat_mo", {}))
	unlocked_characters = unlocked_raw if unlocked_raw is Dictionary else {}
	if bool(data.get("golshi_unlocked", false)):
		unlocked_characters["golshi"] = true
	var seen_raw: Variant = data.get("intro_seen", data.get("da_gioi_thieu", {}))
	intro_seen = seen_raw if seen_raw is Dictionary else {}
	var board_raw: Variant = data.get("leaderboard", data.get("bang_xep_hang", {}))
	leaderboard = board_raw if board_raw is Dictionary else {}
	var last_raw: Variant = data.get("last_rank", {})
	last_rank = last_raw if last_raw is Dictionary else {}
	cheat_time_skip = bool(data.get("cheat_time_skip", data.get("cheat_tua_gio", false)))
	shop_coins = maxi(int(data.get("shop_coins", 0)), 0)
	var os_raw: Variant = data.get("owned_skins", {})
	owned_skins = os_raw if os_raw is Dictionary else {}
	var es_raw: Variant = data.get("equipped_skins", {})
	equipped_skins = es_raw if es_raw is Dictionary else {}
	cheat_free_ingredients = bool(data.get("cheat_free_ingredients", false))
	if bool(data.get("golshi_da_gioi_thieu", false)):
		intro_seen["golshi"] = true
	if selected_character == "locked_1":
		selected_character = ""
	progress_changed.emit()
