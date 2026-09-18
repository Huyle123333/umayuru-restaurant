class_name BoChonMucTieu
extends Area3D
## Bộ chọn mục tiêu tương tác. Gắn vào nhân vật lúc chạy bởi level_base.gd.
##
## QUY TẮC THIẾT KẾ QUAN TRỌNG NHẤT: mặc định KHÔNG phải bấm Tab.
##
## Thể loại nấu ăn sống bằng trí nhớ cơ bắp — người chơi giỏi là người biết
## tay mình phải đi đâu mà không cần nghĩ. Nếu mỗi lần lấy đồ đều phải mở một
## danh sách rồi Tab qua lại thì nhịp chơi bị bẻ gãy, và tệ hơn là số lần bấm
## Tab thay đổi tuỳ chỗ đứng — tức là thêm may rủi vào một thao tác bắt buộc,
## đúng cái lỗi mình đã gạt ra khi bàn về con pet.
##
## Nên ở đây: mục tiêu TỰ ĐỘNG chọn cái nằm gần hướng nhân vật đang quay mặt
## nhất. Đi tới, bấm E, xong — không thêm một phím nào. Tab chỉ để phá thế hoà
## khi nhiều mục tiêu chồng nhau, và khi bấm thì nó KHOÁ lựa chọn một lúc để
## hướng quay mặt không cướp lại ngay.
##
## Luật phát hiện là CHẠM: phải áp sát món đồ thì nó mới vào danh sách. Nhờ
## vậy phần lớn thời gian danh sách chỉ có một mục, và Tab gần như không phải
## dùng tới — đúng ý đồ ở trên. Tab chỉ cần khi đứng ở góc giữa hai món, hoặc
## ở cột nguyên liệu có hai thùng chồng lên nhau.
##
## Lưu ý: CHẠM chỉ làm món đồ HIỆN RA trong danh sách, KHÔNG tự kích hoạt.
## Vẫn phải bấm E. Nếu để đâm vào là tự tương tác thì người chơi sẽ vô tình
## nhặt/bỏ đồ mỗi lần đi lướt qua — mà trong bếp chật thì lướt qua liên tục.

## Danh sách đã đổi hoặc lựa chọn đã đổi — HUD nghe tín hiệu này.
signal danh_sach_thay_doi(ung_vien: Array, chi_so_chon: int)

## Vùng với: một khối hộp ÔM SÁT người chơi theo chiều ngang, nhưng CAO.
##
## Trước đây là hình cầu bán kính 2.6 — với xa hơn một ô rưỡi, nên đứng giữa
## bếp là dính cùng lúc bốn năm trạm và danh sách dài ngoằng. Giờ đổi thành
## luật "CHẠM MỚI TÍNH": hộp chỉ rộng hơn thân nhân vật khoảng nửa đơn vị mỗi
## bên, nên phải áp sát món đồ thì nó mới hiện ra.
##
## Vì sao NGANG thì hẹp mà DỌC thì cao: với tay trong bếp là chuyện của mặt
## sàn chứ không phải chiều cao. Thùng nguyên liệu tầng trên nằm ở y = 2, cao
## hơn đỉnh đầu nhân vật (1.76) — dùng hình cầu ôm sát thì không bao giờ với
## tới, mà cột hai thùng chồng nhau lại đúng là thiết kế mình muốn giữ.
##
## Dùng HỘP chứ không dùng cầu còn vì thân nhân vật (CharacterBody3D) không
## xoay — chỉ node _model bên trong xoay. Nên hộp luôn thẳng trục với thế giới,
## vùng với giống hệt nhau ở mọi hướng quay mặt, không có góc nào "với xa hơn
## góc khác" như khi xoay một hộp theo nhân vật.
@export var rong_voi: float = 1.9
@export var cao_voi: float = 3.2
## Sau khi bấm Tab, khoá lựa chọn bằng tay trong bao lâu (giây).
@export var thoi_gian_khoa_tay: float = 2.0

## Mỗi phần tử: { "tram": TramTuongTac, "chi_so": int, "nhan": String }
var _ung_vien: Array[Dictionary] = []
var _chi_so_chon: int = -1
var _khoa_tay: float = 0.0
## Nhớ lựa chọn đang khoá để giữ đúng nó khi danh sách thay đổi thứ tự.
var _tram_khoa: TramTuongTac = null
var _chi_so_khoa: int = 0

var _than: Node3D = null
## Hình hộp dùng để dò. Giữ tham chiếu để mỗi frame lấy lại đúng vị trí của nó.
var _hinh: CollisionShape3D = null


