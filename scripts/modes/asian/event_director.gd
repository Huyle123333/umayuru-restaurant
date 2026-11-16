extends CanvasLayer
## ASIAN MODE — bộ điều phối SỰ KIỆN (bước 3, user chốt 27/10/2026).
##
## Việc của node này: lên lịch, báo trước 5 giây, bật hiệu ứng, đếm giờ, tắt.
## Sự kiện bốc NGẪU NHIÊN và ĐƯỢC LẶP LẠI (user chốt). Nhịp theo bảng 3.5 của
## tài liệu:
##   phút 0–2   không có sự kiện
##   phút 2–5   mỗi 60–80 giây một sự kiện
##   phút 5–10  mỗi 45–60 giây; từ phút 8 có 50% bật hai sự kiện cùng lúc
##
## Bảy sự kiện ở bước này đều chỉ ĐỔI THÔNG SỐ của hệ có sẵn (giá nguyên liệu,
## nhịp khách, tốc độ chạy, trượt...). Gom vào một file với hai hàm _apply /
## _revert thay vì mỗi sự kiện một file: mỗi cái chỉ vài dòng, và hai sự kiện
## cùng đụng nhịp khách (Giờ cao điểm, Trời mưa) cần tính lại CHUNG — tách file
## thì file này tắt sẽ xoá mất tác dụng của file kia đang bật.
## Sự kiện có NPC (thanh tra, trộm chó, khách VIP) sẽ làm file riêng ở bước 4.

const WARN_SECONDS := 5.0

## id -> tên hiện trên màn hình, mô tả ngắn, thời lượng (giây).
const EVENTS := {
	"fuel": {"name": "Xăng tăng", "desc": "5 nguyên liệu đắt thêm 20%", "duration": 120.0},
	"burnout": {"name": "Burn out", "desc": "Không chạy nhanh được", "duration": 60.0},
	"rush": {"name": "Giờ cao điểm", "desc": "Khách vào liên tục", "duration": 30.0},
	"slippery": {"name": "Sàn trơn", "desc": "Nhân vật trượt theo quán tính", "duration": 40.0},
	"rain": {"name": "Trời mưa", "desc": "Khách đến ít hẳn", "duration": 30.0},
	"stockout": {"name": "Hết hàng", "desc": "%s tạm hết", "duration": 45.0},
	"review": {"name": "Review 1 sao", "desc": "Giá mọi món −15%", "duration": 60.0},
	# Sự kiện có NPC / hiệu ứng hình: mỗi cái một file trong events/, tự kết
	# thúc bằng finish(). "duration" chỉ là trần an toàn.
	"inspector": {"name": "Thanh tra", "desc": "Không để đồ ăn dưới sàn bếp!", "duration": 120.0,
		"script": "res://scripts/modes/asian/events/inspector.gd"},
	"dog_thief": {"name": "Trộm chó", "desc": "Bấm vào Doro trước khi nó ra tới cửa!", "duration": 120.0,
		"script": "res://scripts/modes/asian/events/dog_thief.gd"},
	"vip": {"name": "Khách VIP", "desc": "Món khó, trả gấp 3 — bỏ về mất 2 mạng", "duration": 300.0,
		"script": "res://scripts/modes/asian/events/vip_guest.gd"},
	"blackout": {"name": "Cúp điện", "desc": "Chỉ thấy quanh nhân vật", "duration": 20.0,
		"script": "res://scripts/modes/asian/events/blackout.gd"},
	# Không nằm trong vòng bốc ngẫu nhiên: có lịch riêng (mỗi 70–120 giây) và
	# KHÔNG báo trước 5 giây — 15 giây đếm ngược của chính nó đã là lời báo.
	"doro_hunger": {"name": "Doro đói", "desc": "Cho Doro ăn một món hoàn chỉnh!", "duration": 16.0,
		"script": "res://scripts/modes/asian/events/doro_hunger.gd"},
}
## Sự kiện bốc ngẫu nhiên. "review" không nằm đây: nó tự bật khi mất khách.
const RANDOM_POOL := ["fuel", "burnout", "rush", "slippery", "rain", "stockout",
	"dog_thief", "vip", "blackout"]  # bỏ "inspector" 12/11/2026: không còn đồ dưới sàn

## Sự kiện có file riêng đang chạy: id -> thực thể (RefCounted có start/stop/tick).
var _scripted: Dictionary = {}

const FUEL_COUNT := 5
const FUEL_FACTOR := 1.2
const REVIEW_FACTOR := 0.85
const RUSH_INTERVAL := Vector2(1.5, 3.0)
const RAIN_FACTOR := 4.0

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const COLOR_WARN := Color("ffd76a")
const COLOR_TEXT := Color(1, 1, 1)

var _level: Node
var _customers: Node
var _clock: Node
var _hands: Node
var _player: Node
var _rules: Node

## Sự kiện đang chạy: id -> giây còn lại.
var _active: Dictionary = {}
## Sự kiện đang báo trước: [{id, left}].
var _pending: Array = []
var _next_in := 0.0
var _hunger_in := 0.0
var _started := false
var _saved_sprint := 2.0
var _stock_item := ""
var _stock_labels: Array = []
var _lbl_banner: Label
var _lbl_list: Label


