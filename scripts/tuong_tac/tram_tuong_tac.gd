@tool
class_name TramTuongTac
extends StaticBody3D
## Ghi chú về @tool ở dòng đầu: lớp con BanAn cần chạy trong editor để hiện
## số bàn ngay lúc đang sắp bàn. Godot chỉ chạy script nào ĐƯỢC ĐÁNH DẤU
## @tool, nên lớp cha cũng phải đánh dấu thì lớp con mới chạy trọn vẹn.
## An toàn: file này không có _ready/_process và không @export nào có setter,
## nên đánh dấu @tool KHÔNG làm gì xảy ra trong editor.

const _DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")

## Lớp vật lý số 3 — dành riêng cho VẬT PHẨM cầm được đang nằm dưới đất.
##
## Vì sao phải có lớp riêng: nhân vật KHÔNG được bị chặn bởi một củ cà rốt
## rơi giữa lối đi, nhưng bộ chọn mục tiêu thì VẪN phải nhìn thấy nó để bấm
## E nhặt lên. Hai yêu cầu ngược nhau trên cùng một vật thể, nên không thể
## giải bằng cách bật/tắt va chạm — phải tách ra hai lớp và cho hai bên nhìn
## vào những lớp khác nhau.
##
## Nội thất (tủ, bếp, bàn, tường) VẪN Ở LỚP 1 và vẫn chặn đường như cũ: nếu
## đi xuyên được cả cái tủ lạnh thì bố cục bếp mất hết ý nghĩa, mà toàn bộ
## cân bằng thời gian di chuyển đều dựa trên bố cục đó.
const LOP_VAT_PHAM := 1 << 2

## Mặt nạ cho bộ chọn mục tiêu: nhìn thấy CẢ nội thất lẫn vật phẩm.
const MAT_NA_TRAM := 1 | LOP_VAT_PHAM
## Một trạm người chơi tương tác được: kệ nguyên liệu, tủ lạnh, thớt, bếp,
## chồng đĩa, máng bỏ đồ.
##
## Ý tưởng cốt lõi: KHÔNG dùng một ô sàn cho mỗi nguyên liệu.
##
## Bố cục cũ đặt mỗi nguyên liệu vào một ô 2x2 riêng, lát kín cả bốn cạnh khu
## bếp. Hậu quả là ba trạm ở góc (Khay1, Khay4, Bep1) bị hai trạm khác kẹp
## lại và người chơi không tài nào đứng cạnh mà bấm được. Đó không phải lỗi
## đặt sai toạ độ mà là lỗi hệ thống: trên lưới 2 đơn vị, lát kín viền thì góc
## luôn bị bịt.
##
## Cách sửa: một trạm chứa NHIỀU lựa chọn (mảng `lua_chon`), xếp chồng thành
## cột. Số nguyên liệu trong màn không còn bị giới hạn bởi diện tích bếp, nên
## chỉ cần vài ô là đủ và các góc được để trống.


## Phát khi người chơi bấm tương tác. Trạm KHÔNG tự xử lý hậu quả — hệ thống
## nấu ăn sẽ nghe tín hiệu này. Tách như vậy để trạm chỉ lo phần "là một mục
## tiêu bấm được", còn luật chơi nằm chỗ khác.
signal da_tuong_tac(tram: Node, chi_so: int)

## Tương tác PHỤ — phím F. Hiện chỉ bàn chế tạo dùng tới (ráp món).
##
## Vì sao thêm một tín hiệu thứ hai chứ không nhồi thêm nhánh vào `da_tuong_tac`:
## hai phím là hai Ý ĐỊNH khác nhau của người chơi, và trộn chúng vào một tín
## hiệu thì bên nhận phải đoán "lần này E hay F" qua một tham số phụ. Tách ra
## thì mỗi bên nghe đúng cái nó quan tâm, và trạm nào không dùng F thì đơn giản
## là không ai nối vào.
@warning_ignore("unused_signal")
signal da_tuong_tac_phu(tram: Node, chi_so: int)

## Tên hiện trên HUD.
@export var ten_hien_thi: String = ""

