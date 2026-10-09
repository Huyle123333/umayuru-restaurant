@tool
extends CharacterBody3D
## Một người khách. CHỈ biết đi và diễn: đi tới một điểm, đứng chờ, ăn, rồi về.
##
## Không biết đơn hàng, không biết tiền, không biết bàn nào còn trống — tất cả
## những thứ đó do customer_manager.gd quyết rồi RA LỆNH xuống đây. Lý do tách:
## luật nhà hàng (ai ngồi bàn nào, đơn nào khớp món nào) sẽ còn đổi rất nhiều,
## còn "đi từ A tới B rồi phát tín hiệu đã tới" thì gần như không đổi. Trộn hai
## thứ vào một file thì mỗi lần sửa luật lại phải đọc qua cả phần điều khiển.
##
## KHÔNG đặt class_name: level_base nạp mọi hệ thống bằng load() lúc chạy để
## một lỗi cú pháp ở đây không kéo sập cả màn chơi. class_name phân giải lúc
## biên dịch nên sẽ phá mất lớp bảo vệ đó.

## Đi tới nơi rồi. `viec` là chuỗi do người ra lệnh gửi kèm lúc gọi go_to(),
## trả lại nguyên vẹn để bên đó biết đây là chuyến nào — nhờ vậy máy trạng
## thái NẰM Ở quản lý, còn ở đây chỉ có "đang đi" và "đứng yên".
signal arrived(customer: Node, task: String)
## Ăn xong.
signal ate(customer: Node)

## Cỡ người khách. 1,0 = đúng cỡ model gốc (cao 1,52 đơn vị).
##
## ĐÂY LÀ Ô DUY NHẤT CẦN CHỈNH. Mở scenes/restaurant/customer.tscn, chọn node gốc
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
##
## (1/10/2026) Đổi tên từ `patience_ratio`. Tên cũ là lỗi của đợt đổi tên sang
## tiếng Anh: "tỉ lệ" bị dịch theo nghĩa của order.patience_ratio() (tỉ lệ
## kiên nhẫn còn lại), trong khi số này là CỠ THÂN. Đọc tên cũ thì tưởng
## khách to ra là khách kiên nhẫn hơn.
@export var body_scale: float = 1.3:
	set(v):
		body_scale = maxf(0.1, v)
		_apply_scale()

## Cỡ gốc, dùng làm mốc nhân. Phải trùng số trong customer.tscn.
const BASE_RADIUS := 0.4
const BASE_HEIGHT := 1.5
const BASE_AGENT_RADIUS := 0.45
const BASE_BUBBLE_HEIGHT := 2.05

const SPEED := 2.6
## Xoay người mượt thay vì bẻ lái tức thì. Đơn vị: radian mỗi giây.
const TURN_SPEED := 8.0
const GRAVITY := 24.0

@onready var _agent: NavigationAgent3D = $Agent
var _anim_player: AnimationPlayer = null
@onready var _bubble: Node3D = $Bubble

var _task := ""
var _moving := false
## Hướng quay đích khi đứng yên (ví dụ quay mặt vào bàn). Vector3.ZERO = kệ.
var _face_dir := Vector3.ZERO
var _anim_now := ""


