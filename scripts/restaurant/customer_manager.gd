extends Node

signal customer_seated(customer: Node, table: Node)
signal customer_ate(customer: Node, table: Node, dish_id: String)
signal customer_left(customer: Node)

## Một đơn vừa sinh ra (khách đã ngồi vào bàn và gọi món).
signal order_created(order_: Order)
## Một đơn kết thúc. ly_do: "xong" (giao đúng) hoặc "bo_di" (hết kiên nhẫn).
signal order_finished(order_: Order, reason: String)
## Ví thay đổi. `cho` là chỗ vừa xảy ra việc, để bắn hiệu ứng tiền bay lên.
signal money_changed(total: int, added: int, spot: Vector3)

const CUSTOMER_SCENE := preload("res://scenes/restaurant/customer.tscn")
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const Order := preload("res://scripts/restaurant/order.gd")
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"

## Thời gian ăn, giây. Màn thật sẽ tỉ lệ với độ khó; tutorial để cố định.
@export var eat_seconds: float = 5.0
## Ép mọi khách ngồi đúng bàn này (dùng cho tutorial). 0 = chọn ngẫu nhiên.
@export var force_table: int = 0

## Ép mọi khách gọi đúng món này (dùng cho tutorial). Rỗng = bốc ngẫu nhiên.
@export var force_dish: String = ""
## Số khách tối đa có mặt cùng lúc, kể cả đang xếp hàng.
@export var max_customers: int = 6

## Số khách tối đa ĐANG NGỒI BÀN cùng lúc. 0 = không giới hạn (dùng hết bàn).
@export var max_tables: int = 0

## Số ô hàng đợi được dùng. 0 = dùng hết số Marker HangDoi có trong map.
@export var max_queue: int = 0

## Thực đơn RIÊNG của màn: chỉ những món trong đây mới được khách gọi.
@export var menu: Array[String] = []

## Trọng số bốc món: id -> số. Món không có tên trong đây tính là 1.
@export var weights: Dictionary = {}

## Trọng số theo MỨC ĐỘ KHÓ: {"easy": 7, "medium": 3, "hard": 0}. Rỗng = không
@export var tier_weights: Dictionary = {}

## Sau một món KHÓ, phải qua bấy nhiêu đơn KHÔNG khó thì món khó mới được xuất
@export var hard_cooldown_orders: int = 2
## Số đơn không-khó đã ra kể từ món khó gần nhất.
var _orders_since_hard: int = 0

## Có trừ kiên nhẫn theo thời gian không.
@export var drain_patience: bool = true

## Tự sinh khách theo nhịp. Màn hướng dẫn tắt đi và gọi spawn_customer() bằng tay
@export var auto_spawn: bool = true
## Giây giữa hai lần thử sinh khách.
@export var spawn_interval: float = 12.0
## Giây chờ trước người khách đầu tiên — cho người chơi kịp nhìn quanh bếp.
@export var first_wait: float = 4.0

## Hệ số nhân vào GIÁ BÁN mọi món của màn này. 1.0 = giá gốc trong ItemCatalog.
@export var price_factor: float = 1.0

## Khoảng cách NGẪU NHIÊN giữa hai lượt khách, tính bằng giây: mỗi lần một
@export var spawn_interval_min: float = 0.0
@export var spawn_interval_max: float = 0.0

## Kiên nhẫn lúc đứng XẾP HÀNG (chưa có bàn), giây. CỐ ĐỊNH, không theo món.
@export var queue_patience: float = 45.0

## Khách đứng cáu bao lâu trước khi bỏ ra cửa, giây.
@export var beg_seconds: float = 2.0

## Asian Mode: giao NHẦM món thì khách bỏ về ngay (thay vì chỉ cáu và chờ).
var wrong_dish_leaves: bool = false

## Asian Mode: thuế VAT, trừ theo tỉ lệ trên tiền của MỖI đơn lúc trả vào ví.
var vat_rate: float = 0.0

## Asian Mode: kiên nhẫn KHÔNG nạp đầy khi khách ngồi vào bàn. Thanh ở bàn bắt
var keep_queue_patience: bool = false

## true trong lúc clear_all_customers() đang chạy. Những "left" phát ra lúc đó
var clearing_all: bool = false

## Sự kiện Asian (event_director.gd) vặn hai núm này:
var ingredient_cost_factors: Dictionary = {}
var event_price_factor: float = 1.0

