extends Node
## Luật nhà hàng: ai vào, đứng đâu trong hàng, ngồi bàn nào, khi nào về.
##
## Node này do level_base tạo lúc chạy, cùng lý do với bộ chọn mục tiêu và hệ
## bếp: bảy nhân vật người chơi thì nhét vào scene nhân vật là bảy chỗ phải sửa.
##
## Máy trạng thái của MỘT người khách nằm ở đây chứ không nằm trong khach.gd.
## khach.gd chỉ biết "đi tới đó rồi hét lên một tiếng"; còn thứ tự vào hàng →
## nhích lên → ra bàn → ăn → về là LUẬT, mà luật thì đổi liên tục. Gom hết luật
## về một chỗ thì đọc một file là hiểu cả vòng đời người khách.

signal khach_ngoi_xuong(khach: Node, ban: Node)
signal khach_an_xong(khach: Node, ban: Node, id_mon: String)
signal khach_bo_di(khach: Node)

## Một đơn vừa sinh ra (khách đã ngồi vào bàn và gọi món).
signal don_moi(don: DonHang)
## Một đơn kết thúc. ly_do: "xong" (giao đúng) hoặc "bo_di" (hết kiên nhẫn).
signal don_ket_thuc(don: DonHang, ly_do: String)
## Ví thay đổi. `cho` là chỗ vừa xảy ra việc, để bắn hiệu ứng tiền bay lên.
signal tien_thay_doi(tong: int, them: int, cho: Vector3)

const KHACH := preload("res://scenes/nha_hang/khach.tscn")
const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")
const DonHang := preload("res://scripts/nha_hang/don_hang.gd")
const ANH_TIEN := "res://assets/ui/tien/carrot_tien.png"

## Thời gian ăn, giây. Màn thật sẽ tỉ lệ với độ khó; tutorial để cố định.
@export var thoi_gian_an: float = 5.0
## Ép mọi khách ngồi đúng bàn này (dùng cho tutorial). 0 = chọn ngẫu nhiên.
@export var ep_ban: int = 0

## Ép mọi khách gọi đúng món này (dùng cho tutorial). Rỗng = bốc ngẫu nhiên.
##
## Màn hướng dẫn dạy làm món Steak, nên người khách trong đó phải gọi đúng món
## Steak — để ngẫu nhiên thì có lúc bài giảng nói một đằng còn bong bóng trên
## đầu khách hiện một nẻo, và người chơi tin cái bong bóng.
@export var ep_mon: String = ""
## Số khách tối đa có mặt cùng lúc, kể cả đang xếp hàng.
@export var toi_da: int = 6

## Số khách tối đa ĐANG NGỒI BÀN cùng lúc. 0 = không giới hạn (dùng hết bàn).
##
## Vì sao cần một trần RIÊNG bên cạnh `toi_da`: `toi_da` đếm tổng số người có
## mặt, nên với sáu bàn trống thì cả sáu người đều được xếp chỗ ngay và người
## chơi phải phục vụ sáu đơn song song. Ngày 1 mà như thế là quá tải ngay từ
## phút đầu — người chơi mới chưa thuộc đường đi trong bếp, sáu đơn cùng lúc
## nghĩa là sáu thanh kiên nhẫn cùng cạn và họ mất hết mà không hiểu vì sao.
##
## Chặn ở SỐ CHỖ NGỒI chứ không tắt bớt bàn: cả sáu bàn vẫn dùng được, khách
## vẫn rải khắp phòng, chỉ là không bao giờ quá ba người ngồi cùng lúc. Tắt
## bớt bàn thì quán trông vắng và nửa gian phòng thành đồ trang trí.
@export var ban_toi_da: int = 0

## Số ô hàng đợi được dùng. 0 = dùng hết số Marker HangDoi có trong map.
##
## Tách khỏi `ban_toi_da` vì hai con số điều khiển hai áp lực khác nhau: trần
## bàn quyết định "phải nấu mấy món cùng lúc", trần hàng đợi quyết định "có
## bao nhiêu người đang giận dần ở cửa". Ngày 1 hạ cả hai xuống 3.
@export var o_hang_toi_da: int = 0

## Thực đơn RIÊNG của màn: chỉ những món trong đây mới được khách gọi.
##
## RỖNG = cả danh mục (mọi món có giá). Mặc định để rỗng chứ không liệt kê sẵn
## mười lăm món: một danh sách chép lại danh mục là một bản sao sẽ lệch khỏi
## bản gốc ngay lần đầu ai đó thêm món mới.
##
## Vì sao mỗi màn một thực đơn: Ngày 1 là màn THẬT đầu tiên, ngay sau bài học
## dạy đúng một món. Mở cả mười lăm món ở đó thì người chơi vừa học xong một
## chuỗi bốn bước đã phải nấu Bữa tối năm bước, và họ thua vì chưa kịp biết
## công thức chứ không phải vì chậm tay. Mở dần thực đơn theo ngày biến cái
## danh mục món ăn thành đường cong học tập, thay vì một bức tường.
@export var thuc_don: Array[String] = []

## Trọng số bốc món: id -> số. Món không có tên trong đây tính là 1.
##
## Vì sao cần trọng số chứ không bốc đều: giá món trong thực đơn Ngày 1 trải
## từ 15 (kem) tới 95 (hamburger). Bốc đều thì ba loại kem chiếm đúng một nửa
## số đơn, doanh thu trần tụt gần một nửa, và điểm cuối màn phụ thuộc vào việc
## người chơi GẶP MAY được mấy đơn đắt — chứ không phụ thuộc họ nấu nhanh cỡ
## nào. Có trọng số thì "trung bình một khách đáng bao nhiêu tiền" là con số
## người thiết kế đặt ra, và bốn mốc S/A/B/C mới có cơ sở để tính.
##
## Kem vẫn giữ trọng số thấp chứ không bỏ hẳn: một đơn 4 giây xen giữa hai đơn
## 20 giây là quãng nghỉ, và một màn không có quãng nghỉ nào thì mệt đều chứ
## không căng dần.
@export var trong_so: Dictionary = {}

