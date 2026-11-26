extends RefCounted

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Ngưỡng "đơn hoàn hảo": giao khi kiên nhẫn còn TRÊN mức này.
const PERFECT_THRESHOLD := 0.5

var customer: Node
var table: Node
var dish: String = ""
var price: int = 0

var patience_max: float = 0.0
var patience_left: float = 0.0

## Nhân vào ngân sách kiên nhẫn của CẢ HAI giai đoạn. 1,0 = không đổi.
var patience_factor: float = 1.0

## Đang ở giai đoạn nào. true = đứng xếp hàng, false = đã ngồi vào bàn.
var in_queue: bool = true

## Có trừ kiên nhẫn theo thời gian không.
var draining: bool = true

## Tiền đã chốt lúc GIAO, gồm cả thưởng hoàn hảo. Trả vào ví lúc khách ăn xong.
var payout: int = 0
var was_perfect: bool = false
## Hoàn hảo THẬT (giao lúc kiên nhẫn còn trên nửa), không tính phần kĩ năng ép
var truly_perfect: bool = false

## Đơn này có được kĩ năng nhân đôi tiền không. Chỉ để HIỂN THỊ.
var was_doubled: bool = false


## Đơn sinh ra lúc khách vào hàng đợi, khi CHƯA biết sẽ ngồi bàn nào.
func _init(customer_node: Node, dish_id: String) -> void:
	customer = customer_node
	dish = dish_id
	price = ItemCatalog.price(dish_id)


## Bắt đầu giai đoạn CHỜ BÀN với ngân sách kiên nhẫn cho trước.
func wait_in_queue(seconds: float) -> void:
	in_queue = true
	patience_max = seconds * patience_factor
	patience_left = patience_max


## Ngồi được vào bàn: NẠP ĐẦY LẠI kiên nhẫn, lần này tính theo món.
func sit_at_table(cai_ban: Node) -> void:
	table = cai_ban
	in_queue = false
	patience_max = ItemCatalog.patience(dish) * patience_factor
	patience_left = patience_max


## Trừ thời gian. Trả về true đúng MỘT lần, ở khoảnh khắc kiên nhẫn vừa cạn.
func tick(delta: float) -> bool:
	if not draining or patience_left <= 0.0:
		return false
	patience_left = maxf(0.0, patience_left - delta)
	return patience_left <= 0.0


## Kiên nhẫn còn lại, quy về 0…1 để vẽ thanh.
func patience_ratio() -> float:
	if patience_max <= 0.0:
		return 0.0
	return clampf(patience_left / patience_max, 0.0, 1.0)


func is_perfect() -> bool:
	return patience_ratio() > PERFECT_THRESHOLD


func table_number() -> int:
	return int(table.table_number) if table != null and "table_number" in table else 0


func dish_name() -> String:
	return ItemCatalog.display_name(dish)


func icon_path() -> String:
	return ItemCatalog.icon_path(dish)
