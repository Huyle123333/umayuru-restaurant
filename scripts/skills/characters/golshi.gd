extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA GOLD SHIP — sửa số ở ĐÂY                                ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd. NHỚ SỬA KÈM câu mô tả trong
## GameData.CHARACTERS["golshi"]["skills"].
##
## Nhân vật ẩn — cố ý PHÁ CÂN BẰNG, và cố ý vô lý: giao gì cũng hoàn hảo, nấu
## gì cũng có thể hỏng, và đủ một vòng thực đơn là thắng luôn.


# ═══════════════════════════ CHỦ ĐỘNG: Anchors Aweigh! Lv999 (Space)
#
# "Điều kiện: mỗi món trong thực đơn đã được hoàn thành hoàn hảo ít nhất một
#  lần. Nhận ngay 9.999.999 tiền và kết thúc màn chơi."
#
# KHÔNG khai "threshold": ngưỡng là số món của thực đơn hôm đó, quan_ly tự
# đếm (xem _threshold() trong skill_manager.gd).
#
# (5/10/2026) User chốt luật xếp hạng: lượt THẮNG BẰNG KĨ NĂNG NÀY chỉ lên
# bảng xếp hạng MỘT lần cho mỗi màn, ở hạng 0; dùng lại không được xếp nữa trừ
# khi xoá dữ liệu. Gold Ship chơi không bấm kĩ năng thì xếp hạng bình thường.
# Luật đó nằm ở GameData.record_rank().
const ACTIVE := {
	"name": "Anchors Aweigh!",
	"condition": "menu_covered",       # Registry.COND_MENU_COVERED
	"script": "res://scripts/skills/effects/anchors_aweigh.gd",
	"uses": 1,

	"reward_money": 9999999,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Aura farming ──────────────────────────────────────────────────
	# "Mọi đơn giao ra đều được tính là hoàn hảo, bất kể thanh kiên nhẫn."
	"force_perfect": true,

	# ── Everything but cooking ────────────────────────────────────────
	# "Mọi thao tác nấu (bếp, lò nướng, bàn chế tạo) có 20% tỉ lệ thất bại."
	#
	# (5/10/2026) User chốt: thất bại = ra đồ hỏng, MẤT nguyên liệu.
	"cook_fail_chance": 0.2,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
## và các bảng chốt sau đó). Chỉ ghi những khoá KHÁC bản thường; skill_registry
## trộn đè lên ACTIVE / PASSIVE / SECONDARY khi GameData.is_asian_mode().
## Gold Ship ở Asian là nhân vật RỦI RO CAO, LỢI NHUẬN CAO (user chốt 27/10).
## Ba khoá "start_lives" / "overflow_life_money" / "streak_counts_forced" chỉ
## asian_mode.gd đọc; skill_manager bỏ qua khoá nó không biết.
const ASIAN := {
	"active": {"reward_money": 1000, "restore_lives": 3, "end_level": false},
	"passive": {
		"cook_fail_chance": 0.3,
		"start_lives": 1,
		"overflow_life_money": 250,
		"streak_counts_forced": true,
	},
}