## Có trừ kiên nhẫn theo thời gian không.
##
## Màn hướng dẫn tắt cờ này: thanh kiên nhẫn vẫn hiện đầy đủ để người chơi làm
## quen với cách đọc nó, nhưng không bao giờ cạn. Bắt học một thứ mới VÀ chịu
## phạt vì nó cùng lúc là cách nhanh nhất để người mới bỏ game.
@export var tru_kien_nhan: bool = true

## Tự sinh khách theo nhịp. Màn hướng dẫn tắt đi và gọi them_khach() bằng tay
## ở đúng bước cần.
@export var tu_sinh: bool = true
## Giây giữa hai lần thử sinh khách.
@export var nhip_sinh: float = 12.0
## Giây chờ trước người khách đầu tiên — cho người chơi kịp nhìn quanh bếp.
@export var cho_dau: float = 4.0

## Kiên nhẫn lúc đứng XẾP HÀNG (chưa có bàn), giây. CỐ ĐỊNH, không theo món.
##
## 45 giây: đủ để người chơi dọn xong một bàn và đón người tiếp theo, nhưng
## không đủ để mặc kệ hàng đợi cả màn. Xem thêm lý do vì sao là con số cố định
## ở DonHang.cho_ban().
@export var kien_nhan_hang: float = 45.0

## Khách đứng cáu bao lâu trước khi bỏ ra cửa, giây.
##
## 2,0 = ĐÚNG độ dài clip "angry" trong khach_akikawa.glb (đo từ accessor
## input của animation: angry 2,00 s | eat 3,00 | idle 4,00 | walk 1,00).
## Đặt ngắn hơn thì animation bị cắt ngang giữa chừng; dài hơn thì model đứng
## đơ ở khung cuối vì clip này KHÔNG lặp — và không lặp là cố ý, cáu là một
## cử chỉ diễn một lần chứ không phải một trạng thái.
##
## Đổi model khách khác thì phải đo lại con số này theo clip của model đó.
@export var giay_cau: float = 2.0

## Thưởng thêm khi giao lúc kiên nhẫn còn trên 50%. 0,35 = +35%.
##
## CHỐT 35% (9/9/2026). Vì sao không phải 20% như bản nháp: Hamburger 95 thành
## 114, tức chạy vội cả màn để được thêm 19 tiền — người chơi tính nhẩm một
## lần rồi thôi không nhắm vào cơ chế này nữa. 35% cho 128, đủ để đáng đánh
## đổi. Vì sao không lên 50%: khi đó "luôn đạt hoàn hảo" thành cách chơi duy
## nhất đúng, và điểm giữa người chơi giỏi với người chơi thường tách gấp đôi.
##
## Bốn kĩ năng bị động (Victory Cheer, Conguamoidaden, Aura farming, Fan tê
## liệt) quy đổi giá trị theo đúng con số này — đổi ở đây là phải tính lại
## bảng kĩ năng trong Bang can bang.xlsx.
@export var thuong_hoan_hao: float = 0.35

## ───────────────────────────── HAI NÚM DO HỆ KĨ NĂNG VẶN ──────────────────
##
## Hai biến dưới đây là số GỐC của game; hệ kĩ năng (quan_ly_ki_nang.gd) đổi
## chúng khi người chơi đang dùng đúng nhân vật có kĩ năng tương ứng. Chọn
## nhân vật khác thì chúng giữ nguyên và màn chơi chạy đúng luật gốc.
##
## File này KHÔNG biết kĩ năng là gì và không đi hỏi bảng kĩ năng — nó chỉ có
## hai biến số. Nhờ vậy hệ khách hàng chạy y hệt nhau dù màn chơi có gắn hệ
## kĩ năng hay không.

## Nhân vào kiên nhẫn của mọi đơn, cả lúc xếp hàng lẫn lúc ngồi bàn.
## Kita — "Kiên nhẫn là một đức tính": 1,30.
@export var he_so_kien_nhan: float = 1.0

## Bỏ qua thanh kiên nhẫn: MỌI đơn giao ra đều tính là hoàn hảo.
## Kita — "Victory Cheer!", bật khi bấm Space và giữ tới hết màn.
##
## Đơn ép hoàn hảo được tính vào cả TIỀN THƯỞNG lẫn bộ đếm so_don_hoan_hao và
## tiếng "hoàn hảo" — tức nó hoàn hảo theo đúng mọi nghĩa mà game đang dùng.
## Làm nửa vời (ăn tiền nhưng không đếm) thì bảng tổng kết nói một đằng, ví
## tiền nói một nẻo.
var ep_hoan_hao: bool = false

## Tổng tiền đã kiếm trong màn.
var tien: int = 0

## Thống kê một lượt chơi, để bảng kết quả đọc lúc hết giờ.
##
## Đếm Ở ĐÂY chứ không để bảng kết quả tự đếm bằng cách nghe tín hiệu: bảng
## kết quả chỉ được dựng lúc hết giờ, mà lúc đó mọi tín hiệu đã bay qua từ lâu.
## Nơi biết chuyện gì đã xảy ra phải là nơi giữ sổ.
var so_don_xong: int = 0
var so_don_hoan_hao: int = 0
var so_khach_bo_di: int = 0

var _don: Dictionary = {}       # khach -> DonHang
var _hen_sinh: float = 0.0

var _map: Node3D
var _moc: Node
var _hang: Array[Marker3D] = []          # HangDoi1..N, [0] là đầu hàng
var _cua: Marker3D
var _ban: Array = []                     # mọi BanAn trong màn
var _o_hang: Array = []                  # ai đang đứng ở ô hàng đợi nào
var _ban_cua_khach: Dictionary = {}       # khach -> BanAn
var _khach_cua_ban: Dictionary = {}       # BanAn -> khach


