@tool
extends CharacterBody3D
## Một người khách. CHỈ biết đi và diễn: đi tới một điểm, đứng chờ, ăn, rồi về.
##
## Không biết đơn hàng, không biết tiền, không biết bàn nào còn trống — tất cả
## những thứ đó do quan_ly_khach.gd quyết rồi RA LỆNH xuống đây. Lý do tách:
## luật nhà hàng (ai ngồi bàn nào, đơn nào khớp món nào) sẽ còn đổi rất nhiều,
## còn "đi từ A tới B rồi phát tín hiệu đã tới" thì gần như không đổi. Trộn hai
## thứ vào một file thì mỗi lần sửa luật lại phải đọc qua cả phần điều khiển.
##
## KHÔNG đặt class_name: level_base nạp mọi hệ thống bằng load() lúc chạy để
## một lỗi cú pháp ở đây không kéo sập cả màn chơi. class_name phân giải lúc
## biên dịch nên sẽ phá mất lớp bảo vệ đó.

## Đi tới nơi rồi. `viec` là chuỗi do người ra lệnh gửi kèm lúc gọi di_toi(),
## trả lại nguyên vẹn để bên đó biết đây là chuyến nào — nhờ vậy máy trạng
## thái NẰM Ở quản lý, còn ở đây chỉ có "đang đi" và "đứng yên".
signal da_toi_noi(khach: Node, viec: String)
## Ăn xong.
signal da_an_xong(khach: Node)

## Cỡ người khách. 1,0 = đúng cỡ model gốc (cao 1,52 đơn vị).
##
## ĐÂY LÀ Ô DUY NHẤT CẦN CHỈNH. Mở scenes/nha_hang/khach.tscn, chọn node gốc
## "Khach", sửa số này trong Inspector — model, hộp va chạm, bán kính agent và
## độ cao bong bóng đều đổi theo cùng lúc.
##
## Vì sao không kéo thẳng scale của node Model: scale chỉ đổi phần NHÌN THẤY.
## Hộp va chạm và agent giữ nguyên cỡ cũ, nên một người khách to gấp rưỡi vẫn
## lách qua khe hẹp như người tí hon, còn navmesh thì được nướng theo bán kính
## agent chứ không theo model. Sai lệch kiểu đó không có lỗi nào báo, chỉ thấy
## khách thỉnh thoảng lún vào bàn.
##
## Cũng KHÔNG scale node gốc: Godot khuyến cáo không scale CharacterBody3D,
## vì máy vật lý dùng hình va chạm chứ không dùng transform của thân.
##
## Nhân vật người chơi (model chibi) cao khoảng 1,94 sau khi phóng 1,6; để
## khách cao ngang thì tỉ lệ khoảng 1,3.
@export var ti_le: float = 1.3:
	set(v):
		ti_le = maxf(0.1, v)
		_ap_ti_le()

## Cỡ gốc, dùng làm mốc nhân. Phải trùng số trong khach.tscn.
const BAN_KINH_GOC := 0.4
const CAO_GOC := 1.5
const BAN_KINH_AGENT_GOC := 0.45
const CAO_BONG_GOC := 2.05

const TOC_DO := 2.6
## Xoay người mượt thay vì bẻ lái tức thì. Đơn vị: radian mỗi giây.
const TOC_XOAY := 8.0
const TRONG_LUC := 24.0

@onready var _agent: NavigationAgent3D = $Agent
@onready var _hoat_hinh: AnimationPlayer = $Model/AnimationPlayer
@onready var _bong: Node3D = $Bong

var _viec := ""
var _dang_di := false
## Hướng quay đích khi đứng yên (ví dụ quay mặt vào bàn). Vector3.ZERO = kệ.
var _huong_dung := Vector3.ZERO
var _hoat_hinh_hien := ""


func _ready() -> void:
	_ap_ti_le()
	if Engine.is_editor_hint():
		return
	_bong.visible = false
	_dung_bong()
	_dat_hoat_hinh("idle")


