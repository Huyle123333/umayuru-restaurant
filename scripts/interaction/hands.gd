extends Node

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Đang cầm gì — HUD nghe để hiện tên trên màn hình.
signal held_name_changed(item_name: String)

## Cùng khoảnh khắc với do_tren_tay_doi nhưng mang ID vật phẩm thay vì CHỮ
signal held_item_changed(id: String)

## Một câu báo ngắn cho HUD (ghép xong / ghép hụt). `tot` false = tin xấu.
signal notice(text: String, good: bool)
## Xin mở bảng chọn nguyên liệu cho một trạm. level_base nối tới bảng.
signal request_picker(station: Node)

## Người chơi vừa LẤY một nguyên liệu ở kệ / tủ lạnh / máy kem.
signal ingredient_taken(id: String, at: Vector3)

## Vừa vứt một thứ vào thùng rác. Asian Mode nghe để phạt đồ cháy; các màn khác
signal item_discarded(id: String, station: Node)

## Nguyên liệu đang HẾT HÀNG (sự kiện Asian). Kệ và tủ lạnh vẫn đứng đó nhưng
var blocked_items: Array = []

## Hệ thống bếp, do level_base gán vào. Để rỗng thì bếp chỉ là đồ trang trí.
var cooking: Node = null

## Đặt xuống cách nhân vật bao xa.
@export var drop_distance := 1.1
## ============================ CHỈNH VỊ TRÍ VẬT CẦM TẠI ĐÂY ============
@export var hold_distance := 0.70
@export var hold_height := 0.72

## Ảnh 2D lơ lửng trên đầu cao bao nhiêu.
@export var sign_height := 2.35
## Bề ngang ảnh 2D, tính bằng đơn vị thế giới.
@export var sign_width := 0.62
## Có hiện ảnh 2D trên đầu không.
@export var show_2d_sign := true
## Cạnh hộp va chạm của một vật phẩm nằm dưới đất.
@export var item_scale := 0.45

var _body: CharacterBody3D = null
var _model: Node3D = null
## Ảnh 2D hiện thứ đang cầm, lơ lửng trên đầu nhân vật.
var _sign: Sprite3D = null
## Điểm treo model vật phẩm trước ngực nhân vật.
var _hand_point: Node3D = null

## Vật đang cầm. Luôn là node THẬT trong thế giới chứ không phải bản sao —
var _held: Workstation = null
## Node cha lúc chưa cầm, để đặt xuống thì trả về đúng chỗ cũ trong cây scene.
var _orig_parent: Node = null
## Nơi thả vật phẩm mới sinh ra. Lấy node gốc màn chơi.
var _world: Node = null


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_model = _body.get_node_or_null("Model") as Node3D

	_hand_point = Node3D.new()
	_hand_point.name = "HandPoint"
	_body.add_child(_hand_point)

	_sign = Sprite3D.new()
	_sign.name = "HeldSign"
	_sign.position = Vector3(0.0, sign_height, 0.0)
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.shaded = false
	_sign.no_depth_test = true
	_sign.render_priority = 10
	_sign.pixel_size = 0.002
	_sign.hide()
	_body.add_child(_sign)

	await get_tree().process_frame
	_world = _body.get_parent()
	for n in get_tree().get_nodes_in_group("station"):
		_listen_station(n as Workstation)

	get_tree().node_added.connect(_on_node_added)


## Bắt mọi node mới vào cây; chỉ quan tâm trạm.
func _on_node_added(n: Node) -> void:
	var t := n as Workstation
	if t != null:
		_listen_station(t)


func _listen_station(t: Workstation) -> void:
	if t != null and not t.interacted.is_connected(_on_interact):
		t.interacted.connect(_on_interact)
	if t != null and not t.interacted_alt.is_connected(_on_interact_alt):
		t.interacted_alt.connect(_on_interact_alt)


## Kéo điểm cầm ra trước mặt mỗi frame.
func _process(_delta: float) -> void:
	if _hand_point == null:
		return
	var origin := _model.rotation.y if _model != null else 0.0
	_hand_point.position = Vector3(0.0, hold_height, 0.0) \
		+ Vector3(sin(origin), 0.0, cos(origin)) * hold_distance
	_hand_point.rotation.y = origin


# ------------------------------------------------------------ tương tác ---

