extends CanvasLayer
## ────────────────────────────────── VÌ SAO BỎ THANH CHUNG Ở ĐỈNH MÀN HÌNH
## ─────────────────────────────────────────── VÌ SAO BÁM THEO TRẠM, KHÔNG NEO
## ───────────────────────────────────────────────────────── HAI GIAI ĐOẠN

## Cỡ bar, tính theo viewport thiết kế 1920×1080 (chia 1.5 ra cỡ thật ở cửa
const WIDTH := 92.0
const HEIGHT := 12.0

## Neo bar cao hơn gốc trạm bấy nhiêu đơn vị. 1,55 là vừa trên mặt bếp mà
const ANCHOR_HEIGHT := 1.55

## Chừa bấy nhiêu pixel khi kẹp bar vào mép frame hình.
const MARGIN := 10.0

const COLOR_BG := Color(0.09, 0.11, 0.10, 0.82)
const COLOR_COOK := Color(0.95, 0.55, 0.2)
const COLOR_BURN := Color("c4433a")

## Dưới mức này thì bar cháy bắt đầu nhấp nháy.
const BLINK_THRESHOLD := 0.35

## trạm -> { "bar": ProgressBar, "day": StyleBoxFlat, "chay": bool }
var _cells: Dictionary = {}


func _ready() -> void:
	layer = 12


## Nối vào hệ bếp. level_base gọi sau khi dựng cả hai.
func listen_to_cooking(system: Node) -> void:
	system.progress_changed.connect(_on_cooking)
	system.burn_warning.connect(_on_burn_warning)


func _on_cooking(station: Node, ratio: float) -> void:
	if ratio <= 0.0:
		_drop_bar(station)
		return
	_set_bar(station, ratio, false)


func _on_burn_warning(station: Node, time_left: float) -> void:
	if time_left <= 0.0:
		_drop_bar(station)
		return
	_set_bar(station, time_left, true)


func _set_bar(station: Node, ratio: float, burn_warning_: bool) -> void:
	var entry: Dictionary = _cells.get(station, {})
	if entry.is_empty():
		entry = _make_bar()
		_cells[station] = entry
	var bar: ProgressBar = entry["bar"]
	bar.value = ratio
	if bool(entry["chay"]) != burn_warning_:
		entry["chay"] = burn_warning_
		(entry["day"] as StyleBoxFlat).bg_color = COLOR_BURN if burn_warning_ else COLOR_COOK
	if burn_warning_ and ratio < BLINK_THRESHOLD:
		bar.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.008))
	else:
		bar.modulate.a = 1.0


func _drop_bar(station: Node) -> void:
	var entry: Dictionary = _cells.get(station, {})
	if entry.is_empty():
		return
	(entry["bar"] as ProgressBar).queue_free()
	_cells.erase(station)


func _make_bar() -> Dictionary:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(WIDTH, HEIGHT)
	t.size = Vector2(WIDTH, HEIGHT)
	t.max_value = 1.0
	t.value = 0.0
	t.show_percentage = false
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	bg.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_COOK
	fill.set_corner_radius_all(5)
	t.add_theme_stylebox_override("background", bg)
	t.add_theme_stylebox_override("fill", fill)
	add_child(t)
	return {"bar": t, "day": fill, "chay": false}


## Đặt lại vị trí mọi bar theo vị trí trạm trên màn hình.
func _process(_delta: float) -> void:
	if _cells.is_empty():
		return
	var orange := get_viewport().get_camera_3d()
	if orange == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size

	for station in _cells.keys():
		if not is_instance_valid(station):
			_cells.erase(station)
			continue
		var entry: Dictionary = _cells[station]
		var bar: ProgressBar = entry["bar"]
		var point: Vector3 = (station as Node3D).global_position + Vector3(0.0, ANCHOR_HEIGHT, 0.0)
		var screen := orange.unproject_position(point)
		if orange.is_position_behind(point):
			screen = viewport_size - screen
		bar.position = Vector2(
			clampf(screen.x - WIDTH * 0.5, MARGIN, viewport_size.x - WIDTH - MARGIN),
			clampf(screen.y - HEIGHT * 0.5, MARGIN, viewport_size.y - HEIGHT - MARGIN))
