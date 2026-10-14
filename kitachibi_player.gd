extends CharacterBody3D
## Test controller for the chibi model exported from Blender.
## Animations expected inside the .glb: "Idle", "Run", "Run_Carry".
##
## Controls -- WASD / arrows: move | Mouse: look (goc nhin thu 3)
##             E: tuong tac / cam - dat do | Q: bo do | Shift: chay nuoc rut
##             Space: ki nang chu dong | Esc: mo menu Pause

@export_group("Movement")
## Tốc độ đi bộ. Gấp đôi mức cũ (3.2) sau khi đo lại: với map 32 × 24 và luật
## bê một món mỗi lượt, phần lớn thời gian một màn chơi là đi lại chứ không
## phải nấu — mà đi lại thì không đòi hỏi kỹ năng gì. Tăng tốc độ cắt được
## thời gian chết mà không làm món ăn dễ nấu hơn.
@export var walk_speed := 6.4
## Tốc độ khi đang bê đồ. Bằng ĐÚNG tốc độ đi bộ, cố ý.
##
## Phạt tốc độ khi bê đồ nghe có vẻ hợp lý về mặt mô phỏng, nhưng trong một
## game mà gần như lúc nào cũng đang bê một thứ gì đó thì nó chỉ có tác dụng
## kéo dài mọi chuyến đi. Người chơi không có lựa chọn nào để "chơi giỏi
## hơn" trước một hình phạt luôn luôn bật.
@export var carry_speed := 6.4
@export var acceleration := 14.0
@export var turn_speed := 14.0
## Có TRƯỢT THEO QUÁN TÍNH không.
##
## false (mặc định) — nhả phím là đứng lại ngay, đổi hướng là đổi ngay. Trong
## một game bếp, người chơi phải dừng ĐÚNG trước một trạm rộng chưa tới một ô;
## trượt thêm nửa giây là trôi qua trạm rồi phải lùi lại, và lỗi đó không do
## người chơi tính sai mà do nhân vật không nghe lời.
##
## true — vận tốc tiến dần về đích theo `acceleration` (cách cũ): khởi động
## chậm, dừng chậm, trôi khi rẽ. KHÔNG xoá nhánh này: để dành làm đặc điểm
## riêng cho một nhân vật sau này. Bật bằng cách tick ô này trên scene của
## nhân vật đó trong Inspector, không phải sửa code.
@export var slippery := false

@export_group("Sprint (Shift)")
## Nhân thêm bấy nhiêu vào tốc độ khi giữ Shift. 2,0 = chạy nhanh GẤP ĐÔI
## (6,4 -> 12,8 m/s).
##
## Bản đầu để 1,2 (+20%) với lập luận "chênh lệch lớn thì người chơi giữ Shift
## suốt và tốc độ đi bộ thành vô nghĩa". Chơi thử thì lập luận đó sai ở chỗ
## khác: +20% NHỎ TỚI MỨC KHÔNG CẢM NHẬN ĐƯỢC. Người chơi bấm Shift, không
## thấy gì đổi, rồi thôi không bấm nữa — cơ chế coi như không tồn tại, mà
## thanh thể lực trên HUD vẫn chiếm chỗ.
##
## Cái GIỚI HẠN việc lạm dụng nước rút không phải là hệ số tốc độ, mà là THANH
## THỂ LỰC: 5 giây chạy, 8 giây hồi đầy, và chỉ tiêu khi thật sự đang di
## chuyển. Giữ Shift suốt là không giữ được. Nên hệ số cứ để đủ lớn để người
## chơi CẢM THẤY, còn việc phanh lại đã có chỗ khác lo.
@export var sprint_factor := 2.0
## Giữ Shift được tối đa bao nhiêu giây khi thanh đầy.
@export var stamina_max := 5.0
## Hồi lại hết thanh mất bao nhiêu giây.
##
## Hồi CHẬM HƠN lúc tiêu (8 s so với 5 s) để nước rút là một quyết định có
## giá. Hồi nhanh bằng lúc tiêu thì cứ chạy - nghỉ - chạy là được dùng gần
## như liên tục, và cơ chế mất hết ý nghĩa.
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
##
## Khai báo `set = set_carrying` chứ không để biến trơn: hands.gd gán
## THẲNG `_than.carrying = true`, mà gán thẳng vào một biến trơn thì không
## có hàm nào chạy — nên hoạt hình bê đồ vẫn đổi (vì _physics_process đọc cờ
## mỗi frame) còn khuôn mặt thì không, vì nó chỉ đổi một lần lúc được gọi.
## Đó chính là lý do "cầm đồ vật mà model không thay đổi biểu cảm".
##
## Sửa ở ĐÂY chứ không sửa hands.gd gọi set_carrying(): đôi tay không có
## nghĩa vụ nhớ rằng đổi cờ này thì phải gọi kèm một hàm nào đó. Gắn hành vi
## vào chính biến thì mọi nơi gán nó — hôm nay và sau này — đều đúng.
var carrying := false : set = set_carrying