## Asian Mode — TIỀN ĐỂ TRÊN BÀN: khách ăn xong để tiền lại trên bàn thay vì
var money_on_table: bool = false
const CASH_SECONDS := 20.0
const CASH_ICON := "res://assets/ui/tien/carrot_tien.png"
const CASH_ICON_HEIGHT := 0.7
## Bàn -> {"amount", "left", "perfect", "label"}
var _cash: Dictionary = {}

## Khách VIP: kiên nhẫn bằng 60% bình thường, trả gấp 3 (tài liệu mục 3.6).
const VIP_PATIENCE := 0.6
const VIP_PAYOUT := 3.0

## Thưởng thêm khi giao lúc kiên nhẫn còn trên 50%. 0,35 = +35%.
@export var perfect_bonus: float = 0.35

## ───────────────────────────── HAI NÚM DO HỆ KĨ NĂNG VẶN ──────────────────

## Nhân vào kiên nhẫn của mọi đơn, cả lúc xếp hàng lẫn lúc ngồi bàn.
@export var patience_factor: float = 1.0

## Bỏ qua thanh kiên nhẫn: MỌI đơn giao ra đều tính là hoàn hảo.
var force_perfect: bool = false

## Kita — "Victory Cheer!", phần NHÂN ĐÔI TIỀN. 1,0 = không đổi.
var perfect_payout_multiplier: float = 1.0

## Các món giao được cho MỌI đơn, kể cả khi khách gọi món khác. Rỗng = tắt.
var wildcard_dishes: Array = []

## Bộ đếm cho điều kiện kĩ năng "giao xong N đơn thuộc một nhóm món".
var counted_dishes: Array = []
var counted_orders_done: int = 0

## Mỗi đơn giao ra có `bonus_payout_chance` (0…1) cơ hội được NHÂN tiền với
var bonus_payout_chance: float = 0.0

## Hệ số giá RIÊNG theo món: id món -> hệ số. Rỗng = không món nào đổi giá.
var dish_price_factors: Dictionary = {}

## Hệ số nhân vào TRỌNG SỐ bốc món: id món -> hệ số. Rỗng = bốc như thường.
var dish_weight_factors: Dictionary = {}

## BẢNG GIEO THƯỞNG cho đơn HOÀN HẢO của một nhóm món. Rỗng = tắt.
var perfect_roll: Dictionary = {}

## ĐÓNG BĂNG toàn bộ hệ khách: không khách mới, không trừ kiên nhẫn, và mọi
var frozen: bool = false

const CUSTOMER_GROUP := "customers"

func set_frozen(value: bool) -> void:
	if frozen == value:
		return
	frozen = value
	var mode := Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	for k in get_tree().get_nodes_in_group(CUSTOMER_GROUP):
		k.process_mode = mode
var bonus_payout_multiplier: float = 3.0

## Hệ số giá do KĨ NĂNG đặt, nhân lên MỌI món. 1,0 = không đổi.
var skill_price_factor: float = 1.0

## Tốc độ trôi của hệ khách: nhân vào nhịp khách đến VÀ tốc độ tụt kiên nhẫn.
var time_scale: float = 1.0

## Những món đã từng được giao HOÀN HẢO trong màn này: id món -> true.
var perfect_dishes: Dictionary = {}

## Nguyên liệu miễn phí (cheat). false = trừ tiền như bình thường.
var free_ingredients: bool = false

## Khách hết kiên nhẫn vẫn ngồi chờ, không bỏ về (AAA Mode: không thể thua).
var never_leave: bool = false

## Tổng tiền trong màn. CÓ THỂ ÂM.
var money: int = 0

## Thống kê một lượt chơi, để bảng kết quả đọc lúc hết giờ.
var orders_done: int = 0
var perfect_orders: int = 0
var customers_lost: int = 0

var _orders: Dictionary = {}
var _spawn_timer: float = 0.0

var _map: Node3D
var _spawn_points: Node
var _queue: Array[Marker3D] = []
var _door: Marker3D
var _tables: Array = []
var _in_queue: Array = []
var _table_of: Dictionary = {}
var _customer_at: Dictionary = {}