func chuan_bi(map: Node3D) -> void:
	_map = map
	_moc = map.get_node_or_null("Moc")
	_cua = _lay_moc("CuaVao")

	var i := 1
	while true:
		var m := _lay_moc("HangDoi%d" % i)
		if m == null:
			break
		_hang.append(m)
		i += 1
	_o_hang.resize(_hang.size())
	_o_hang.fill(null)

	_ban = get_tree().get_nodes_in_group("ban_an")
	_ban.sort_custom(func(a, b): return int(a.so_ban) < int(b.so_ban))
	for b in _ban:
		if b.has_signal("da_nhan_mon"):
			b.da_nhan_mon.connect(_khi_ban_nhan_mon)

	_dung_vung_di_lai()
	_hen_sinh = cho_dau


func _lay_moc(ten: String) -> Marker3D:
	if _moc == null:
		return null
	return _moc.get_node_or_null(ten) as Marker3D


# ------------------------------------------------------- vùng đi lại (navmesh)

## Vùng đi được của khách, NƯỚNG LÚC CHẠY chứ không đặt sẵn trong file map.
##
## Ba lý do:
##  1. Kê thêm hay dời một cái bàn thì đường đi tự đúng theo, không ai phải nhớ
##     bấm lại nút Bake — quên bấm thì khách đi xuyên qua bàn mới và rất khó
##     lần ra vì không có lỗi nào cả.
##  2. Không có mesh nướng sẵn nằm trong file .tscn, nên file map không phình
##     lên vì một thứ suy ra được từ chính nó.
##  3. Cùng nếp với mọi hệ thống khác của màn chơi — tất cả đều do level_base
##     dựng lúc chạy.
##
## HAI vùng chứ không một, vì khu khách hình chữ L: dải bên phải bếp (x 16→32,
## z 0→12) chứa hàng đợi, và sảnh phía nam (x 0→32, z 12→24) chứa sáu cái bàn.
## Một khung bao chỉ vẽ được hình hộp, mà hộp trùm cả chữ L thì trùm luôn cả
## bếp — khách sẽ đi thẳng vào bếp qua lối người chơi ở x=16. Hai hộp chạm nhau
## dọc cạnh z=12, Godot tự nối hai vùng ở cạnh chung nên khách vẫn đi qua lại
## được.
const NHOM_NGUON := "nguon_navmesh"

## Lớp va chạm 5 (bit 16) dành RIÊNG cho mấy tấm chắn vô hình chỉ tồn tại với
## navmesh. Người chơi có mask 1 nên đi xuyên qua chúng như không có gì.
const LOP_CHAN_NAV := 1 << 4

## Hai lối vào bếp, chắn lại để khách không lang thang vào khu bếp.
## Mỗi mục: [tâm hộp, nửa kích thước].
const CHAN := [
	# Lối người chơi ở x=16, z 4→8.
	[Vector3(16.0, 1.0, 6.0), Vector3(0.4, 1.5, 2.2)],
	# Khe trống ở tường nam khu bếp, z=12, x 0→4.
	[Vector3(2.0, 1.0, 12.0), Vector3(2.2, 1.5, 0.4)],
]

var _vung: Array[NavigationRegion3D] = []
## Mặt navmesh nằm cao hơn mặt sàn bấy nhiêu. ĐO lúc chạy chứ không gõ tay:
## con số này do Recast quyết theo cell_height và chiều dày hình va chạm sàn,
## đổi một trong hai là nó đổi theo.
var _lech_cao := 0.0


func _dung_vung_di_lai() -> void:
	if not _map.is_in_group(NHOM_NGUON):
		_map.add_to_group(NHOM_NGUON)
	_dung_tam_chan()

	var luoi := NavigationMesh.new()
	# Ba con số này phải là BỘI SỐ của ô lưới, và ô lưới phải TRÙNG với ô lưới
	# của bản đồ điều hướng (mặc định project là 0,25). Lệch thì Godot cảnh báo
	# "cell_size mismatch" và mép navmesh bị rasterize sai; còn agent_radius /
	# agent_max_climb không tròn ô thì bị làm tròn và giá trị thật khác hẳn giá
	# trị mình gõ.
	luoi.cell_size = 0.25
	luoi.cell_height = 0.25
	# 0,5 = đúng 2 ô, và vẫn lớn hơn bán kính người khách 0,45 nên navmesh co
	# khỏi mọi vật cản đủ để khách không cọ vào mép bàn rồi kẹt.
	luoi.agent_radius = 0.5
	luoi.agent_height = 1.5
	luoi.agent_max_climb = 0.25
	luoi.agent_max_slope = 45.0
	# Đọc HÌNH VA CHẠM chứ không đọc mesh hiển thị: trong map này bàn ghế tường
	# đều là StaticBody3D + CollisionShape3D, còn mesh gltf chỉ để nhìn. Đọc
	# mesh thì mấy thứ trang trí không có va chạm cũng chắn đường.
	luoi.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	luoi.geometry_collision_mask = 1 | LOP_CHAN_NAV
	luoi.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	luoi.geometry_source_group_name = NHOM_NGUON

	var vung := NavigationRegion3D.new()
	vung.name = "VungKhach"
	vung.navigation_mesh = luoi
	_map.add_child(vung)
	_vung.append(vung)
	# Nướng đồng bộ: màn chơi chưa bắt đầu nên một nhịp khựng ở đây không ai
	# thấy, đổi lại khách đầu tiên chắc chắn có đường để đi.
	vung.bake_navigation_mesh(false)
	_ghi_lech_cao(luoi)