## Các model khách. Mỗi người khách bốc NGẪU NHIÊN một model khi sinh ra.
##
##   path   — file .glb. Đường dẫn dạng CHUỖI rồi load() lúc chạy, chứ không kéo
##            PackedScene vào scene: thiếu một file (chưa xuất xong) thì model
##            đó tự bị bỏ qua thay vì làm hỏng cả scene khách.
##   weight — trọng số bốc, tính theo TỈ LỆ trên tổng. Hiện năm model bằng
##            nhau; muốn một khách hiếm thì cho trọng số nhỏ hơn hẳn số còn lại.
##   scale  — nhân thêm vào body_scale, cho model có cỡ gốc khác các model
##            Umamusume (1,5–1,7 đơn vị).
##
## Model trong customer.tscn (Akikawa) là dự phòng khi không nạp được cái nào.
## Mọi model phải có cùng bốn animation idle / walk / eat / angry.
const MODELS := [
	{"path": "res://assets/models/khach_akikawa.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_tazuna.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_hello.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_riko.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_etsuko.glb", "weight": 1.0, "scale": 1.0},
	# KHÁCH HIẾM: Spiki (Trickcal). 1% = 1 phần trong 100, mà năm model trên đã
	# chiếm 5 phần, nên trọng số của Spiki là 5 / 99 ≈ 0,0505.
	# scale 1,3: model chibi cao 0,75, nhân body_scale 2 và 1,3 thành ~1,95 —
	# đúng chiều cao nhân vật chibi người chơi điều khiển.
	# Rig Biped của 3ds Max, khác hẳn Umamusume, nên animation dựng riêng trong
	# assets/npc/spiki/spiki_v2.blend, nhưng vẫn cùng bốn tên clip.
	{"path": "res://assets/models/customer_spiki.glb", "weight": 5.0 / 99.0, "scale": 1.3},
]

## Animation phải LẶP. glTF không mang được cờ lặp, nên đặt ở đây lúc chạy thay
## vì sửa tay file .import của từng model — thêm model mới không phải nhớ bước
## đó. `angry` cố ý không lặp: cáu là cử chỉ diễn một lần.
const LOOPING_ANIMS := ["idle", "walk", "eat"]

## Model nạp sẵn, dùng chung cho mọi người khách: mỗi phần tử là
## {"scene": PackedScene, "weight": float, "scale": float}. static để chỉ load()
## một lần cho cả màn chơi chứ không mỗi người khách một lần.
static var _model_cache: Array[Dictionary] = []

## Tỉ lệ riêng của model đang dùng (khoá "scale" trong MODELS).
var _model_scale := 1.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		_pick_model()
	_anim_player = get_node_or_null("Model/AnimationPlayer") as AnimationPlayer
	_apply_scale()
	if Engine.is_editor_hint():
		return
	_make_loops()
	_bubble.visible = false
	_build_bubble()
	_set_anim("idle")


## Thay model mặc định bằng một model bốc theo trọng số trong MODELS.
func _pick_model() -> void:
	if _model_cache.is_empty():
		for entry in MODELS:
			var path := String(entry["path"])
			if ResourceLoader.exists(path):
				var scene := load(path) as PackedScene
				if scene != null:
					_model_cache.append({"scene": scene,
						"weight": float(entry.get("weight", 1.0)),
						"scale": float(entry.get("scale", 1.0))})
	if _model_cache.is_empty():
		return
	var picked := _pick_weighted()
	var old := get_node_or_null("Model")
	var fresh := (picked["scene"] as PackedScene).instantiate() as Node3D
	if fresh == null:
		return
	if old != null:
		# remove_child TRƯỚC queue_free: queue_free chỉ xoá ở cuối khung hình,
		# trong lúc đó hai node cùng tên "Model" và get_node lấy nhầm cái cũ.
		remove_child(old)
		old.queue_free()
	fresh.name = "Model"
	add_child(fresh)
	move_child(fresh, 2)
	_model_scale = float(picked["scale"])


## Bốc theo trọng số: gieo một số trong [0, tổng) rồi trừ dần.
##
## Không dùng pick_random(): nó chia đều, không cho khách nào hiếm hơn. Trọng số
## tính trên các model ĐÃ NẠP ĐƯỢC, nên thiếu một file thì phần của nó chia
## đều cho số còn lại thay vì làm lệch tỉ lệ.
func _pick_weighted() -> Dictionary:
	var total := 0.0
	for entry in _model_cache:
		total += float(entry["weight"])
	var roll := randf() * total
	for entry in _model_cache:
		roll -= float(entry["weight"])
		if roll < 0.0:
			return entry
	return _model_cache[-1]


