class_name TargetPicker
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
signal candidates_changed(candidates: Array, selected_index: int)

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
@export var reach_width: float = 1.9
@export var reach_height: float = 3.2
## Sau khi bấm Tab, khoá lựa chọn bằng tay trong bao lâu (giây).
@export var hand_lock_time: float = 2.0

## Mỗi phần tử: { "tram": TramTuongTac, "chi_so": int, "nhan": String }
var _candidates: Array[Dictionary] = []
var _selected: int = -1
var _hand_lock: float = 0.0
## Nhớ lựa chọn đang khoá để giữ đúng nó khi danh sách thay đổi thứ tự.
var _locked_station: Workstation = null
var _locked_index: int = 0

var _body: Node3D = null
## Hình hộp dùng để dò. Giữ tham chiếu để mỗi frame lấy lại đúng vị trí của nó.
var _shape: CollisionShape3D = null


func _ready() -> void:
	_body = get_parent() as Node3D
	monitoring = true
	monitorable = false
	# Nhìn thấy cả nội thất (lớp 1) lẫn vật phẩm rơi dưới đất (lớp 3) — nhân
	# vật thì chỉ va chạm với lớp 1, nên đi xuyên qua vật phẩm được.
	collision_mask = Workstation.STATION_MASK
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(reach_width, reach_height, reach_width)
	_shape.shape = box
	# Gốc toạ độ nhân vật nằm ở chân, nên đẩy hộp lên nửa chiều cao thì đáy
	# hộp trùng mặt sàn và đỉnh chạm quá nóc thùng tầng trên.
	_shape.position = Vector3(0.0, reach_height * 0.5, 0.0)
	add_child(_shape)


func _process(delta: float) -> void:
	if _hand_lock > 0.0:
		_hand_lock -= delta
	_build_candidates()


# ------------------------------------------------------------ danh sách ---

## Dựng lại danh sách ứng viên mỗi frame.
##
## Thứ tự sắp xếp theo GÓC quanh nhân vật chứ không theo khoảng cách. Lý do:
## khoảng cách thay đổi liên tục khi đi lại nên thứ tự sẽ nhảy loạn, bấm Tab
## hai lần giống nhau ra hai kết quả khác nhau. Sắp theo góc thì Tab luôn chạy
## vòng quanh theo một chiều cố định — đoán trước được.
func _build_candidates() -> void:
	var prev_size := _candidates.size()
	var prev_sel := _selected
	_candidates.clear()

	var center_pos := global_position
	for body in _probe_collisions():
		var station := body as Workstation
		if station == null:
			continue
		var v := station.aim_position() - center_pos
		var angle := atan2(v.x, v.z)
		for i in station.target_count():
			_candidates.append({
				"station": station,
				"index": i,
				"label": station.target_label(i),
				"_angle": angle,
				"_dist": v.length(),
			})
	_candidates.sort_custom(_compare_angle)

	_selected = _find_choice()

	if _candidates.size() != prev_size or _selected != prev_sel:
		candidates_changed.emit(_candidates, _selected)


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
func _probe_collisions() -> Array:
	if _shape == null or _body == null:
		return []
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# Bỏ chính nhân vật ra: hộp dò nằm ôm quanh thân nên lúc nào cũng chạm
	# chính mình, và mỗi frame lại phải lọc lại một phần tử vô nghĩa.
	if _body is CollisionObject3D:
		query.exclude = [(_body as CollisionObject3D).get_rid()]

	var out: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(query, 12):
		out.append(r["collider"])
	return out


## Hàm so sánh viết rời thay vì lambda nhiều dòng ngay trong lời gọi.
## Lambda nhiều dòng của GDScript rất kén chỗ đặt dấu đóng ngoặc; viết rời thì
## không bao giờ vướng, và đặt breakpoint để soi thứ tự cũng dễ hơn.
static func _compare_angle(a: Dictionary, b: Dictionary) -> bool:
	if is_equal_approx(float(a["_angle"]), float(b["_angle"])):
		return int(a["index"]) < int(b["index"])
	return float(a["_angle"]) < float(b["_angle"])


