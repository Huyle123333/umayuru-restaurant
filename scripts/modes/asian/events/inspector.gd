extends RefCounted
## SỰ KIỆN ASIAN: THANH TRA (user chốt 27/10/2026).
##
## Spiki đi từ cửa chính vào, đứng ở cửa bếp nhìn vào 30–60 giây rồi đi ra.
## Trong lúc Spiki ĐỨNG ở cửa bếp, hễ có nguyên liệu hay món ăn nằm dưới sàn
## TRONG khu bếp là thua ngay. Đồ đặt ngoài khu bếp thì không sao — user cố ý
## để người chơi tự phát hiện mẹo này.
##
## Spiki có VIỀN ĐỎ (customer.set_outline) để nổi bật giữa đám khách, và không
## nằm trong nhóm khách: không gọi món, hệ khách không biết nó tồn tại.
##
## Đứng ở cửa bếp chứ không đi vào trong: vùng đi lại của khách cố ý loại khu
## bếp ra; đi vào thì phải nướng thêm một vùng riêng.

const SPIKI := {"path": "res://assets/models/customer_spiki.glb", "scale": 1.3, "yaw": 180.0}
## Chỗ đứng: ngay ngoài lối người chơi vào bếp (tấm chắn nav ở x 15,6–16,4).
const STAND := Vector3(17.6, 0.0, 6.0)
## Khu bếp trên sàn (x, z) — trùng tường bếp trong restaurant_map_planb.
const KITCHEN := Rect2(0.0, 0.0, 16.0, 12.0)
## Cao hơn mức này coi là đang nằm trên bàn/kệ, không phải dưới sàn.
const FLOOR_MAX_Y := 0.3

var _d: Node
var _npc: Node
var _inspecting := false
var _left := 0.0


func start(director: Node) -> void:
	_d = director
	var cm: Node = director._customers
	_npc = cm.CUSTOMER_SCENE.instantiate()
	_npc.forced_model = SPIKI
	cm._map.add_child(_npc)
	_npc.global_position = _npc.snap_to_navmesh(cm._map.get_world_3d().navigation_map,
		cm._door.global_position)
	_npc.set_height_offset(cm._height_offset)
	_npc.set_outline(Color(1.0, 0.1, 0.1), 0.03)
	var tag := Label3D.new()
	tag.text = Lang.t("THANH TRA")
	tag.font_size = 72
	tag.pixel_size = 0.004
	tag.modulate = Color(1.0, 0.3, 0.3)
	tag.outline_size = 14
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.position = Vector3(0, 2.6, 0)
	_npc.add_child(tag)
	_npc.arrived.connect(_on_arrived)
	_npc.go_to(STAND, "inspect", Vector3(-1, 0, 0))


func _on_arrived(_c: Node, task: String) -> void:
	if task == "inspect":
		_inspecting = true
		_left = randf_range(30.0, 60.0)
	elif task == "leave":
		_d.finish("inspector")


func tick(delta: float) -> void:
	if not _inspecting:
		return
	if _food_on_kitchen_floor():
		_inspecting = false
		_d.lose(Lang.t("Thua: thanh tra phát hiện đồ ăn dưới sàn bếp."))
		return
	_left -= delta
	if _left <= 0.0:
		_inspecting = false
		_npc.go_to(_d._customers._door.global_position, "leave")


func _food_on_kitchen_floor() -> bool:
	var held: Node = _d._hands._held if _d._hands != null else null
	for n in _d.get_tree().get_nodes_in_group("station"):
		if String(n.get("kind")) != "carriable" or n == held or not (n is Node3D):
			continue
		var p: Vector3 = (n as Node3D).global_position
		if p.y < FLOOR_MAX_Y and KITCHEN.has_point(Vector2(p.x, p.z)):
			return true
	return false


func stop(_director: Node) -> void:
	_inspecting = false
	if _npc != null and is_instance_valid(_npc):
		_npc.queue_free()
