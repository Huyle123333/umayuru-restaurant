@tool
extends "res://scripts/interaction/workstation.gd"

const MODEL := "res://assets/models/doro.glb"

## MỌI CON SỐ chỉnh được của Doro nằm ở file riêng — sửa bên đó, không sửa ở
const Config := preload("res://scripts/restaurant/doro_main.gd")

var _agent: NavigationAgent3D
var _anim_player: AnimationPlayer
var _body: Node3D
var _player: Node3D

var _anim_now := ""
var _rest_left := 0.0
var _moving := false
var _floor_y := 0.0

## Sự kiện Asian "Trộm chó": Doro tự đi về phía cửa. Bấm vào Doro (E) là giữ
signal escaped
signal escape_stopped
var _escaping := false
var _escape_target := Vector3.ZERO


func start_escape(door: Vector3) -> void:
	_escaping = true
	_escape_target = door
	_agent.target_position = door
	_moving = true
	_set_anim("walk")


func stop_escape() -> void:
	if not _escaping:
		return
	_escaping = false
	_moving = false
	_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)
	_set_anim("idle")
	escape_stopped.emit()


func is_escaping() -> bool:
	return _escaping


## Dựng Doro. Gọi từ level_base sau khi hệ khách đã nướng xong navmesh.
func setup(seat_marker: Vector3, lech_cao: float, nguoi_choi: Node3D) -> void:
	_player = nguoi_choi
	_floor_y = seat_marker.y
	global_position = seat_marker

	display_name = "Doro"
	kind = "bin"
	pick_priority = -1

	add_to_group("station")
	collision_layer = LAYER_ITEM
	collision_mask = 0

	_build_body()
	_build_collision()
	_build_agent(lech_cao)

	_set_anim("idle")
	_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)

	if not interacted.is_connected(_on_fed):
		interacted.connect(_on_fed)


# ------------------------------------------------------------------ dựng ---

func _build_body() -> void:
	if not ResourceLoader.exists(MODEL):
		push_warning("Thiếu model Doro: %s — pet sẽ vô hình." % MODEL)
		return
	var packed := load(MODEL) as PackedScene
	if packed == null:
		return
	_body = packed.instantiate() as Node3D
	_body.name = "Mesh"
	var scale_ := Config.HEIGHT / Config.BASE_HEIGHT
	_body.scale = Vector3(scale_, scale_, scale_)
	add_child(_body)
	_anim_player = _body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player == null:
		push_warning("Model Doro không có AnimationPlayer — pet sẽ đứng đơ.")


func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var edge := Config.HEIGHT * Config.BOX_WIDTH
	box.size = Vector3(edge, Config.HEIGHT, edge)
	shape.shape = box
	shape.position = Vector3(0.0, Config.HEIGHT * 0.5, 0.0)
	add_child(shape)

	var marker := Marker3D.new()
	marker.name = "AimPoint"
	marker.position = Vector3(0.0, Config.HEIGHT + 0.12, 0.0)
	add_child(marker)
	aim_point = NodePath("AimPoint")


func _build_agent(lech_cao: float) -> void:
	_agent = NavigationAgent3D.new()
	_agent.name = "Agent"
	_agent.radius = 0.3
	_agent.height = Config.HEIGHT
	_agent.path_desired_distance = 0.3
	_agent.target_desired_distance = 0.35
	_agent.path_height_offset = lech_cao
	_agent.avoidance_enabled = false
	add_child(_agent)


# ------------------------------------------------------------------ đi lại ---

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _agent == null:
		return

	# 1. Người chơi tới gần -> đứng yên, quay mặt về phía họ.
	if _escaping:
		var to_door := _escape_target - global_position
		to_door.y = 0.0
		if to_door.length() < 1.2 or _agent.is_navigation_finished():
			_escaping = false
			escaped.emit()
			return
		var next := _agent.get_next_path_position() - global_position
		next.y = 0.0
		if next.length_squared() > 0.0001:
			next = next.normalized()
			global_position += next * Config.SPEED * 0.6 * delta
			global_position.y = _floor_y
			_turn_towards(next, delta)
		return

	if _near_player():
		if _moving:
			_moving = false
		_set_anim("idle")
		var back := _player.global_position - global_position
		back.y = 0.0
		_turn_towards(back, delta)
		return

	# 2. Đang nghỉ -> đếm ngược rồi chọn chỗ mới.
	if not _moving:
		_rest_left -= delta
		if _rest_left <= 0.0:
			_wander()
		return

	# 3. Đang đi.
	if _agent.is_navigation_finished():
		_moving = false
		_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)
		_set_anim("idle")
		return

	var to_pos := _agent.get_next_path_position()
	var dir_ := to_pos - global_position
	dir_.y = 0.0
	if dir_.length_squared() < 0.0001:
		return
	dir_ = dir_.normalized()
	global_position += dir_ * Config.SPEED * delta
	global_position.y = _floor_y
	_turn_towards(dir_, delta)