func _find_choice() -> int:
	if _candidates.is_empty():
		_locked_station = null
		return -1

	# Đang khoá bằng tay: giữ đúng mục tiêu đó nếu nó còn trong tầm.
	if _hand_lock > 0.0 and is_instance_valid(_locked_station):
		for i in _candidates.size():
			if _candidates[i]["station"] == _locked_station and _candidates[i]["index"] == _locked_index:
				return i
		# Ra khỏi tầm rồi thì bỏ khoá luôn, không giữ một mục tiêu đã biến mất.
		_hand_lock = 0.0

	# Chấm điểm theo hướng quay mặt. Tích vô hướng của hướng nhìn với hướng
	# tới mục tiêu: 1.0 là ngay trước mặt, -1.0 là sau lưng. Trừ một chút theo
	# khoảng cách để hai mục tiêu cùng hướng thì cái gần hơn thắng.
	var dir := -_body.global_transform.basis.z if _body != null else Vector3.FORWARD
	dir.y = 0.0
	dir = dir.normalized()

	var best := -INF
	var choice := 0
	for i in _candidates.size():
		var station: Workstation = _candidates[i]["station"]
		var v: Vector3 = station.aim_position() - global_position
		v.y = 0.0
		if v.length() < 0.001:
			continue
		var point: float = dir.dot(v.normalized()) - float(_candidates[i]["_dist"]) * 0.08
		if point > best:
			best = point
			choice = i
	return choice


# ---------------------------------------------------------------- nhập ---

func _unhandled_input(event: InputEvent) -> void:
	if _candidates.is_empty():
		return

	if event.is_action_pressed("chon_muc_tieu"):
		_selected = (_selected + 1) % _candidates.size()
		_lock_choice()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_activate()
		get_viewport().set_input_as_handled()
		return

	# F đi qua ĐÚNG bộ chọn này, không phải một đường riêng.
	#
	# Nhờ vậy F thừa hưởng nguyên vẹn mọi luật đã có của E: phải đứng đủ gần,
	# chọn được bằng Tab, chọn được bằng tâm ngắm ở góc nhìn thứ ba. Cho F một
	# đường bắt phím riêng trong tay_cam thì hai phím sẽ nhắm vào hai thứ khác
	# nhau đúng lúc trong bếp có nhiều trạm sát nhau.
	if event.is_action_pressed("rap_mon"):
		_activate_alt()
		get_viewport().set_input_as_handled()
		return

	# Góc nhìn thứ 3: chuột đang bị khoá nên tâm ngắm luôn ở giữa màn hình.
	# Bắn tia từ tâm camera để người chơi trỏ thẳng vào trạm mình muốn, thay
	# vì Tab. Tab VẪN dùng được — hai cách song song, tuỳ người chơi.
	if GameData.third_person_active and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pick_by_crosshair():
			_activate()
		get_viewport().set_input_as_handled()


func _lock_choice() -> void:
	_locked_station = _candidates[_selected]["station"]
	_locked_index = _candidates[_selected]["index"]
	_hand_lock = hand_lock_time
	candidates_changed.emit(_candidates, _selected)


func _activate() -> void:
	if _selected < 0 or _selected >= _candidates.size():
		return
	var m := _candidates[_selected]
	(m["station"] as Workstation).interact(m["index"])


func _activate_alt() -> void:
	if _selected < 0 or _selected >= _candidates.size():
		return
	var m := _candidates[_selected]
	(m["station"] as Workstation).interact_alt(m["index"])


## Bắn tia từ giữa màn hình. Trả về true nếu trúng một trạm đang trong tầm.
##
## Chỉ chấp nhận trạm CÓ TRONG danh sách ứng viên: nhìn thấy chưa đủ, vẫn phải
## đứng đủ gần. Nếu không, người chơi sẽ nấu được món ở đầu bên kia phòng.
func _pick_by_crosshair() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var center := get_viewport().get_visible_rect().size * 0.5
	var from_pt := cam.project_ray_origin(center)
	var to_pt := from_pt + cam.project_ray_normal(center) * 30.0

	var query := PhysicsRayQueryParameters3D.create(from_pt, to_pt)
	query.exclude = [_body.get_rid()] if _body is CollisionObject3D else []
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false

	var station := result.get("collider") as Workstation
	if station == null:
		return false
	for i in _candidates.size():
		if _candidates[i]["station"] == station:
			_selected = i
			_lock_choice()
			return true
	return false