func _on_interact(station: Node, _index: int) -> void:
	var t := station as Workstation
	if t == null:
		return

	if t.use_picker:
		if _held == null:
			request_picker.emit(t)
		return

	match t.kind:
		"carriable":
			if ItemCatalog.is_locked(t.item_id):
				return
			if _held == null:
				_pick_up(t)
		"ingredient_shelf":
			if t.item_id.is_empty():
				return
			if _held == null:
				if blocked_items.has(t.item_id):
					notice.emit(Lang.t("Hết hàng!"), false)
					return
				_pick_up(_spawn_item(t.item_id))
				ingredient_taken.emit(t.item_id, t.global_position)
		"cutting_board":
			_use_single_station(t, "chop")
		"stove":
			_use_cooker(t)
		"oven":
			_use_oven(t)
		"plate_stack":
			if _held == null:
				_pick_up(_spawn_item("bowl"))
		"pot_stack":
			if _held == null and not ItemCatalog.is_locked("noi"):
				_pick_up(_spawn_item("noi"))
		"bin":
			_discard(t)
		"crafting_table", "prep_table":
			_put_on_table(t)
		"counter":
			_use_counter(t)
		"guest_table":
			_deliver_dish(t)
		_:
			pass


## Phím F: hiện chỉ có bàn chế tạo dùng — RÁP những thứ đang nằm trên bàn.
func _on_interact_alt(station: Node, _index: int) -> void:
	var t := station as Workstation
	if t == null:
		return
	if t.kind == "crafting_table":
		_assemble_table(t)


## Ráp món từ những thứ đang có trên bàn chế tạo.
func _assemble_table(table: Workstation) -> void:
	if table.contents.is_empty():
		notice.emit(Lang.t("Bàn đang trống"), false)
		return

	var dish: String = ItemCatalog.combine_on_table(table.contents)
	if dish.is_empty():
		var list_: Array[String] = []
		for x in table.contents:
			list_.append(ItemCatalog.display_name(String(x)))
		notice.emit(Lang.t("Không thành món: ") + ", ".join(list_), false)
		AmThanh.play_sfx("craft_fail")
		return

	if craft_fail_chance > 0.0 and randf() < craft_fail_chance:
		table.clear_all()
		table.add_item(FAILED_ITEM)
		table.show_model(FAILED_ITEM)
		notice.emit(Lang.t("Ghép hỏng!"), false)
		AmThanh.play_sfx("craft_fail")
		return

	table.clear_all()
	table.add_item(dish)
	table.show_model(dish)
	notice.emit(Lang.t("Ghép xong: ") + ItemCatalog.display_name(dish), true)
	AmThanh.play_sfx("craft_ok")


## Bảng chọn trả về một id vật phẩm. Sinh vật rồi cầm lên, cùng đường với
var craft_fail_chance: float = 0.0
const FAILED_ITEM := "do_hong"


## Đặt thẳng một món vào tay, KHÔNG trừ tiền. Trả về false nếu tay đang bận.
func give_item(id: String) -> bool:
	if _held != null or id.is_empty() or not ItemCatalog.has_item(id):
		return false
	_pick_up(_spawn_item(id))
	return true


func is_holding() -> bool:
	return _held != null


## Màn hướng dẫn: tủ lạnh chỉ cho lấy đúng món đang dạy ("" = không giới hạn).
var tutorial_item := ""


func receive_ingredient(station: Node, id: String) -> void:
	if _held != null or id.is_empty():
		return
	if not tutorial_item.is_empty() and id != tutorial_item \
			and (station as Workstation) != null and (station as Workstation).kind != "crafting_table":
		notice.emit(Lang.t("Lấy đúng %s theo hướng dẫn nhé") % ItemCatalog.display_name(tutorial_item), false)
		return
	var ws := station as Workstation
	if ws != null and ws.kind == "crafting_table":
		var at_ := ws.contents.find(id)
		if at_ < 0:
			return
		ws.contents.remove_at(at_)
		ws.contents_changed.emit(ws)
		ws.show_stack(ws.contents)
		_pick_up(_spawn_item(id))
		return
	if blocked_items.has(id):
		notice.emit(Lang.t("Hết hàng!"), false)
		return
	_pick_up(_spawn_item(id))
	var at := Vector3.ZERO
	if station is Node3D:
		at = (station as Node3D).global_position
	ingredient_taken.emit(id, at)


# ---------------------------------------------------------- sinh vật phẩm ---

