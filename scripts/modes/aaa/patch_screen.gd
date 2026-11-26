extends CanvasLayer

signal finished

const RISE_SECONDS := 3.0
const STUCK_SECONDS := 3.0

var _bar: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(_bar, "value", 99.0, RISE_SECONDS)
	tween.tween_interval(STUCK_SECONDS)
	tween.tween_property(_bar, "value", 100.0, 0.15)
	tween.tween_callback(func() -> void: _label.text = Lang.t("Cài đặt hoàn tất. Chúc bạn có trải nghiệm điện ảnh!"))
	tween.tween_interval(1.0)
	tween.tween_callback(_done)


func _done() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	center.add_child(col)

	var studio := Label.new()
	studio.text = "0rca dev"
	studio.add_theme_font_size_override("font_size", 40)
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(studio)

	_label = Label.new()
	_label.text = Lang.t("Đang tải bản vá ngày đầu (87 GB)…")
	_label.add_theme_font_size_override("font_size", 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_label)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(720, 34)
	_bar.max_value = 100.0
	col.add_child(_bar)
