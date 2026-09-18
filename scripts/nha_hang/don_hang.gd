extends RefCounted
## MỘT đơn hàng: một người khách đang ngồi ở một cái bàn, muốn một món.
##
## KHÔNG khai class_name mà để bên dùng preload thành hằng số.
## Lý do rất thực tế: class_name chỉ có tác dụng sau khi trình soạn thảo Godot
## quét lại thư mục và ghi vào bộ nhớ đệm lớp toàn cục. Chạy game thẳng từ dòng
## lệnh trên một file vừa thêm thì bộ nhớ đệm đó chưa có, và game chết ngay lúc
## phân tích cú pháp với "Could not find type". preload thì trỏ thẳng vào file,
## không qua bộ nhớ đệm nào cả — luôn đúng, kể cả ở lần chạy đầu tiên.
##
## Vì sao là một lớp riêng chứ không phải vài `set_meta()` gắn lên người khách:
## cái vé trên HUD và luật trong quan_ly_khach.gd phải nhìn thấy CÙNG MỘT con
## số kiên nhẫn. Nếu mỗi bên giữ một bản sao thì sớm muộn thanh trên màn hình
## và luật tính điểm lệch nhau, mà lệch kiểu đó không báo lỗi — chỉ làm người
## chơi thấy "rõ ràng còn thanh mà khách vẫn bỏ đi".
##
## Đây là RefCounted nên nó KHÔNG nằm trong cây scene: quản lý khách giữ một
## tham chiếu, cái vé giữ một tham chiếu, và cả hai đọc chung một chỗ nhớ. Cái
## vé chỉ ĐỌC, không bao giờ ghi — luật nằm một phía.
##
## Vì sao không lưu sẵn "kiên nhẫn" thành một cột trong DanhMuc: nó đã suy ra
## được từ thời gian làm món (2,5 × thời gian, sàn 35 giây). Hai cột số rời
## nhau thì sửa cột này quên cột kia.

const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")

## Ngưỡng "đơn hoàn hảo": giao khi kiên nhẫn còn TRÊN mức này.
##
## Con số 0,5 không phải chọn bừa — nó đi cùng hệ số 2,5 trong DanhMuc: kiên
## nhẫn = 2,5 × thời gian làm, nên còn trên một nửa nghĩa là người chơi xong
## trong khoảng 1,25 lần thời gian tối ưu. Đủ chặt để phải cố, đủ rộng để
## không cần chơi hoàn hảo.
const NGUONG_HOAN_HAO := 0.5

var khach: Node
var ban: Node
var mon: String = ""
var gia: int = 0

var toi_da: float = 0.0     ## kiên nhẫn ban đầu của GIAI ĐOẠN hiện tại, giây
var con: float = 0.0        ## kiên nhẫn còn lại, giây

## Nhân vào ngân sách kiên nhẫn của CẢ HAI giai đoạn. 1,0 = không đổi.
##
## Đây là chỗ kĩ năng "Kiên nhẫn là một đức tính" của Kita cắm vào (1,30).
## quan_ly_khach gán giá trị này ngay sau khi tạo đơn, TRƯỚC cho_ban().
##
## Vì sao để ở đơn chứ không nhân sẵn vào hai con số gốc bên quan_ly_khach:
## ngân sách lúc ngồi bàn tính từ DanhMuc.kien_nhan(mon), tức nó được tính
## LẠI ở thời điểm khách ngồi xuống chứ không phải lúc tạo đơn. Nhân sẵn ở
## ngoài thì phải nhớ nhân ở hai chỗ, và chỗ thứ hai rất dễ quên vì nó nằm
## trong vao_ban() của file này.
var he_so_kien_nhan: float = 1.0

