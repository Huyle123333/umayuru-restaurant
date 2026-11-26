extends RefCounted

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Tên trạm hiển thị, theo `kind`. Không dùng display_name trong file map vì
const STATION_NAMES := {
	"crafting_table": "Bàn chế tạo",
	"cutting_board": "Thớt",
	"stove": "Bếp",
	"plate_stack": "Chồng đĩa",
	"bin": "Thùng rác",
	"fridge": "Tủ lạnh",
}


## Kết quả là một Dictionary:
static func plan(order_: Object, held: String, stations: Dictionary) -> Dictionary:
	if order_ == null:
		return _result(Lang.t("Chờ khách gọi món"), Lang.t("Mẹo: khách sẽ tới nếu bạn chờ."), null, "", 0, 0)

	var dish: String = String(order_.dish)
	var table_no: int = int(order_.table_number())
	var craft: Node = stations.get("crafting_table")
	var key := ItemCatalog._recipe_key_for(dish)
	var parts: Array[String] = []
	for p in key.split("+"):
		parts.append(String(p))
	var on_table: Array[String] = []
	if craft != null:
		for c in craft.contents:
			on_table.append(String(c))

	var missing := _subtract(parts, on_table)
	var extra := _subtract(on_table, parts)
	var total := parts.size() + 2
	var step := clampi(parts.size() - missing.size() + 1, 1, total)
	var dish_name := ItemCatalog.display_name(dish)

	# 1. Đang cầm đúng món → giao.
	if held == dish:
		var guest: Node = stations.get("tables", {}).get(table_no)
		return _result(Lang.t("Mang %s tới Bàn %d") % [dish_name, table_no],
			Lang.t("Mẹo: khách gọi món nào thì muốn ăn món đó."), guest, "E", total, total)

	# 2. Đang cầm thứ khác.
	if not held.is_empty():
		var held_name := ItemCatalog.display_name(held)
		if missing.has(held):
			return _result(Lang.t("Đặt %s lên %s") % [held_name, _name("crafting_table")],
				Lang.t("Mẹo: %s là một phần của %s.") % [held_name, dish_name], craft, "E", step, total)
		var next_kind := _process_kind_toward(held, missing)
		if not next_kind.is_empty():
			return _result(Lang.t("Đặt %s lên %s") % [held_name, _name(next_kind)],
				Lang.t("Mẹo: %s cần được %s trước.") % [held_name,
					Lang.t("thái") if next_kind == "cutting_board" else Lang.t("nấu")],
				stations.get(next_kind), "E", step, total)
		return _result(Lang.t("Vứt %s vào %s") % [held_name, _name("bin")],
			Lang.t("Mẹo: món này không cần %s.") % held_name, stations.get("bin"), "E", step, total)

	# 3. Tay không.
	if not extra.is_empty():
		return _result(Lang.t("Lấy lại %s khỏi %s") % [ItemCatalog.display_name(extra[0]), _name("crafting_table")],
			Lang.t("Mẹo: bỏ thừa nguyên liệu thì không ráp được món."), craft, "E", step, total)
	if missing.is_empty():
		return _result(Lang.t("Bấm F ở %s để ráp %s") % [_name("crafting_table"), dish_name],
			Lang.t("Mẹo: ráp món thì phải bấm phím ráp món."), craft, "F", total - 1, total)

	# Thành phẩm đang nằm trên thớt / bếp mà món cần → lấy ra.
	for kind in ["stove", "cutting_board"]:
		var st: Node = stations.get(kind)
		if st == null or st.contents.is_empty():
			continue
		var c := String(st.contents[0])
		if missing.has(c):
			return _result(Lang.t("Lấy %s ở %s") % [ItemCatalog.display_name(c), _name(kind)],
				Lang.t("Mẹo: món đã xong thì nên lấy ra."), st, "E", step, total)
		if _is_waste(c):
			return _result(Lang.t("Lấy %s ở %s rồi vứt đi") % [ItemCatalog.display_name(c), _name(kind)],
				Lang.t("Mẹo: đồ cháy thì không bán được."), st, "E", step, total)

	# Nguyên liệu còn thiếu mà CHƯA có gì đang chế biến thành nó → đi lấy.
	for p in missing:
		if _in_progress(p, stations):
			continue
		var raw := _raw_source(p)
		var where := _source_station(raw, stations)
		var raw_name := ItemCatalog.display_name(raw)
		return _result(Lang.t("Lấy %s ở %s") % [raw_name, _station_label(raw, where)],
			Lang.t("Mẹo: %s là nguyên liệu dùng để làm %s.") % [raw_name, dish_name],
			where, "E", step, total)

	# Mọi thứ còn thiếu đều đang trên thớt/bếp → chờ.
	for kind in ["stove", "cutting_board"]:
		var st2: Node = stations.get(kind)
		if st2 != null and not st2.contents.is_empty():
			return _result(Lang.t("Chờ %s xong") % _name(kind),
				Lang.t("Mẹo: hãy kiên nhẫn!"), st2, "", step, total)
	return _result(Lang.t("Nấu %s cho Bàn %d") % [dish_name, table_no],
		Lang.t("Mẹo: nấu ăn là việc của đầu bếp."), craft, "", step, total)


