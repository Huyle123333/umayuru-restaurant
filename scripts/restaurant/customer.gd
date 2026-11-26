@tool
extends CharacterBody3D

## Đi tới nơi rồi. `viec` là chuỗi do người ra lệnh gửi kèm lúc gọi go_to(),
signal arrived(customer: Node, task: String)
## Ăn xong.
signal ate(customer: Node)

## Cỡ người khách. 1,0 = đúng cỡ model gốc (cao 1,52 đơn vị).
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
const RARE_WEIGHT := 5.0 / 18.0

const MODELS := [
	{"path": "res://assets/models/khach_akikawa.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_tazuna.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_hello.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_riko.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/khach_etsuko.glb", "weight": 1.0, "scale": 1.0},
	{"path": "res://assets/models/customer_spiki.glb", "weight": RARE_WEIGHT, "scale": 1.3,
		"yaw": 180.0},
	{"path": "res://assets/models/customer_gugugaga.glb", "weight": RARE_WEIGHT, "scale": 1.5},
]

## Animation phải LẶP. glTF không mang được cờ lặp, nên đặt ở đây lúc chạy thay
const LOOPING_ANIMS := ["idle", "walk", "eat"]

## Model nạp sẵn, dùng chung cho mọi người khách: mỗi phần tử là
static var _model_cache: Array[Dictionary] = []

## Tỉ lệ riêng của model đang dùng (khoá "scale" trong MODELS).
var _model_scale := 1.0

## Ép một model cụ thể thay vì bốc ngẫu nhiên: {"path", "scale", "yaw"}. Gán
var forced_model: Dictionary = {}


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
	if not forced_model.is_empty() and ResourceLoader.exists(String(forced_model["path"])):
		_swap_model({"scene": load(String(forced_model["path"])),
			"scale": float(forced_model.get("scale", 1.0)),
			"yaw": float(forced_model.get("yaw", 0.0))})
		return
	if _model_cache.is_empty():
		for entry in MODELS:
			var path := String(entry["path"])
			if ResourceLoader.exists(path):
				var scene := load(path) as PackedScene
				if scene != null:
					_model_cache.append({"scene": scene,
						"weight": float(entry.get("weight", 1.0)),
						"scale": float(entry.get("scale", 1.0)),
						"yaw": float(entry.get("yaw", 0.0))})
	if _model_cache.is_empty():
		return
	_swap_model(_pick_weighted())


func _swap_model(picked: Dictionary) -> void:
	var old := get_node_or_null("Model")
	var fresh := (picked["scene"] as PackedScene).instantiate() as Node3D
	if fresh == null:
		return
	if old != null:
		remove_child(old)
		old.queue_free()
	fresh.name = "Model"
	add_child(fresh)
	move_child(fresh, 2)
	fresh.rotation.y = deg_to_rad(float(picked.get("yaw", 0.0)))
	_model_scale = float(picked["scale"])


## Bốc theo trọng số: gieo một số trong [0, tổng) rồi trừ dần.
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
		col.position.y = BASE_HEIGHT * 0.5 * body_scale

	if _agent != null:
		_agent.radius = BASE_AGENT_RADIUS * body_scale
		_agent.height = BASE_HEIGHT * body_scale
	if _bubble != null:
		_bubble.position.y = BASE_BUBBLE_HEIGHT * body_scale


## Ra lệnh đi tới một vị trí.
func go_to(dest: Vector3, task: String, final_dir: Vector3 = Vector3.ZERO) -> void:
	_task = task
	_face_dir = final_dir
	dest = snap_to_navmesh(get_world_3d().navigation_map, dest)
	_agent.target_position = dest
	_moving = true
	_set_anim("walk")


## Đứng lại tại chỗ, quay mặt về một hướng nếu có.
static func snap_to_navmesh(nav_map: RID, point: Vector3) -> Vector3:
	if not nav_map.is_valid() or NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		return point
	var nearest := NavigationServer3D.map_get_closest_point(nav_map, point)
	if nearest.is_equal_approx(Vector3.ZERO) and not point.is_equal_approx(Vector3.ZERO):
		return point
	nearest.y = point.y
	return nearest


## Khai báo mặt navmesh cao hơn chân nhân vật bao nhiêu.
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
	_eat_left = maxf(seconds, 0.01)


## Viền màu quanh model (thanh tra Spiki: viền đỏ cho dễ nhận ra giữa đám khách).
func set_outline(color: Color, width: float = 0.02) -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform vec4 outline_color : source_color;
uniform float width;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = outline_color.rgb; }
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("width", width / maxf(_model_scale * body_scale, 0.01))
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_overlay = mat


func beg() -> void:
	_set_anim("angry")


## Hết cáu, về lại tư thế trước đó.
func calm() -> void:
	_set_anim("eat" if _eat_left > 0.0 else "idle")


## Bong bóng trên đầu (đơn hàng). Nội dung do hệ đơn hàng đổ vào sau.
func bubble() -> Node3D:
	return _bubble


# ---------------------------------------------------------- bong bóng đơn ---

## Bề rộng thanh chờ tính bằng ĐIỂM ẢNH của tấm ảnh sinh ra lúc chạy.
const BAR_WIDTH := 64
const BAR_HEIGHT := 10

## Chiều cao mong muốn của ảnh món trong không gian 3D, đơn vị Godot.
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
func _turn_towards(dir_: Vector3, delta: float) -> void:
	if dir_.length_squared() < 0.0001:
		return
	var target_yaw := atan2(dir_.x, dir_.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, TURN_SPEED * delta)


## Đổi animation, bỏ qua nếu đang chạy đúng cái đó.
func _set_anim(anim_name: String) -> void:
	if _anim_now == anim_name:
		return
	if _anim_player == null or not _anim_player.has_animation(anim_name):
		return
	_anim_now = anim_name
	_anim_player.play(anim_name)