## Tấm chắn vô hình bịt hai lối vào bếp.
##
## Vì sao KHÔNG chia khu khách thành hai vùng navmesh hình hộp (bản trước làm
## thế và hỏng): Recast bào lùi mép mỗi vùng đúng bằng agent_radius, nên hai
## vùng dán sát nhau vẫn hở ra 2 × 0,5 = 1,0 đơn vị. Godot chỉ nối hai vùng khi
## mép tự do của chúng cách nhau dưới edge_connection_margin (0,25), nên khách
## đi tới rìa vùng thứ nhất là agent báo "đã tới nơi" rồi đứng lại giữa sảnh —
## đúng triệu chứng đo được: dừng ở z ≈ 10,8 trong khi bàn ở z = 19.
##
## Một vùng duy nhất thì không có mép nào để nối, còn khu bếp thì loại ra bằng
## vật cản thật. Đặt tấm chắn ở lớp riêng để chúng chỉ tồn tại với bộ nướng
## navmesh, người chơi vẫn đi qua lối của mình như cũ.
func _dung_tam_chan() -> void:
	for c in CHAN:
		var than := StaticBody3D.new()
		than.name = "ChanNav"
		than.collision_layer = LOP_CHAN_NAV
		than.collision_mask = 0
		var hinh := CollisionShape3D.new()
		var hop := BoxShape3D.new()
		hop.size = (c[1] as Vector3) * 2.0
		hinh.shape = hop
		than.add_child(hinh)
		_map.add_child(than)
		than.global_position = c[0]


## Đọc độ cao mặt navmesh THẲNG TỪ LƯỚI vừa nướng.
##
## Bản trước hỏi NavigationServer bằng map_get_closest_point() và nhận về 0,0
## — sai. Lý do: map_get_iteration_id() khác 0 mới chỉ nghĩa là bản đồ đã chạy
## xong MỘT vòng đồng bộ, không bảo đảm vòng đó đã gộp mấy vùng mình vừa thêm.
## Truy vấn trượt thì lại trả (0,0,0) chứ không báo lỗi, đúng cái bẫy đã dính
## một lần ở điểm đích.
##
## Đọc đỉnh của chính cái NavigationMesh thì không phụ thuộc server, không phụ
## thuộc thời điểm, và là dữ liệu gốc chứ không phải kết quả suy ra.
func _ghi_lech_cao(luoi: NavigationMesh) -> void:
	var dinh := luoi.get_vertices()
	if dinh.is_empty():
		return
	# Sàn phẳng nên mọi đỉnh cùng cao độ; lấy đỉnh đầu là đủ.
	_lech_cao = dinh[0].y


## Chờ NavigationServer đồng bộ xong bản đồ.
##
## Server chỉ gộp các vùng vừa thêm vào CUỐI một khung hình vật lý, nên mọi
## truy vấn đường đi trước thời điểm đó đều hỏng. Đáng nói là nó hỏng LẶNG LẼ
## kiểu tệ nhất: map_get_closest_point() trả về (0,0,0) chứ không báo gì, nên
## người khách đầu tiên lầm lũi đi về gốc toạ độ thay vì vào hàng đợi.
##
## Đợi bằng map_get_iteration_id() chứ không đợi "vài khung cho chắc": số nhịp
## cần đợi phụ thuộc thời điểm gọi trong khung hình, đoán bao nhiêu cũng có
## ngày trượt.
func cho_san_sang() -> void:
	var ban_do := _map.get_world_3d().navigation_map
	while NavigationServer3D.map_get_iteration_id(ban_do) == 0:
		await get_tree().physics_frame


## Số đa giác của từng vùng — dùng để kiểm nhanh navmesh có nướng ra gì không.
## Mặt navmesh cao hơn mặt sàn bao nhiêu — ĐO được lúc nướng.
##
## Mở hàm đọc thay vì để nơi khác chọc thẳng vào `_lech_cao`: con số này chỉ
## có nghĩa SAU khi navmesh nướng xong, và một hàm công khai là chỗ để ghi
## đúng điều đó. Hiện có hai nơi cần: khách hàng và Doro.
func lech_cao_navmesh() -> float:
	return _lech_cao


func thong_ke_vung() -> Array:
	var ra := []
	for v in _vung:
		ra.append({"ten": v.name, "da_giac": v.navigation_mesh.get_polygon_count()})
	return ra


# --------------------------------------------------------------- vòng đời khách

func them_khach() -> Node:
	if _cua == null or _hang.is_empty():
		push_warning("Map thiếu Moc/CuaVao hoặc Moc/HangDoi1 — không sinh khách được.")
		return null
	var o := _o_trong()
	if o == -1:
		return null

	var k := KHACH.instantiate()
	_map.add_child(k)
	# Nắn chỗ sinh về navmesh rồi lệch ngẫu nhiên một chút: cửa vào nằm sát
	# tường đông (x=31,5 so với tường x=32) nên điểm gốc rơi ra ngoài vùng đi
	# được, mà sinh mấy người CHỒNG LÊN NHAU ở đúng một toạ độ thì họ đẩy nhau
	# ra và có người bị ép xuyên qua tường.
	var vt: Vector3 = k.nan_ve_navmesh(_map.get_world_3d().navigation_map,
		_cua.global_position)
	vt.z += randf_range(-0.7, 0.7)
	k.global_position = vt
	k.dat_lech_cao(_lech_cao)
	k.da_toi_noi.connect(_khi_toi_noi)
	k.da_an_xong.connect(_khi_an_xong)

	_o_hang[o] = k
	k.set_meta("o_hang", o)
	AmThanh.phat("khach_vao")
	k.di_toi(_hang[o].global_position, "hang")
	return k


