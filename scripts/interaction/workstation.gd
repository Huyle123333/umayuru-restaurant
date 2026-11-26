@tool
class_name Workstation
extends StaticBody3D

const _ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Lớp vật lý số 3 — dành riêng cho VẬT PHẨM cầm được đang nằm dưới đất.
const LAYER_ITEM := 1 << 2

## Lớp của VÙNG TƯƠNG TÁC tách riêng (xem reach_size). Nhân vật không va
const LAYER_REACH := 1 << 9

## Mặt nạ cho bộ chọn mục tiêu: nhìn thấy nội thất, vật phẩm và vùng tương tác.
const STATION_MASK := 1 | LAYER_ITEM | LAYER_REACH


## Phát khi người chơi bấm tương tác. Trạm KHÔNG tự xử lý hậu quả — hệ thống
signal interacted(station: Node, index: int)

@warning_ignore("unused_signal")
signal interacted_alt(station: Node, index: int)

## Tên hiện trên HUD.
@export var display_name: String = ""

## Loại trạm, để hệ thống nấu ăn biết phải làm gì.
@export var kind: String = ""

## Mức ưu tiên khi bộ chọn mục tiêu TỰ chọn giữa nhiều trạm cùng trong tầm.
@export var pick_priority: int = 0

## Danh sách lựa chọn hiện ra khi người chơi đứng trong tầm.
@export var options: PackedStringArray = PackedStringArray()

## Id vật phẩm mà trạm này cho ra (thùng nguyên liệu), hoặc id của chính vật
@export var item_id: String = ""

## Trạm này mở BẢNG CHỌN riêng thay vì đổ hết lựa chọn vào danh sách Tab.
@export var use_picker: bool = false

## Điểm để bộ chọn đo hướng và khoảng cách.
@export var aim_point: NodePath


## Những thứ đang NẰM TRÊN trạm này (bàn chế tạo, bếp, lò nướng).
var contents: Array[String] = []

## Phát khi `chua` đổi. HUD nghe để cập nhật ghi chú trên bàn chế tạo.
signal contents_changed(station: Node)


func add_item(item_name: String) -> void:
	contents.append(item_name)
	contents_changed.emit(self)


## Lấy ra phần tử cuối cùng. Trả về "" nếu đang rỗng.
func pop_last() -> String:
	if contents.is_empty():
		return ""
	var id: String = String(contents[contents.size() - 1])
	contents.remove_at(contents.size() - 1)
	contents_changed.emit(self)
	return id


func clear_all() -> void:
	contents.clear()
	contents_changed.emit(self)


## Model của thứ đang nằm TRÊN mặt trạm (thớt, bếp, bàn chế tạo).
var _model_node: Node3D = null

## Model bày cao bao nhiêu so với gốc trạm. Mặt bàn/quầy KayKit cao 1 đơn vị.
@export var place_height := 1.02

## TÁCH khối vật lý và khối tương tác (12/11/2026).
@export var reach_size := Vector3.ZERO
@export var reach_offset := Vector3(0, 0.5, 0)

## Có vùng tương tác riêng thì bộ chọn bỏ qua khối vật lý của trạm.
func has_reach() -> bool:
	return reach_size != Vector3.ZERO


func _ready() -> void:
	if not has_reach():
		return
	var area := StaticBody3D.new()
	area.name = "Reach"
	area.collision_layer = LAYER_REACH
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = reach_size
	shape.shape = box
	shape.position = reach_offset
	area.add_child(shape)
	add_child(area)


## Bày một vật phẩm lên mặt trạm. Truyền "" để dọn sạch.
func show_model(id: String) -> void:
	clear_model()
	if id.is_empty():
		return
	var m: Node3D = _ItemCatalog.make_model(id)
	if m == null:
		return
	m.name = "TopModel"
	add_child(m)
	m.position = Vector3(0.0, place_height, 0.0)
	_model_node = m


## Bày CẢ CHỒNG đồ đang nằm trên mặt trạm. Truyền mảng rỗng để dọn sạch.
func show_stack(list_: Array[String]) -> void:
	clear_model()
	if list_.is_empty():
		return
	var m: Node3D = _ItemCatalog.make_stack(list_)
	if m == null:
		return
	m.name = "TopModel"
	add_child(m)
	m.position = Vector3(0.0, place_height, 0.0)
	_model_node = m


func clear_model() -> void:
	if _model_node != null and is_instance_valid(_model_node):
		_model_node.queue_free()
	_model_node = null


func aim_position() -> Vector3:
	if aim_point.is_empty():
		return global_position
	var n := get_node_or_null(aim_point) as Node3D
	return n.global_position if n != null else global_position


## Số mục tiêu trạm này đóng góp vào danh sách chọn.
func target_count() -> int:
	if use_picker:
		return 1
	return maxi(options.size(), 1)


func target_label(index: int) -> String:
	if use_picker or options.is_empty():
		return Lang.t(display_name)
	return "%s · %s" % [Lang.t(display_name), Lang.t(String(options[index]))]


func interact(index: int) -> void:
	interacted.emit(self, index)


## Phím F trên trạm này.
func interact_alt(index: int = 0) -> void:
	interacted_alt.emit(self, index)


# ---------------------------------------------- vật cầm đặt sẵn trong map ---

## Cạnh hộp va chạm của một vật cầm được. Trùng với `canh_vat_pham` bên
const ITEM_SIZE := 0.55


## Dựng phần NHÌN THẤY và phần BẤM ĐƯỢC cho một `vat_cam` đặt sẵn trong map.
func build_carriable() -> void:
	if kind != "carriable" or item_id.is_empty():
		return

	if get_node_or_null("Mesh") == null:
		_swap_mesh()

	# Hộp va chạm: thiếu nó thì trạm không bao giờ được bộ chọn nhìn thấy.
	if _find_collision_shape() == null:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(ITEM_SIZE, ITEM_SIZE, ITEM_SIZE)
		shape.shape = box
		shape.position = Vector3(0.0, ITEM_SIZE * 0.5, 0.0)
		add_child(shape)

	if get_node_or_null("AimPoint") == null:
		var mark := Marker3D.new()
		mark.name = "AimPoint"
		mark.position = Vector3(0.0, 0.25, 0.0)
		add_child(mark)
		aim_point = NodePath("AimPoint")

	if not contents_changed.is_connected(_on_contents_changed):
		contents_changed.connect(_on_contents_changed)


func _on_contents_changed(_station: Node) -> void:
	_swap_mesh()


## Dựng lại node "Mesh" theo trạng thái rỗng/đầy hiện tại.
func _swap_mesh() -> void:
	var has_content := not contents.is_empty()
	var new_ := "day" if has_content else "rong"
	if String(get_meta("kieu_mesh", "")) == new_ and get_node_or_null("Mesh") != null:
		return
	set_meta("kieu_mesh", new_)

	var old := get_node_or_null("Mesh")
	if old != null:
		old.queue_free()

	var m: Node3D = _ItemCatalog.make_model(item_id, has_content)
	if m == null:
		push_warning("Vật cầm '%s' chưa có model." % item_id)
		return
	m.name = "Mesh"
	add_child(m)


func _find_collision_shape() -> CollisionShape3D:
	for c in get_children():
		if c is CollisionShape3D:
			return c
	return null
