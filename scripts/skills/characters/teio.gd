extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA TOKAI TEIO — sửa số ở ĐÂY                               ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd: MỘT nhân vật, MỘT file; sửa số rồi chạy lại game.
## NHỚ SỬA KÈM câu mô tả trong GameData.CHARACTERS["hachimi"]["skills"].
##
## Nhân vật ẩn — cố ý PHÁ CÂN BẰNG (mục 6 tài liệu kĩ năng). Thế mạnh của Teio
## là THỜI GIAN: màn chơi dài ra theo từng đơn, và có sáu món "từ trên trời rơi
## xuống" để gỡ những lúc bí.

const ICECREAMS := ["icecream_vani", "icecream_chocolate", "icecream_strawberry",
	"kem_tam_hop", "kem_tam_hop_que"]


# ═══════════════════════════ CHỦ ĐỘNG: Sky-High Teio Step Lv3 (Space)
#
# "Điều kiện: có 1500 tiền. Từ đó tới hết màn, mỗi lần hoàn thành đơn sẽ +10
#  giây vào bộ đếm thời gian."
#
# Điều kiện đọc số tiền ĐANG CÓ trong ví (con số người chơi nhìn thấy trên
# HUD), không phải tổng đã thu: hai con số lệch nhau đúng bằng tiền nguyên
# liệu, và người chơi chỉ nhìn thấy một trong hai.
const ACTIVE := {
	"name": "Sky-High Teio Step",
	"condition": "money_earned",       # Registry.COND_MONEY_EARNED
	"threshold": 1500,
	"script": "res://scripts/skills/effects/time_bonus.gd",
	"uses": 1,

	## Mỗi đơn GIAO XONG cộng bấy nhiêu giây vào đồng hồ màn.
	"bonus_seconds": 10.0,
}


# ════════════════════════════════ CHỦ ĐỘNG THỨ HAI: Fan tê liệt (phím 3)
#
# "Mở một bảng chọn 1 món có trong thực đơn; nhận ngay món đó trên tay. Tối
#  đa 6 lần mỗi màn."
#
# Không có điều kiện, không có phim cut-in — dùng được ngay từ đầu màn.
const SECONDARY := {
	"name": "Fan tê liệt",
	"script": "res://scripts/skills/dish_picker.gd",
	"uses": 6,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Tưởng tày nhưng không ─────────────────────────────────────────
	# "Các món kem tăng 60% giá trị nhưng giảm 50% tỉ lệ khách gọi món kem."
	"dish_price_factors": {
		"icecream_vani": 1.6,
		"icecream_chocolate": 1.6,
		"icecream_strawberry": 1.6,
		"kem_tam_hop": 1.6,
		"kem_tam_hop_que": 1.6,
	},
	"dish_weight_factors": {
		"icecream_vani": 0.5,
		"icecream_chocolate": 0.5,
		"icecream_strawberry": 0.5,
		"kem_tam_hop": 0.5,
		"kem_tam_hop_que": 0.5,
	},
}