## Ô hàng đợi trống gần đầu hàng nhất, hoặc -1 nếu hết chỗ.
##
## Chỉ xét `o_hang_toi_da` ô ĐẦU TIÊN chứ không cắt bớt mảng `_o_hang`: các ô
## sau vẫn tồn tại và vẫn đúng vị trí, nên Ngày 2 chỉ cần nâng con số lên là
## hàng đợi dài ra ngay, không phải dựng lại gì.
func _o_trong() -> int:
	var het: int = _o_hang.size()
	if o_hang_toi_da > 0:
		het = mini(het, o_hang_toi_da)
	for i in het:
		if _o_hang[i] == null:
			return i
	return -1


## Đã đủ trần số khách ngồi bàn chưa.
func _kin_ban() -> bool:
	return ban_toi_da > 0 and _khach_cua_ban.size() >= ban_toi_da


## Nhịp tim của cả nhà hàng: sinh khách và đếm kiên nhẫn.
##
## Đếm ở MỘT vòng lặp chung thay vì cho mỗi khách một Timer riêng: sáu Timer
## thì sáu chỗ có thể quên tắt lúc khách bị xoá, và một Timer sống sót sẽ gọi
## vào node đã biến mất. Một vòng lặp thì danh sách đơn chính là nguồn sự thật.
func _process(delta: float) -> void:
	if _map == null:
		return

	if tu_sinh:
		_hen_sinh -= delta
		if _hen_sinh <= 0.0:
			_hen_sinh = nhip_sinh
			them_khach()

	if not tru_kien_nhan:
		return
	# Duyệt trên BẢN SAO danh sách: _bo_di_gian() xoá phần tử khỏi _don ngay
	# trong vòng lặp, mà sửa Dictionary đang duyệt thì Godot bỏ sót phần tử.
	for don in _don.values().duplicate():
		# Khai kiểu tường minh: `don` lấy từ Dictionary nên kiểu tĩnh là Variant,
		# `:=` không suy được kiểu trả về và Godot báo lỗi biên dịch.
		var het: bool = don.dem(delta)
		# Vẽ thanh chờ trên đầu người đang xếp hàng. Chỉ giai đoạn hàng đợi mới
		# vẽ ở đây; ngồi vào bàn rồi thì tấm vé trên HUD lo phần đó.
		if don.o_hang and is_instance_valid(don.khach):
			don.khach.dat_thanh_cho(don.ti_le())
		if het:
			_bo_di_gian(don)


func _khi_toi_noi(khach: Node, viec: String) -> void:
	match viec:
		"hang":
			# Tới chỗ xếp hàng. Quay mặt về phía quầy rồi thử ra bàn ngay —
			# nếu còn bàn trống thì không phải đợi ai.
			khach.dung_lai(Vector3.LEFT)
			# Gọi món NGAY khi vào hàng, trước cả khi biết có bàn hay không.
			# Đúng ý đã chốt: kể cả lúc hết bàn trống thì đơn vẫn hiện trên
			# đầu khách — người chơi nhìn thấy công việc đang dồn tới, đó là
			# phần áp lực mà cái hàng đợi tồn tại để tạo ra.
			_goi_mon(khach)
			# Đứng luôn vào ô đầu hàng (quán đang vắng) thì đơn lên bảng ngay.
			if int(khach.get_meta("o_hang", -1)) == 0:
				_bao_don_len_bang(khach)
			_thu_xep_ban(khach)
		"ban":
			var ban = _ban_cua_khach.get(khach)
			if ban == null:
				return
			# Quay mặt vào tâm bàn.
			# Khai kiểu tường minh: `ban` lấy từ Dictionary nên kiểu tĩnh là
			# Variant, `:=` không suy được kiểu và Godot báo lỗi biên dịch.
			var huong: Vector3 = ban.global_position - khach.global_position
			huong.y = 0.0
			khach.dung_lai(huong.normalized())
			khach_ngoi_xuong.emit(khach, ban)
			_ngoi_vao_ban(khach, ban)
		"ve":
			_don_khach(khach)


## Tìm bàn trống cho một người đang đứng ở hàng đợi.
##
## Chỉ người ĐẦU HÀNG mới được đi. Không có luật này thì người thứ ba có thể
## vọt lên bàn trước người thứ nhất, và cái hàng đợi mất hết ý nghĩa.
func _thu_xep_ban(khach: Node) -> void:
	if _o_hang.is_empty() or _o_hang[0] != khach:
		return
	var ban = _ban_trong()
	if ban == null:
		return

	var o: int = int(khach.get_meta("o_hang", -1))
	if o >= 0:
		_o_hang[o] = null
	khach.remove_meta("o_hang")

	_ban_cua_khach[khach] = ban
	_khach_cua_ban[ban] = khach

	# ĐÓNG BĂNG đồng hồ chờ ngay khi có bàn, chứ không đợi tới lúc ngồi xuống.
	# Quãng đường từ cửa tới bàn xa nhất là 33 đơn vị, đi mất hơn mười giây —
	# để đồng hồ chạy tiếp thì có khách đã được xếp bàn vẫn bỏ đi giữa đường,
	# và người chơi không hiểu vì sao vì họ đã thấy khách được gọi vào rồi.
	var don: DonHang = _don.get(khach)
	if don != null:
		don.chay = false

	khach.di_toi((ban.cho_dung(0) as Marker3D).global_position, "ban")
	_nhich_hang()


## Dồn hàng lên một ô sau khi người đầu hàng rời đi.
func _nhich_hang() -> void:
	for i in range(1, _o_hang.size()):
		var k = _o_hang[i]
		if k == null:
			continue
		var truoc := i - 1
		if _o_hang[truoc] != null:
			continue
		_o_hang[truoc] = k
		_o_hang[i] = null
		k.set_meta("o_hang", truoc)
		# Vừa nhích lên đầu hàng -> đơn lên bảng NGAY, không đợi đi tới nơi.
		# Người chơi nhìn bảng chứ không nhìn chân khách, nên sớm vài giây ở
		# đây chính là vài giây họ dùng để bắc nồi trước.
		if truoc == 0:
			_bao_don_len_bang(k)
		k.di_toi(_hang[truoc].global_position, "hang")


