extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  SỔ ĐĂNG KÍ KĨ NĂNG — nối id nhân vật với file kĩ năng của họ         ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## File này KHÔNG chứa con số nào. Nó chỉ có ba thứ:
##   1. Bảng SKILL_FILES: id nhân vật → file kĩ năng trong nhan_vat/
##   2. Tên các LOẠI điều kiện (DK_*) và LOẠI hiệu ứng (HU_*) dùng chung
##   3. Bộ số GỐC dùng cho nhân vật chưa có kĩ năng
##
## ─────────────────────────────────── VÌ SAO MỖI NHÂN VẬT MỘT FILE
##
## Bản đầu gom số của cả bảy người vào một bảng, lý do là để so sánh sức mạnh
## giữa các nhân vật — mục 6 tài liệu yêu cầu bốn nhân vật chính cân bằng
## ngang nhau, mà muốn so thì phải nhìn cùng lúc.
##
## Người làm đồ án đã bỏ ràng buộc đó (15/9/2026): chỉnh theo cảm giác chơi,
## không theo một bảng cân bằng. Khi so sánh chéo không còn là việc thường
## xuyên nữa thì lợi thế của bảng gộp mất, còn bất lợi thì vẫn nguyên: một
## file dài dần theo số nhân vật, và mỗi lần sửa Kita vẫn phải cuộn qua sáu
## người khác.
##
## Tách file thì mỗi lần chỉnh chỉ mở đúng một file, nhật ký git nói rõ "sửa
## kĩ năng của ai", và thêm nhân vật mới là THÊM một file chứ không SỬA một
## file đang có.
##
## ────────────────────────────────────────── BA KIỂU FILE TRONG THƯ MỤC NÀY
##
##   skill_registry.gd      — file này: sổ đăng kí, không có số
##   nhan_vat/<ten>.gd    — SỐ của từng nhân vật (ACTIVE + PASSIVE)
##   hieu_ung/<ten>.gd    — CƠ CHẾ của những kĩ năng phức tạp; xem
##                          effects/_template.gd để biết cách viết một cái mới
##
## Kĩ năng chỉ đổi một con số của hệ khác (cả ba kĩ năng của Kita) KHÔNG cần
## file trong hieu_ung/ — chúng dùng hiệu ứng có sẵn HU_* ở dưới.


# ═══════════════════════════════════════════════ ĐIỀU KIỆN KĨ NĂNG CHỦ ĐỘNG
#
# Dùng hằng CHUỖI chứ không dùng enum vì các file nhân vật là Dictionary —
# enum ghi vào Dictionary thành số, và đọc file dữ liệu mà thấy
# `"condition": 2` thì phải lật ngược lên đây mới biết 2 là gì.

## Đếm số ĐƠN HOÀN HẢO đã giao. (Kita — Victory Cheer!)
const COND_PERFECT_ORDERS := "perfect_orders"
## Đếm số đơn đã hoàn thành, hoàn hảo hay không. (Mambo, Chiyono O)
const COND_ORDERS_DONE := "orders_done"
## Đếm số đơn ĐÃ GIAO mà món khách gọi thuộc một nhóm món. Nhóm khai ở khoá
## "dishes" của ACTIVE. (Special Week — Shooting Star)
const COND_ORDERS_WITH_DISHES := "orders_with_dishes"
## Đếm số MÓN đã nấu xong thuộc một nhóm. (Mambo — chưa cài)
const COND_DISHES_COOKED := "dishes_cooked"
## Đếm giây đã trôi của màn chơi. (Oguri Cap — Triumphant Pulse)
const COND_TIME_ELAPSED := "time_elapsed"
## Số tiền đang có trong ví. (Tokai Teio — Sky-High Teio Step)
const COND_MONEY_EARNED := "money_earned"
## Mọi món trong thực đơn đã hoàn hảo ít nhất một lần. Ngưỡng tự lấy bằng số
## món của thực đơn hôm đó, không khai "threshold". (Gold Ship — Anchors Aweigh!)
const COND_MENU_COVERED := "menu_covered"


# ═══════════════════════════════════════ HIỆU ỨNG CÓ SẴN (KHÔNG CẦN FILE)
#
# Những hiệu ứng chỉ là "bật một cờ" hoặc "đổi một con số" của hệ khác.
# quan_ly_ki_nang thi hành thẳng, không nạp file nào.
#
# Cần gì phức tạp hơn thì viết một file trong hieu_ung/ và khai khoá "script"
# thay cho "effect" — xem effects/_template.gd.