func _ready() -> void:
	_than = get_parent() as Node3D
	monitoring = true
	monitorable = false
	# Nhìn thấy cả nội thất (lớp 1) lẫn vật phẩm rơi dưới đất (lớp 3) — nhân
	# vật thì chỉ va chạm với lớp 1, nên đi xuyên qua vật phẩm được.
	collision_mask = TramTuongTac.MAT_NA_TRAM
	_hinh = CollisionShape3D.new()
	var hop := BoxShape3D.new()
	hop.size = Vector3(rong_voi, cao_voi, rong_voi)
	_hinh.shape = hop
	# Gốc toạ độ nhân vật nằm ở chân, nên đẩy hộp lên nửa chiều cao thì đáy
	# hộp trùng mặt sàn và đỉnh chạm quá nóc thùng tầng trên.
	_hinh.position = Vector3(0.0, cao_voi * 0.5, 0.0)
	add_child(_hinh)


func _process(delta: float) -> void:
	if _khoa_tay > 0.0:
		_khoa_tay -= delta
	_dung_danh_sach()


# ------------------------------------------------------------ danh sách ---

## Dựng lại danh sách ứng viên mỗi frame.
##
## Thứ tự sắp xếp theo GÓC quanh nhân vật chứ không theo khoảng cách. Lý do:
## khoảng cách thay đổi liên tục khi đi lại nên thứ tự sẽ nhảy loạn, bấm Tab
## hai lần giống nhau ra hai kết quả khác nhau. Sắp theo góc thì Tab luôn chạy
## vòng quanh theo một chiều cố định — đoán trước được.
func _dung_danh_sach() -> void:
	var cu_size := _ung_vien.size()
	var cu_chon := _chi_so_chon
	_ung_vien.clear()

	var tam := global_position
	for co_the in _do_va_cham():
		var tram := co_the as TramTuongTac
		if tram == null:
			continue
		var v := tram.vi_tri_nham() - tam
		var goc := atan2(v.x, v.z)
		for i in tram.so_muc_tieu():
			_ung_vien.append({
				"tram": tram,
				"chi_so": i,
				"nhan": tram.nhan_muc_tieu(i),
				"_goc": goc,
				"_xa": v.length(),
			})
	_ung_vien.sort_custom(_so_sanh_goc)

	_chi_so_chon = _tim_lua_chon()

	if _ung_vien.size() != cu_size or _chi_so_chon != cu_chon:
		danh_sach_thay_doi.emit(_ung_vien, _chi_so_chon)


## Trả về danh sách vật thể đang chạm hộp với.
##
## Dùng TRUY VẤN TRỰC TIẾP vào không gian vật lý thay vì
## Area3D.get_overlapping_bodies(). Đây không phải sở thích mà là kết quả đo:
## với cùng một hình hộp, cùng một vị trí, cùng một collision_mask, truy vấn
## thủ công tìm ra các trạm (StaticBody3D) còn danh sách của Area3D thì chỉ
## thấy mỗi CharacterBody3D của nhân vật — tức là mọi trạm trong bếp đều
## không bao giờ vào được danh sách chọn.
##
## Nguyên nhân là danh sách của Area3D được engine dựng dần qua các sự kiện
## "vào/ra" ở pha broadphase; với vật thể TĨNH đứng yên tuyệt đối và một Area
## được tạo lúc chạy rồi bị cha kéo đi, cặp va chạm đó không phải lúc nào
## cũng được đăng ký. Truy vấn trực tiếp không có bộ nhớ đệm nào cả: nó hỏi
## lại hình học ngay tại frame này, nên không có gì để sai.
##
## Giá phải trả là một truy vấn mỗi frame. Với một hộp nhỏ và vài chục vật
## thể tĩnh thì chi phí này không đáng kể, và đổi lại là hành vi đoán trước
## được — thứ đắt hơn nhiều so với vài micro giây.
func _do_va_cham() -> Array:
	if _hinh == null or _than == null:
		return []
	var truy := PhysicsShapeQueryParameters3D.new()
	truy.shape = _hinh.shape
	truy.transform = _hinh.global_transform
	truy.collision_mask = collision_mask
	truy.collide_with_areas = false
	truy.collide_with_bodies = true
	# Bỏ chính nhân vật ra: hộp dò nằm ôm quanh thân nên lúc nào cũng chạm
	# chính mình, và mỗi frame lại phải lọc lại một phần tử vô nghĩa.
	if _than is CollisionObject3D:
		truy.exclude = [(_than as CollisionObject3D).get_rid()]

	var ra: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(truy, 12):
		ra.append(r["collider"])
	return ra


## Hàm so sánh viết rời thay vì lambda nhiều dòng ngay trong lời gọi.
## Lambda nhiều dòng của GDScript rất kén chỗ đặt dấu đóng ngoặc; viết rời thì
## không bao giờ vướng, và đặt breakpoint để soi thứ tự cũng dễ hơn.
static func _so_sanh_goc(a: Dictionary, b: Dictionary) -> bool:
	if is_equal_approx(float(a["_goc"]), float(b["_goc"])):
		return int(a["chi_so"]) < int(b["chi_so"])
	return float(a["_goc"]) < float(b["_goc"])