func setup(map: Node3D) -> void:
	_map = map
	_spawn_points = map.get_node_or_null("Markers")
	_door = _pick_spawn("Entrance")

	var i := 1
	while true:
		var m := _pick_spawn("Queue%d" % i)
		if m == null:
			break
		_queue.append(m)
		i += 1
	_in_queue.resize(_queue.size())
	_in_queue.fill(null)

	_tables = get_tree().get_nodes_in_group("dining_table")
	_tables.sort_custom(func(a, b): return int(a.table_number) < int(b.table_number))
	for b in _tables:
		if b.has_signal("dish_delivered"):
			b.dish_delivered.connect(_on_dish_delivered)
		if b.has_signal("delivery_rejected"):
			b.delivery_rejected.connect(_on_delivery_rejected)
		if b.has_signal("cash_collected"):
			b.cash_collected.connect(_on_cash_collected)

	_bake_navmesh()
	_spawn_timer = first_wait


func _pick_spawn(marker_name: String) -> Marker3D:
	if _spawn_points == null:
		return null
	return _spawn_points.get_node_or_null(marker_name) as Marker3D


# ------------------------------------------------------- vùng đi lại (navmesh)

## Vùng đi được của khách, NƯỚNG LÚC CHẠY chứ không đặt sẵn trong file map.
const SOURCE_GROUP := "navmesh_source"

## Lớp va chạm 5 (bit 16) dành RIÊNG cho mấy tấm chắn vô hình chỉ tồn tại với
const NAV_BLOCK_LAYER := 1 << 4

## Hai lối vào bếp, chắn lại để khách không lang thang vào khu bếp.
const BLOCKERS := [
	[Vector3(16.0, 1.0, 6.0), Vector3(0.4, 1.5, 2.2)],
	[Vector3(2.0, 1.0, 12.0), Vector3(2.2, 1.5, 0.4)],
]

var _nav_region: Array[NavigationRegion3D] = []
## Mặt navmesh nằm cao hơn mặt sàn bấy nhiêu. ĐO lúc chạy chứ không gõ tay:
var _height_offset := 0.0


func _bake_navmesh() -> void:
	if not _map.is_in_group(SOURCE_GROUP):
		_map.add_to_group(SOURCE_GROUP)
	_build_blockers()

	var mesh_ := NavigationMesh.new()
	mesh_.cell_size = 0.25
	mesh_.cell_height = 0.25
	mesh_.agent_radius = 0.5
	mesh_.agent_height = 1.5
	mesh_.agent_max_climb = 0.25
	mesh_.agent_max_slope = 45.0
	mesh_.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh_.geometry_collision_mask = 1 | NAV_BLOCK_LAYER
	mesh_.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh_.geometry_source_group_name = SOURCE_GROUP

	var region := NavigationRegion3D.new()
	region.name = "CustomerNavRegion"
	region.navigation_mesh = mesh_
	_map.add_child(region)
	_nav_region.append(region)
	region.bake_navigation_mesh(false)
	_measure_height_offset(mesh_)


## Tấm chắn vô hình bịt hai lối vào bếp.
func _build_blockers() -> void:
	for c in BLOCKERS:
		var body := StaticBody3D.new()
		body.name = "NavBlocker"
		body.collision_layer = NAV_BLOCK_LAYER
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = (c[1] as Vector3) * 2.0
		shape.shape = box
		body.add_child(shape)
		_map.add_child(body)
		body.global_position = c[0]


## Đọc độ cao mặt navmesh THẲNG TỪ LƯỚI vừa nướng.
func _measure_height_offset(mesh_: NavigationMesh) -> void:
	var verts := mesh_.get_vertices()
	if verts.is_empty():
		return
	_height_offset = verts[0].y


## Chờ NavigationServer đồng bộ xong bản đồ.
func is_ready() -> void:
	var nav_map := _map.get_world_3d().navigation_map
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame


## Số đa giác của từng vùng — dùng để kiểm nhanh navmesh có nướng ra gì không.
func navmesh_height_offset() -> float:
	return _height_offset


func nav_stats() -> Array:
	var out := []
	for v in _nav_region:
		out.append({"ten": v.name, "da_giac": v.navigation_mesh.get_polygon_count()})
	return out


# --------------------------------------------------------------- vòng đời khách

## Hỏi trước khi cho khách vào (16/11/2026): level_base nối vào
var can_accept: Callable = Callable()


