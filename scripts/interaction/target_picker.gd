class_name TargetPicker
extends Area3D

## Danh sách đã đổi hoặc lựa chọn đã đổi — HUD nghe tín hiệu này.
signal candidates_changed(candidates: Array, selected_index: int)

## Vùng với: một khối hộp ÔM SÁT người chơi theo chiều ngang, nhưng CAO.
@export var reach_width: float = 1.9
@export var reach_height: float = 3.2
## Sau khi bấm Tab, khoá lựa chọn bằng tay trong bao lâu (giây).
@export var hand_lock_time: float = 2.0

## Mỗi phần tử: { "station": Workstation, "index": int, "label": String }
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
	collision_mask = Workstation.STATION_MASK
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(reach_width, reach_height, reach_width)
	_shape.shape = box
	_shape.position = Vector3(0.0, reach_height * 0.5, 0.0)
	add_child(_shape)


func _process(delta: float) -> void:
	if _hand_lock > 0.0:
		_hand_lock -= delta
	_build_candidates()


# ------------------------------------------------------------ danh sách ---

## Dựng lại danh sách ứng viên mỗi frame.
func _build_candidates() -> void:
	var prev_sig := _signature()
	var prev_keys := _keys()
	_candidates.clear()

	var center_pos := global_position
	var seen := {}
	for body in _probe_collisions():
		var station := body as Workstation
		if station != null and station.has_reach():
			continue
		if station == null and body is Node and (body as Node).name == "Reach":
			station = (body as Node).get_parent() as Workstation
		if station == null or seen.has(station):
			continue
		seen[station] = true
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
	_keep_previous_order(prev_keys)

	_selected = _find_choice()

	if _signature() != prev_sig:
		candidates_changed.emit(_candidates, _selected)
	_update_highlight()


## Trả về danh sách vật thể đang chạm hộp với.
func _probe_collisions() -> Array:
	if _shape == null or _body == null:
		return []
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if _body is CollisionObject3D:
		query.exclude = [(_body as CollisionObject3D).get_rid()]

	var out: Array = []
	for r in get_world_3d().direct_space_state.intersect_shape(query, MAX_HITS):
		out.append(r["collider"])
	return out


## Số vật chạm tối đa một lần dò. Dư thừa có chủ ý: chi phí gần như không đổi,
const MAX_HITS := 64


## Khoá (trạm, mục) của từng ứng viên, theo đúng thứ tự trong danh sách.
func _keys() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _candidates:
		out.append("%d:%d" % [(c["station"] as Object).get_instance_id(), int(c["index"])])
	return out


## Nếu TẬP ứng viên không đổi so với khung trước thì giữ nguyên THỨ TỰ cũ.
func _keep_previous_order(prev_keys: PackedStringArray) -> void:
	if prev_keys.size() != _candidates.size() or prev_keys.is_empty():
		return
	var now := _keys()
	var by_key := {}
	for i in _candidates.size():
		by_key[now[i]] = _candidates[i]
	for k in prev_keys:
		if not by_key.has(k):
			return
	var ordered: Array[Dictionary] = []
	for k in prev_keys:
		ordered.append(by_key[k])
	_candidates = ordered


## Chữ ký của danh sách hiện tại, để biết có gì thật sự thay đổi không.
func _signature() -> String:
	return "%s|%d" % [",".join(_keys()), _selected]


## Hàm so sánh viết rời thay vì lambda nhiều dòng ngay trong lời gọi.
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
		_hand_lock = 0.0

	var dir := -_body.global_transform.basis.z if _body != null else Vector3.FORWARD
	dir.y = 0.0
	dir = dir.normalized()

	var top_priority := -1000000
	for c in _candidates:
		top_priority = maxi(top_priority, int((c["station"] as Workstation).pick_priority))

	var best := -INF
	var choice := 0
	for i in _candidates.size():
		var station: Workstation = _candidates[i]["station"]
		if station.pick_priority < top_priority:
			continue
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

