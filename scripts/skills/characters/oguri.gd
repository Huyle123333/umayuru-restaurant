extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA OGURI CAP — sửa số ở ĐÂY                                ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd: MỘT nhân vật, MỘT file; sửa số rồi chạy lại game.
## NHỚ SỬA KÈM câu mô tả trong GameData.CHARACTERS["oui"]["skills"].
##
## Thế mạnh của Oguri là THỜI GIAN: dừng được đồng hồ, và chạy nhanh gần như
## liên tục.


# ═══════════════════════════════ CHỦ ĐỘNG: Triumphant Pulse Lv11 (Space)
#
# "Điều kiện: màn chơi trôi qua 4 phút. Bật/tắt bằng phím Space. Khi bật:
#  đồng hồ màn, khách hàng và thanh kiên nhẫn đứng im; nhân vật và khu bếp vẫn
#  hoạt động. Tổng cộng 30 giây cho cả màn."
#
# (4/10/2026) User chốt giữ CỐ ĐỊNH 4 phút dù ba ngày giờ dài 5 / 6 / 7 phút.
# Hệ quả: Ngày 1 chỉ còn 1 phút cuối để dùng, Ngày 3 còn 3 phút — kĩ năng
# mạnh dần theo ngày. Đổi "threshold" (giây) nếu muốn mở sớm hơn.
#
# Kĩ năng BẬT/TẮT ("toggle"): không có "uses" — thứ giới hạn nó là ngân sách
# "budget_seconds", trừ dần trong lúc đang bật.
const ACTIVE := {
	"name": "Triumphant Pulse",
	"condition": "time_elapsed",       # Registry.COND_TIME_ELAPSED
	"threshold": 240,                  # giây đã trôi của màn
	"toggle": true,
	"budget_seconds": 30.0,
	"script": "res://scripts/skills/effects/time_stop.gd",
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Alo vũ à vũ ───────────────────────────────────────────────────
	# "Các món pizza tăng 60% giá trị."
	#
	# Ngày 1 không có pizza nên kĩ năng này chưa có tác dụng ở đó (user chốt
	# giữ nguyên); Ngày 2 có một loại, Ngày 3 có cả ba.
	"dish_price_factors": {
		"pizza_cheese": 1.6,
		"pizza_mushroom": 1.6,
		"pizza_peperoni": 1.6,
	},

	# ── Hốc trưởng ────────────────────────────────────────────────────
	# "Mỗi lần giao xong một đơn, thanh chạy nhanh đầy lại ngay."
	#
	# (4/10/2026) User chốt là BỊ ĐỘNG — bản chốt cũ ghi chủ động phím Z.
	"refill_stamina_on_order": true,
}