## Khoá di chuyển khi một bảng chọn đang mở.
##
## Cần vì W/S vừa là phím đi lại vừa là phím đổi nguyên liệu trong bảng. Để
## cả hai cùng nhận thì mỗi lần đổi món nhân vật lại nhích lên nhích xuống.
## Chỉ khoá NHÂN VẬT, không dừng game — thanh kiên nhẫn của khách vẫn chạy,
## nên đứng mở tủ lạnh vẫn là quyết định tốn thời gian thật.
var movement_locked := false

## Thanh thể lực, tính bằng GIÂY còn lại chứ không phải phần trăm — nhờ vậy
## trừ đi mỗi frame chỉ là `_stamina -= delta`, không phải quy đổi gì.
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


func _ready() -> void:
	_stamina = stamina_max
	_model = $Model
	_pivot = $CameraPivot
	_arm = $CameraPivot/SpringArm3D
	# Nhãn chẩn đoán (tên animation, cờ cầm đồ, gợi ý phím không dấu) còn sót
	# trong scene nhân vật từ hồi dựng điều khiển. Xoá lúc chạy chứ không sửa
	# bảy file player_*.tscn: một chỗ sửa thay vì bảy, và nhân vật thêm sau
	# này có lỡ chép node đó theo thì cũng tự biến mất.
	var debug_label := get_node_or_null("HUD")
	if debug_label != null:
		debug_label.queue_free()

	_anim = _find_first(self, "AnimationPlayer") as AnimationPlayer
	_mesh = _find_biggest_mesh(self)

	if _anim == null:
		push_error("Khong tim thay AnimationPlayer trong model.")
	else:
		# glTF does not carry loop flags -- set them here.
		for anim_name in _anim.get_animation_list():
			var a := _anim.get_animation(anim_name)
			if a: a.loop_mode = Animation.LOOP_LINEAR
		print("Animations: ", _anim.get_animation_list())

	_cache_face_materials()
	_apply_face(eye_cell_normal, mouth_cell_normal)
	# Chuột chỉ bị khoá khi đang ở góc nhìn thứ 3. Ở top-down không có gì để
	# xoay, mà khoá chuột thì người chơi không rê ra ngoài cửa sổ được.
	GameData.view_mode_changed.connect(_on_view_mode_changed)
	_on_view_mode_changed(GameData.third_person_active)
	_play("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Nhân thêm hệ số người chơi chỉnh trong cửa sổ Cài đặt.
		var sens := mouse_sensitivity * SettingsManager.mouse_sensitivity
		_yaw -= event.relative.x * sens
		_pitch = clamp(_pitch + event.relative.y * sens, pitch_min, pitch_max)
	# Phím E KHÔNG xử lý ở đây nữa.
	#
	# Trước kia E là công tắc thử nghiệm: bấm một cái là đổi cờ `carrying`
	# để xem hoạt hình "Run_Carry" và khuôn mặt lúc bê đồ. Giờ E đã là phím
	# tương tác thật (bộ chọn mục tiêu bấm trạm, đôi tay cầm/đặt đồ), nên
	# giữ lại công tắc cũ là để hai thứ tranh nhau một phím: bấm E lấy
	# nguyên liệu xong thì hoạt hình bê đồ tự bật/tắt loạn xạ, và cờ
	# `carrying` — thứ quyết định tốc độ và hoạt hình — không còn phản ánh
	# đúng tay có đang cầm gì không.
	#
	# Từ giờ chỉ hands.gd được đặt `carrying`, và chỉ khi thật sự cầm hay
	# đặt một vật xuống. Một trạng thái chỉ nên có ĐÚNG MỘT nơi ghi vào.
	#
	# Esc cũng không xử lý ở đây: trước kia nhân vật nuốt phím này để nhả
	# chuột nên menu Pause không bao giờ nhận được. Giờ Esc là action
	# "pause", để pause_menu.gd lo.
	elif event is InputEventMouseButton and event.pressed:
		# Chỉ bắt lại chuột khi đang ở góc nhìn thứ 3; ở top-down thì một cú
		# click vào màn hình không được phép khoá chuột lại.
		if GameData.third_person_active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_pivot.rotation.y = _yaw
	_arm.rotation.x = -_pitch

	# Vẫn giữ trọng lực dù đã bỏ nhảy: nhân vật sinh ra ở PlayerSpawn cao hơn
	# mặt sàn một chút, và sàn bếp có bậc. Không có trọng lực thì nhân vật
	# đứng lơ lửng ở đúng độ cao được sinh ra.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Vector2.ZERO
	if not movement_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Ở góc nhìn thứ 3, hướng đi tính theo góc xoay của camera (_yaw).
	# Ở top-down camera đứng yên và chỉ nghiêng quanh trục X, nên "lên màn
	# hình" luôn là -Z của thế giới — dùng yaw = 0 là khớp đúng.
	var yaw := _yaw if GameData.third_person_active else 0.0
	var dir := (Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := carry_speed if carrying else walk_speed
	speed *= _update_sprint(delta, dir.length() > 0.01)

	# Vận tốc ngang muốn có ở khung hình này (0 nếu không bấm phím nào).
	var wanted := dir * speed
	if slippery:
		# Quán tính: tiến DẦN về vận tốc muốn có.
		velocity.x = move_toward(velocity.x, wanted.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, wanted.z, acceleration * delta)
	else:
		# Gán THẲNG: bấm là đi, nhả là dừng. Chỉ đụng x và z — y thuộc về
		# trọng lực ở trên.
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
##
## Chỉ TIÊU thể lực khi thật sự đang di chuyển. Giữ Shift đứng yên mà vẫn
## cạn thanh thì người chơi bị phạt vì một thao tác không đem lại gì —
## kiểu lỗi khiến họ phải nhớ nhả phím mỗi lần dừng, thêm việc vặt chứ
## không thêm chiều sâu.
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
## giao xong một đơn.)
func refill_stamina() -> void:
	_stamina = stamina_max
	_regen_timer = 0.0


## Tỉ lệ thể lực còn lại (0..1) — HUD đọc giá trị này để vẽ thanh.
func stamina_ratio() -> float:
	return _stamina / stamina_max if stamina_max > 0.0 else 0.0


func is_sprinting() -> bool:
	return _sprinting


## Đổi góc nhìn: khoá chuột khi vào góc nhìn thứ 3, nhả ra khi về top-down.
## Camera nào được bật do camera_top_down.gd lo, ở đây chỉ lo phần điều khiển.
func _on_view_mode_changed(is_third_person: bool) -> void:
	if is_third_person:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Trả góc xoay về 0 để lần sau bật lại không bị lệch một góc lạ.
		_yaw = 0.0
		_pitch = 0.0


func set_carrying(value: bool) -> void:
	# Gán vào `carrying` bên trong chính hàm setter của nó KHÔNG gọi lại
	# setter — GDScript truy cập thẳng ô nhớ ở đây, nên không có đệ quy.
	carrying = value
	if carrying:
		_apply_face(eye_cell_carry, mouth_cell_carry)
	else:
		_apply_face(eye_cell_normal, mouth_cell_normal)


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
		var dup := src.duplicate()          # unique per instance
		_mesh.set_surface_override_material(i, dup)
		var n := String(src.resource_name).to_lower()
		if n.contains("_eye"):
			_eye_mats.append(dup)
		elif n.contains("_mouth"):
			_mouth_mats.append(dup)
	print("Face materials -> eye: %d, mouth: %d" % [_eye_mats.size(), _mouth_mats.size()])


func _apply_face(eye_cell: Vector2i, mouth_cell: Vector2i) -> void:
	# Blender V axis is flipped on glTF export, so the row offset is positive here.
	for m in _eye_mats:
		m.uv1_offset = Vector3(float(eye_cell.x) / eye_grid.x, float(eye_cell.y) / eye_grid.y, 0.0)
	for m in _mouth_mats:
		m.uv1_offset = Vector3(float(mouth_cell.x) / mouth_grid.x, float(mouth_cell.y) / mouth_grid.y, 0.0)