## Mọi đơn giao ra tính là hoàn hảo bất kể thanh kiên nhẫn. (Kita)
const FX_FORCE_PERFECT := "force_perfect"
## Các món khai ở khoá "wildcard_dishes" giao được cho MỌI đơn; tiền tính theo
## món đã giao. (Special Week — Shooting Star)
const FX_WILDCARD_DISHES := "wildcard_dishes"


# ═══════════════════════════════════ NÚM PHỤ CỦA KĨ NĂNG CHỦ ĐỘNG
#
# Một kĩ năng chủ động khai được ĐÚNG MỘT khoá "effect". Khi nó cần thêm một
# tác dụng nhỏ nữa thì khai thêm một khoá NÚM PHỤ vào cùng Dictionary ACTIVE —
# quan_ly_ki_nang đọc riêng, không đi qua `match` của "effect".
#
# Vì sao không đặt tên hiệu ứng mới cho mỗi tổ hợp: hai tác dụng độc lập thì
# có bốn tổ hợp, ba tác dụng thì tám. Đặt tên cho từng tổ hợp là nhân bản
# không kiểm soát được; để rời thì mỗi tác dụng một khoá, cộng lại tuỳ ý.
#
# Bỏ trống khoá nào thì nhận giá trị đơn vị ở dưới, tức không có gì đổi.
const ACTIVE_EXTRAS := {
	## NHÂN vào tiền của đơn giao khi kiên nhẫn còn TRÊN ngưỡng hoàn hảo.
	## Không áp cho đơn chỉ hoàn hảo nhờ FX_FORCE_PERFECT — xem
	## customer_manager.perfect_payout_multiplier để biết vì sao tách.
	"perfect_payout_multiplier": 1.0,
}


# ══════════════════════════════════════════════════ SỐ GỐC (KHÔNG KĨ NĂNG)
#
# Ba con số này là ĐƠN VỊ: nhân với 1,0 và cộng với 0,0 thì không có gì đổi.
# Viết ra thành một bảng thật thay vì rải `if` kiểm tra null ở ba nơi dùng —
# nơi dùng chỉ việc đọc bảng rồi nhân, không cần biết nhân vật có kĩ năng hay
# không.
const DEFAULTS := {
	## Nhân vào MỌI thanh kiên nhẫn của khách (cả xếp hàng lẫn ngồi bàn).
	"patience_factor": 1.0,
	## CỘNG thêm vào tỉ lệ thưởng đơn hoàn hảo của customer_manager (gốc 0,35).
	"perfect_bonus_add": 0.0,
	## BỚT bấy nhiêu GIÂY vào thời điểm món trên bếp bị cháy.
	"burn_time_cut": 0.0,
	## BỚT bấy nhiêu GIÂY khi nấu trên bếp các món trong cook_time_cut_items.
	"cook_time_cut": 0.0,
	"cook_time_cut_items": [],
	## Mỗi đơn có bấy nhiêu cơ hội (0…1) được nhân tiền với bonus_payout_multiplier.
	"bonus_payout_chance": 0.0,
	"bonus_payout_multiplier": 3.0,
	## Hệ số giá riêng theo món: {id món: hệ số}.
	"dish_price_factors": {},
	## BỚT bấy nhiêu GIÂY cho mọi mẻ nướng trong lò.
	"bake_time_cut": 0.0,
	## Hệ số nhân vào trọng số bốc món: {id món: hệ số}.
	"dish_weight_factors": {},
	## true = mỗi đơn giao xong nạp đầy thanh thể lực (chạy nhanh).
	"refill_stamina_on_order": false,
	## true = mọi đơn tính là hoàn hảo ngay từ đầu màn. (Gold Ship)
	"force_perfect": false,
	## Xác suất (0…1) một lần nấu / nướng / ghép ra đồ hỏng. (Gold Ship)
	"cook_fail_chance": 0.0,
	## NHÂN vào giá của mọi món. (Chiyono O)
	"all_price_factor": 1.0,
	## Tốc độ chạy của đồng hồ màn, bếp lò, nhịp khách và kiên nhẫn. (Chiyono O)
	"time_scale": 1.0,
}


