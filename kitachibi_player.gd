extends CharacterBody3D

@export_group("Movement")
## Tốc độ đi bộ. Gấp đôi mức cũ (3.2) sau khi đo lại: với map 32 × 24 và luật
@export var walk_speed := 6.4
## Tốc độ khi đang bê đồ. Bằng ĐÚNG tốc độ đi bộ, cố ý.
@export var carry_speed := 6.4
@export var acceleration := 14.0
@export var turn_speed := 14.0
## Có TRƯỢT THEO QUÁN TÍNH không.
@export var slippery := false

@export_group("Sprint (Shift)")
## Nhân thêm bấy nhiêu vào tốc độ khi giữ Shift. 2,0 = chạy nhanh GẤP ĐÔI
@export var sprint_factor := 2.0
## Giữ Shift được tối đa bao nhiêu giây khi thanh đầy.
@export var stamina_max := 5.0
## Hồi lại hết thanh mất bao nhiêu giây.
@export var stamina_regen := 8.0
## Phải chờ bao lâu sau khi nhả Shift mới bắt đầu hồi.
@export var regen_delay := 0.6

@export_group("Camera")
@export var mouse_sensitivity := 0.0035
@export var pitch_min := -0.55
@export var pitch_max := 1.05

@export_group("Model")
## The exported model faces +Z (Blender forward -Y). Untick if yours faces -Z.
@export var model_faces_plus_z := true

@export_group("Face expression (atlas cells, counted from 0)")
@export var eye_grid := Vector2i(8, 8)
@export var mouth_grid := Vector2i(4, 8)
@export var eye_cell_normal := Vector2i(0, 0)
@export var mouth_cell_normal := Vector2i(0, 0)
@export var eye_cell_carry := Vector2i(6, 1)
@export var mouth_cell_carry := Vector2i(2, 4)

## Tay có đang cầm gì không. Quyết định tốc độ, hoạt hình VÀ biểu cảm.
var carrying := false : set = set_carrying

## Khoá di chuyển khi một bảng chọn đang mở.
var movement_locked := false

## Thanh thể lực, tính bằng GIÂY còn lại chứ không phải phần trăm — nhờ vậy
var _stamina := 0.0
var _regen_timer := 0.0
var _sprinting := false

var _model: Node3D
var _anim: AnimationPlayer
var _mesh: MeshInstance3D
var _pivot: Node3D
var _arm: SpringArm3D

var _eye_mats: Array = []
var _mouth_mats: Array = []
var _yaw := 0.0
var _pitch := 0.35

## Hai node hiệu ứng choáng, dựng lần đầu khi set_dizzy(true).
var _dizzy_head: DizzyHeadModifier
var _dizzy_stars: DizzyStars