func spawn_customer(model_override: Dictionary = {}, is_vip: bool = false) -> Node:
	if can_accept.is_valid() and not bool(can_accept.call()):
		return null
	if _door == null or _queue.is_empty():
		push_warning("Map thiếu Markers/Entrance hoặc Markers/Queue1 — không sinh khách được.")
		return null
	var slot := _free_seat()
	if slot == -1:
		return null

	var k := CUSTOMER_SCENE.instantiate()
	k.add_to_group(CUSTOMER_GROUP)
	if not model_override.is_empty():
		k.forced_model = model_override
	if is_vip:
		k.set_meta("vip", true)
	_map.add_child(k)
	var pos: Vector3 = k.snap_to_navmesh(_map.get_world_3d().navigation_map,
		_door.global_position)
	pos.z += randf_range(-0.7, 0.7)
	k.global_position = pos
	k.set_height_offset(_height_offset)
	k.arrived.connect(_on_arrived)
	k.ate.connect(_on_ate)

	_in_queue[slot] = k
	k.set_meta("in_queue", slot)
	AmThanh.play_sfx("customer_in")
	k.go_to(_queue[slot].global_position, "queue")
	return k


## Ô hàng đợi trống gần đầu hàng nhất, hoặc -1 nếu hết chỗ.
func _free_seat() -> int:
	var limit: int = _in_queue.size()
	if max_queue > 0:
		limit = mini(limit, max_queue)
	for i in limit:
		if _in_queue[i] == null:
			return i
	return -1


## Đã đủ trần số khách ngồi bàn chưa.
func _tables_full() -> bool:
	return max_tables > 0 and _customer_at.size() >= max_tables


## Nhịp tim của cả nhà hàng: sinh khách và đếm kiên nhẫn.
func _process(delta: float) -> void:
	if _map == null or frozen:
		return
	_tick_cash(delta)

	if auto_spawn:
		_spawn_timer -= delta * time_scale
		if _spawn_timer <= 0.0:
			_spawn_timer = _next_spawn_gap()
			spawn_customer()

	if not drain_patience:
		return
	for order_ in _orders.values().duplicate():
		var expired: bool = order_.tick(delta * time_scale)
		if order_.in_queue and is_instance_valid(order_.customer):
			order_.customer.set_patience_bar(order_.patience_ratio())
		if expired and not never_leave:
			_leave_angry(order_)


## Bao lâu nữa thì lượt khách kế tiếp vào.
func _next_spawn_gap() -> float:
	if spawn_interval_max <= 0.0:
		return spawn_interval
	return randf_range(minf(spawn_interval_min, spawn_interval_max), spawn_interval_max)


func _on_arrived(customer: Node, task: String) -> void:
	match task:
		"queue":
			customer.stop_moving(Vector3.LEFT)
			_place_order(customer)
			if int(customer.get_meta("in_queue", -1)) == 0:
				_push_to_board(customer)
			_try_seat(customer)
		"table":
			var table = _table_of.get(customer)
			if table == null:
				return
			var dir_: Vector3 = table.global_position - customer.global_position
			dir_.y = 0.0
			customer.stop_moving(dir_.normalized())
			customer_seated.emit(customer, table)
			_seat_at_table(customer, table)
		"leave":
			_clear_customer(customer)


## Tìm bàn trống cho một người đang đứng ở hàng đợi.
func _try_seat(customer: Node) -> void:
	if _in_queue.is_empty() or _in_queue[0] != customer:
		return
	var table = _empty_table()
	if table == null:
		return

	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0:
		_in_queue[slot] = null
	customer.remove_meta("in_queue")

	_table_of[customer] = table
	_customer_at[table] = customer

	var order_: Order = _orders.get(customer)
	if order_ != null:
		order_.draining = false

	customer.go_to((table.seat_marker(0) as Marker3D).global_position, "table")
	_shift_queue()


## Dồn hàng lên một ô sau khi người đầu hàng rời đi.
func _shift_queue() -> void:
	for i in range(1, _in_queue.size()):
		var k = _in_queue[i]
		if k == null:
			continue
		var before := i - 1
		if _in_queue[before] != null:
			continue
		_in_queue[before] = k
		_in_queue[i] = null
		k.set_meta("in_queue", before)
		if before == 0:
			_push_to_board(k)
		k.go_to(_queue[before].global_position, "queue")


func _empty_table():
	if _tables_full():
		return null
	if force_table > 0:
		for b in _tables:
			if int(b.table_number) == force_table and not _customer_at.has(b):
				return b
		return null
	var free := []
	for b in _tables:
		if not _customer_at.has(b) and not _cash.has(b):
			free.append(b)
	if free.is_empty():
		return null
	return free.pick_random()


