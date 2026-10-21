extends CanvasLayer
## AAA MODE — DÒNG NHIỆM VỤ KHÔNG BAO GIỜ TẮT, giữa mép trên màn hình.
##
## Ba dòng: nhiệm vụ, bước hiện tại kèm khoảng cách, và một "mẹo" luôn nói
## điều hiển nhiên — chính sự hiển nhiên đó là câu đùa.

const THEME := "res://ui/theme/menu_theme.tres"

var _mission: Label
var _step: Label
var _tip: Label


func _ready() -> void:
	layer = 7
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.position.y = 14
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME):
		top.theme = load(THEME)
	add_child(top)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	_mission = _line(26, Color(0.55, 0.2, 0.05))
	_step = _line(24, Color(0.29, 0.153, 0.071))
	_tip = _line(19, Color(0.45, 0.4, 0.35))
	for l in [_mission, _step, _tip]:
		col.add_child(l)


func show_plan(mission: String, plan: Dictionary, distance: float) -> void:
	_mission.text = "▶ " + mission
	var step_text := String(plan.get("text", ""))
	if int(plan.get("total", 0)) > 0:
		step_text = Lang.t("Bước %d/%d: %s") % [int(plan["step"]), int(plan["total"]), step_text]
	if distance >= 0.0:
		step_text += Lang.t(" (cách %.1f m)") % distance
	_step.text = "▶ " + step_text
	_tip.text = "▶ " + String(plan.get("tip", ""))


func _line(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