func _ready() -> void:
	_stamina = stamina_max
	_model = $Model
	_pivot = $CameraPivot
	_arm = $CameraPivot/SpringArm3D
	var debug_label := get_node_or_null("HUD")
	if debug_label != null:
		debug_label.queue_free()

	_anim = _find_first(self, "AnimationPlayer") as AnimationPlayer
	_mesh = _find_biggest_mesh(self)

	if _anim == null:
		push_error("Khong tim thay AnimationPlayer trong model.")
	else:
		for anim_name in _anim.get_animation_list():
			var a := _anim.get_animation(anim_name)
			if a: a.loop_mode = Animation.LOOP_LINEAR
		print("Animations: ", _anim.get_animation_list())

	_cache_face_materials()
	_apply_face(eye_cell_normal, mouth_cell_normal)
	GameData.view_mode_changed.connect(_on_view_mode_changed)
	_on_view_mode_changed(GameData.third_person_active)
	_play("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sensitivity * SettingsManager.mouse_sensitivity
		_yaw -= event.relative.x * sens
		_pitch = clamp(_pitch + event.relative.y * sens, pitch_min, pitch_max)
	elif event is InputEventMouseButton and event.pressed:
		if GameData.third_person_active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_pivot.rotation.y = _yaw
	_arm.rotation.x = -_pitch

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Vector2.ZERO
	if not movement_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var yaw := _yaw if GameData.third_person_active else 0.0
	var dir := (Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := carry_speed if carrying else walk_speed
	speed *= _update_sprint(delta, dir.length() > 0.01)

	# Vận tốc ngang muốn có ở khung hình này (0 nếu không bấm phím nào).
	var wanted := dir * speed
	if slippery:
		velocity.x = move_toward(velocity.x, wanted.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, wanted.z, acceleration * delta)
	else:
		velocity.x = wanted.x
		velocity.z = wanted.z

	if dir.length() > 0.01:
		var target := atan2(dir.x, dir.z)
		if not model_faces_plus_z:
			target += PI
		_model.rotation.y = lerp_angle(_model.rotation.y, target, turn_speed * delta)
		_play("Run_Carry" if carrying else "Run")
	else:
		_play("Idle")

	move_and_slide()


## Xử lý thể lực, trả về hệ số nhân tốc độ cho frame này.
func _update_sprint(delta: float, dang_di: bool) -> float:
	var want_sprint: bool = Input.is_action_pressed("dash") and dang_di and _stamina > 0.0
	_sprinting = want_sprint

	if want_sprint:
		_stamina = maxf(_stamina - delta, 0.0)
		_regen_timer = regen_delay
		return sprint_factor

	if _regen_timer > 0.0:
		_regen_timer -= delta
	else:
		_stamina = minf(_stamina + delta * (stamina_max / stamina_regen), stamina_max)
	return 1.0


## Nạp ĐẦY thanh thể lực ngay lập tức. (Oguri Cap — Hốc trưởng gọi mỗi khi
func refill_stamina() -> void:
	_stamina = stamina_max
	_regen_timer = 0.0


## Tỉ lệ thể lực còn lại (0..1) — HUD đọc giá trị này để vẽ thanh.
func stamina_ratio() -> float:
	return _stamina / stamina_max if stamina_max > 0.0 else 0.0


func is_sprinting() -> bool:
	return _sprinting


## Đổi góc nhìn: khoá chuột khi vào góc nhìn thứ 3, nhả ra khi về top-down.
func _on_view_mode_changed(is_third_person: bool) -> void:
	if is_third_person:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_yaw = 0.0
		_pitch = 0.0


func set_carrying(value: bool) -> void:
	carrying = value
	if carrying:
		_apply_face(eye_cell_carry, mouth_cell_carry)
	else:
		_apply_face(eye_cell_normal, mouth_cell_normal)


## Bật/tắt hiệu ứng CHOÁNG: sao bay quanh đầu + đầu đảo vòng.
func set_dizzy(on: bool) -> void:
	if _dizzy_head == null:
		var skeleton := _find_first(self, "Skeleton3D") as Skeleton3D
		if skeleton == null:
			return
		_dizzy_head = DizzyHeadModifier.new()
		skeleton.add_child(_dizzy_head)
		_dizzy_stars = DizzyStars.new()
		add_child(_dizzy_stars)
		_dizzy_stars.setup(skeleton, _dizzy_head.head_bone)
	_dizzy_head.dizzy = on
	_dizzy_stars.visible = on

# ---------------------------------------------------------------- helpers ---

func _play(clip: String) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _anim.current_animation != clip:
		_anim.play(clip, 0.15)


func _find_first(node: Node, cls: String) -> Node:
	for child in node.get_children():
		if child.is_class(cls):
			return child
		var found := _find_first(child, cls)
		if found != null:
			return found
	return null


func _find_biggest_mesh(node: Node) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_count := -1
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			var c: int = child.mesh.get_surface_count()
			if c > best_count:
				best_count = c
				best = child
		var deeper := _find_biggest_mesh(child)
		if deeper != null and deeper.mesh.get_surface_count() > best_count:
			best_count = deeper.mesh.get_surface_count()
			best = deeper
	return best


func _cache_face_materials() -> void:
	_eye_mats.clear()
	_mouth_mats.clear()
	if _mesh == null:
		push_error("Khong tim thay MeshInstance3D.")
		return
	for i in _mesh.mesh.get_surface_count():
		var src := _mesh.get_active_material(i)
		if src == null:
			continue
		var dup := src.duplicate()
		_mesh.set_surface_override_material(i, dup)
		var n := String(src.resource_name).to_lower()
		if n.contains("_eye"):
			_eye_mats.append(dup)
		elif n.contains("_mouth"):
			_mouth_mats.append(dup)
	print("Face materials -> eye: %d, mouth: %d" % [_eye_mats.size(), _mouth_mats.size()])


func _apply_face(eye_cell: Vector2i, mouth_cell: Vector2i) -> void:
	for m in _eye_mats:
		m.uv1_offset = Vector3(float(eye_cell.x) / eye_grid.x, float(eye_cell.y) / eye_grid.y, 0.0)
	for m in _mouth_mats:
		m.uv1_offset = Vector3(float(mouth_cell.x) / mouth_grid.x, float(mouth_cell.y) / mouth_grid.y, 0.0)
