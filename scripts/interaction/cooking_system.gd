extends Node
## ------------------------------------------------------------- LUẬT NẤU
## ------------------------------------------- BỎ KIỂU NẤU "NỒI" — 14/9/2026

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Nấu xong một mẻ. `thanh_cong` false nghĩa là ra đồ hỏng.
signal cook_finished(cooker: Node, dish: String, success: bool)
## Tiến trình NẤU đổi. 0..1, đầy dần. Phát 0 nghĩa là "hết việc" — thanh ẩn.
signal progress_changed(cooker: Node, ratio: float)

## Món đã CHÍN và đang nằm chờ trên bếp, đếm tới lúc cháy. 1..0, VƠI dần.
signal burn_warning(cooker: Node, time_left: float)

## Nấu một mẻ trên bếp mất bao nhiêu giây.
@export var cook_seconds := 8.0

## Nướng một cái pizza mất bao nhiêu giây.
@export var bake_seconds := 11.0

## Thái ở thớt mất bao nhiêu giây.
@export var chop_seconds := 1.0

## Để trên bếp quá bao nhiêu LẦN thời gian nấu thì cháy.
@export var burn_factor := 2.0

## BỚT bấy nhiêu giây vào mốc cháy. 0 = số gốc của game.
@export var burn_time_cut := 0.0

## trạm -> { "kho": Workstation, "t": float, "kieu": String }
var _running: Dictionary = {}

## Xác suất (0…1) một mẻ NẤU hoặc NƯỚNG ra đồ hỏng thay vì món chín.
var fail_chance: float = 0.0

## Tốc độ chạy của mọi bộ đếm nấu (kể cả đếm tới lúc cháy). 1,0 = bình thường.
var speed_factor: float = 1.0


func _process(delta: float) -> void:
	for station in _running.keys():
		var m: Dictionary = _running[station]
		var store: Workstation = m["store"]
		var mode: String = m["mode"]

		# Kho bị xoá khỏi cây scene giữa chừng thì huỷ mẻ.
		if not is_instance_valid(store):
			_cancel(station)
			continue
		if store.contents.is_empty():
			continue

		var limit: float = _duration_for_batch(m)
		m["elapsed"] += delta * speed_factor

		if not bool(m.get("done", false)):
			progress_changed.emit(station, clampf(m["elapsed"] / limit, 0.0, 1.0))
		else:
			var burn_limit: float = _burn_mark_for_batch(m)
			var span: float = maxf(0.001, burn_limit - limit)
			burn_warning.emit(station, clampf((burn_limit - m["elapsed"]) / span, 0.0, 1.0))

		if m["elapsed"] < limit:
			continue
		if not bool(m.get("done", false)):
			m["done"] = true
			_finish(station, store, mode)
			if not ["cook", "bake"].has(mode) \
					or ItemCatalog.burnt_state(String(m["source_id"])).is_empty():
				_running.erase(station)
				progress_changed.emit(station, 0.0)
		elif m["elapsed"] >= _burn_mark_for_batch(m):
			_burn(station, store, String(m["source_id"]))


## Mốc CHÁY, tính bằng giây kể từ lúc bỏ món lên.
func _burn_mark(limit: float) -> float:
	return maxf(limit, limit * burn_factor - burn_time_cut)


## BỚT bấy nhiêu giây khi NẤU TRÊN BẾP những món trong `cook_time_cut_items`.
var cook_time_cut: float = 0.0
var cook_time_cut_items: Array = []
## BỚT bấy nhiêu giây cho mọi mẻ NƯỚNG trong lò. 0 = tắt. (Mambo)
var bake_time_cut: float = 0.0
## Sàn: nấu nhanh mấy cũng còn ít nhất bấy nhiêu giây, để thanh tiến trình và
const MIN_COOK_SECONDS := 1.0


## Thời gian nấu của ĐÚNG MẺ này (đã tính kĩ năng bớt giờ theo món).
func _duration_for_batch(m: Dictionary) -> float:
	var base := _duration_for(String(m["mode"]))
	if String(m["mode"]) == "cook" and cook_time_cut > 0.0 \
			and (cook_time_cut_items.has("*") \
				or cook_time_cut_items.has(String(m.get("source_id", "")))):
		return maxf(MIN_COOK_SECONDS, base - cook_time_cut)
	if String(m["mode"]) == "bake" and bake_time_cut > 0.0:
		return maxf(MIN_COOK_SECONDS, base - bake_time_cut)
	return base


