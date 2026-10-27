extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA MATIKANETANNHAUSER (MAMBO) — sửa số ở ĐÂY               ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd: MỘT nhân vật, MỘT file; sửa số rồi chạy lại game.
## NHỚ SỬA KÈM câu mô tả trong GameData.CHARACTERS["mambo"]["skills"].
##
## Thế mạnh của Mambo là BẾP LÒ và PIZZA — và một chút hên xui.

const PIZZAS := ["pizza_cheese", "pizza_mushroom", "pizza_peperoni"]


# ═════════════════════════════════ CHỦ ĐỘNG: Go, Go, Mun! Lv120 (Space)
#
# "Điều kiện: hoàn thành 15 đơn. Trong thời gian còn lại của màn chơi, đơn
#  pizza hoàn hảo có 36% nhân ba giá trị, 18% nhân đôi, còn lại giá thường.
#  Đổi lại: trong lúc di chuyển, mỗi giây có 3% bị choáng đứng yên 2 giây."
#
# (4/10/2026) User chốt giữ 15 ĐƠN. Với Ngày 1 dài 5 phút, mốc này rơi vào
# gần cuối màn, nên ở đó phần thưởng pizza chỉ kịp ăn vài đơn cuối.
#
# Giá trị kỳ vọng của một đơn pizza hoàn hảo khi kĩ năng bật:
#     0,36 × 3 + 0,18 × 2 + 0,46 × 1 = 1,90 lần giá thường.
const ACTIVE := {
	"name": "Go, Go, Mun!",
	"condition": "orders_done",        # Registry.COND_ORDERS_DONE
	"threshold": 15,
	"script": "res://scripts/skills/effects/go_go_mun.gd",
	"uses": 1,

	## Bảng gieo cho đơn HOÀN HẢO của các món trong "dishes".
	## Mỗi dòng "rolls" là [xác suất, hệ số]; gieo một lần cho cả bảng.
	"perfect_roll": {
		"dishes": PIZZAS,
		"rolls": [[0.36, 3.0], [0.18, 2.0]],
	},
	## Mỗi GIÂY đang di chuyển có bấy nhiêu xác suất bị choáng.
	"stun_chance_per_second": 0.03,
	## Choáng đứng yên bao lâu.
	"stun_seconds": 2.0,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Mambo tongye ──────────────────────────────────────────────────
	# "Thời gian nấu trên bếp và lò nướng −4 giây (bếp 8 → 4, lò 11 → 7)."
	#
	# "*" = mọi thứ đặt lên bếp (ham, steak, chả rau củ, nồi canh). Rộng hơn
	# kĩ năng của Special Week, vốn chỉ bớt giờ cho món thịt.
	"cook_time_cut": 4.0,
	"cook_time_cut_items": ["*"],
	"bake_time_cut": 4.0,

	# ── Vua làm nền ───────────────────────────────────────────────────
	# "Khách gọi pizza nhiều hơn 20%."
	#
	# (4/10/2026) User chốt cách hiểu: nhân 1,2 vào TRỌNG SỐ bốc của ba loại
	# pizza. Pizza nằm trong nhóm món "trung bình", nên tác dụng thật là pizza
	# chiếm phần lớn hơn TRONG nhóm đó — nhỏ, khó nhận ra bằng mắt.
	"dish_weight_factors": {
		"pizza_cheese": 1.2,
		"pizza_mushroom": 1.2,
		"pizza_peperoni": 1.2,
	},
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
## và các bảng chốt sau đó). Chỉ ghi những khoá KHÁC bản thường; skill_registry
## trộn đè lên ACTIVE / PASSIVE / SECONDARY khi GameData.is_asian_mode().
const ASIAN := {
	"active": {"threshold": 20},
	"passive": {"cook_time_cut": 2.0, "bake_time_cut": 2.0},
}