func setup(level: Node, customers: Node, clock: Node, hands: Node) -> void:
	_level = level
	_customers = customers
	_clock = clock
	_hands = hands
	_player = level.get("player")
	_rules = level.get_node_or_null("LevelRules")
	if _player != null:
		_saved_sprint = float(_player.sprint_factor)
	layer = 7
	_build_ui()
	_next_in = 120.0
	_hunger_in = randf_range(70.0, 120.0)


func _elapsed() -> float:
	return float(_clock.duration) - float(_clock.time_left)


func _process(delta: float) -> void:
	# Bắt đầu đếm khi ca làm việc bắt đầu (hết màn đếm ngược mở đầu). Sau đó
	# chạy theo giờ THẬT, không theo đồng hồ màn: kĩ năng dừng thời gian của
	# Oguri không được dừng sự kiện (bản Asian của kĩ năng đã ghi rõ).
	if not _started:
		if not bool(_clock.counting_down):
			return
		_started = true
	if get_tree().paused:
		return

	# Báo trước -> bật.
	for p in _pending.duplicate():
		p["left"] -= delta
		if p["left"] <= 0.0:
			_pending.erase(p)
			_start(String(p["id"]))

	for id in _scripted.keys():
		if _scripted.has(id):
			_scripted[id].tick(delta)

	# Đang chạy -> hết giờ thì tắt.
	for id in _active.keys():
		_active[id] -= delta
		if _active[id] <= 0.0:
			_stop(String(id))

	# Cơn đói của Doro: lịch riêng, từ đầu ca.
	_hunger_in -= delta
	if _hunger_in <= 0.0:
		_hunger_in = randf_range(70.0, 120.0)
		_start("doro_hunger")

	# Lên lịch.
	_next_in -= delta
	if _next_in <= 0.0:
		var t := _elapsed()
		_queue_random()
		if t >= 480.0 and randf() < 0.5:
			_queue_random()
		_next_in = randf_range(60.0, 80.0) if t < 300.0 else randf_range(45.0, 60.0)
	_draw_list()


func _queue_random() -> void:
	_queue(String(RANDOM_POOL.pick_random()))


## Bật một sự kiện có báo trước 5 giây. Dùng cho cả sự kiện tự bật (review).
func trigger(id: String) -> void:
	_queue(id)


func _queue(id: String) -> void:
	_pending.append({"id": id, "left": WARN_SECONDS})
	_show_banner(Lang.t("SẮP CÓ SỰ KIỆN: %s") % Lang.t(String(EVENTS[id]["name"])), COLOR_WARN)
	AmThanh.play_sfx("time_warning")


func _start(id: String) -> void:
	var info: Dictionary = EVENTS[id]
	# Đang chạy rồi mà bốc trúng lần nữa (được lặp lại): chỉ nạp lại thời lượng.
	var again := _active.has(id)
	# Sự kiện có NPC đang chạy thì không chồng thêm bản thứ hai (hai thanh tra,
	# hai con Doro... không có nghĩa) — bỏ qua lần bốc trùng.
	if again and info.has("script"):
		return
	_active[id] = float(info["duration"])
	if not again:
		_apply(id)
	var desc := Lang.t(String(info["desc"]))
	if id == "stockout":
		desc = desc % ItemCatalog.display_name(_stock_item)
	_show_banner("%s — %s" % [Lang.t(String(info["name"])), desc], COLOR_TEXT)


func _stop(id: String) -> void:
	_active.erase(id)
	_revert(id)


## Tắt sạch mọi sự kiện (thua / hết màn).
func stop_all() -> void:
	_pending.clear()
	for id in _active.keys():
		_stop(String(id))
	set_process(false)


# --------------------------------------------------------- tác dụng ---

## Sự kiện có NPC tự báo đã xong (thanh tra đi về, Doro được giữ lại...).
func finish(id: String) -> void:
	if _active.has(id):
		_stop(id)


## Thua vì sự kiện (thanh tra bắt, Doro bị trộm).
func lose(note: String) -> void:
	get_parent().lose(note)


func _apply(id: String) -> void:
	if EVENTS[id].has("script"):
		var inst: RefCounted = (load(String(EVENTS[id]["script"])) as GDScript).new()
		_scripted[id] = inst
		inst.start(self)
		return
	match id:
		"fuel":
			var pool: Array = []
			for item in ItemCatalog.items():
				if ItemCatalog.cost(String(item)) > 0 and not ItemCatalog.is_locked(String(item)):
					pool.append(String(item))
			pool.shuffle()
			var factors := {}
			for item in pool.slice(0, FUEL_COUNT):
				factors[item] = FUEL_FACTOR
			_customers.ingredient_cost_factors = factors
		"burnout":
			if _player != null:
				_player.sprint_factor = 1.0
		"slippery":
			if _player != null:
				_player.slippery = true
		"rush", "rain":
			_refresh_spawn()
		"stockout":
			_stock_item = _pick_stock_item()
			if _hands != null:
				_hands.blocked_items = [_stock_item]
			_mark_shelves(_stock_item)
		"review":
			_customers.event_price_factor = REVIEW_FACTOR


