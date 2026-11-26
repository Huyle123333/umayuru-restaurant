extends Camera3D

## Kích thước bản đồ theo trục X và Z, tính từ gốc (0, 0).
@export var map_size := Vector2(32.0, 24.0)

## Mép BẮC của bản đồ (z nhỏ nhất). Map hình chữ L từ 12/11/2026: bếp kéo dài
@export var map_min_z: float = 0.0

## Độ mượt khi bám. Càng lớn càng bám sát, càng nhỏ càng "trôi" theo sau.
@export var smoothing: float = 6.0

## Có chặn camera ở mép bản đồ không. Tắt đi khi cần quay phim demo.
@export var clamp_at_edge: bool = true

## Nới thêm bấy nhiêu đơn vị ở MÉP TRÊN của khung hình (phía z nhỏ).
@export var extra_top: float = 2.0

var _player_camera: Camera3D = null
var _character: Node3D = null
## Vector từ điểm camera nhìn xuống (trên mặt sàn) tới chỗ camera đứng.
var _offset := Vector3.ZERO


func _ready() -> void:
	GameData.third_person_active = false
	GameData.view_mode_changed.connect(_apply_view)

	_offset = global_position - _ground_point()

	await get_tree().process_frame
	_character = _find_character()
	_player_camera = _find_player_camera()
	_apply_view(false)

	if _character != null:
		global_position = _target_pos()


## Bám trong _physics_process chứ không phải _process, vì nhân vật là
func _physics_process(delta: float) -> void:
	if _character == null or not current:
		return
	var factor := 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(_target_pos(), factor)


# ------------------------------------------------------------- bám theo ---

## Chỗ camera cần đứng để nhân vật nằm giữa khung hình.
func _target_pos() -> Vector3:
	var center := _character.global_position
	center.y = 0.0
	if clamp_at_edge:
		center = _clamp_to_map(center)
	return center + _offset


## Kéo tâm khung hình vào trong lòng bản đồ.
func _clamp_to_map(center: Vector3) -> Vector3:
	var aspect := float(get_viewport().get_visible_rect().size.aspect())
	var half_width := size * aspect * 0.5
	var sin_angle := absf((-global_transform.basis.z).y)
	var half_depth := (size / maxf(sin_angle, 0.05)) * 0.5

	if half_width * 2.0 >= map_size.x:
		center.x = map_size.x * 0.5
	else:
		center.x = clampf(center.x, half_width, map_size.x - half_width)

	var top_limit := map_min_z + half_depth - extra_top
	var bottom_limit := map_size.y - half_depth
	if top_limit >= bottom_limit:
		center.z = (top_limit + bottom_limit) * 0.5
	else:
		center.z = clampf(center.z, top_limit, bottom_limit)
	return center


## Điểm camera đang nhìn tới trên mặt sàn (y = 0), tính bằng giao tuyến của
func _ground_point() -> Vector3:
	var dir_ := -global_transform.basis.z
	if dir_.y >= -0.01:
		push_warning("CameraTopDown không chúc xuống mặt sàn, hướng = %s" % dir_)
		return Vector3(global_position.x, 0.0, global_position.z)
	return global_position + dir_ * (global_position.y / -dir_.y)


func _find_character() -> Node3D:
	var level := get_parent()
	if level == null or not ("player" in level):
		return null
	return level.player as Node3D


# ---------------------------------------------------------- đổi góc nhìn ---

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_view"):
		return
	if not GameData.third_person_unlocked or GameData.is_aaa_mode():
		return
	GameData.toggle_view_mode()
	get_viewport().set_input_as_handled()


func _apply_view(is_third_person: bool) -> void:
	if is_third_person and is_instance_valid(_player_camera):
		_player_camera.make_current()
	else:
		make_current()


## Tìm Camera3D bên trong scene nhân vật.
func _find_player_camera() -> Camera3D:
	if _character == null:
		return null
	for n in _character.find_children("*", "Camera3D", true, false):
		return n as Camera3D
	return null