## Dựng một vật phẩm cầm được từ id trong danh mục.
func _spawn_item(id: String) -> Workstation:
	var item := Workstation.new()
	item.name = "Item_" + id
	item.display_name = ItemCatalog.display_name(id)
	item.kind = "carriable"
	item.item_id = id
	item.add_to_group("station")
	item.collision_layer = Workstation.LAYER_ITEM
	item.collision_mask = 0

	var m: Node3D = ItemCatalog.make_model(id)
	if m != null:
		m.name = "Mesh"
		item.add_child(m)
	else:
		push_warning("Vật phẩm '%s' chưa có model." % id)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(item_scale, item_scale, item_scale)
	shape.shape = box
	shape.position = Vector3(0.0, item_scale * 0.5, 0.0)
	item.add_child(shape)

	var mark := Marker3D.new()
	mark.name = "AimPoint"
	mark.position = Vector3(0.0, 0.25, 0.0)
	item.add_child(mark)

	_world.add_child(item)
	_listen_station(item)
	return item


# ------------------------------------------------------------ cầm / đặt ---

## Cầm một vật lên: treo model thật vào điểm trước ngực nhân vật.
func _pick_up(t: Workstation) -> void:
	if t == null:
		return
	_held = t
	_orig_parent = t.get_parent()
	AmThanh.play_sfx("pick_up", randf_range(0.94, 1.06))

	_set_collision(t, false)
	if _orig_parent != null:
		_orig_parent.remove_child(t)
	_hand_point.add_child(t)
	t.transform = Transform3D.IDENTITY
	t.visible = true

	_body.carrying = true
	_draw_sign()


## Bật/tắt mọi hình va chạm con của một vật.
func _set_collision(t: Node3D, on: bool) -> void:
	for c in t.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", not on)


## Bấm E vào bếp.
func _use_cooker(cooker: Workstation) -> void:
	_use_single_station(cooker, "cook")


## Thớt và bếp-nấu-món-lẻ dùng chung một luật: bỏ vào, chờ, lấy ra.
func _use_single_station(station: Workstation, mode: String) -> void:
	if cooking == null:
		return
	if _held != null:
		if cooking.put_item(station, _held.item_id, mode):
			_clear_held()
		return
	var id: String = cooking.take_out(station)
	if not id.is_empty():
		_pick_up(_spawn_item(id))


## Bấm E vào lò nướng.
func _use_oven(oven: Workstation) -> void:
	if cooking == null:
		return

	if _held != null:
		var id: String = _held.item_id
		if id == ItemCatalog.PIZZA_BASE and oven.contents.is_empty() \
				and ItemCatalog.oven_takes_base():
			if cooking.start_oven(oven):
				_clear_held()
		elif not ItemCatalog.bake_step(id).is_empty() and oven.contents.is_empty():
			if cooking.start_oven(oven, id):
				_clear_held()
		elif cooking.is_burning(oven) and ItemCatalog.can_go_in_oven(id):
			if cooking.add_to_oven(oven, id):
				_clear_held()
		return

	if not cooking.is_burning(oven) and not oven.contents.is_empty():
		var id: String = cooking.take_out(oven)
		if id.is_empty():
			return
		_pick_up(_spawn_item(id))


## Bấm E vào máng bỏ đồ — thùng rác VÀ Doro.
func _discard(bin: Workstation) -> void:
	if _held == null:
		return
	AmThanh.play_sfx("trash")
	item_discarded.emit(String(_held.item_id), bin)
	_clear_held()


## Bỏ hẳn thứ đang cầm khỏi thế giới.
func _clear_held() -> void:
	if _held == null:
		return
	var t := _held
	_held = null
	_orig_parent = null
	_body.carrying = false
	_draw_sign()
	t.queue_free()


func _throw_out() -> void:
	var dir := Vector3(sin(_model.rotation.y), 0.0, cos(_model.rotation.y)) \
		if _model != null else Vector3.FORWARD
	var dest := _body.global_position + dir * drop_distance
	dest.y = 0.0
	_place_at(_held, dest)


## Bàn chế tạo: bỏ nguyên liệu vào, và khi tay không thì lấy món ra.
func _put_on_table(table: Workstation) -> void:
	if _held == null:
		_take_dish_from_table(table)
		return

	var id: String = _held.item_id
	if id.is_empty():
		id = _held.display_name
	if ItemCatalog.is_locked(id):
		return
	table.add_item(id)
	_clear_held()
	AmThanh.play_sfx("put_down", randf_range(0.94, 1.06))

	table.show_stack(table.contents)