func _ban_trong():
	# Trần số chỗ ngồi. Kiểm tra ở ĐÂY, chỗ duy nhất trả lời "có bàn cho người
	# này không", nên mọi đường đi vào bàn đều bị chặn cùng một luật — kể cả
	# nhánh ép bàn của màn hướng dẫn.
	if _kin_ban():
		return null
	if ep_ban > 0:
		for b in _ban:
			if int(b.so_ban) == ep_ban and not _khach_cua_ban.has(b):
				return b
		return null
	var rong := []
	for b in _ban:
		if not _khach_cua_ban.has(b):
			rong.append(b)
	if rong.is_empty():
		return null
	return rong.pick_random()


## Bàn nhận được món. Chỉ người đang ngồi ở CHÍNH bàn đó mới ăn.
func _khi_ban_nhan_mon(ban: Node, id_mon: String) -> void:
	var khach = _khach_cua_ban.get(ban)
	if khach == null:
		return
	var don: DonHang = _don.get(khach)
	if don == null:
		return

	# GIAO NHẦM MÓN: không làm gì cả.
	#
	# Cố ý im lặng chứ không phạt: món vẫn nằm trên mặt bàn và người chơi bấm
	# E lần nữa là nhấc lại được (xem _giao_mon trong tay_cam.gd). Hình phạt
	# duy nhất là thời gian — mà trong một màn 7 phút thì thời gian đã là đồng
	# tiền đắt nhất. Tịch thu cả món lẫn đơn thì một lần bấm nhầm lúc vội đủ
	# làm hỏng cả màn, và người chơi học được điều sai: "đừng vội" thay vì
	# "nhìn vé trước khi bê".
	if id_mon != don.mon:
		return

	# Chốt tiền NGAY LÚC GIAO, trả vào ví lúc khách ăn xong.
	#
	# Phải chốt ở đây vì "hoàn hảo" đo bằng kiên nhẫn còn lại, mà trong 5 giây
	# ngồi ăn thì thanh đó vẫn đang chạy. Tính lúc ăn xong thì mọi đơn đều
	# thành không hoàn hảo, và cái thưởng 20% coi như không tồn tại.
	don.chay = false
	don.da_hoan_hao = ep_hoan_hao or don.hoan_hao()
	don.tien_tra = don.gia
	if don.da_hoan_hao:
		don.tien_tra = int(round(don.gia * (1.0 + thuong_hoan_hao)))

	so_don_xong += 1
	if don.da_hoan_hao:
		so_don_hoan_hao += 1
		# Chồng LÊN TRÊN tiếng giao món, không thay thế: người chơi vẫn nghe
		# tiếng giao quen thuộc, cộng thêm một tiếng nữa báo "lần này hoàn hảo".
		AmThanh.phat("hoan_hao")

	khach.set_meta("mon", id_mon)
	khach.an(thoi_gian_an)
	don_ket_thuc.emit(don, "xong")


func _khi_an_xong(khach: Node) -> void:
	var ban = _ban_cua_khach.get(khach)
	var id_mon := str(khach.get_meta("mon", ""))
	if ban != null:
		ban.don_sach()
		ban.xoa_mo_hinh()
	var don: DonHang = _don.get(khach)
	if don != null:
		_don.erase(khach)
		if don.tien_tra > 0:
			tien += don.tien_tra
			var cho: Vector3 = ban.global_position if ban != null \
				else khach.global_position
			tien_thay_doi.emit(tien, don.tien_tra, cho)
			AmThanh.phat("tien")
			_tien_bay(cho, don.tien_tra, don.da_hoan_hao)

	khach_an_xong.emit(khach, ban, id_mon)
	if _cua != null:
		khach.di_toi(_cua.global_position, "ve")


## Xoá hẳn người khách và trả lại cái bàn.
func _don_khach(khach: Node) -> void:
	var ban = _ban_cua_khach.get(khach)
	if ban != null:
		_khach_cua_ban.erase(ban)
		_ban_cua_khach.erase(khach)
	var o: int = int(khach.get_meta("o_hang", -1))
	if o >= 0 and o < _o_hang.size() and _o_hang[o] == khach:
		_o_hang[o] = null
		_nhich_hang()
	# Lưới an toàn: nếu vì lý do nào đó người khách biến mất khi đơn còn treo
	# (đổi màn, gọi don_khach thẳng tay), cái vé phải đi theo. Đơn mồ côi thì
	# vé nằm lại trên HUD vĩnh viễn và trỏ vào một node đã bị xoá.
	var don: DonHang = _don.get(khach)
	if don != null:
		_don.erase(khach)
		don_ket_thuc.emit(don, "bo_di")

	khach_bo_di.emit(khach)
	khach.queue_free()
	# Người đầu hàng có thể đã chờ sẵn một cái bàn vừa trống ra.
	if not _o_hang.is_empty() and _o_hang[0] != null:
		_thu_xep_ban(_o_hang[0])


# ------------------------------------------------------------- đơn hàng ---