func _make_loops() -> void:
	if _anim_player == null:
		return
	for anim_name in LOOPING_ANIMS:
		if _anim_player.has_animation(anim_name):
			_anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


## Áp tỉ lệ cho model, hộp va chạm, agent và bong bóng.
##
## is_node_ready() chặn lần gọi đầu: setter của @export chạy NGAY LÚC NẠP
## SCENE, sớm hơn @onready, nên lúc đó _agent và _bubble còn là null. _ready()
## gọi lại một lần nữa nên không mất giá trị nào.
func _apply_scale() -> void:
	if not is_node_ready():
		return
	var model := get_node_or_null("Model") as Node3D
	if model != null:
		model.scale = Vector3.ONE * body_scale * _model_scale

	var col := get_node_or_null("Col") as CollisionShape3D
	if col != null and col.shape is CapsuleShape3D:
		var shape := col.shape as CapsuleShape3D
		shape.radius = BASE_RADIUS * body_scale
		shape.height = BASE_HEIGHT * body_scale
		# Capsule lấy gốc ở TÂM, nên phải nâng lên nửa chiều cao thì chân mới
		# chạm sàn. Quên bước này là nhân vật lún nửa người xuống đất.
		col.position.y = BASE_HEIGHT * 0.5 * body_scale

	if _agent != null:
		_agent.radius = BASE_AGENT_RADIUS * body_scale
		_agent.height = BASE_HEIGHT * body_scale
	if _bubble != null:
		_bubble.position.y = BASE_BUBBLE_HEIGHT * body_scale


## Ra lệnh đi tới một vị trí.
##
## Điểm đích được NẮN về navmesh trước khi giao cho agent. Bắt buộc: mấy cái
## Marker3D trong map do người kê bằng mắt, có cái nằm sát tường (CuaVao ở
## x=31,5 trong khi tường ở x=32) nên rơi ra NGOÀI vùng đi được sau khi navmesh
## co vào theo bán kính agent. Giao thẳng điểm ngoài mesh thì agent tìm đường
## tới chỗ gần nhất rồi loay hoay không bao giờ báo "đã tới".
func go_to(dest: Vector3, task: String, final_dir: Vector3 = Vector3.ZERO) -> void:
	_task = task
	_face_dir = final_dir
	dest = snap_to_navmesh(get_world_3d().navigation_map, dest)
	_agent.target_position = dest
	_moving = true
	_set_anim("walk")


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
static func snap_to_navmesh(nav_map: RID, point: Vector3) -> Vector3:
	if not nav_map.is_valid() or NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		return point
	var nearest := NavigationServer3D.map_get_closest_point(nav_map, point)
	if nearest.is_equal_approx(Vector3.ZERO) and not point.is_equal_approx(Vector3.ZERO):
		return point
	# Chỉ lấy phần NGANG, giữ nguyên độ cao gốc.
	#
	# Điểm nắn ra nằm trên mặt navmesh, mà mặt đó cao hơn sàn nửa mét (Recast
	# rasterize theo ô cao cell_height). Nếu để nguyên độ cao đó làm đích thì
	# khoảng cách từ người khách (y=0) tới đích không bao giờ nhỏ hơn 0,5 —
	# tức là target_desired_distance 0,45 KHÔNG BAO GIỜ thoả và người khách
	# đứng dí một chỗ dù vẫn có vận tốc. Sàn quán phẳng tuyệt đối nên bỏ trục
	# đứng đi là đúng, không mất gì.
	nearest.y = point.y
	return nearest


## Khai báo mặt navmesh cao hơn chân nhân vật bao nhiêu.
##
## NavigationAgent3D trừ con số này khỏi trục Y ở CẢ điểm đường trả về LẪN phép
## đo "đã tới điểm giữa chưa". Không khai thì agent thấy mỗi điểm đường luôn
## cách nó ít nhất 0,5 theo trục đứng, không bao giờ nhích sang điểm kế tiếp,
## và người khách đi mãi về phía một cái mốc ngay dưới chân mình.
func set_height_offset(icon_height: float) -> void:
	_agent.path_height_offset = icon_height


