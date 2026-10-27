extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA SPECIAL WEEK — sửa số ở ĐÂY                             ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## Cùng quy ước với kita.gd: MỘT nhân vật, MỘT file; sửa số rồi chạy lại game.
## NHỚ SỬA KÈM câu mô tả trong GameData.CHARACTERS["tuandb"]["skills"] — chữ
## người chơi đọc nằm ở đó và không tự đồng bộ với file này.
##
## Thế mạnh của Special Week là THỊT: mọi thứ ở đây xoay quanh ham và steak.
##
## Không preload skill_registry.gd (tham chiếu vòng — xem kita.gd), nên hai
## khoá "condition" và "effect" viết thẳng chuỗi, chép từ skill_registry.gd.

## Các món BÁN ĐƯỢC có ham hoặc steak bên trong. Dùng cho CẢ hai việc: đếm
## điều kiện (đơn khách gọi một trong các món này) và danh sách món thế chỗ
## khi kĩ năng bật. Một danh sách cho hai việc là cố ý — người chơi chỉ phải
## nhớ MỘT nhóm "món thịt".
##
## Chả rau củ tính là món steak vì nó nắn từ steak thái (xem TABLE_RECIPES).
const MEAT_DISHES := [
	"mon_ham", "mon_steak", "hambuger",
	"vegetablesteak", "vegetablebuger", "dinner",
]


# ═══════════════════════════════════ CHỦ ĐỘNG: Shooting Star Lv24 (Space)
#
# "Điều kiện: giao xong 5 đơn có ham hoặc steak. Trong thời gian còn lại của
#  màn chơi, các món có ham hoặc steak giao được cho MỌI đơn, kể cả khi khách
#  gọi món khác. Tiền nhận tính theo giá của món bạn giao."
#
# (4/10/2026) Điều kiện đếm ĐƠN ĐÃ GIAO, theo yêu cầu user để thử nghiệm.
# Bản chốt 5/9 từng bác cách này vì phụ thuộc may rủi của hàng đơn (lúc đó
# thực đơn chỉ có 2 món steak) — nay nhóm món thịt đã rộng tới 6 món nên xác
# suất gặp cao hơn nhiều. Nếu thử thấy mở quá muộn, đổi "condition" sang một
# kiểu đếm món nấu ra và giữ nguyên phần còn lại.
#
# Tiền theo MÓN ĐÃ GIAO chứ không theo món khách gọi: kĩ năng này là lưới cứu
# khách (không ai phải bỏ về vì món khó), không phải cách đổi món rẻ lấy tiền
# món đắt.
const ACTIVE := {
	"name": "Shooting Star",
	"condition": "orders_with_dishes",   # Registry.COND_ORDERS_WITH_DISHES
	"dishes": MEAT_DISHES,
	"threshold": 5,
	"effect": "wildcard_dishes",         # Registry.FX_WILDCARD_DISHES
	"wildcard_dishes": MEAT_DISHES,
	"uses": 1,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Độc tày Spe-chan ──────────────────────────────────────────────
	# "Ham, steak và chả rau củ nấu trên bếp nhanh hơn 4 giây (8 → 4 giây)."
	#
	# Khai theo NGUYÊN LIỆU ĐẶT LÊN BẾP (id lúc còn sống), vì đó là thứ cái
	# bếp nhìn thấy. Quãng chờ trước khi cháy giữ nguyên như nấu thường.
	"cook_time_cut": 4.0,
	"cook_time_cut_items": ["ham", "steak_uncook", "vegetablebuger_uncook"],

	# ── Hốc phó ───────────────────────────────────────────────────────
	# "Mỗi đơn giao ra có 20% cơ hội được trả gấp 3."
	#
	# (4/10/2026) User chốt là BỊ ĐỘNG, áp cho mọi đơn — bản chốt cũ ghi là
	# chủ động phím Z. Giá trị kỳ vọng: 0,2 × 3 + 0,8 × 1 = 1,4, tức trung
	# bình +40% doanh thu, nhưng đến theo từng cú may chứ không đều.
	"bonus_payout_chance": 0.20,
	"bonus_payout_multiplier": 3.0,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
## và các bảng chốt sau đó). Chỉ ghi những khoá KHÁC bản thường; skill_registry
## trộn đè lên ACTIVE / PASSIVE / SECONDARY khi GameData.is_asian_mode().
const ASIAN := {
	"active": {"threshold": 8},
	"passive": {"cook_time_cut": 2.0, "bonus_payout_chance": 0.10},
}
