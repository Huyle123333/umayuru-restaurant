extends Node
## CHẾ ĐỘ THỬ NGHIỆM phương án B (thực đơn theo họ món).
##
## Vào từ màn Chọn màn → nút "Thử nghiệm B" → chọn nhân vật, như mọi chế độ
## khác (khai trong GameData.LEVELS, id "plan_b"). Mở thẳng scene này rồi F6
## trong editor cũng được.
##
## Không phải một map mới: scene bật công tắc ItemCatalog.plan_b rồi dựng lại
## đúng cái map đang dùng. Mọi hệ thống (bàn chế tạo, bếp, lò, khách gọi món,
## vé đơn, F1) đọc công thức qua ItemCatalog, nên bật một công tắc là cả nhà
## hàng chạy theo bộ công thức B.
##
## Thứ tự quan trọng: bật công tắc TRƯỚC khi thêm map vào cây. Map dựng hệ
## khách trong _ready của nó — dựng trước khi bật thì khách gọi món bộ cũ.
##
## Màn thử KHÔNG đếm ngược (level_base bỏ qua màn mở đầu cho "plan_b"), KHÔNG
## cho khách tự vào và KHÔNG chạy đồng hồ: người thử gọi từng khách bằng tay
## để thử từng món, không bị hết giờ giữa chừng.
##
## PHÍM TẮT (phím F vì không đụng phím điều khiển nào):
##   F5  mở BẢNG CHỌN MÓN dạng lưới — WASD / phím mũi tên / chuột để chọn,
##       E hoặc click để xác nhận, Esc để đóng. Chọn xong: khách sau gọi đúng
##       món đó, và một khách được gọi vào ngay.
##   F6  về món ngẫu nhiên
##   F7  đổi loại khách (Ngẫu nhiên → từng model)
##   F8  gọi một khách vào NGAY
##
## (Bỏ F9 "bật/tắt khách tự đến": màn thử không cho khách tự vào nữa, và F9
## trùng phím tạm dừng khi chạy từ editor.)

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const CustomerScript := preload("res://scripts/restaurant/customer.gd")
const MAP := preload("res://restaurant_map_planb.tscn")

## Lưới chọn món: 4 cột — 16 món vừa 4 hàng, nhìn hết trong một màn hình.
const GRID_COLUMNS := 4
const CELL_SIZE := Vector2(190, 150)
const COLOR_PANEL := Color("4a2f1f")
const COLOR_BORDER := Color("c8935a")
const COLOR_TEXT := Color("fbecd2")

var _map: Node
var _dishes: Array[String] = []
var _dish := ""            # "" = ngẫu nhiên
var _model_i := 0          # 0 = ngẫu nhiên, i>0 = MODELS[i-1]
var _label: Label
var _grid_layer: CanvasLayer
var _grid: GridContainer


func _ready() -> void:
	ItemCatalog.plan_b = true
	var gd := get_node_or_null("/root/GameData")
	if gd != null and String(gd.current_level).is_empty():
		gd.current_level = "plan_b"
	_map = MAP.instantiate()
	add_child(_map)
	_dishes = ItemCatalog.sellable_dishes()
	_stop_auto_flow()
	_build_hud()
	_build_grid()
	_refresh()


## Tắt công tắc khi rời scene (về menu) để các màn thường không dính bộ công
## thức B — biến static sống suốt phiên chạy game.
## (16/11/2026) Không tắt nữa: bộ B giờ là bộ công thức của game gốc.
func _exit_tree() -> void:
	pass


## Khách không tự vào, đồng hồ không chạy. Gọi ngay sau khi map dựng xong.
func _stop_auto_flow() -> void:
	var cm := _customers()
	if cm != null:
		cm.auto_spawn = false
	var clock := _map.find_child("HudClock", true, false)
	if clock != null:
		clock.counting_down = false
	AmThanh.play_random_music("level")


## Hệ khách do level_base dựng lúc chạy, nên tìm theo tên mỗi lần dùng.
func _customers() -> Node:
	return _map.find_child("CustomerManager", true, false) if _map != null else null


func _current_model() -> Dictionary:
	return {} if _model_i == 0 else CustomerScript.MODELS[_model_i - 1]


func _spawn() -> void:
	var cm := _customers()
	if cm != null and cm.spawn_customer(_current_model()) == null:
		_flash("Không nhận thêm khách (hết bàn / hết chỗ vé)")


# ---------------------------------------------------------------- phím ---

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or _grid_layer.visible:
		return
	match k.keycode:
		KEY_F5:
			_open_grid()
		KEY_F6:
			_dish = ""
		KEY_F7:
			_model_i = posmod(_model_i + 1, CustomerScript.MODELS.size() + 1)
		KEY_F8:
			_spawn()
		_:
			return
	get_viewport().set_input_as_handled()
	_refresh()


