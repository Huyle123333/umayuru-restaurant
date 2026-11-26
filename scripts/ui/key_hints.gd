extends CanvasLayer

const MARGIN := 24.0
const COLOR_BG := Color(0.09, 0.08, 0.07, 0.62)
const COLOR_KEY_BG := Color(0.96, 0.93, 0.88)
const COLOR_KEY_TEXT := Color("4a3421")
const COLOR_TEXT := Color(1, 1, 1, 0.92)

## [hành động trong InputMap (hoặc "" cho phím cố định), chữ phím cố định, mô tả]
const ROWS := [
	["", "W A S D", "Di chuyển"],
	["interact", "", "Lấy / đặt / dùng trạm"],
	["assemble", "", "Ráp món ở bàn chế tạo"],
	["cycle_target", "", "Đổi trạm đang chọn"],
	["dash", "", "Chạy nhanh"],
	["skill", "", "Kĩ năng nhân vật"],
	["toggle_orders", "", "Ẩn / hiện vé đơn"],
	["", "F1", "Hướng dẫn đầy đủ"],
	["", "Esc", "Tạm dừng"],
]

var _panel: PanelContainer


func _ready() -> void:
	layer = 5
	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_right = -MARGIN
	_panel.offset_bottom = -MARGIN
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_panel)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(grid)

	for row in ROWS:
		var key_text := String(row[1])
		if not String(row[0]).is_empty():
			key_text = SettingsManager.key_name(String(row[0]))
		grid.add_child(_key_cap(key_text))
		var l := Label.new()
		l.text = Lang.t(String(row[2]))
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", COLOR_TEXT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(l)


## Ô phím: nền kem, chữ nâu — cùng tông với vé đơn hàng, nhìn ra ngay là "phím".
func _key_cap(text: String) -> Control:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_KEY_BG
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", COLOR_KEY_TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	return p