## Khoá mọi tương tác (E/F/Tab). Màn hướng dẫn bật trong lúc người chơi chưa
var locked := false

## Màn hướng dẫn: chỉ cho bấm vào các loại trạm trong danh sách này (rỗng =
var allowed_kinds: Array = []
signal blocked(station: Node)


func _allowed(station: Workstation) -> bool:
	if allowed_kinds.is_empty() or allowed_kinds.has(String(station.kind)):
		return true
	blocked.emit(station)
	return false


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if _candidates.is_empty():
		return

	if event.is_action_pressed("cycle_target"):
		_selected = (_selected + 1) % _candidates.size()
		_lock_choice()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		_activate()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("assemble"):
		_activate_alt()
		get_viewport().set_input_as_handled()
		return

	if GameData.third_person_active and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pick_by_crosshair():
			_activate()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------- viền nhấp nháy ---

## Viền nhấp nháy quanh trạm SẼ nhận phím E.
const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;
uniform vec4 color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float width = 0.08;
void vertex() {
	// Bề dày tính theo mét thế giới: chia cho tỉ lệ của node để model
	// phóng to hay thu nhỏ trong map vẫn có viền dày như nhau.
	float s = length(MODEL_MATRIX[0].xyz);
	VERTEX += normalize(VERTEX + vec3(0.0, 0.0001, 0.0)) * width / max(s, 0.001);
}
void fragment() {
	ALBEDO = color.rgb;
	// Nhấp nháy khoảng 2,5 lần/giây, không tắt hẳn để vẫn thấy khi đang mờ.
	ALPHA = 0.45 + 0.55 * (0.5 + 0.5 * sin(TIME * 16.0));
}
"""
static var _outline_mat: ShaderMaterial = null
var _hl_station: Workstation = null
## Mesh đang được tô viền -> overlay cũ của nó (để trả lại y nguyên).
var _hl_meshes: Dictionary = {}


static func _outline() -> ShaderMaterial:
	if _outline_mat == null:
		var sh := Shader.new()
		sh.code = OUTLINE_SHADER
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = sh
	return _outline_mat


## Gọi mỗi frame sau khi chọn xong. Chỉ làm việc khi trạm được chọn ĐỔI, nên
func _update_highlight() -> void:
	var want: Workstation = null
	if not locked and _selected >= 0 and _selected < _candidates.size():
		want = _candidates[_selected]["station"]
	if want == _hl_station:
		return
	_clear_highlight()
	if want == null or not is_instance_valid(want):
		return
	_hl_station = want
	for mi in want.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var old: Material = m.material_overlay
		_hl_meshes[m] = old
		if old == null:
			m.material_overlay = _outline()
		else:
			var copy := old.duplicate() as Material
			copy.next_pass = _outline()
			m.material_overlay = copy


func _clear_highlight() -> void:
	for m in _hl_meshes:
		if is_instance_valid(m):
			(m as MeshInstance3D).material_overlay = _hl_meshes[m]
	_hl_meshes.clear()
	_hl_station = null


func _exit_tree() -> void:
	_clear_highlight()


func _lock_choice() -> void:
	_locked_station = _candidates[_selected]["station"]
	_locked_index = _candidates[_selected]["index"]
	_hand_lock = hand_lock_time
	candidates_changed.emit(_candidates, _selected)


func _activate() -> void:
	if _selected < 0 or _selected >= _candidates.size():
		return
	var m := _candidates[_selected]
	if not _allowed(m["station"] as Workstation):
		return
	(m["station"] as Workstation).interact(m["index"])


func _activate_alt() -> void:
	if _selected < 0 or _selected >= _candidates.size():
		return
	var m := _candidates[_selected]
	if not _allowed(m["station"] as Workstation):
		return
	(m["station"] as Workstation).interact_alt(m["index"])


## Bắn tia từ giữa màn hình. Trả về true nếu trúng một trạm đang trong tầm.
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
