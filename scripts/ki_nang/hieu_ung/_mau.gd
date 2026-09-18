extends RefCounted
## ╔══════════════════════════════════════════════════════════════════════╗
## ║  MẪU HIỆU ỨNG KĨ NĂNG — chép file này ra khi viết một kĩ năng phức tạp ║
## ╚══════════════════════════════════════════════════════════════════════╝
##
## File này KHÔNG chạy trong game. Nó là bản mẫu để chép, và là chỗ ghi lại
## giao ước giữa quan_ly_ki_nang.gd với một hiệu ứng viết riêng.
##
## Tên bắt đầu bằng gạch dưới để nó luôn nằm đầu danh sách thư mục và để nhìn
## là biết ngay "không phải kĩ năng thật".
##
## ────────────────────────────────────── KHI NÀO CẦN MỘT FILE TRONG ĐÂY
##
## KHÔNG cần, nếu kĩ năng chỉ đổi MỘT con số hoặc bật MỘT cờ của hệ khác. Cả
## ba kĩ năng của Kita thuộc loại này — chúng dùng hiệu ứng có sẵn (HU_* trong
## bang_ki_nang.gd) và quan_ly_ki_nang thi hành thẳng.
##
## CẦN, khi kĩ năng là một CƠ CHẾ có trạng thái riêng, có thời gian sống, hoặc
## phải nghe tín hiệu. Bốn kĩ năng đã biết chắc sẽ cần:
##
##   Triumphant Pulse (Oguri Cap)
##       Dừng đồng hồ màn, khách và thanh kiên nhẫn; bếp và nhân vật vẫn chạy.
##       Bật/tắt tự do trong ngân sách 30 giây cho cả màn. Đây là cái khó nhất
##       trong bảy nhân vật: phải tách hai dòng thời gian, một cho thế giới và
##       một cho khu bếp.
##
##   Ambition to Surpass the Sakura (Chiyono O)
##       Đặt lại đồng hồ và hàng đợi về đầu màn, GIỮ tiền. Không giới hạn số
##       lần dùng.
##
##   Anchors Aweigh! (Gold Ship)
##       Cộng thẳng 9.999.999 rồi kết thúc màn. Số tiền này KHÔNG được ghi vào
##       kỷ lục — nên hiệu ứng phải báo cho bảng kết quả biết đừng lưu.
##
##   Sky-High Teio Step (Tokai Teio)
##       Mỗi lần cho pet ăn cộng 10 giây vào đồng hồ màn, từ lúc bật tới hết
##       màn. Cần nghe một tín hiệu từ hệ pet — tín hiệu đó chưa tồn tại.
##
## ─────────────────────────────────────────────────────── CÁCH DÙNG
##
##   1. Chép file này thành hieu_ung/<ten_ki_nang>.gd
##   2. Viết phần thân của bat() (và tat() nếu kĩ năng bật/tắt được)
##   3. Trong file nhân vật (nhan_vat/<ten>.gd), ở khối CHU_DONG, thay khoá
##      "hieu_ung" bằng:
##
##          "script": "res://scripts/ki_nang/hieu_ung/<ten_ki_nang>.gd",
##
##      Khai cả hai khoá thì "script" thắng — hiệu ứng viết riêng luôn được
##      ưu tiên hơn hiệu ứng có sẵn.
##
## Không phải sửa quan_ly_ki_nang.gd, không phải thêm dòng nào vào bảng nào.


## Bật hiệu ứng. Gọi NGAY LÚC người chơi bấm Space, không đợi cut-in chiếu
## xong — nếu buộc đợi hết phim thì người bỏ qua đoạn phim sẽ được lợi (hoặc
## thiệt) hơn người ngồi xem, tức cùng một kĩ năng cho hai kết quả khác nhau
## tuỳ thói quen bấm phím.
##
## `ctx` là mọi thứ hiệu ứng có thể cần, gói trong một Dictionary:
##
##   ctx["ql"]       Node   — quan_ly_khach: khách, đơn, tiền, thanh kiên nhẫn
##   ctx["bep"]      Node   — he_bep: bếp, lò, thớt, mốc cháy
##   ctx["gio"]      Node   — bang_thoi_gian: đồng hồ màn và ví tiền (có thể null)
##   ctx["man"]      Node   — node gốc của màn chơi, để kết thúc màn hoặc
##                            thêm node con
##   ctx["nhan_vat"] Node   — nhân vật người chơi
##   ctx["so"]       Dict   — chính khối CHU_DONG của kĩ năng, để đọc các con
##                            số riêng (ví dụ "ngan_sach": 30.0)
##
## Vì sao gói vào một Dictionary thay vì sáu tham số: thêm một thứ vào ctx sau
## này KHÔNG bắt phải sửa lại chữ kí của mọi hiệu ứng đã viết. Đổi lại thì gõ
## sai tên khoá không bị báo lỗi lúc biên dịch — nên danh sách khoá ghi ngay
## trên đây, và mỗi hiệu ứng nên đọc ra biến cục bộ ở dòng đầu tiên.
##
## KHÔNG có gì gọi tat() tự động khi hết màn. Hầu hết kĩ năng hiệu lực TỚI HẾT
## MÀN nên không cần dọn: cả màn chơi bị xoá khi đổi scene. Hiệu ứng nào đụng
## vào autoload (AmThanh, GameData) thì phải tự dọn lấy.
func bat(ctx: Dictionary) -> void:
	var ql: Node = ctx.get("ql")
	if ql == null:
		return
	# Ví dụ — đây đúng là thứ mà hiệu ứng có sẵn HU_EP_HOAN_HAO đang làm,
	# viết ra để thấy một hiệu ứng thật trông như thế nào:
	#
	#     ql.ep_hoan_hao = true
	pass


## Tắt hiệu ứng. CHỈ cần viết cho kĩ năng bật/tắt được — hiện mới có
## Triumphant Pulse của Oguri.
##
## quan_ly_ki_nang chỉ gọi hàm này nếu file có khai nó (kiểm bằng has_method),
## nên kĩ năng một chiều thì xoá hẳn hàm này đi cho gọn.
func tat(_ctx: Dictionary) -> void:
	pass