## Bàn nhận được món. Chỉ người đang ngồi ở CHÍNH bàn đó mới ăn.
func _on_dish_delivered(table: Node, dish_id: String) -> void:
	var customer = _customer_at.get(table)
	if customer == null:
		return
	var order_: Order = _orders.get(customer)
	if order_ == null:
		return

	var is_wildcard := dish_id != order_.dish and wildcard_dishes.has(dish_id)
	if dish_id != order_.dish and not is_wildcard:
		if _waiting_at_table(order_):
			if wrong_dish_leaves:
				table.clear_all()
				table.clear_model()
				_speech_popup(customer, Lang.t("Đây không phải món tôi gọi!"))
				_leave_angry(order_)
			else:
				_complain(customer, Lang.t("Đây không phải món tôi gọi!"))
		return

	order_.draining = false

	var truly_perfect := order_.is_perfect()
	order_.was_perfect = force_perfect or truly_perfect
	order_.truly_perfect = truly_perfect
	var base_price: int = order_.price
	if is_wildcard:
		base_price = maxi(1, int(round(ItemCatalog.price(dish_id) * price_factor * skill_price_factor \
			* float(dish_price_factors.get(dish_id, 1.0)))))
	order_.payout = base_price
	if order_.was_perfect:
		order_.payout = int(round(base_price * (1.0 + perfect_bonus)))
	if truly_perfect and not is_equal_approx(perfect_payout_multiplier, 1.0):
		order_.payout = int(round(order_.payout * perfect_payout_multiplier))
		order_.was_doubled = true

	if order_.was_perfect and not perfect_roll.is_empty() \
			and (perfect_roll.get("dishes", []) as Array).has(dish_id):
		var roll := randf()
		for entry in perfect_roll.get("rolls", []):
			roll -= float(entry[0])
			if roll < 0.0:
				order_.payout = int(round(order_.payout * float(entry[1])))
				break

	if order_.has_meta("vip"):
		order_.payout = int(round(order_.payout * VIP_PAYOUT))

	if bonus_payout_chance > 0.0 and randf() < bonus_payout_chance:
		order_.payout = int(round(order_.payout * bonus_payout_multiplier))

	orders_done += 1
	if counted_dishes.has(order_.dish):
		counted_orders_done += 1
	if order_.was_perfect:
		perfect_orders += 1
		perfect_dishes[order_.dish] = true
		AmThanh.play_sfx("perfect")

	customer.set_meta("dish", dish_id)
	customer.eat(eat_seconds)
	order_finished.emit(order_, "served")


## Bàn từ chối đồ người chơi bê tới (chưa thành món, vd. thiếu đĩa).
func _on_delivery_rejected(table: Node, reason: String) -> void:
	var customer = _customer_at.get(table)
	if customer == null:
		return
	var order_: Order = _orders.get(customer)
	if order_ == null or not _waiting_at_table(order_):
		return
	if reason == "no_plate":
		_complain(customer, Lang.t("Đĩa đâu rồi?!"))


## Khách đã NGỒI vào bàn và đang chờ món. Bàn được giữ chỗ ngay khi khách
func _waiting_at_table(order_: Order) -> bool:
	return not order_.in_queue and order_.draining


## Khách nổi cáu tại chỗ: animation angry + một câu nói nổi trên đầu.
func _complain(customer: Node, text: String) -> void:
	if not is_instance_valid(customer):
		return
	customer.beg()
	_speech_popup(customer, text)
	await get_tree().create_timer(beg_seconds).timeout
	if is_instance_valid(customer) and customer.is_inside_tree():
		customer.calm()


## Câu nói đỏ nổi trên đầu khách. Gắn làm CON của khách để đi theo người;
func _speech_popup(customer: Node, text: String) -> void:
	var old := customer.get_node_or_null("ComplaintText")
	if old != null:
		old.name = "ComplaintTextOld"
		old.queue_free()
	var label := Label3D.new()
	label.name = "ComplaintText"
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color("ff5a4a")
	label.outline_modulate = Color(0.15, 0.0, 0.0)
	label.outline_size = 24
	label.position = Vector3(0.0, 2.9, 0.0)
	customer.add_child(label)
	var tw := label.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.finished.connect(label.queue_free)


