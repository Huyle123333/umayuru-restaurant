@tool
class_name DiningTable
extends Workstation

## Số bàn hiện trên vé đơn hàng và trên biển nổi bên trên bàn.
@export var table_number: int = 1:
	set(v):
		table_number = v
		_update_sign()

@warning_ignore("unused_signal")
signal dish_delivered(table: Node, dish_id: String)

@warning_ignore("unused_signal")
signal delivery_rejected(table: Node, reason: String)

@warning_ignore("unused_signal")
signal cash_collected(table: Node)

## Bật/tắt biển số, dùng khi muốn chụp ảnh map cho báo cáo.
@export var show_number := true:
	set(v):
		show_number = v
		_update_sign()

var _sign: Label3D = null


func _ready() -> void:
	_update_sign()
	if not Engine.is_editor_hint():
		display_name = Lang.t("Bàn %d") % table_number


## Món đang nằm trên bàn, chuỗi rỗng nếu bàn trống.
func dish_on_table() -> String:
	return String(contents[0]) if not contents.is_empty() else ""


func _update_sign() -> void:
	if _sign == null or not is_instance_valid(_sign):
		_sign = get_node_or_null("NumberLabel") as Label3D
	if _sign == null:
		return
	_sign.text = str(table_number)
	_sign.visible = show_number


## Số chỗ khách đứng được quanh bàn này.
func seat_count() -> int:
	var n := 0
	for c in get_children():
		if c is Marker3D and String(c.name).begins_with("ChoDung"):
			n += 1
	return n


## Chỗ đứng thứ i (đếm từ 0). Trả về null nếu không có.
func seat_marker(i: int) -> Marker3D:
	var list_: Array[Marker3D] = []
	for c in get_children():
		if c is Marker3D and String(c.name).begins_with("ChoDung"):
			list_.append(c)
	if i < 0 or i >= list_.size():
		return null
	return list_[i]


## Tìm bàn theo số. Dùng nhóm "dining_table" nên không phụ thuộc đường dẫn node —
static func find_by_number(tree: SceneTree, number: int) -> DiningTable:
	for n in tree.get_nodes_in_group("dining_table"):
		var b := n as DiningTable
		if b != null and b.table_number == number:
			return b
	return null


## Danh sách mọi bàn, đã sắp theo số bàn tăng dần.
static func all_nodes(tree: SceneTree) -> Array[DiningTable]:
	var list_: Array[DiningTable] = []
	for n in tree.get_nodes_in_group("dining_table"):
		var b := n as DiningTable
		if b != null:
			list_.append(b)
	list_.sort_custom(func(a: DiningTable, b: DiningTable) -> bool: return a.table_number < b.table_number)
	return list_