# ═════════════════════════════════════════════════════════ SỔ ĐĂNG KÍ
#
# Thêm kĩ năng cho một nhân vật = tạo file trong nhan_vat/ rồi thêm MỘT dòng
# ở đây. Không phải sửa gì khác.
#
# Dùng preload chứ không load(): preload chạy lúc BIÊN DỊCH nên gõ sai đường
# dẫn là báo lỗi ngay khi mở game, thay vì im lặng cho một nhân vật mất sạch
# kĩ năng mà không ai biết.
const SKILL_FILES := {
	"kitamoi": preload("res://scripts/skills/characters/kita.gd"),
	"tuandb": preload("res://scripts/skills/characters/spe.gd"),
	"oui": preload("res://scripts/skills/characters/oguri.gd"),
	"mambo": preload("res://scripts/skills/characters/mambo.gd"),
	"hachimi": preload("res://scripts/skills/characters/teio.gd"),
	"chiyo": preload("res://scripts/skills/characters/chiyono.gd"),
	"golshi": preload("res://scripts/skills/characters/golshi.gd"),
}


# ═══════════════════════════════════════════════════════════════════ TRA

## Bộ số bị động của một nhân vật, đã trộn sẵn với DEFAULTS.
##
## LUÔN trả về đủ ba khoá, kể cả với nhân vật không có trong sổ. Nhờ vậy nơi
## gọi viết thẳng `p["patience_factor"]` mà không phải kiểm tra gì — nhân vật
## chưa có kĩ năng nhận đúng 1,0 và phép nhân không đổi gì cả.
static func passive(character_id: String) -> Dictionary:
	var out := DEFAULTS.duplicate()
	var script_class: GDScript = SKILL_FILES.get(character_id, null)
	if script_class == null:
		return out
	# Đọc hằng của một GDScript bằng get_script_constant_map() chứ không tạo
	# thực thể rồi đọc thuộc tính: hằng là hằng, không cần dựng đối tượng để
	# hỏi. Nhờ vậy file nhân vật thuần là dữ liệu, không có vòng đời nào.
	var constants: Dictionary = script_class.get_script_constant_map()
	var entry: Dictionary = constants.get("PASSIVE", {})
	for key in entry:
		out[key] = entry[key]
	_merge_asian(out, constants, "passive")
	return out


## Asian Mode: trộn đè bản chỉnh (hằng ASIAN trong file nhân vật) lên bản
## thường. Chỉ ghi khoá KHÁC, khoá không nhắc tới giữ nguyên — nhờ vậy mọi chỗ
## đang đọc ACTIVE/PASSIVE không phải biết Asian tồn tại.
static func _merge_asian(out: Dictionary, constants: Dictionary, part: String) -> void:
	if not GameData.is_asian_mode():
		return
	var patch: Dictionary = (constants.get("ASIAN", {}) as Dictionary).get(part, {})
	for key in patch:
		out[key] = patch[key]


## Mô tả kĩ năng chủ động của một nhân vật, hoặc Dictionary RỖNG nếu nhân vật
## đó chưa có kĩ năng chủ động nào được cài.
##
## Rỗng là một câu trả lời hợp lệ, không phải lỗi: sáu trong bảy nhân vật đang
## ở tình trạng đó. Nơi gọi đọc rỗng thì hiểu là "không bao giờ đủ điều kiện",
## và phím Space không làm gì cả.
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
## họ), hoặc rỗng. Hiện chỉ Tokai Teio có: Fan tê liệt, bấm bằng phím riêng.
##
## Vì sao không cho ACTIVE thành một mảng: mọi nhân vật khác có đúng một kĩ
## năng chủ động gắn với phím Space, thanh tiến độ và đoạn phim cut-in. Kĩ năng
## thứ hai của Teio không có thứ nào trong ba thứ đó — nó là một cái bảng chọn
## có phím riêng. Ép hai thứ khác bản chất vào chung một mảng thì quan_ly phải
## rẽ nhánh ở mọi chỗ đọc ACTIVE.
static func secondary(character_id: String) -> Dictionary:
	var script_class: GDScript = SKILL_FILES.get(character_id, null)
	if script_class == null:
		return {}
	var constants: Dictionary = script_class.get_script_constant_map()
	var out: Dictionary = (constants.get("SECONDARY", {}) as Dictionary).duplicate()
	if not out.is_empty():
		_merge_asian(out, constants, "secondary")
	return out