func stop_moving(final_dir: Vector3 = Vector3.ZERO) -> void:
	_moving = false
	_face_dir = final_dir
	velocity.x = 0.0
	velocity.z = 0.0
	_set_anim("idle")


func eat(seconds: float) -> void:
	_moving = false
	velocity = Vector3(0.0, velocity.y, 0.0)
	_set_anim("eat")
	# Đếm bằng bộ đếm RIÊNG trong _physics_process, không dùng
	# get_tree().create_timer(): đồng hồ của cây scene không dừng theo node,
	# nên khi kĩ năng dừng thời gian đóng băng người khách này (tắt xử lý của
	# node) thì bữa ăn vẫn "xong" và tiền vẫn rơi ra giữa lúc mọi thứ đứng im.
	_eat_left = maxf(seconds, 0.01)


func beg() -> void:
	_set_anim("angry")


## Bong bóng trên đầu (đơn hàng). Nội dung do hệ đơn hàng đổ vào sau.
func bubble() -> Node3D:
	return _bubble


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
const BAR_WIDTH := 64
const BAR_HEIGHT := 10

## Chiều cao mong muốn của ảnh món trong không gian 3D, đơn vị Godot.
##
## pixel_size của Sprite3D tính theo TỪNG điểm ảnh, mà ảnh nguyên liệu là ảnh
## 512 px. Để nguyên pixel_size 0,004 như trong scene thì bong bóng cao hơn 2
## đơn vị — to hơn cả người khách. Nên phải suy pixel_size ngược từ chiều cao
## mong muốn, và như vậy ảnh to nhỏ khác nhau vẫn hiện cùng một cỡ.
const DISH_ICON_HEIGHT := 0.55

const BAR_BG := Color(0.10, 0.08, 0.07, 0.85)
const COLOR_GREEN := Color("4f9d5d")
const COLOR_YELLOW := Color("d9a520")
const COLOR_RED := Color("c4433a")

var _dish_icon: Sprite3D
var _bar: Sprite3D
var _bar_sprite: Image
var _bar_tex: ImageTexture
var _last_col := -1


func _build_bubble() -> void:
	if _bubble == null:
		return
	_dish_icon = _bubble.get_node_or_null("DishIcon") as Sprite3D

	_bar = Sprite3D.new()
	_bar.name = "PatienceBar"
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.shaded = false
	_bar.no_depth_test = true
	# Lọc điểm ảnh KIỂU GẦN NHẤT: ảnh chỉ 64 px mà kéo rộng ra, lọc mượt sẽ
	# làm mép thanh nhoè thành một vệt chuyển màu, đọc không ra mốc.
	_bar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_bar.pixel_size = 0.6 / float(BAR_WIDTH)
	_bar.position.y = -DISH_ICON_HEIGHT * 0.5 - 0.08
	_bubble.add_child(_bar)

	_bar_sprite = Image.create(BAR_WIDTH, BAR_HEIGHT, false, Image.FORMAT_RGBA8)
	_bar_tex = ImageTexture.create_from_image(_bar_sprite)
	_bar.texture = _bar_tex
	_draw_bar(1.0)


## Hiện bong bóng với ảnh món. Gọi lúc khách vào hàng đợi.
func show_order(icon: Texture2D) -> void:
	if _bubble == null:
		return
	if _dish_icon != null and icon != null:
		_dish_icon.texture = icon
		var icon_height := maxi(icon.get_height(), 1)
		_dish_icon.pixel_size = DISH_ICON_HEIGHT / float(icon_height)
	_last_col = -1
	_draw_bar(1.0)
	_bubble.visible = true