## Lúc lưới mở: bắt phím ở _input (chạy TRƯỚC đôi tay và bộ chọn mục tiêu)
## để E không nhặt đồ và WASD không làm gì ngoài di chuyển ô chọn.
func _input(event: InputEvent) -> void:
	if _grid_layer == null or not _grid_layer.visible:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if event.is_action_pressed("cancel_menu") or event.is_action_pressed("ui_cancel"):
		_close_grid()
	elif event.is_action_pressed("interact") and focus is Button:
		(focus as Button).pressed.emit()
	elif focus != null:
		# WASD đi theo đúng hàng xóm mà Godot tự tính cho lưới (phím mũi tên
		# thì Godot tự xử lý sẵn) — không phải tự đếm hàng/cột.
		var side := -1
		if event.is_action_pressed("move_up"): side = SIDE_TOP
		elif event.is_action_pressed("move_down"): side = SIDE_BOTTOM
		elif event.is_action_pressed("move_left"): side = SIDE_LEFT
		elif event.is_action_pressed("move_right"): side = SIDE_RIGHT
		if side == -1:
			return
		var next := focus.find_valid_focus_neighbor(side)
		if next != null:
			next.grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()


# ------------------------------------------------------------ lưới món ---

## Lưới chọn món: mỗi ô [ảnh món + tên]. Dạng lưới thay cho danh sách dọc
## của tủ lạnh: 16 món xếp dọc phải bấm S mười lần mới tới cuối, lưới 4×4 thì
## món nào cũng cách tối đa vài bước, và nhìn được hết một lúc.
func _build_grid() -> void:
	_grid_layer = CanvasLayer.new()
	_grid_layer.layer = 40
	add_child(_grid_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grid_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grid_layer.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var title := Label.new()
	title.text = "CHỌN MÓN KHÁCH GỌI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	col.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	col.add_child(_grid)
	for dish in _dishes:
		_grid.add_child(_dish_cell(dish))

	var hint := Label.new()
	hint.text = "WASD / mũi tên: chọn    E / click: xác nhận    Esc: đóng"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", COLOR_BORDER)
	col.add_child(hint)

	_grid_layer.hide()


func _dish_cell(dish: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CELL_SIZE
	b.text = ItemCatalog.display_name(dish)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.expand_icon = true
	b.add_theme_font_size_override("font_size", 18)
	var path_ := ItemCatalog.icon_path(dish)
	if ResourceLoader.exists(path_):
		b.icon = load(path_)
	b.pressed.connect(_on_dish_chosen.bind(dish))
	return b


func _open_grid() -> void:
	_grid_layer.show()
	_lock(true)
	# Đặt sẵn ô chọn vào món đang ép (nếu có), không thì ô đầu tiên.
	var at := maxi(_dishes.find(_dish), 0)
	if _grid.get_child_count() > at:
		(_grid.get_child(at) as Control).grab_focus()


func _close_grid() -> void:
	_grid_layer.hide()
	_lock(false)


func _on_dish_chosen(dish: String) -> void:
	_close_grid()
	_dish = dish
	_refresh()
	_spawn()


## Khoá nhân vật lúc lưới mở — dùng đúng hàm level_base dùng cho tủ lạnh.
func _lock(is_open: bool) -> void:
	if _map != null and _map.has_method("_lock_player"):
		_map._lock_player(is_open)


# ---------------------------------------------------------- bảng phím ---

## Ghi lựa chọn vào hệ khách và vẽ lại bảng. force_dish là ô ép món sẵn có
## của customer_manager (vốn dùng cho màn hướng dẫn): khách nào NGỒI XUỐNG sau
## khi đổi sẽ gọi đúng món đang chọn.
func _refresh() -> void:
	var cm := _customers()
	if cm != null:
		cm.force_dish = _dish
	var model_name := "Ngẫu nhiên"
	if _model_i > 0:
		model_name = String(CustomerScript.MODELS[_model_i - 1]["path"]).get_file().get_basename()
	_label.text = "THỬ NGHIỆM PHƯƠNG ÁN B\n" \
		+ "F5  Chọn món: %s\n" % ("Ngẫu nhiên" if _dish.is_empty() else ItemCatalog.display_name(_dish)) \
		+ "F6  Về ngẫu nhiên\n" \
		+ "F7  Khách: %s\n" % model_name \
		+ "F8  Gọi khách vào"


func _flash(text: String) -> void:
	_label.text += "\n" + text


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 230)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(_label)