## Mốc cháy của ĐÚNG MẺ này.
func _burn_mark_for_batch(m: Dictionary) -> float:
	var base := _duration_for(String(m["mode"]))
	return _duration_for_batch(m) + (_burn_mark(base) - base)


func _duration_for(mode: String) -> float:
	match mode:
		"bake": return bake_seconds
		"chop": return chop_seconds
		_: return cook_seconds


# --------------------------------------------------------------- lò nướng ---

## Bỏ thứ bật lò vào lò và bật lò.
func start_oven(oven: Workstation, id: String = ItemCatalog.PIZZA_BASE) -> bool:
	if oven == null or _running.has(oven) or not oven.contents.is_empty():
		return false
	oven.add_item(id)
	_running[oven] = {"store": oven, "elapsed": 0.0, "mode": "bake", "source_id": id}
	progress_changed.emit(oven, 0.0)
	return true


## Thêm topping vào lò đang chạy.
func add_to_oven(oven: Workstation, id: String) -> bool:
	if not _running.has(oven) or not ItemCatalog.can_go_in_oven(id):
		return false
	if oven.contents.is_empty() or String(oven.contents[0]) != ItemCatalog.PIZZA_BASE:
		return false
	oven.add_item(id)
	return true


func is_burning(station: Workstation) -> bool:
	return _running.has(station) and not bool(_running[station].get("done", false))


# ------------------------------------------------- thao tác trên một món ---

## Đặt một món lẻ lên trạm để thái (thớt) hoặc nấu (bếp).
func put_item(station: Workstation, id: String, mode: String) -> bool:
	if station == null or _running.has(station) or not station.contents.is_empty():
		return false
	var out: String = ItemCatalog.prep_step(id) if mode == "chop" else ItemCatalog.cook_step(id)
	if out.is_empty():
		return false
	station.add_item(id)
	station.show_model(id)
	_running[station] = {"store": station, "elapsed": 0.0, "mode": mode, "source_id": id}
	progress_changed.emit(station, 0.0)
	return true


## Lấy thành phẩm khỏi trạm. Trả về id, hoặc "" nếu chưa có gì để lấy.
func take_out(station: Workstation) -> String:
	if station == null or station.contents.is_empty() or is_burning(station):
		return ""
	var id: String = String(station.contents[0])
	station.clear_all()
	station.clear_model()
	_running.erase(station)
	progress_changed.emit(station, 0.0)
	return id


func _cancel(cooker: Node) -> void:
	_running.erase(cooker)
	progress_changed.emit(cooker, 0.0)


## Chỗ DUY NHẤT bốn kiểu rẽ nhánh: tra bảng nào.
func _finish(station: Node, store: Workstation, mode: String) -> void:
	if mode != "chop" and fail_chance > 0.0 and randf() < fail_chance:
		_burn(station, store, String(_running.get(station, {}).get("source_id", "")))
		return
	var dish: String = ""
	match mode:
		"bake": dish = ItemCatalog.bake_in_oven(store.contents)
		"chop": dish = ItemCatalog.prep_step(String(store.contents[0]))
		_: dish = ItemCatalog.cook_step(String(store.contents[0]))

	var success := not dish.is_empty()
	store.clear_all()
	var out: String = dish if success else "do_hong"
	store.add_item(out)
	store.show_model(out)
	AmThanh.play_sfx("cook_done" if success else "cook_fail")
	cook_finished.emit(station, dish, success)


## Để trên bếp quá lâu.
func _burn(station: Node, store: Workstation, source_id: String) -> void:
	var burnt: String = ItemCatalog.burnt_state(source_id)
	if burnt.is_empty():
		burnt = "do_hong"
	store.clear_all()
	store.add_item(burnt)
	store.show_model(burnt)
	_running.erase(station)
	AmThanh.play_sfx("burn")
	progress_changed.emit(station, 0.0)
	cook_finished.emit(station, "", false)