## Loại trạm, để hệ thống nấu ăn biết phải làm gì.
##
## Dùng CHUỖI chứ không dùng enum, vì trạm được gán trực tiếp trong trình
## chỉnh scene: thêm một loại mới chỉ cần gõ tên vào ô Inspector, không phải
## sửa script rồi build lại. Đổi lại là gõ sai chính tả thì không ai báo —
## nên danh sách hợp lệ nằm ngay đây:
##   "ke_nguyen_lieu" — thùng/kệ để lấy một nguyên liệu
##   "tu_lanh"        — nhiều lựa chọn, chọn bằng Tab (xem lua_chon)
##   "thot"           — thái
##   "bep"            — nấu trên bếp
##   "lo_nuong"       — lò pizza / lò nướng
##   "may_kem"        — máy kem, nhiều vị
##   "chong_dia"      — lấy đĩa sạch (vô hạn)
##   "chong_noi"      — lấy nồi rỗng (vô hạn)
##   "ban_che_tao"    — bàn chế tạo: gom nguyên liệu + đĩa thành món
##   "vat_cam"        — vật thể cầm lên mang đi được, đặt sẵn trong file map.
##                      Từ 14/9/2026 KHÔNG map nào còn dùng tới: cái nồi —
##                      thứ duy nhất từng thuộc loại này — đã thành một vật
##                      phẩm vô hạn lấy ở chồng nồi. Giữ lại loại này và hàm
##                      dung_vat_cam() bên dưới vì nó vẫn là cách duy nhất
##                      đặt sẵn một vật cầm được vào map lúc kê bố cục.
##   "mang_bo_do"     — vứt đồ hỏng
@export var loai: String = ""

## Danh sách lựa chọn hiện ra khi người chơi đứng trong tầm.
## Để RỖNG nghĩa là trạm chỉ có một hành động duy nhất — thớt, bếp, chồng đĩa
## và máng bỏ đồ đều thuộc loại này.
@export var lua_chon: PackedStringArray = PackedStringArray()

## Id vật phẩm mà trạm này cho ra (thùng nguyên liệu), hoặc id của chính vật
## phẩm này khi nó là một thứ cầm được đang nằm dưới đất.
##
## Dùng ID chứ không dùng tên hiển thị: tên là chữ cho người đọc và sẽ đổi
## (dịch, sửa chính tả), còn id là khoá tra trong danh mục và phải bất biến.
## Lẫn hai thứ vào nhau thì sửa một dấu tiếng Việt là hỏng cả công thức.
@export var vat_pham: String = ""

## Trạm này mở BẢNG CHỌN riêng thay vì đổ hết lựa chọn vào danh sách Tab.
##
## Tủ lạnh và máy kem có nhiều nguyên liệu, mà danh sách Tab thì chỉ có chữ
## và phải bấm Tab qua từng mục. Với thứ người chơi lấy hàng chục lần mỗi
## màn thì một bảng có ẢNH nhận ra nhanh hơn đọc chữ nhiều lần — nhận dạng
## hình khối nhanh hơn đọc, đó là lý do mọi game nấu ăn đều dùng icon.
##
## Bật cờ này thì trạm chỉ chiếm MỘT dòng trong danh sách Tab (chính nó),
## còn phần chọn nguyên liệu do bảng lo.
@export var dung_bang_chon: bool = false

## Điểm để bộ chọn đo hướng và khoảng cách.
##
## Vì sao cần: trạm áp tường có tâm nằm TRONG tường. Nếu đo từ tâm thì hướng
## nhắm bị lệch vào trong tường, và người chơi đứng đúng chỗ vẫn thấy trạm
## khác được ưu tiên. Đặt một Marker3D nhô ra phía lối đi thì hướng nhắm khớp
## với chỗ người chơi thật sự đứng.
@export var diem_nham: NodePath


## Những thứ đang NẰM TRÊN trạm này (bàn chế tạo, bếp, lò nướng).
##
## Để ở trạm chứ không để trong một "kho" tập trung: cái gì đang trên bàn nào
## là thuộc tính của cái bàn đó. Gom hết vào một chỗ thì mỗi lần hỏi "trên
## bàn có gì" lại phải tra ngược xem món nào thuộc bàn nào — thừa một lớp mà
## không được gì.
var chua: Array[String] = []