## Áp tỉ lệ cho model, hộp va chạm, agent và bong bóng.
##
## is_node_ready() chặn lần gọi đầu: setter của @export chạy NGAY LÚC NẠP
## SCENE, sớm hơn @onready, nên lúc đó _agent và _bong còn là null. _ready()
## gọi lại một lần nữa nên không mất giá trị nào.
func _ap_ti_le() -> void:
	if not is_node_ready():
		return
	var model := get_node_or_null("Model") as Node3D
	if model != null:
		model.scale = Vector3.ONE * ti_le

	var col := get_node_or_null("Col") as CollisionShape3D
	if col != null and col.shape is CapsuleShape3D:
		var hinh := col.shape as CapsuleShape3D
		hinh.radius = BAN_KINH_GOC * ti_le
		hinh.height = CAO_GOC * ti_le
		# Capsule lấy gốc ở TÂM, nên phải nâng lên nửa chiều cao thì chân mới
		# chạm sàn. Quên bước này là nhân vật lún nửa người xuống đất.
		col.position.y = CAO_GOC * 0.5 * ti_le

	if _agent != null:
		_agent.radius = BAN_KINH_AGENT_GOC * ti_le
		_agent.height = CAO_GOC * ti_le
	if _bong != null:
		_bong.position.y = CAO_BONG_GOC * ti_le


## Ra lệnh đi tới một vị trí.
##
## Điểm đích được NẮN về navmesh trước khi giao cho agent. Bắt buộc: mấy cái
## Marker3D trong map do người kê bằng mắt, có cái nằm sát tường (CuaVao ở
## x=31,5 trong khi tường ở x=32) nên rơi ra NGOÀI vùng đi được sau khi navmesh
## co vào theo bán kính agent. Giao thẳng điểm ngoài mesh thì agent tìm đường
## tới chỗ gần nhất rồi loay hoay không bao giờ báo "đã tới".
func di_toi(dich: Vector3, viec: String, huong_cuoi: Vector3 = Vector3.ZERO) -> void:
	_viec = viec
	_huong_dung = huong_cuoi
	dich = nan_ve_navmesh(get_world_3d().navigation_map, dich)
	_agent.target_position = dich
	_dang_di = true
	_dat_hoat_hinh("walk")


## Đứng lại tại chỗ, quay mặt về một hướng nếu có.
## Nắn một điểm bất kỳ về điểm gần nhất còn nằm trên vùng đi được.
##
## Hai cái bẫy đã đo được lúc chạy, cả hai đều HỎNG LẶNG LẼ:
##  1. `agent.get_navigation_map()` của một agent vừa mới vào cây scene chưa
##     chắc đã trỏ đúng bản đồ có sẵn các vùng. Hỏi qua world_3d thì luôn là
##     bản đồ mà quản lý khách đã gắn vùng vào.
##  2. Truy vấn hỏng KHÔNG báo lỗi mà trả về đúng (0,0,0). Người khách đầu tiên
##     vì thế nhận đích là gốc toạ độ, đứng chết ngay cửa, và hai người sinh
##     sau chồng lên rồi kẹt cả đám. Nên phải coi (0,0,0) là "hỏng" và giữ
##     nguyên điểm gốc — trừ khi bản thân điểm cần nắn vốn đã là gốc toạ độ.
static func nan_ve_navmesh(ban_do: RID, diem: Vector3) -> Vector3:
	if not ban_do.is_valid() or NavigationServer3D.map_get_iteration_id(ban_do) == 0:
		return diem
	var gan := NavigationServer3D.map_get_closest_point(ban_do, diem)
	if gan.is_equal_approx(Vector3.ZERO) and not diem.is_equal_approx(Vector3.ZERO):
		return diem
	# Chỉ lấy phần NGANG, giữ nguyên độ cao gốc.
	#
	# Điểm nắn ra nằm trên mặt navmesh, mà mặt đó cao hơn sàn nửa mét (Recast
	# rasterize theo ô cao cell_height). Nếu để nguyên độ cao đó làm đích thì
	# khoảng cách từ người khách (y=0) tới đích không bao giờ nhỏ hơn 0,5 —
	# tức là target_desired_distance 0,45 KHÔNG BAO GIỜ thoả và người khách
	# đứng dí một chỗ dù vẫn có vận tốc. Sàn quán phẳng tuyệt đối nên bỏ trục
	# đứng đi là đúng, không mất gì.
	gan.y = diem.y
	return gan