func _near_player() -> bool:
	if not is_instance_valid(_player):
		return false
	var d := _player.global_position - global_position
	d.y = 0.0
	return d.length() <= Config.NEAR_PLAYER


## Chọn chỗ đi tiếp: bốc quanh chỗ đang đứng, KẸP vào vùng cho phép, rồi nắn
func _wander() -> void:
	var nav_map := get_world_3d().navigation_map
	if not nav_map.is_valid():
		return

	var angle := randf() * TAU
	var dist := randf_range(1.5, Config.WANDER_RADIUS)
	var dest := global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	dest = _clamp_to_area(dest)
	dest = NavigationServer3D.map_get_closest_point(nav_map, dest)

	if dest.is_equal_approx(Vector3.ZERO) or not _inside_area(dest):
		_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)
		return

	_agent.target_position = dest
	_moving = true
	_set_anim("walk")


## Kéo một điểm vào trong hình chữ nhật cho phép (giữ nguyên độ cao).
static func _clamp_to_area(point: Vector3) -> Vector3:
	return Vector3(
		clampf(point.x, Config.AREA_MIN.x, Config.AREA_MAX.x),
		point.y,
		clampf(point.z, Config.AREA_MIN.y, Config.AREA_MAX.y))


## Điểm có nằm trong vùng cho phép không.
const AREA_MARGIN := 0.6

static func _inside_area(point: Vector3) -> bool:
	return point.x >= Config.AREA_MIN.x - AREA_MARGIN \
		and point.x <= Config.AREA_MAX.x + AREA_MARGIN \
		and point.z >= Config.AREA_MIN.y - AREA_MARGIN \
		and point.z <= Config.AREA_MAX.y + AREA_MARGIN


## Chỗ Doro đứng lúc màn bắt đầu: GIỮA vùng cho phép, nắn về navmesh.
static func first_stand_point(nav_map: RID, cao_san: float) -> Vector3:
	var center := Vector3(
		(Config.AREA_MIN.x + Config.AREA_MAX.x) * 0.5,
		cao_san,
		(Config.AREA_MIN.y + Config.AREA_MAX.y) * 0.5)
	if not nav_map.is_valid() or NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		return center
	var snapped_ := NavigationServer3D.map_get_closest_point(nav_map, center)
	if snapped_.is_equal_approx(Vector3.ZERO):
		return center
	snapped_.y = cao_san
	return snapped_


func _turn_towards(dir_: Vector3, delta: float) -> void:
	if dir_.length_squared() < 0.0001:
		return
	var target_yaw := atan2(dir_.x, dir_.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, Config.TURN_SPEED * delta)


# ------------------------------------------------------------------ diễn ---

func _set_anim(anim_name: String) -> void:
	if _anim_now == anim_name:
		return
	if _anim_player == null or not _anim_player.has_animation(anim_name):
		return
	_anim_now = anim_name
	_anim_player.play(anim_name)


## Nảy một cái khi người chơi bấm E vào Doro.
func _on_fed(_station: Node, _index: int) -> void:
	AmThanh.play_sfx("doro", randf_range(0.95, 1.08))
	if _escaping:
		stop_escape()
	if _body == null:
		return
	var scale_ := Config.HEIGHT / Config.BASE_HEIGHT
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "scale", Vector3(scale_ * 1.2, scale_ * 0.8, scale_ * 1.2), 0.09)
	tw.tween_property(_body, "scale", Vector3(scale_, scale_, scale_), 0.09)