## Phát khi `chua` đổi. HUD nghe để cập nhật ghi chú trên bàn chế tạo.
signal noi_dung_thay_doi(tram: Node)


func them_vao(ten: String) -> void:
	chua.append(ten)
	noi_dung_thay_doi.emit(self)


## Lấy ra phần tử cuối cùng. Trả về "" nếu đang rỗng.
func bo_cuoi() -> String:
	if chua.is_empty():
		return ""
	var id: String = String(chua[chua.size() - 1])
	chua.remove_at(chua.size() - 1)
	noi_dung_thay_doi.emit(self)
	return id


func don_sach() -> void:
	chua.clear()
	noi_dung_thay_doi.emit(self)


## Model của thứ đang nằm TRÊN mặt trạm (thớt, bếp, bàn chế tạo).
##
## Vì sao trạm tự lo phần này thay vì để đôi tay hay hệ nấu dựng model rồi
## gắn vào: cả ba hệ đó đều có lúc cần đổi thứ đang bày trên mặt bàn, và nếu
## ai cũng tự gắn thì rất dễ có hai model chồng lên nhau — một cái cũ không
## ai xoá. Trạm giữ đúng MỘT tham chiếu, nên bày cái mới là cái cũ tự đi.
var _mo_hinh: Node3D = null

## Model bày cao bao nhiêu so với gốc trạm. Mặt bàn/quầy KayKit cao 1 đơn vị.
@export var cao_dat := 1.02


## Bày một vật phẩm lên mặt trạm. Truyền "" để dọn sạch.
func hien_mo_hinh(id: String) -> void:
	xoa_mo_hinh()
	if id.is_empty():
		return
	var m: Node3D = _DanhMuc.tao_mo_hinh(id)
	if m == null:
		return
	m.name = "MoHinhTren"
	# Không cấp va chạm cho model bày trên bàn: nó chỉ để nhìn. Cấp va chạm
	# thì nó chắn mất chính cái bàn, và người chơi hết bấm được vào trạm.
	add_child(m)
	m.position = Vector3(0.0, cao_dat, 0.0)
	_mo_hinh = m


## Bày CẢ CHỒNG đồ đang nằm trên mặt trạm. Truyền mảng rỗng để dọn sạch.
##
## Tách khỏi hien_mo_hinh() chứ không thêm tham số: hai hàm trả lời hai câu
## khác nhau — "bày đúng một thứ này" (thớt, bếp) và "bày tất cả những gì đang
## có" (bàn chế tạo). Gộp lại thì mọi nơi gọi đều phải truyền thêm một tham số
## mà chín trên mười nơi không quan tâm.
func hien_chong(ds: Array[String]) -> void:
	xoa_mo_hinh()
	if ds.is_empty():
		return
	var m: Node3D = _DanhMuc.tao_chong(ds)
	if m == null:
		return
	m.name = "MoHinhTren"
	add_child(m)
	m.position = Vector3(0.0, cao_dat, 0.0)
	_mo_hinh = m


func xoa_mo_hinh() -> void:
	if _mo_hinh != null and is_instance_valid(_mo_hinh):
		_mo_hinh.queue_free()
	_mo_hinh = null


func vi_tri_nham() -> Vector3:
	if diem_nham.is_empty():
		return global_position
	var n := get_node_or_null(diem_nham) as Node3D
	return n.global_position if n != null else global_position


## Số mục tiêu trạm này đóng góp vào danh sách chọn.
## Trạm không có lựa chọn vẫn là MỘT mục tiêu (chính nó), nên dùng max(_, 1).
func so_muc_tieu() -> int:
	if dung_bang_chon:
		return 1
	return maxi(lua_chon.size(), 1)


func nhan_muc_tieu(chi_so: int) -> String:
	if dung_bang_chon or lua_chon.is_empty():
		return ten_hien_thi
	return "%s · %s" % [ten_hien_thi, lua_chon[chi_so]]


func tuong_tac(chi_so: int) -> void:
	da_tuong_tac.emit(self, chi_so)


## Phím F trên trạm này.
func tuong_tac_phu(chi_so: int = 0) -> void:
	da_tuong_tac_phu.emit(self, chi_so)


# ---------------------------------------------- vật cầm đặt sẵn trong map ---