## Người khách vừa ngồi xuống thì gọi món.
##
## Món bốc NGẪU NHIÊN từ DanhMuc.danh_sach_mon_ban() chứ không từ một danh
## sách gõ tay ở đây. Nhờ vậy thêm một món có giá vào danh mục là nó tự vào
## thực đơn, còn khoá một món (như cả nhóm món nồi hiện giờ) là khách tự động
## thôi gọi — không có chỗ thứ hai để quên cập nhật.
func _goi_mon(khach: Node) -> void:
	if _don.has(khach):
		return
	var mon_co_the := _thuc_don_thuc_te()
	if mon_co_the.is_empty():
		push_warning("Thực đơn rỗng — không món nào có giá trong DanhMuc.")
		return

	var chon := _boc_mon(mon_co_the)
	# Chỉ ép khi món đó THẬT SỰ bán được. Gõ nhầm tên món vào ô ép thì quay về
	# ngẫu nhiên chứ không sinh ra một đơn không bao giờ giao được.
	if not ep_mon.is_empty() and mon_co_the.has(ep_mon):
		chon = ep_mon

	var don := DonHang.new(khach, chon)
	# Gán hệ số TRƯỚC cho_ban(): hàm đó chốt ngân sách kiên nhẫn ngay tại chỗ.
	don.he_so_kien_nhan = he_so_kien_nhan
	don.cho_ban(kien_nhan_hang)
	don.chay = tru_kien_nhan
	_don[khach] = don

	# Bong bóng trên đầu. Vé ở HUD do `_bao_don_len_bang()` lo, và chỉ cho
	# người ĐỨNG ĐẦU HÀNG — xem giải thích ở hàm đó.
	khach.hien_don(_anh_mon(don.mon))


## Đẩy đơn của một người lên BẢNG ĐƠN HÀNG (phím 1), nếu chưa có.
##
## Gọi cho người ĐỨNG ĐẦU HÀNG, tức trước cả khi họ có bàn. Đây là một ưu ái
## có chủ ý cho người chơi: biết trước món kế tiếp thì họ nấu sẵn được trong
## lúc bàn còn bận, thay vì đứng chờ khách ngồi xuống rồi mới bắt đầu.
##
## Chỉ ĐẦU HÀNG chứ không cả hàng: cho xem hết thì bảng thành danh sách việc
## dài dằng dặc và mất luôn cảm giác "đơn tới dồn dập". Một đơn nhìn trước là
## đủ để chuẩn bị, không đủ để chơi thành game xếp lịch.
##
## Phát lại `don_moi` cho cùng một đơn là AN TOÀN: bảng bỏ qua đơn đã có
## (`them()` kiểm tra `_ve.has(don)`), nên lúc người này ngồi vào bàn và
## `_ngoi_vao_ban()` phát lần nữa thì không sinh vé thứ hai.
func _bao_don_len_bang(khach: Node) -> void:
	var don: DonHang = _don.get(khach)
	if don != null:
		don_moi.emit(don)


## Thực đơn thật sự dùng để bốc món.
##
## LỌC qua danh mục chứ không tin thẳng ô `thuc_don`: gõ sai một id trong bảng
## luật màn (hoặc để sót một món thuộc nhóm đang bị khoá, ví dụ nhóm món nồi)
## thì khách sẽ gọi một món KHÔNG THỂ nấu ra, và cái đơn đó đứng đó cho tới
## khi hết kiên nhẫn. Lỗi kiểu này không có thông báo nào và rất khó nhìn ra
## khi đang chơi — nên chặn ngay ở đây, kèm cảnh báo chỉ đúng tên món sai.
func _thuc_don_thuc_te() -> Array[String]:
	var day_du := DanhMuc.danh_sach_mon_ban()
	if thuc_don.is_empty():
		return day_du

	var ra: Array[String] = []
	for m in thuc_don:
		var id := String(m)
		if day_du.has(id):
			ra.append(id)
		else:
			push_warning("Thực đơn màn có món '%s' không bán được — bỏ qua." % id)

	if ra.is_empty():
		push_warning("Thực đơn màn lọc xong thành rỗng — dùng cả danh mục.")
		return day_du
	return ra


## Bốc một món theo trọng số.
##
## Cách làm: cộng dồn tổng trọng số, bắn một số ngẫu nhiên trong [0, tổng),
## rồi trừ dần cho tới khi âm. Ngắn hơn cách dựng sẵn một mảng lặp lại phần tử
## theo trọng số, và quan trọng hơn là nhận được trọng số THẬP PHÂN — sau này
## muốn chỉnh "hamburger hiếm hơn steak một chút" thì đổi 3 thành 2.5, không
## phải nhân cả bảng lên mười lần.
func _boc_mon(ds: Array[String]) -> String:
	var tong := 0.0
	for id in ds:
		tong += maxf(0.0, float(trong_so.get(id, 1)))
	# Không có trọng số nào (hoặc toàn số 0): quay về bốc đều.
	if tong <= 0.0:
		return String(ds.pick_random())

	var moc := randf() * tong
	for id in ds:
		moc -= maxf(0.0, float(trong_so.get(id, 1)))
		if moc <= 0.0:
			return id
	# Lưới an toàn cho sai số dấu phẩy động: randf() trả về gần đúng 1.0 thì
	# vòng trên có thể chạy hết mà chưa chạm 0.
	return ds[ds.size() - 1]


## Khách đã tới bàn: tắt bong bóng, nạp đầy kiên nhẫn, bật vé trên HUD.
func _ngoi_vao_ban(khach: Node, ban: Node) -> void:
	var don: DonHang = _don.get(khach)
	if don == null:
		# Lưới an toàn: nếu vì lý do nào đó khách tới bàn mà chưa có đơn (bị
		# gọi thẳng them_khach rồi ép ngồi trong lúc thử), vẫn tạo đơn để bàn
		# không kẹt vĩnh viễn với một người không bao giờ gọi món.
		_goi_mon(khach)
		don = _don.get(khach)
		if don == null:
			return

	khach.an_don()
	don.vao_ban(ban)
	don.chay = tru_kien_nhan
	don_moi.emit(don)


## Ảnh 2D của một món, hoặc null nếu thiếu file.
##
## Nạp qua ResourceLoader.exists() chứ không load() thẳng: thiếu một ảnh thì
## chỉ mất cái hình trong bong bóng, còn cả màn chơi vẫn chạy. Ảnh món là thứ
## đang được vẽ dần, nên thiếu là chuyện bình thường trong lúc làm.
func _anh_mon(id: String) -> Texture2D:
	var dd := DanhMuc.duong_dan_anh(id)
	if not ResourceLoader.exists(dd):
		push_warning("Bong bóng đơn: thiếu ảnh %s" % dd)
		return null
	return load(dd) as Texture2D


