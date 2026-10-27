extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA SAKURA CHIYONO O — sửa số ở ĐÂY                         ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd. NHỚ SỬA KÈM câu mô tả trong
## GameData.CHARACTERS["chiyo"]["skills"].
##
## Nhân vật ẩn — cố ý PHÁ CÂN BẰNG. Mọi thứ của Chiyono O chạy nhanh hơn và
## đắt hơn, và cô có thể bắt đầu lại màn bao nhiêu lần tuỳ thích.


# ════════════════ CHỦ ĐỘNG: Ambition to Surpass the Sakura Lv76 (Space)
#
# "Điều kiện: hoàn thành 10 đơn. Đặt lại bộ đếm thời gian và hàng đợi khách
#  về đầu màn, giữ nguyên số tiền đã kiếm. Không giới hạn số lần dùng."
#
# (5/10/2026) User chốt: lúc đặt lại thì XOÁ TOÀN BỘ khách, cả người đang ngồi
# bàn; không ai bị tính là bỏ về.
#
# "repeat": true = mười đơn đếm LẠI TỪ ĐẦU sau mỗi lần dùng. Không có khoá này
# thì đủ mười đơn một lần là bấm được mãi mãi.
const ACTIVE := {
	"name": "Ambition to Surpass the Sakura",
	"condition": "orders_done",        # Registry.COND_ORDERS_DONE
	"threshold": 10,
	"script": "res://scripts/skills/effects/level_reset.gd",
	"repeat": true,
	## "Không giới hạn": một con số không ai chạm tới được trong một màn.
	"uses": 9999,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Cute puppy ────────────────────────────────────────────────────
	# "Giá trị của tất cả món ăn +50%."
	"all_price_factor": 1.5,

	# ── Made in haven ─────────────────────────────────────────────────
	# "Bộ đếm thời gian màn chơi, thời gian nấu, tốc độ khách đến và thanh
	#  kiên nhẫn đều chạy nhanh hơn 25%."
	#
	# MỘT con số cho cả bốn thứ: chúng phải nhanh lên CÙNG NHAU thì mới đúng là
	# "thời gian trôi nhanh hơn". Tách bốn núm thì sớm muộn có người vặn lệch,
	# và bếp chạy nhanh trong khi khách vẫn thong thả.
	"time_scale": 1.25,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
## và các bảng chốt sau đó). Chỉ ghi những khoá KHÁC bản thường; skill_registry
## trộn đè lên ACTIVE / PASSIVE / SECONDARY khi GameData.is_asian_mode().
const ASIAN := {
	# Đặt lại đồng hồ 10 phút = bắt chơi lại từ đầu, nên ở Asian kĩ năng CHỈ
	# cho khách ra về (level_reset.gd tự bỏ phần đồng hồ). Một lần mỗi màn.
	"active": {"threshold": 15, "repeat": false, "uses": 1},
	"passive": {"all_price_factor": 1.25},
}