func _revert(id: String) -> void:
	if _scripted.has(id):
		var inst: RefCounted = _scripted[id]
		_scripted.erase(id)
		inst.stop(self)
		return
	match id:
		"fuel":
			_customers.ingredient_cost_factors = {}
		"burnout":
			if _player != null:
				_player.sprint_factor = _saved_sprint
		"slippery":
			if _player != null:
				_player.slippery = false
		"rush", "rain":
			_refresh_spawn()
		"stockout":
			if _hands != null:
				_hands.blocked_items = []
			for l in _stock_labels:
				if is_instance_valid(l):
					l.queue_free()
			_stock_labels.clear()
		"review":
			_customers.event_price_factor = 1.0


## Nhịp khách = nhịp của giai đoạn hiện tại, rồi Giờ cao điểm / Trời mưa đè lên.
## Luôn tính lại TỪ ĐẦU (nhờ level_rules áp lại giai đoạn), nên tắt sự kiện này
## không xoá tác dụng của sự kiện kia đang còn chạy. Hai cái cùng bật thì Giờ
## cao điểm thắng — đông khách là thứ người chơi phải xử lý gấp hơn.
func _refresh_spawn() -> void:
	if _rules != null:
		_rules._go_to_stage(int(_rules._index))
	if _active.has("rush"):
		_customers.spawn_interval = RUSH_INTERVAL.x
		_customers.spawn_interval_min = RUSH_INTERVAL.x
		_customers.spawn_interval_max = RUSH_INTERVAL.y
		_customers._spawn_timer = minf(float(_customers._spawn_timer), RUSH_INTERVAL.x)
	elif _active.has("rain"):
		_customers.spawn_interval *= RAIN_FACTOR
		_customers.spawn_interval_min *= RAIN_FACTOR
		_customers.spawn_interval_max *= RAIN_FACTOR


## Nguyên liệu có thật trong bếp (kệ + tủ lạnh) để khoá — khoá thứ không có
## trên map thì sự kiện vô nghĩa.
func _pick_stock_item() -> String:
	var pool: Array = []
	for st in _level._find_stations(_level):
		var kind := String(st.kind)
		if kind == "ingredient_shelf" and not String(st.item_id).is_empty():
			pool.append(String(st.item_id))
		elif kind == "fridge":
			for o in st.options:
				pool.append(String(o))
	return String(pool.pick_random()) if not pool.is_empty() else ""


## Biển "HẾT HÀNG" nổi trên kệ của nguyên liệu bị khoá.
func _mark_shelves(item: String) -> void:
	for st in _level._find_stations(_level):
		var is_shelf := String(st.kind) == "ingredient_shelf" and String(st.item_id) == item
		var in_fridge := String(st.kind) == "fridge" and (st.options as PackedStringArray).has(item)
		if not (is_shelf or in_fridge):
			continue
		var marker := Label3D.new()
		marker.text = Lang.t("HẾT HÀNG")
		marker.font_size = 64
		marker.pixel_size = 0.005
		marker.modulate = Color(1.0, 0.35, 0.3)
		marker.outline_size = 12
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.no_depth_test = true
		st.add_child(marker)
		marker.position = Vector3(0, 1.6, 0)
		_stock_labels.append(marker)


# ------------------------------------------------------------ giao diện ---

func _build_ui() -> void:
	_lbl_banner = Label.new()
	_lbl_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lbl_banner.offset_left = -700.0
	_lbl_banner.offset_right = 700.0
	_lbl_banner.offset_top = 150.0
	_lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_banner.add_theme_font_size_override("font_size", 40)
	_lbl_banner.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0))
	_lbl_banner.add_theme_constant_override("outline_size", 12)
	_lbl_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_banner.modulate.a = 0.0
	add_child(_lbl_banner)

	# Danh sách sự kiện đang chạy, ngay dưới khung MẠNG (asian_mode.gd).
	_lbl_list = Label.new()
	_lbl_list.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lbl_list.offset_right = -28.0
	_lbl_list.offset_left = -328.0
	_lbl_list.offset_top = 262.0
	_lbl_list.add_theme_font_size_override("font_size", 20)
	_lbl_list.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_lbl_list.add_theme_constant_override("outline_size", 8)
	_lbl_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lbl_list)


func _show_banner(text: String, color: Color) -> void:
	_lbl_banner.text = text
	_lbl_banner.add_theme_color_override("font_color", color)
	var tw := create_tween()
	tw.tween_property(_lbl_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.5)
	tw.tween_property(_lbl_banner, "modulate:a", 0.0, 0.5)


func _draw_list() -> void:
	var lines: PackedStringArray = []
	for p in _pending:
		lines.append("⚠ %s  %d" % [Lang.t(String(EVENTS[p["id"]]["name"])), ceili(float(p["left"]))])
	for id in _active:
		var s := ceili(float(_active[id]))
		@warning_ignore("integer_division")
		lines.append("%s  %d:%02d" % [Lang.t(String(EVENTS[id]["name"])), s / 60, s % 60])
	_lbl_list.text = "\n".join(lines)