func hide_order() -> void:
	if _bubble != null:
		_bubble.visible = false


## Cập nhật thanh chờ. `ti` là phần kiên nhẫn còn lại, 0…1.
##
## Tham số tên `ti` chứ không phải `body_scale`: lớp này đã có @export `body_scale` (cỡ
## người khách), trùng tên thì tham số che mất biến thành viên — Godot cảnh
## báo, và kiểu nhầm đó rất khó thấy khi đọc lại.
func set_patience_bar(ratio: float) -> void:
	if _bubble == null or not _bubble.visible:
		return
	_draw_bar(ratio)


func _draw_bar(ratio: float) -> void:
	if _bar_sprite == null:
		return
	var filled_px := int(round(clampf(ratio, 0.0, 1.0) * BAR_WIDTH))
	if filled_px == _last_col:
		return
	_last_col = filled_px

	# Ba bậc màu theo ngưỡng, khớp đúng ba bậc trên tấm vé ở HUD. Cùng một
	# thông tin thì phải cùng một mã màu, dù vẽ ở hai chỗ khác nhau.
	var color_ := COLOR_GREEN
	if ratio <= 0.2:
		color_ = COLOR_RED
	elif ratio <= 0.5:
		color_ = COLOR_YELLOW

	_bar_sprite.fill(BAR_BG)
	if filled_px > 0:
		_bar_sprite.fill_rect(Rect2i(0, 0, filled_px, BAR_HEIGHT), color_)
	_bar_tex.update(_bar_sprite)


## Còn bao nhiêu giây thì ăn xong. 0 = không đang ăn.
var _eat_left: float = 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _eat_left > 0.0:
		_eat_left -= delta
		if _eat_left <= 0.0:
			_eat_left = 0.0
			_set_anim("idle")
			ate.emit(self)
	# Giữ dính sàn. Sàn phẳng tuyệt đối nhưng vẫn cần trọng lực: nhân vật được
	# sinh ra hơi cao hơn mặt sàn, không có trọng lực thì lơ lửng mãi.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	if _moving:
		if _agent.is_navigation_finished():
			_moving = false
			velocity.x = 0.0
			velocity.z = 0.0
			_set_anim("idle")
			arrived.emit(self, _task)
		else:
			var to_pos := _agent.get_next_path_position()
			var dir_ := (to_pos - global_position)
			dir_.y = 0.0
			dir_ = dir_.normalized()
			velocity.x = dir_.x * SPEED
			velocity.z = dir_.z * SPEED
			_turn_towards(dir_, delta)
	elif _face_dir != Vector3.ZERO:
		_turn_towards(_face_dir, delta)

	move_and_slide()


## Xoay thân về một hướng nằm ngang.
##
## Xoay CẢ CharacterBody3D chứ không xoay riêng node Model như bên nhân vật
## người chơi: khách không có camera gắn vào nên không có lý do gì phải tách
## thân và model, mà xoay thẳng thân thì hướng nhìn và hướng va chạm luôn khớp.
func _turn_towards(dir_: Vector3, delta: float) -> void:
	if dir_.length_squared() < 0.0001:
		return
	# Model nhìn về −Z, đúng quy ước của Godot, nên atan2 lấy thẳng góc.
	var target_yaw := atan2(dir_.x, dir_.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, TURN_SPEED * delta)


## Đổi animation, bỏ qua nếu đang chạy đúng cái đó.
##
## Kiểm trùng chứ không gọi play() vô tư: play() cùng tên vẫn khởi động lại
## từ đầu, nên gọi mỗi khung hình thì animation đứng mãi ở khung 0 — đúng kiểu
## lỗi nhìn như "model bị đơ" mà không có dòng lỗi nào.
func _set_anim(anim_name: String) -> void:
	if _anim_now == anim_name:
		return
	if _anim_player == null or not _anim_player.has_animation(anim_name):
		return
	_anim_now = anim_name
	_anim_player.play(anim_name)
