extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  SỔ ĐĂNG KÍ KĨ NĂNG — nối id nhân vật với file kĩ năng của họ         ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## File này KHÔNG chứa con số nào. Nó chỉ có ba thứ:
##   1. Bảng SO_KI_NANG: id nhân vật → file kĩ năng trong nhan_vat/
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
##   bang_ki_nang.gd      — file này: sổ đăng kí, không có số
##   nhan_vat/<ten>.gd    — SỐ của từng nhân vật (CHU_DONG + BI_DONG)
##   hieu_ung/<ten>.gd    — CƠ CHẾ của những kĩ năng phức tạp; xem
##                          hieu_ung/_mau.gd để biết cách viết một cái mới
##
## Kĩ năng chỉ đổi một con số của hệ khác (cả ba kĩ năng của Kita) KHÔNG cần
## file trong hieu_ung/ — chúng dùng hiệu ứng có sẵn HU_* ở dưới.


# ═══════════════════════════════════════════════ ĐIỀU KIỆN KĨ NĂNG CHỦ ĐỘNG
#
# Dùng hằng CHUỖI chứ không dùng enum vì các file nhân vật là Dictionary —
# enum ghi vào Dictionary thành số, và đọc file dữ liệu mà thấy
# `"dieu_kien": 2` thì phải lật ngược lên đây mới biết 2 là gì.

## Đếm số ĐƠN HOÀN HẢO đã giao. (Kita — Victory Cheer!)
const DK_DON_HOAN_HAO := "don_hoan_hao"
## Đếm số đơn đã hoàn thành, hoàn hảo hay không. (Chiyono O — chưa cài)
const DK_DON_XONG := "don_xong"
## Đếm số MÓN đã nấu xong thuộc một nhóm. (Special Week, Mambo — chưa cài)
const DK_MON_NAU := "mon_nau"
## Đếm giây đã trôi của màn chơi. (Oguri — chưa cài)
const DK_THOI_GIAN := "thoi_gian"
## Đếm số lần cho pet ăn. (Teio — chưa cài)
const DK_CHO_PET_AN := "cho_pet_an"
## Mọi món trong thực đơn đã hoàn hảo ít nhất một lần. (Gold Ship — chưa cài)
const DK_PHU_KIN_THUC_DON := "phu_kin_thuc_don"


# ═══════════════════════════════════════ HIỆU ỨNG CÓ SẴN (KHÔNG CẦN FILE)
#
# Những hiệu ứng chỉ là "bật một cờ" hoặc "đổi một con số" của hệ khác.
# quan_ly_ki_nang thi hành thẳng, không nạp file nào.
#
# Cần gì phức tạp hơn thì viết một file trong hieu_ung/ và khai khoá "script"
# thay cho "hieu_ung" — xem hieu_ung/_mau.gd.

## Mọi đơn giao ra tính là hoàn hảo bất kể thanh kiên nhẫn. (Kita)
const HU_EP_HOAN_HAO := "ep_hoan_hao"


# ══════════════════════════════════════════════════ SỐ GỐC (KHÔNG KĨ NĂNG)
#
# Ba con số này là ĐƠN VỊ: nhân với 1,0 và cộng với 0,0 thì không có gì đổi.
# Viết ra thành một bảng thật thay vì rải `if` kiểm tra null ở ba nơi dùng —
# nơi dùng chỉ việc đọc bảng rồi nhân, không cần biết nhân vật có kĩ năng hay
# không.
const MAC_DINH := {
	## Nhân vào MỌI thanh kiên nhẫn của khách (cả xếp hàng lẫn ngồi bàn).
	"he_so_kien_nhan": 1.0,
	## CỘNG thêm vào tỉ lệ thưởng đơn hoàn hảo của quan_ly_khach (gốc 0,35).
	"cong_thuong_hoan_hao": 0.0,
	## BỚT bấy nhiêu GIÂY vào thời điểm món trên bếp bị cháy.
	"bot_giay_chay": 0.0,
}


# ═════════════════════════════════════════════════════════ SỔ ĐĂNG KÍ
#
# Thêm kĩ năng cho một nhân vật = tạo file trong nhan_vat/ rồi thêm MỘT dòng
# ở đây. Không phải sửa gì khác.
#
# Sáu nhân vật còn lại (Special Week, Oguri Cap, Mambo, Gold Ship, Tokai Teio,
# Chiyono O) cố ý KHÔNG có dòng nào: thiếu dòng đọc ra là "chưa làm tới", còn
# một dòng trỏ tới file rỗng đọc ra là "nhân vật này không có kĩ năng". Hai
# câu khác nhau.
#
# Dùng preload chứ không load(): preload chạy lúc BIÊN DỊCH nên gõ sai đường
# dẫn là báo lỗi ngay khi mở game, thay vì im lặng cho một nhân vật mất sạch
# kĩ năng mà không ai biết.
const SO_KI_NANG := {
	"kitamoi": preload("res://scripts/ki_nang/nhan_vat/kita.gd"),
}


# ═══════════════════════════════════════════════════════════════════ TRA

## Bộ số bị động của một nhân vật, đã trộn sẵn với MAC_DINH.
##
## LUÔN trả về đủ ba khoá, kể cả với nhân vật không có trong sổ. Nhờ vậy nơi
## gọi viết thẳng `bs["he_so_kien_nhan"]` mà không phải kiểm tra gì — nhân vật
## chưa có kĩ năng nhận đúng 1,0 và phép nhân không đổi gì cả.
static func bi_dong(id_nhan_vat: String) -> Dictionary:
	var ra := MAC_DINH.duplicate()
	var lop: GDScript = SO_KI_NANG.get(id_nhan_vat, null)
	if lop == null:
		return ra
	# Đọc hằng của một GDScript bằng get_script_constant_map() chứ không tạo
	# thực thể rồi đọc thuộc tính: hằng là hằng, không cần dựng đối tượng để
	# hỏi. Nhờ vậy file nhân vật thuần là dữ liệu, không có vòng đời nào.
	var hang: Dictionary = lop.get_script_constant_map()
	var muc: Dictionary = hang.get("BI_DONG", {})
	for khoa in muc:
		ra[khoa] = muc[khoa]
	return ra


## Mô tả kĩ năng chủ động của một nhân vật, hoặc Dictionary RỖNG nếu nhân vật
## đó chưa có kĩ năng chủ động nào được cài.
##
## Rỗng là một câu trả lời hợp lệ, không phải lỗi: sáu trong bảy nhân vật đang
## ở tình trạng đó. Nơi gọi đọc rỗng thì hiểu là "không bao giờ đủ điều kiện",
## và phím Space không làm gì cả.
static func chu_dong(id_nhan_vat: String) -> Dictionary:
	var lop: GDScript = SO_KI_NANG.get(id_nhan_vat, null)
	if lop == null:
		return {}
	var hang: Dictionary = lop.get_script_constant_map()
	return hang.get("CHU_DONG", {})