## Cạnh hộp va chạm của một vật cầm được. Trùng với `canh_vat_pham` bên
## tay_cam.gd — hai nơi sinh ra cùng một loại vật thì phải cùng kích thước.
const CANH_VAT := 0.55


## Dựng phần NHÌN THẤY và phần BẤM ĐƯỢC cho một `vat_cam` đặt sẵn trong map.
##
## Vì sao cần hàm này: vật phẩm do người chơi tạo ra lúc chơi thì tay_cam.gd
## dựng đủ bộ (model + hộp va chạm + điểm nhắm). Nhưng vật đặt SẴN trong file
## map — hiện chỉ có cái nồi — là một StaticBody3D trần do người kê map thêm
## vào, và nó thiếu cả ba thứ đó.
##
## Hậu quả trước khi có hàm này, và đây là kiểu lỗi tệ nhất vì nó im lặng
## tuyệt đối: cái nồi VÔ HÌNH (không mesh) và KHÔNG BẤM ĐƯỢC (bộ chọn mục
## tiêu dò va chạm, mà nó không có hình va chạm nào). Không một dòng lỗi nào
## trong console — chỉ là ở chỗ đó chẳng có gì cả.
##
## Gọi lúc CHẠY từ level_base chứ không tự gọi trong _ready: lớp này là @tool,
## _ready cũng chạy trong trình soạn thảo, và thêm node ngầm vào lúc đang kê
## map là thứ gây nhầm lẫn hơn là giúp.
func dung_vat_cam() -> void:
	if loai != "vat_cam" or vat_pham.is_empty():
		return

	if get_node_or_null("Mesh") == null:
		_thay_mesh()

	# Hộp va chạm: thiếu nó thì trạm không bao giờ được bộ chọn nhìn thấy.
	if _tim_hinh_va_cham() == null:
		var hinh := CollisionShape3D.new()
		var hop := BoxShape3D.new()
		hop.size = Vector3(CANH_VAT, CANH_VAT, CANH_VAT)
		hinh.shape = hop
		hinh.position = Vector3(0.0, CANH_VAT * 0.5, 0.0)
		add_child(hinh)

	if get_node_or_null("DiemNham") == null:
		var moc := Marker3D.new()
		moc.name = "DiemNham"
		moc.position = Vector3(0.0, 0.25, 0.0)
		add_child(moc)
		diem_nham = NodePath("DiemNham")

	# Ruột đổi thì hình đổi theo (nồi rỗng ↔ nồi có đồ). Nối MỘT lần ở đây
	# thay vì bắt mọi chỗ gọi them_vao/bo_cuoi/don_sach nhớ vẽ lại — bốn chỗ
	# gọi là bốn cơ hội quên.
	if not noi_dung_thay_doi.is_connected(_khi_ruot_doi):
		noi_dung_thay_doi.connect(_khi_ruot_doi)


func _khi_ruot_doi(_tram: Node) -> void:
	_thay_mesh()


## Dựng lại node "Mesh" theo trạng thái rỗng/đầy hiện tại.
##
## So sánh tên model TRƯỚC khi dựng lại: `noi_dung_thay_doi` bắn mỗi lần bỏ
## thêm một nguyên liệu, mà từ nguyên liệu thứ hai trở đi hình không đổi gì
## cả. Dựng lại vô tư thì mỗi lần bỏ đồ là một lần nạp scene và xoá node, chỉ
## để ra đúng cái hình cũ.
func _thay_mesh() -> void:
	var co_do := not chua.is_empty()
	var moi := "day" if co_do else "rong"
	if String(get_meta("kieu_mesh", "")) == moi and get_node_or_null("Mesh") != null:
		return
	set_meta("kieu_mesh", moi)

	var cu := get_node_or_null("Mesh")
	if cu != null:
		cu.queue_free()

	var m: Node3D = _DanhMuc.tao_mo_hinh(vat_pham, co_do)
	if m == null:
		push_warning("Vật cầm '%s' chưa có model." % vat_pham)
		return
	m.name = "Mesh"
	add_child(m)


func _tim_hinh_va_cham() -> CollisionShape3D:
	for c in get_children():
		if c is CollisionShape3D:
			return c
	return null