func _tim_lua_chon() -> int:
	if _ung_vien.is_empty():
		_tram_khoa = null
		return -1

	# Đang khoá bằng tay: giữ đúng mục tiêu đó nếu nó còn trong tầm.
	if _khoa_tay > 0.0 and is_instance_valid(_tram_khoa):
		for i in _ung_vien.size():
			if _ung_vien[i]["tram"] == _tram_khoa and _ung_vien[i]["chi_so"] == _chi_so_khoa:
				return i
		# Ra khỏi tầm rồi thì bỏ khoá luôn, không giữ một mục tiêu đã biến mất.
		_khoa_tay = 0.0

	# Chấm điểm theo hướng quay mặt. Tích vô hướng của hướng nhìn với hướng
	# tới mục tiêu: 1.0 là ngay trước mặt, -1.0 là sau lưng. Trừ một chút theo
	# khoảng cách để hai mục tiêu cùng hướng thì cái gần hơn thắng.
	var huong := -_than.global_transform.basis.z if _than != null else Vector3.FORWARD
	huong.y = 0.0
	huong = huong.normalized()

	var tot_nhat := -INF
	var chon := 0
	for i in _ung_vien.size():
		var tram: TramTuongTac = _ung_vien[i]["tram"]
		var v: Vector3 = tram.vi_tri_nham() - global_position
		v.y = 0.0
		if v.length() < 0.001:
			continue
		var diem: float = huong.dot(v.normalized()) - float(_ung_vien[i]["_xa"]) * 0.08
		if diem > tot_nhat:
			tot_nhat = diem
			chon = i
	return chon


# ---------------------------------------------------------------- nhập ---

func _unhandled_input(event: InputEvent) -> void:
	if _ung_vien.is_empty():
		return

	if event.is_action_pressed("chon_muc_tieu"):
		_chi_so_chon = (_chi_so_chon + 1) % _ung_vien.size()
		_khoa_lua_chon()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_kich_hoat()
		get_viewport().set_input_as_handled()
		return

	# F đi qua ĐÚNG bộ chọn này, không phải một đường riêng.
	#
	# Nhờ vậy F thừa hưởng nguyên vẹn mọi luật đã có của E: phải đứng đủ gần,
	# chọn được bằng Tab, chọn được bằng tâm ngắm ở góc nhìn thứ ba. Cho F một
	# đường bắt phím riêng trong tay_cam thì hai phím sẽ nhắm vào hai thứ khác
	# nhau đúng lúc trong bếp có nhiều trạm sát nhau.
	if event.is_action_pressed("rap_mon"):
		_kich_hoat_phu()
		get_viewport().set_input_as_handled()
		return

	# Góc nhìn thứ 3: chuột đang bị khoá nên tâm ngắm luôn ở giữa màn hình.
	# Bắn tia từ tâm camera để người chơi trỏ thẳng vào trạm mình muốn, thay
	# vì Tab. Tab VẪN dùng được — hai cách song song, tuỳ người chơi.
	if GameData.third_person_active and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _chon_bang_tam_ngam():
			_kich_hoat()
		get_viewport().set_input_as_handled()


func _khoa_lua_chon() -> void:
	_tram_khoa = _ung_vien[_chi_so_chon]["tram"]
	_chi_so_khoa = _ung_vien[_chi_so_chon]["chi_so"]
	_khoa_tay = thoi_gian_khoa_tay
	danh_sach_thay_doi.emit(_ung_vien, _chi_so_chon)


func _kich_hoat() -> void:
	if _chi_so_chon < 0 or _chi_so_chon >= _ung_vien.size():
		return
	var m := _ung_vien[_chi_so_chon]
	(m["tram"] as TramTuongTac).tuong_tac(m["chi_so"])


func _kich_hoat_phu() -> void:
	if _chi_so_chon < 0 or _chi_so_chon >= _ung_vien.size():
		return
	var m := _ung_vien[_chi_so_chon]
	(m["tram"] as TramTuongTac).tuong_tac_phu(m["chi_so"])


## Bắn tia từ giữa màn hình. Trả về true nếu trúng một trạm đang trong tầm.
##
## Chỉ chấp nhận trạm CÓ TRONG danh sách ứng viên: nhìn thấy chưa đủ, vẫn phải
## đứng đủ gần. Nếu không, người chơi sẽ nấu được món ở đầu bên kia phòng.
func _chon_bang_tam_ngam() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var giua := get_viewport().get_visible_rect().size * 0.5
	var tu := cam.project_ray_origin(giua)
	var den := tu + cam.project_ray_normal(giua) * 30.0

	var truy := PhysicsRayQueryParameters3D.create(tu, den)
	truy.exclude = [_than.get_rid()] if _than is CollisionObject3D else []
	var kq := get_world_3d().direct_space_state.intersect_ray(truy)
	if kq.is_empty():
		return false

	var tram := kq.get("collider") as TramTuongTac
	if tram == null:
		return false
	for i in _ung_vien.size():
		if _ung_vien[i]["tram"] == tram:
			_chi_so_chon = i
			_khoa_lua_chon()
			return true
	return false