func _leave_cash(table: Node, amount: int, is_perfect: bool) -> void:
	var label := Label3D.new()
	label.font_size = 96
	label.pixel_size = 0.004
	label.modulate = Color("ffd76a")
	label.outline_size = 20
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = Vector3(-0.9, 1.5, 1.4)
	table.add_child(label)
	if ResourceLoader.exists(CASH_ICON):
		var icon := Sprite3D.new()
		icon.texture = load(CASH_ICON)
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.render_priority = 1
		icon.pixel_size = CASH_ICON_HEIGHT / float(icon.texture.get_height())
		icon.position = Vector3(-0.4, 0.0, 0)
		label.add_child(icon)
		var tw := icon.create_tween().set_loops()
		tw.tween_property(icon, "position:y", 0.12, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(icon, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	table.set_meta("cash", amount)
	_cash[table] = {"amount": amount, "left": CASH_SECONDS, "perfect": is_perfect, "label": label}
	AmThanh.play_sfx("coin")


func _tick_cash(delta: float) -> void:
	for table in _cash.keys():
		var c: Dictionary = _cash[table]
		c["left"] -= delta
		var lab: Label3D = c["label"]
		if is_instance_valid(lab):
			lab.text = "+%d  (%d)" % [int(c["amount"]), ceili(float(c["left"]))]
		if c["left"] <= 0.0:
			var lost := int(c["amount"])
			_remove_cash(table)
			_money_popup(table.global_position, -lost, false)
			if not _in_queue.is_empty() and _in_queue[0] != null:
				_try_seat(_in_queue[0])


func _on_cash_collected(table: Node) -> void:
	if not _cash.has(table):
		return
	var c: Dictionary = _cash[table]
	_remove_cash(table)
	var amount := int(c["amount"])
	money += amount
	money_changed.emit(money, amount, table.global_position)
	AmThanh.play_sfx("coin")
	_money_popup(table.global_position, amount, bool(c["perfect"]))
	if not _in_queue.is_empty() and _in_queue[0] != null:
		_try_seat(_in_queue[0])


func _remove_cash(table: Node) -> void:
	var c: Dictionary = _cash[table]
	_cash.erase(table)
	if is_instance_valid(c["label"]):
		c["label"].queue_free()
	if is_instance_valid(table):
		table.remove_meta("cash")


func _on_ate(customer: Node) -> void:
	var table = _table_of.get(customer)
	var dish_id := str(customer.get_meta("dish", ""))
	if table != null:
		table.clear_all()
		table.clear_model()
	var order_: Order = _orders.get(customer)
	if order_ != null:
		_orders.erase(customer)
		if order_.payout > 0:
			var net := order_.payout - int(ceil(order_.payout * vat_rate))
			if money_on_table and table != null:
				_leave_cash(table, net, order_.was_perfect)
				customer_ate.emit(customer, table, dish_id)
				if _door != null:
					customer.go_to(_door.global_position, "leave")
				return
			money += net
			var spot: Vector3 = table.global_position if table != null \
				else customer.global_position
			money_changed.emit(money, net, spot)
			AmThanh.play_sfx("coin")
			_money_popup(spot, net, order_.was_perfect)

	customer_ate.emit(customer, table, dish_id)
	if _door != null:
		customer.go_to(_door.global_position, "leave")


## Xoá hẳn người khách và trả lại cái bàn.
func _clear_customer(customer: Node) -> void:
	var table = _table_of.get(customer)
	if table != null:
		_customer_at.erase(table)
		_table_of.erase(customer)
	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0 and slot < _in_queue.size() and _in_queue[slot] == customer:
		_in_queue[slot] = null
		_shift_queue()
	var order_: Order = _orders.get(customer)
	if order_ != null:
		_orders.erase(customer)
		order_finished.emit(order_, "left")

	customer_left.emit(customer)
	customer.queue_free()
	if not _in_queue.is_empty() and _in_queue[0] != null:
		_try_seat(_in_queue[0])


# ------------------------------------------------------------- đơn hàng ---

## Người khách vừa ngồi xuống thì gọi món.
func _place_order(customer: Node) -> void:
	if _orders.has(customer):
		return
	var available := _actual_menu()
	if available.is_empty():
		push_warning("Thực đơn rỗng — không món nào có giá trong ItemCatalog.")
		return

	var picked := _pick_dish(available)
	if not force_dish.is_empty() and available.has(force_dish):
		picked = force_dish
	var vip := customer.has_meta("vip")
	if vip:
		var hard: Array[String] = []
		for d in available:
			if ItemCatalog.difficulty(d) == "hard":
				hard.append(d)
		if not hard.is_empty():
			picked = hard.pick_random()

	var order_ := Order.new(customer, picked)
	var factor := price_factor * skill_price_factor * event_price_factor \
		* float(dish_price_factors.get(picked, 1.0))
	if not is_equal_approx(factor, 1.0):
		order_.price = maxi(1, int(round(order_.price * factor)))
	if is_zero_approx(price_factor):
		order_.price = 0
	order_.patience_factor = patience_factor * (VIP_PATIENCE if vip else 1.0)
	if vip:
		order_.set_meta("vip", true)
	order_.wait_in_queue(queue_patience)
	order_.draining = drain_patience
	_orders[customer] = order_

	customer.show_order(_dish_icon(order_.dish))


## Đẩy đơn của một người lên BẢNG ĐƠN HÀNG (phím 1), nếu chưa có.
func _push_to_board(customer: Node) -> void:
	var order_: Order = _orders.get(customer)
	if order_ != null:
		order_created.emit(order_)


## Thực đơn thật sự dùng để bốc món.
func _actual_menu() -> Array[String]:
	var full := ItemCatalog.sellable_dishes()
	if menu.is_empty():
		return full

	var out: Array[String] = []
	for m in menu:
		var id := String(m)
		if full.has(id):
			out.append(id)
		else:
			push_warning("Thực đơn màn có món '%s' không bán được — bỏ qua." % id)

	if out.is_empty():
		push_warning("Thực đơn màn lọc xong thành rỗng — dùng cả danh mục.")
		return full
	return out


## Bốc một món theo trọng số.
func _pick_dish(list_: Array[String]) -> String:
	var picked := _pick_weighted(_narrow_to_tier(_without_hard_if_cooling(list_)))
	if ItemCatalog.difficulty(picked) == "hard":
		_orders_since_hard = 0
	else:
		_orders_since_hard += 1
	return picked


## Đang trong quãng nghỉ sau món khó thì bỏ hẳn các món khó khỏi danh sách.
func _without_hard_if_cooling(list_: Array[String]) -> Array[String]:
	if _orders_since_hard >= hard_cooldown_orders:
		return list_
	var out: Array[String] = []
	for id in list_:
		if ItemCatalog.difficulty(id) != "hard":
			out.append(id)
	return out if not out.is_empty() else list_


## Thu danh sách món về MỘT mức độ khó, bốc theo tier_weights. Trả nguyên danh
func _narrow_to_tier(list_: Array[String]) -> Array[String]:
	if tier_weights.is_empty():
		return list_
	var by_tier: Dictionary = {}
	for id in list_:
		var tier := ItemCatalog.difficulty(id)
		if not by_tier.has(tier):
			var fresh: Array[String] = []
			by_tier[tier] = fresh
		(by_tier[tier] as Array[String]).append(id)

	var total := 0.0
	for tier in by_tier:
		total += maxf(0.0, float(tier_weights.get(tier, 0)))
	if total <= 0.0:
		return list_

	var pick := randf() * total
	var last: Array[String] = list_
	for tier in by_tier:
		var w := maxf(0.0, float(tier_weights.get(tier, 0)))
		if w <= 0.0:
			continue
		last = by_tier[tier]
		pick -= w
		if pick <= 0.0:
			return last
	return last


## Trọng số bốc của một món: số trong bảng `weights` của màn, nhân với hệ số
func _dish_weight(id: String) -> float:
	return maxf(0.0, float(weights.get(id, 1)) * float(dish_weight_factors.get(id, 1.0)))


func _pick_weighted(list_: Array[String]) -> String:
	var total := 0.0
	for id in list_:
		total += _dish_weight(id)
	if total <= 0.0:
		return String(list_.pick_random())

	var pick := randf() * total
	for id in list_:
		pick -= _dish_weight(id)
		if pick <= 0.0:
			return id
	return list_[list_.size() - 1]


## Khách đã tới bàn: tắt bong bóng, nạp đầy kiên nhẫn, bật vé trên HUD.
func _seat_at_table(customer: Node, table: Node) -> void:
	var order_: Order = _orders.get(customer)
	if order_ == null:
		_place_order(customer)
		order_ = _orders.get(customer)
		if order_ == null:
			return

	customer.hide_order()
	var queue_ratio := order_.patience_ratio()
	order_.sit_at_table(table)
	if keep_queue_patience:
		order_.patience_left = order_.patience_max * queue_ratio
	order_.draining = drain_patience
	order_created.emit(order_)


## Ảnh 2D của một món, hoặc null nếu thiếu file.
func _dish_icon(id: String) -> Texture2D:
	var icon_file := ItemCatalog.icon_path(id)
	if not ResourceLoader.exists(icon_file):
		push_warning("Bong bóng đơn: thiếu ảnh %s" % icon_file)
		return null
	return load(icon_file) as Texture2D


## Hết kiên nhẫn: cáu, bỏ đơn, ĐỢI DIỄN XONG rồi mới đi ra cửa.
func _leave_angry(order_: Order) -> void:
	var customer: Node = order_.customer
	_orders.erase(customer)
	if not bool(order_.in_queue):
		customers_lost += 1
		AmThanh.play_sfx("customer_out")
	order_finished.emit(order_, "left")
	if not is_instance_valid(customer):
		return

	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0 and slot < _in_queue.size() and _in_queue[slot] == customer:
		_in_queue[slot] = null
		customer.remove_meta("in_queue")
		_shift_queue()

	customer.hide_order()
	customer.beg()
	await get_tree().create_timer(beg_seconds).timeout

	if not is_instance_valid(customer) or not customer.is_inside_tree():
		return
	if _door != null:
		customer.go_to(_door.global_position, "leave")


## Số tiền bay lên ở chỗ vừa phục vụ xong.
func charge_for_ingredient(id: String, at: Vector3) -> void:
	if free_ingredients:
		return
	var amount := ItemCatalog.cost(id)
	if amount <= 0:
		return
	amount = int(ceil(amount * float(ingredient_cost_factors.get(id, 1.0))))
	money -= amount
	money_changed.emit(money, -amount, at)
	_money_popup(at, -amount, false)


## Số tiền bay lên chỗ vừa xảy ra chuyện. amount ÂM = vừa bị trừ.
func _money_popup(spot: Vector3, amount: int, is_perfect: bool) -> void:
	if _map == null:
		return
	var anchor := Node3D.new()
	anchor.position = spot + Vector3(0.0, 1.9, 0.0)
	_map.add_child(anchor)

	var icon: Sprite3D = null
	if ResourceLoader.exists(COIN_ICON):
		icon = Sprite3D.new()
		icon.texture = load(COIN_ICON)
		icon.pixel_size = 0.0022
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.position.x = -0.28
		anchor.add_child(icon)

	var text_ := Label3D.new()
	text_.text = ("+%d" % amount) if amount >= 0 else ("−%d" % absi(amount))
	text_.font_size = 128
	text_.pixel_size = 0.0028
	text_.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text_.no_depth_test = true
	text_.outline_size = 28
	if amount < 0:
		text_.modulate = Color("e08a7a")
	else:
		text_.modulate = Color("ffd76a") if is_perfect else Color("d8f0c8")
	text_.position.x = 0.22
	anchor.add_child(text_)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(anchor, "position:y", anchor.position.y + 0.9, 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(text_, "modulate:a", 0.0, 0.5).set_delay(0.7)
	if icon != null:
		tw.tween_property(icon, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.finished.connect(anchor.queue_free)


## Đóng cửa: ngừng sinh khách và ngừng đếm kiên nhẫn.
func active_orders() -> Array:
	return _orders.values()


func menu_dishes() -> Array[String]:
	return _actual_menu()


## Cộng thẳng một khoản tiền vào ví, có báo cho HUD.
func add_money(amount: int, spot: Vector3 = Vector3.ZERO) -> void:
	money += amount
	money_changed.emit(money, amount, spot)


## Cho TOÀN BỘ khách biến mất ngay và đưa nhịp khách về như đầu màn.
func clear_all_customers() -> void:
	clearing_all = true
	for customer in _orders.keys():
		var order_: Order = _orders[customer]
		if order_.payout > 0 and not order_.draining and is_instance_valid(customer) \
				and customer.has_meta("dish"):
			add_money(order_.payout - int(ceil(order_.payout * vat_rate)), customer.global_position)
		order_finished.emit(order_, "left")
	_orders.clear()
	clearing_all = false

	for table in _customer_at.keys():
		if is_instance_valid(table):
			table.clear_all()
			table.clear_model()
	_customer_at.clear()
	_table_of.clear()
	for i in _in_queue.size():
		_in_queue[i] = null

	for k in get_tree().get_nodes_in_group(CUSTOMER_GROUP):
		customer_left.emit(k)
		k.queue_free()

	_spawn_timer = first_wait
	_orders_since_hard = 0


func close_shop() -> void:
	auto_spawn = false
	drain_patience = false
	for order_ in _orders.values():
		order_.draining = false