## Khai báo mặt navmesh cao hơn chân nhân vật bao nhiêu.
##
## NavigationAgent3D trừ con số này khỏi trục Y ở CẢ điểm đường trả về LẪN phép
## đo "đã tới điểm giữa chưa". Không khai thì agent thấy mỗi điểm đường luôn
## cách nó ít nhất 0,5 theo trục đứng, không bao giờ nhích sang điểm kế tiếp,
## và người khách đi mãi về phía một cái mốc ngay dưới chân mình.
func dat_lech_cao(cao: float) -> void:
	_agent.path_height_offset = cao


func dung_lai(huong_cuoi: Vector3 = Vector3.ZERO) -> void:
	_dang_di = false
	_huong_dung = huong_cuoi
	velocity.x = 0.0
	velocity.z = 0.0
	_dat_hoat_hinh("idle")


func an(giay: float) -> void:
	_dang_di = false
	velocity = Vector3(0.0, velocity.y, 0.0)
	_dat_hoat_hinh("eat")
	await get_tree().create_timer(giay).timeout
	if not is_inside_tree():
		return
	_dat_hoat_hinh("idle")
	da_an_xong.emit(self)


func cau() -> void:
	_dat_hoat_hinh("angry")


## Bong bóng trên đầu (đơn hàng). Nội dung do hệ đơn hàng đổ vào sau.
func bong_bong() -> Node3D:
	return _bong


# ---------------------------------------------------------- bong bóng đơn ---

## Bề rộng thanh chờ tính bằng ĐIỂM ẢNH của tấm ảnh sinh ra lúc chạy.
##
## Vì sao vẽ thanh bằng một tấm ảnh 64×10 tự sinh chứ không dùng hai cái quad
## rồi co giãn cái bên trong: co giãn KHÔNG ĐỀU một node đang bật billboard là
## chuyện dễ hỏng — billboard thay hệ trục của model bằng hệ trục camera trong
## shader, nên phần scale méo đi theo góc nhìn. Vẽ thẳng vào ảnh thì hình luôn
## đúng, bất kể camera ở đâu, và không phải căn chỉnh gốc co giãn.
##
## Rẻ hơn vẻ ngoài của nó: ảnh chỉ 640 điểm ảnh, và chỉ vẽ lại khi số cột đã
## tô THAY ĐỔI — tức nhiều nhất 64 lần cho trọn một lần đếm ngược, chứ không
## phải mỗi khung hình.
const RONG_THANH := 64
const CAO_THANH := 10

## Chiều cao mong muốn của ảnh món trong không gian 3D, đơn vị Godot.
##
## pixel_size của Sprite3D tính theo TỪNG điểm ảnh, mà ảnh nguyên liệu là ảnh
## 512 px. Để nguyên pixel_size 0,004 như trong scene thì bong bóng cao hơn 2
## đơn vị — to hơn cả người khách. Nên phải suy pixel_size ngược từ chiều cao
## mong muốn, và như vậy ảnh to nhỏ khác nhau vẫn hiện cùng một cỡ.
const CAO_ANH_MON := 0.55

const MAU_NEN_THANH := Color(0.10, 0.08, 0.07, 0.85)
const MAU_XANH := Color("4f9d5d")
const MAU_VANG := Color("d9a520")
const MAU_DO := Color("c4433a")

var _anh_mon: Sprite3D
var _thanh: Sprite3D
var _hinh_thanh: Image
var _tex_thanh: ImageTexture
var _cot_cuoi := -1


func _dung_bong() -> void:
	if _bong == null:
		return
	_anh_mon = _bong.get_node_or_null("Anh") as Sprite3D

	_thanh = Sprite3D.new()
	_thanh.name = "ThanhCho"
	_thanh.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_thanh.shaded = false
	_thanh.no_depth_test = true
	# Lọc điểm ảnh KIỂU GẦN NHẤT: ảnh chỉ 64 px mà kéo rộng ra, lọc mượt sẽ
	# làm mép thanh nhoè thành một vệt chuyển màu, đọc không ra mốc.
	_thanh.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_thanh.pixel_size = 0.6 / float(RONG_THANH)
	_thanh.position.y = -CAO_ANH_MON * 0.5 - 0.08
	_bong.add_child(_thanh)

	_hinh_thanh = Image.create(RONG_THANH, CAO_THANH, false, Image.FORMAT_RGBA8)
	_tex_thanh = ImageTexture.create_from_image(_hinh_thanh)
	_thanh.texture = _tex_thanh
	_ve_thanh(1.0)