## Quầy để đồ: chỗ đặt tạm ĐÚNG MỘT món.
func _use_counter(t: Workstation) -> void:
	if _held != null:
		if not t.contents.is_empty():
			notice.emit(Lang.t("Quầy đã có đồ"), false)
			return
		var id: String = _held.item_id
		if id.is_empty():
			id = _held.display_name
		if ItemCatalog.is_locked(id):
			return
		t.add_item(id)
		t.show_model(id)
		_clear_held()
		AmThanh.play_sfx("put_down", randf_range(0.94, 1.06))
		return
	if t.contents.is_empty():
		return
	var taken := t.pop_last()
	t.clear_model()
	_pick_up(_spawn_item(taken))


## Giao món cho một bàn khách.
func _deliver_dish(table: Workstation) -> void:
	if _held == null and table.has_meta("cash") and table.has_signal("cash_collected"):
		table.emit_signal("cash_collected", table)
		return
	if _held == null:
		if table.contents.is_empty():
			return
		var taken: String = table.pop_last()
		table.clear_model()
		_pick_up(_spawn_item(taken))
		return

	var id: String = _held.item_id
	if not table.contents.is_empty():
		return
	if ItemCatalog.price(id) <= 0:
		notice.emit(Lang.t("Chưa có đĩa! Ráp món với đĩa ở bàn chế tạo trước."), false)
		if table.has_signal("delivery_rejected"):
			table.emit_signal("delivery_rejected", table, "no_plate")
		return

	table.add_item(id)
	table.show_model(id)
	_clear_held()

	AmThanh.play_sfx("serve")
	if table.has_signal("dish_delivered"):
		table.emit_signal("dish_delivered", table, id)


## Tay không, bấm E ở bàn: nhấc món đã ráp, hoặc LẤY LẠI nguyên liệu vừa bỏ.
func _take_dish_from_table(table: Workstation) -> void:
	if table.contents.is_empty():
		return

	if table.kind == "crafting_table" and table.contents.size() >= 2:
		request_picker.emit(table)
		return

	var id: String = table.pop_last()

	table.show_stack(table.contents)

	_pick_up(_spawn_item(id))


func _place_at(t: Workstation, dest: Vector3) -> void:
	var parent: Node = _orig_parent if _orig_parent != null else _world
	if t.get_parent() != null:
		t.get_parent().remove_child(t)
	parent.add_child(t)
	t.global_position = dest
	t.visible = true
	_set_collision(t, true)
	_release()


func _release() -> void:
	_held = null
	_orig_parent = null
	_body.carrying = false
	_draw_sign()


var _knife: Sprite3D = null


## Dấu con dao nhỏ ở góc biển trên đầu: món đang cầm phải qua thớt.
func _draw_knife(on: bool) -> void:
	if _knife == null:
		if not ResourceLoader.exists(ItemCatalog.KNIFE_BADGE):
			return
		_knife = Sprite3D.new()
		_knife.texture = load(ItemCatalog.KNIFE_BADGE)
		_knife.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_knife.shaded = false
		_knife.no_depth_test = true
		_knife.render_priority = 11
		_sign.add_child(_knife)
	var size_ := sign_width * 0.45
	_knife.pixel_size = size_ / float(_knife.texture.get_width())
	_knife.position = Vector3(sign_width * 0.35, -sign_width * 0.3, 0.0)
	_knife.visible = on


## Vẽ lại tấm ảnh trên đầu theo thứ đang cầm.
func _draw_sign() -> void:
	if _sign == null:
		return
	if _held == null:
		_sign.hide()
		held_name_changed.emit("")
		held_item_changed.emit("")
		return

	var id: String = _held.item_id
	var label := _held.display_name
	if not _held.contents.is_empty():
		id = String(_held.contents[_held.contents.size() - 1])
		label = "%s (%d): %s" % [_held.display_name,
			_held.contents.size(), ItemCatalog.display_name(id)]

	var path: String = ItemCatalog.icon_path(id)
	if show_2d_sign and ResourceLoader.exists(path):
		_sign.texture = load(path)
		var w := float(_sign.texture.get_width())
		_sign.pixel_size = sign_width / maxf(w, 1.0)
		_sign.show()
		_draw_knife(false)
	else:
		_sign.hide()
	held_name_changed.emit(label)
	held_item_changed.emit(id)
