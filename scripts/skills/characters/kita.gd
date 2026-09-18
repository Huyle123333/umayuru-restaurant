extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  KĨ NĂNG CỦA KITASAN BLACK — sửa số ở ĐÂY                            ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## MỘT nhân vật, MỘT file. Muốn chỉnh Kita thì mở đúng file này, không phải
## tìm giữa bảng của bảy người.
##
## ─────────────────────────────────────────────────── CÁCH CHỈNH
##
##   1. Sửa số ở dưới rồi LƯU file.
##   2. Chạy lại game (F5). Không phải mở lại Godot, không phải sửa chỗ nào
##      khác.
##
## Ba ví dụ hay gặp:
##
##   • "Kiên nhẫn +30% mạnh quá"      → he_so_kien_nhan: 1.30 → 1.15
##   • "Thưởng hoàn hảo yếu quá"      → cong_thuong_hoan_hao: 0.20 → 0.30
##   • "5 đơn hoàn hảo khó quá"       → threshold: 5 → 4
##
## NHỚ SỬA KÈM câu mô tả trong GameData.CHARACTERS["kitamoi"]["skills"] — đó
## là chữ người chơi đọc ở bảng thông tin nhân vật, và không có gì tự đồng bộ
## hai chỗ. Mỗi mục dưới đây chép sẵn nguyên văn câu mô tả để đối chiếu.
##
## ─────────────────────────────────────── KĨ NĂNG CHỈ ĂN VỚI ĐÚNG CHỦ
##
## Mọi số trong file này chỉ có tác dụng KHI NGƯỜI CHƠI ĐANG DÙNG Kita. Chọn
## nhân vật khác thì màn chơi chạy bằng số GỐC của game — xem skill_registry.gd.

# KHÔNG preload skill_registry.gd ở đây, dù các hằng DK_* / HU_* nằm bên đó.
# Lý do: sổ đăng kí bên đó đã preload NGƯỢC file này, và hai file preload lẫn
# nhau là tham chiếu vòng — Godot báo lỗi ngay lúc phân tích cú pháp.
#
# Nên hai khoá "condition" và "effect" dưới đây viết thẳng labelỗi. Danh sách
# đầy đủ các labelỗi hợp lệ nằm ở skill_registry.gd (phần DK_* và HU_*); gõ sai
# một chữ thì kĩ năng im lặng không bao giờ đủ điều kiện, nên chép từ đó sang
# chứ đừng gõ tay.


# ═══════════════════════════════════ CHỦ ĐỘNG: Victory Cheer! Lv18 (Space)
#
# "Điều kiện: Hoàn thành 5 đơn hoàn hảo. Trong thời gian còn lại của màn chơi,
#  mọi đơn giao ra đều được tính là hoàn hảo bất kể thanh kiên nhẫn."
#
# Vì sao hiệu lực tới HẾT MÀN chứ không phải 45 hay 60 giây (mục 4 tài liệu):
# kĩ năng chủ động mỗi màn chỉ dùng một lần, nên nếu thời lượng cố định thì
# đạt điều kiện ở giây 100 hay giây 300 đều nhận phần thưởng y hệt — người
# chơi không có lý do gì để cố đạt sớm. Kéo tới hết màn thì phần thưởng tỉ lệ
# thuận với việc đạt sớm đến đâu.
#
# Đo được: 5 đơn hoàn hảo rơi vào quanh giây 136 của màn 420 giây, tức còn 68%
# màn được hưởng; chơi giỏi hơn 30 giây thì được thêm 7% màn.
const ACTIVE := {
	"name": "Victory Cheer!",

	## Loại điều kiện. Danh sách các loại có sẵn ở skill_registry.gd (DK_*).
	"condition": "perfect_orders",   # Registry.COND_PERFECT_ORDERS
	## Cần bao nhiêu. Đây là con số dễ chỉnh nhất của cả kĩ năng.
	"threshold": 5,

	## Hiệu ứng khi bấm Space.
	##
	## Ba kĩ năng của Kita đều là VẶN NÚM — đổi một con số của hệ khác — nên
	## dùng hiệu ứng có sẵn (HU_*) chứ không cần file riêng. Những kĩ năng cần
	## cơ chế thật (Triumphant Pulse dừng thời gian, Ambition reset màn) thì
	## khai khoá "script" trỏ tới một file trong thư mục hieu_ung/ — xem
	## effects/_template.gd.
	"effect": "force_perfect",     # Registry.FX_FORCE_PERFECT

	## Mỗi màn dùng được mấy lần. Bỏ trống = 1.
	"uses": 1,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
#
# Luôn có hiệu lực từ lúc vào màn, không cần bấm gì.
const PASSIVE := {

	# "Kiên nhẫn là một đức tính — Thời gian kiên nhẫn của khách hàng +30%."
	#
	# Nhân vào CẢ HAI thanh kiên nhẫn: lúc xếp hàng (45 s → 58,5 s) và lúc
	# ngồi bàn (tính theo món, ví dụ hamburger 75 s → 97,5 s).
	#
	# Vì sao cả hai: đúng chữ "thời gian kiên nhẫn của khách hàng" trong tài
	# liệu. Chỉ áp một giai đoạn thì thành một ngoại lệ người chơi phải học
	# thuộc mà không nhìn thấy được ở đâu cả.
	"patience_factor": 1.30,

	# "Dòng tiền mờ ám — Tiền thưởng từ đơn hoàn hảo +20%."
	#
	# CỘNG ĐIỂM PHẦN TRĂM vào mức gốc 0,35 của quan_ly_khach → 0,55. Món 100
	# đồng giao hoàn hảo trả 155 thay vì 135.
	#
	# Vì sao cộng chứ không nhân (nhân ra 0,42, tức 142 đồng): mục 7 tài liệu
	# đã nhận xét mức 20% là "khá yếu, 35–40% mới xứng với điều kiện phải bỏ
	# ra" — mà cách nhân còn yếu hơn thế, chỉ thêm 7 đồng mỗi món trong khi kĩ
	# năng này CÒN KÈM một điểm trừ. Một kĩ năng có đánh đổi mà phần lợi không
	# cảm nhận được thì phần đánh đổi thành phạt thuần.
	"perfect_bonus_add": 0.20,

	# "Đổi lại: món ăn hỏng sớm hơn 2 giây."
	#
	# Trừ vào MỐC CHÁY, không trừ vào thời gian nấu. Bếp nấu finished ở giây 8,
	# cháy ở giây 16 (he_so_chay = 2,0); kĩ năng này kéo mốc cháy về giây 14,
	# tức quãng ân hạn sau khi chín rút từ 8 xuống 6 giây.
	#
	# Vì sao không trừ vào thời gian nấu: trừ ở đó là LÀM LỢI cho người chơi
	# (món finished sớm hơn), ngược hẳn với chữ "đổi lại".
	#
	# Thực tế chỉ ham và steak chịu ảnh hưởng — hai món duy nhất khai khoá
	# `hong` trong DanhMuc. Vẫn viết chung chứ không viết riêng cho hai món,
	# để thêm một món cháy được sau này không phải sửa lại kĩ năng.
	"burn_time_cut": 2.0,
}
