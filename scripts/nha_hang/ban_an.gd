@tool
class_name BanAn
extends TramTuongTac
## Một bàn ăn trong khu khách ngồi.
##
## Kế thừa TramTuongTac chứ không phải Node3D, vì người chơi MANG MÓN TỚI BÀN
## chứ không giao ở cửa sổ bếp. Kế thừa thì cái bàn tự động có mọi thứ một
## trạm cần và đã chạy đúng ở 18 trạm khác: nằm trong nhóm "tram" để bộ chọn
## mục tiêu thấy, có `chua` để giữ món đang đặt trên mặt bàn, có
## `hien_mo_hinh()` để bày model món đó, và có va chạm vì TramTuongTac vốn là
## StaticBody3D. Viết một lớp trạm riêng cho bàn ăn thì bốn thứ đó phải làm
## lại từ đầu và sẽ lệch dần với phần còn lại.
##
## Node này gom ba thứ vốn nằm rời trong scene: model cái bàn, SỐ BÀN hiện
## nổi bên trên, và các CHỖ ĐỨNG của khách. Gom lại vì cả ba luôn phải đi
## cùng nhau — kéo cái bàn sang chỗ khác thì số và chỗ đứng phải theo, mà nếu
## chúng là ba node anh em rời rạc thì chỉ cần quên kéo một cái là khách đứng
## một nơi còn bàn ở một nẻo.
##
## Vì sao dùng @tool: số bàn hiện ngay trong cửa sổ 3D lúc đang sắp bàn, không
## phải chạy game mới biết mình vừa đặt bàn số mấy ở đâu. Việc sắp bàn là việc
## làm bằng MẮT nên phản hồi phải tức thì.

## Số bàn hiện trên vé đơn hàng và trên biển nổi bên trên bàn.
##
## Là NGUỒN DUY NHẤT: chữ trên biển do hàm này ghi ra, không gõ tay vào node
## Label3D. Gõ tay thì sớm muộn cũng có một bàn mang số khác với biển của nó,
## và lỗi đó chỉ lộ ra khi người chơi mang món tới nhầm bàn.
@export var so_ban: int = 1:
	set(v):
		so_ban = v
		_cap_nhat_bien()

## Phát khi người chơi vừa đặt một món lên bàn.
##
## Hệ đơn hàng sau này nghe tín hiệu này để đối chiếu món với đơn của bàn,
## tính tiền và tính "hoàn hảo". Để cái bàn PHÁT tín hiệu thay vì để đôi tay
## gọi thẳng vào hệ đơn hàng: cái bàn không cần biết hệ đơn hàng tồn tại, nên
## lúc chưa có hệ đó thì mọi thứ vẫn chạy, chỉ là không ai nghe.
## Tắt cảnh báo "khai báo mà không dùng": tín hiệu này được PHÁT từ tay_cam.gd
## bằng emit_signal() nên bộ phân tích tĩnh của Godot không thấy chỗ dùng nào
## trong chính file này. Đó là chủ ý — cái bàn chỉ khai báo, người phát và
## người nghe đều ở ngoài.
@warning_ignore("unused_signal")
signal da_nhan_mon(ban: Node, id_mon: String)

## Bật/tắt biển số, dùng khi muốn chụp ảnh map cho báo cáo.
@export var hien_so := true:
	set(v):
		hien_so = v
		_cap_nhat_bien()

var _bien: Label3D = null


func _ready() -> void:
	_cap_nhat_bien()
	# Tên hiển thị trên HUD bám theo số bàn, không gõ tay trong Inspector —
	# cùng lý do với biển số: hai chỗ ghi số thì sớm muộn cũng lệch nhau.
	if not Engine.is_editor_hint():
		ten_hien_thi = "Bàn %d" % so_ban


## Món đang nằm trên bàn, chuỗi rỗng nếu bàn trống.
func mon_tren_ban() -> String:
	return String(chua[0]) if not chua.is_empty() else ""


func _cap_nhat_bien() -> void:
	if _bien == null or not is_instance_valid(_bien):
		_bien = get_node_or_null("So") as Label3D
	if _bien == null:
		return
	_bien.text = str(so_ban)
	_bien.visible = hien_so


## Số chỗ khách đứng được quanh bàn này.
func so_cho() -> int:
	var n := 0
	for c in get_children():
		if c is Marker3D and String(c.name).begins_with("ChoDung"):
			n += 1
	return n


## Chỗ đứng thứ i (đếm từ 0). Trả về null nếu không có.
##
## Trả về chính Marker3D chứ không phải Vector3: node NPC sau này cần cả HƯỚNG
## quay mặt, mà hướng đó đã nằm sẵn trong transform của marker. Trả toạ độ
## không thôi thì mỗi chỗ gọi lại phải tự tính hướng quay về phía bàn, và bốn
## chỗ tính ra bốn kiểu.
func cho_dung(i: int) -> Marker3D:
	var ds: Array[Marker3D] = []
	for c in get_children():
		if c is Marker3D and String(c.name).begins_with("ChoDung"):
			ds.append(c)
	if i < 0 or i >= ds.size():
		return null
	return ds[i]


## Tìm bàn theo số. Dùng nhóm "ban_an" nên không phụ thuộc đường dẫn node —
## đổi chỗ bàn trong cây scene vẫn tìm ra.
static func tim(cay: SceneTree, so: int) -> BanAn:
	for n in cay.get_nodes_in_group("ban_an"):
		var b := n as BanAn
		if b != null and b.so_ban == so:
			return b
	return null


## Danh sách mọi bàn, đã sắp theo số bàn tăng dần.
static func tat_ca(cay: SceneTree) -> Array[BanAn]:
	var ds: Array[BanAn] = []
	for n in cay.get_nodes_in_group("ban_an"):
		var b := n as BanAn
		if b != null:
			ds.append(b)
	ds.sort_custom(func(a: BanAn, b: BanAn) -> bool: return a.so_ban < b.so_ban)
	return ds
