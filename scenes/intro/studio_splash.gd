extends Control

const NEXT_SCENE := "res://scenes/intro/intro_video.tscn"
const LOGO := "res://assets/ui/logo/orca_dev_logo.png"
const BG_COLOR := Color.WHITE

const FADE_IN := 0.6
const HOLD := 1.6
const FADE_OUT := 0.6

var _leaving := false
var _logo: TextureRect


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_logo = TextureRect.new()
	_logo.texture = load(LOGO)
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.anchor_left = 0.2
	_logo.anchor_right = 0.8
	_logo.anchor_top = 0.2
	_logo.anchor_bottom = 0.8
	_logo.modulate.a = 0.0
	add_child(_logo)

	var tween := create_tween()
	tween.tween_property(_logo, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	tween.tween_callback(_leave)


func _input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(_logo, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(NEXT_SCENE))