## Hết kiên nhẫn: cáu, bỏ đơn, ĐỢI DIỄN XONG rồi mới đi ra cửa.
##
## LỖI ĐÃ SỬA: bản trước gọi `cau()` rồi gọi `di_toi()` ngay dòng sau, nên
## animation "angry" bị "walk" đè lên trong CÙNG một khung hình — người chơi
## không bao giờ thấy khách cáu. Hỏng lặng lẽ: không có lỗi nào báo, chỉ là
## một phản hồi quan trọng biến mất.
##
## Chỗ chờ đặt Ở ĐÂY chứ không trong khach.gd, đúng theo phân vai đã chốt:
## khach.gd chỉ biết ĐI và DIỄN, còn "cáu bao lâu rồi mới bỏ đi" là LUẬT nhà
## hàng. Bỏ luật vào khach.gd thì sau này muốn màn khó cho khách bỏ đi nhanh
## hơn lại phải sửa cả hai file.
##
## Hàm thành coroutine (có await) nhưng bên gọi trong _process KHÔNG await:
## nó chạy tới chỗ await rồi trả quyền về ngay, nên vòng đếm kiên nhẫn không
## bị khựng lại 2 giây. Đơn đã bị xoá khỏi `_don` TRƯỚC khi chờ, nên trong lúc
## chờ không có nguy cơ hàm này bị gọi lần hai cho cùng một người.
func _bo_di_gian(don: DonHang) -> void:
	var khach: Node = don.khach
	_don.erase(khach)
	so_khach_bo_di += 1
	AmThanh.phat("khach_bo_di")
	don_ket_thuc.emit(don, "bo_di")
	if not is_instance_valid(khach):
		return

	# Nhả ô hàng đợi NGAY, đừng đợi tới lúc ra tới cửa.
	#
	# Không phải để hàng nhích nhanh hơn cho đẹp, mà để chặn một lỗi thật:
	# người vừa bỏ cuộc vẫn là _o_hang[0], nên hễ có bàn trống là _thu_xep_ban
	# lại gọi chính họ vào bàn — một người đã cáu bỏ đi bỗng quay lại ngồi
	# xuống và gọi món mới. Dòng meta này chỉ có ở người đang xếp hàng, nên
	# khách đang ngồi bàn không bị đụng tới.
	var o: int = int(khach.get_meta("o_hang", -1))
	if o >= 0 and o < _o_hang.size() and _o_hang[o] == khach:
		_o_hang[o] = null
		khach.remove_meta("o_hang")
		_nhich_hang()

	khach.an_don()
	khach.cau()
	await get_tree().create_timer(giay_cau).timeout

	# Kiểm tra lại sau khi chờ: 2 giây là cả một quãng đời trong game — đổi
	# màn, thoát ra menu hay dọn khách bằng tay đều có thể đã xoá node này.
	# Gọi vào node đã giải phóng là lỗi làm sập game.
	if not is_instance_valid(khach) or not khach.is_inside_tree():
		return
	if _cua != null:
		khach.di_toi(_cua.global_position, "ve")


## Số tiền bay lên ở chỗ vừa phục vụ xong.
##
## Đặt trong không gian 3D chứ không ở góc HUD: phần thưởng phải hiện ra ĐÚNG
## CHỖ vừa xảy ra việc tốt, nếu không người chơi phải tự nối "tôi vừa làm gì"
## với "con số ở góc màn hình vừa nhảy". Ở góc còn có ví tiền nảy lên một cái
## nữa — hai phản hồi, một ngay tại chỗ, một ở nơi lưu tổng.
func _tien_bay(cho: Vector3, so: int, hoan_hao: bool) -> void:
	if _map == null:
		return
	var goc := Node3D.new()
	goc.position = cho + Vector3(0.0, 1.9, 0.0)
	_map.add_child(goc)

	var icon: Sprite3D = null
	if ResourceLoader.exists(ANH_TIEN):
		icon = Sprite3D.new()
		icon.texture = load(ANH_TIEN)
		icon.pixel_size = 0.0022
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.position.x = -0.28
		goc.add_child(icon)

	var chu := Label3D.new()
	chu.text = "+%d" % so
	chu.font_size = 128
	chu.pixel_size = 0.0028
	chu.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	chu.no_depth_test = true
	chu.outline_size = 28
	chu.modulate = Color("ffd76a") if hoan_hao else Color("d8f0c8")
	chu.position.x = 0.22
	goc.add_child(chu)

	# Bay lên 0,9 đơn vị rồi mờ dần. Mờ CHẬM HƠN lúc bay: biến mất cùng lúc
	# với lúc dừng thì con số như bị cắt ngang, còn mờ nốt ở đỉnh thì mắt kịp
	# đọc xong rồi mới mất.
	var tw := create_tween().set_parallel(true)
	tw.tween_property(goc, "position:y", goc.position.y + 0.9, 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(chu, "modulate:a", 0.0, 0.5).set_delay(0.7)
	if icon != null:
		tw.tween_property(icon, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.finished.connect(goc.queue_free)


## Đóng cửa: ngừng sinh khách và ngừng đếm kiên nhẫn.
##
## Gọi lúc hết giờ, TRƯỚC khi hiện bảng kết quả. Không có bước này thì trong
## lúc người chơi đang đọc bảng, đồng hồ kiên nhẫn vẫn chạy ngầm và con số
## "khách bỏ đi" trên bảng cứ tăng lên trước mắt họ.
##
## Không đụng tới người khách đang có mặt: họ cứ đứng đó cho tới khi đổi màn.
## Xoá sạch thì phía sau tấm bảng bỗng thành một cái quán trống trơn.
func dong_cua() -> void:
	tu_sinh = false
	tru_kien_nhan = false
	for don in _don.values():
		don.chay = false