## Hiện bong bóng với ảnh món. Gọi lúc khách vào hàng đợi.
func hien_don(anh: Texture2D) -> void:
	if _bong == null:
		return
	if _anh_mon != null and anh != null:
		_anh_mon.texture = anh
		var cao := maxi(anh.get_height(), 1)
		_anh_mon.pixel_size = CAO_ANH_MON / float(cao)
	_cot_cuoi = -1
	_ve_thanh(1.0)
	_bong.visible = true


func an_don() -> void:
	if _bong != null:
		_bong.visible = false


## Cập nhật thanh chờ. `ti` là phần kiên nhẫn còn lại, 0…1.
##
## Tham số tên `ti` chứ không phải `ti_le`: lớp này đã có @export `ti_le` (cỡ
## người khách), trùng tên thì tham số che mất biến thành viên — Godot cảnh
## báo, và kiểu nhầm đó rất khó thấy khi đọc lại.
func dat_thanh_cho(ti: float) -> void:
	if _bong == null or not _bong.visible:
		return
	_ve_thanh(ti)


func _ve_thanh(ti: float) -> void:
	if _hinh_thanh == null:
		return
	var cot := int(round(clampf(ti, 0.0, 1.0) * RONG_THANH))
	if cot == _cot_cuoi:
		return
	_cot_cuoi = cot

	# Ba bậc màu theo ngưỡng, khớp đúng ba bậc trên tấm vé ở HUD. Cùng một
	# thông tin thì phải cùng một mã màu, dù vẽ ở hai chỗ khác nhau.
	var mau := MAU_XANH
	if ti <= 0.2:
		mau = MAU_DO
	elif ti <= 0.5:
		mau = MAU_VANG

	_hinh_thanh.fill(MAU_NEN_THANH)
	if cot > 0:
		_hinh_thanh.fill_rect(Rect2i(0, 0, cot, CAO_THANH), mau)
	_tex_thanh.update(_hinh_thanh)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Giữ dính sàn. Sàn phẳng tuyệt đối nhưng vẫn cần trọng lực: nhân vật được
	# sinh ra hơi cao hơn mặt sàn, không có trọng lực thì lơ lửng mãi.
	if not is_on_floor():
		velocity.y -= TRONG_LUC * delta
	else:
		velocity.y = 0.0

	if _dang_di:
		if _agent.is_navigation_finished():
			_dang_di = false
			velocity.x = 0.0
			velocity.z = 0.0
			_dat_hoat_hinh("idle")
			da_toi_noi.emit(self, _viec)
		else:
			var toi := _agent.get_next_path_position()
			var huong := (toi - global_position)
			huong.y = 0.0
			huong = huong.normalized()
			velocity.x = huong.x * TOC_DO
			velocity.z = huong.z * TOC_DO
			_xoay_ve(huong, delta)
	elif _huong_dung != Vector3.ZERO:
		_xoay_ve(_huong_dung, delta)

	move_and_slide()


## Xoay thân về một hướng nằm ngang.
##
## Xoay CẢ CharacterBody3D chứ không xoay riêng node Model như bên nhân vật
## người chơi: khách không có camera gắn vào nên không có lý do gì phải tách
## thân và model, mà xoay thẳng thân thì hướng nhìn và hướng va chạm luôn khớp.
func _xoay_ve(huong: Vector3, delta: float) -> void:
	if huong.length_squared() < 0.0001:
		return
	# Model nhìn về −Z, đúng quy ước của Godot, nên atan2 lấy thẳng góc.
	var dich := atan2(huong.x, huong.z)
	rotation.y = rotate_toward(rotation.y, dich, TOC_XOAY * delta)


## Đổi animation, bỏ qua nếu đang chạy đúng cái đó.
##
## Kiểm trùng chứ không gọi play() vô tư: play() cùng tên vẫn khởi động lại
## từ đầu, nên gọi mỗi khung hình thì animation đứng mãi ở khung 0 — đúng kiểu
## lỗi nhìn như "model bị đơ" mà không có dòng lỗi nào.
func _dat_hoat_hinh(ten: String) -> void:
	if _hoat_hinh_hien == ten:
		return
	if _hoat_hinh == null or not _hoat_hinh.has_animation(ten):
		return
	_hoat_hinh_hien = ten
	_hoat_hinh.play(ten)