static func _result(text: String, tip: String, target: Node, key: String, step: int, total: int) -> Dictionary:
	return {"text": text, "tip": tip, "target": target, "key": key, "step": step, "total": total}


static func _name(kind: String) -> String:
	return Lang.t(String(STATION_NAMES.get(kind, kind)))


## Phép trừ đa tập: a trừ b, mỗi phần tử của b chỉ trừ một lần.
static func _subtract(a: Array[String], b: Array[String]) -> Array[String]:
	var rest := b.duplicate()
	var out: Array[String] = []
	for x in a:
		var i := rest.find(x)
		if i >= 0:
			rest.remove_at(i)
		else:
			out.append(x)
	return out


## Thứ đang cầm, đem thái hoặc nấu (một hay nhiều lần), có thành thứ đang
static func _process_kind_toward(id: String, missing: Array[String]) -> String:
	var first := ""
	var x := id
	for _i in 4:
		var kind := ""
		var nx := ItemCatalog.prep_step(x)
		if not nx.is_empty():
			kind = "cutting_board"
		else:
			nx = ItemCatalog.cook_step(x)
			if not nx.is_empty():
				kind = "stove"
		if nx.is_empty():
			return ""
		if first.is_empty():
			first = kind
		if missing.has(nx):
			return first
		x = nx
	return ""


## Lần ngược chuỗi chế biến tới nguyên liệu thô: steak_cooked ← steak_uncook ← steak.
static func _raw_source(id: String) -> String:
	var x := id
	for _i in 4:
		var src := ItemCatalog._source_of(x)
		if src.is_empty():
			return x
		x = src
	return x


## Có trạm nào đang giữ một thứ trong chuỗi chế biến ra `id` không.
static func _in_progress(id: String, stations: Dictionary) -> bool:
	for kind in ["stove", "cutting_board"]:
		var st: Node = stations.get(kind)
		if st == null or st.contents.is_empty():
			continue
		var c := String(st.contents[0])
		var wanted: Array[String] = [id]
		if c == id or _process_kind_toward(c, wanted) != "":
			return true
	return false


static func _is_waste(id: String) -> bool:
	return id == "do_hong" or id.ends_with("_fail")


## Trạm phát ra nguyên liệu thô này.
static func _source_station(raw: String, stations: Dictionary) -> Node:
	if raw == "bowl":
		return stations.get("plate_stack")
	var shelves: Dictionary = stations.get("shelves", {})
	if shelves.has(raw):
		return shelves[raw]
	return stations.get("fridge")


static func _station_label(raw: String, st: Node) -> String:
	if st == null:
		return "?"
	if String(st.kind) == "ingredient_shelf":
		return Lang.t("Kệ %s") % ItemCatalog.display_name(raw)
	return _name(String(st.kind))