## Đang ở giai đoạn nào. true = đứng xếp hàng, false = đã ngồi vào bàn.
##
## MỘT đơn đi qua HAI giai đoạn, mỗi giai đoạn một ngân sách kiên nhẫn riêng
## và một chỗ hiển thị riêng: lúc xếp hàng thì thanh nằm trong bong bóng trên
## đầu khách, lúc ngồi bàn thì nằm trên tấm vé ở HUD. Hai giai đoạn khác nhau,
## hai chỗ nhìn khác nhau — người chơi phân biệt được ngay "đang mất khách ở
## cửa" hay "đang mất khách ở bàn".
var o_hang: bool = true

## Có trừ kiên nhẫn theo thời gian không.
##
## Màn hướng dẫn tắt cờ này: thanh vẫn hiện đầy đủ để người chơi làm quen với
## nó, nhưng không bao giờ cạn. Dạy cách đọc một thứ trước, rồi mới cho nó
## gây áp lực — bắt học và chịu phạt cùng lúc thì người mới bỏ ngay.
var chay: bool = true

## Tiền đã chốt lúc GIAO, gồm cả thưởng hoàn hảo. Trả vào ví lúc khách ăn xong.
var tien_tra: int = 0
var da_hoan_hao: bool = false


## Đơn sinh ra lúc khách vào hàng đợi, khi CHƯA biết sẽ ngồi bàn nào.
##
## Đây là lý do đơn gắn với NGƯỜI KHÁCH chứ không gắn với cái bàn: lúc gọi món
## còn chưa có bàn nào cả. Gắn vào bàn thì phải đợi tới khi ngồi mới tạo được
## đơn, mà như vậy thì không hiện được món trên đầu người đang xếp hàng.
func _init(nguoi: Node, id_mon: String) -> void:
	khach = nguoi
	mon = id_mon
	gia = DanhMuc.gia(id_mon)


## Bắt đầu giai đoạn CHỜ BÀN với ngân sách kiên nhẫn cho trước.
##
## Ngân sách này CỐ ĐỊNH, không suy từ món như lúc ngồi bàn. Lý do: đứng xếp
## hàng thì khách chưa được phục vụ gì cả, nên thời gian chờ dài ngắn theo món
## là thứ người chơi không đoán được và cũng không tác động được. Một con số
## cố định thì thành một luật học một lần là thuộc.
func cho_ban(giay: float) -> void:
	o_hang = true
	toi_da = giay * he_so_kien_nhan
	con = toi_da


## Ngồi được vào bàn: NẠP ĐẦY LẠI kiên nhẫn, lần này tính theo món.
##
## Nạp đầy chứ không trừ tiếp phần đã mất lúc chờ. Vì hai giai đoạn có hai
## thủ phạm khác nhau: hết bàn trống là lỗi của cái QUÁN, còn nấu chậm mới là
## lỗi người chơi. Trừ tiếp thì một lúc đông khách bị phạt hai lần, và tệ hơn
## là thành vòng xoáy — càng đông càng mất khách, càng mất càng đông.
func vao_ban(cai_ban: Node) -> void:
	ban = cai_ban
	o_hang = false
	toi_da = DanhMuc.kien_nhan(mon) * he_so_kien_nhan
	con = toi_da


## Trừ thời gian. Trả về true đúng MỘT lần, ở khoảnh khắc kiên nhẫn vừa cạn.
func dem(delta: float) -> bool:
	if not chay or con <= 0.0:
		return false
	con = maxf(0.0, con - delta)
	return con <= 0.0


## Kiên nhẫn còn lại, quy về 0…1 để vẽ thanh.
func ti_le() -> float:
	if toi_da <= 0.0:
		return 0.0
	return clampf(con / toi_da, 0.0, 1.0)


func hoan_hao() -> bool:
	return ti_le() > NGUONG_HOAN_HAO


func so_ban() -> int:
	return int(ban.so_ban) if ban != null and "so_ban" in ban else 0


func ten_mon() -> String:
	return DanhMuc.ten(mon)


func duong_dan_anh() -> String:
	return DanhMuc.duong_dan_anh(mon)
