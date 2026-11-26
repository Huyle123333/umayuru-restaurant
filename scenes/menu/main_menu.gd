extends Control

const HOVER_SCALE := 1.06
## Nút CODE No.7 để mờ khi không rê chuột vào, cho khỏi hút mắt.
const CODE_IDLE_ALPHA := 0.55
## Số phiên bản đọc từ Project Settings (application/config/version) để chỉ phải sửa một chỗ.
const VERSION_FALLBACK := "1.0"

@export_file("*.tscn") var level_select_scene: String = "res://scenes/menu/level_select.tscn"
@export_file("*.tscn") var character_select_scene: String = "res://scenes/menu/character_select.tscn"

@onready var _btn_new: Button = %BtnNew
@onready var _btn_levels: Button = %BtnLevels
@onready var _btn_options: Button = %BtnOptions
@onready var _btn_quit: Button = %BtnQuit

@onready var _btn_code: TextureButton = %BtnCode

@onready var _credits: Control = %CreditsPanel
@onready var _cheat: Control = %CheatPanel
@onready var _options: Control = %OptionsPanel
@onready var _settings: Control = %SettingsPanel

const ShopPanel := preload("res://scenes/menu/shop_panel.gd")
var _btn_shop: Button
var _shop: Control


func _ready() -> void:
	AmThanh.play_random_music("menu", true)

	_btn_new.pressed.connect(_on_new_pressed)
	_btn_levels.pressed.connect(_on_levels_pressed)
	_btn_options.pressed.connect(_on_options_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

	_options.guide_chosen.connect(_on_guide_pressed)
	_options.settings_chosen.connect(_on_settings_pressed)
	_options.credits_chosen.connect(_on_credits_pressed)

	_btn_shop = Button.new()
	_btn_shop.text = Lang.t("Cửa hàng")
	_btn_levels.get_parent().add_child(_btn_shop)
	_btn_levels.get_parent().move_child(_btn_shop, _btn_levels.get_index() + 1)
	_btn_shop.pressed.connect(_on_shop_pressed)
	_shop = ShopPanel.new()
	add_child(_shop)

	for btn in [_btn_new, _btn_levels, _btn_shop, _btn_options, _btn_quit]:
		_setup_hover(btn)

	# Nút CODE No.7 ở góc dưới phải — công cụ cho người phát triển.
	_btn_code.pressed.connect(_on_code_pressed)
	_btn_code.mouse_entered.connect(_fade_code.bind(1.0))
	_btn_code.mouse_exited.connect(_fade_code.bind(CODE_IDLE_ALPHA))
	_btn_code.modulate.a = CODE_IDLE_ALPHA

	# Bản xuất ra web không thoát được, ẩn nút đi cho gọn.
	if OS.has_feature("web"):
		_btn_quit.hide()

	_add_version_label()

	# Focus sẵn nút đầu tiên để chơi được bằng bàn phím / tay cầm.
	_btn_new.grab_focus()


## Dòng phiên bản nhỏ ở góc trên phải, để người chơi báo lỗi biết mình đang chơi bản nào.
func _add_version_label() -> void:
	var ver := String(ProjectSettings.get_setting("application/config/version", VERSION_FALLBACK))
	if ver.is_empty():
		ver = VERSION_FALLBACK
	var lbl := Label.new()
	lbl.text = "v" + ver
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.offset_left = -200
	lbl.offset_right = -24
	lbl.offset_top = 16
	add_child(lbl)


# ------------------------------------------------------- hiệu ứng rê chuột ---

func _setup_hover(btn: Button) -> void:
	btn.resized.connect(_center_pivot.bind(btn))
	_center_pivot(btn)

	btn.mouse_entered.connect(_scale_to.bind(btn, HOVER_SCALE))
	btn.mouse_exited.connect(_scale_to.bind(btn, 1.0))
	btn.focus_entered.connect(_scale_to.bind(btn, HOVER_SCALE))
	btn.focus_exited.connect(_scale_to.bind(btn, 1.0))


func _center_pivot(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0


func _scale_to(btn: Button, target: float) -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(target, target), 0.12)


# ------------------------------------------------------------ hành động nút ---

## Chơi mới: vào thẳng prologue, KHÔNG qua màn chọn nhân vật — xem
func _on_new_pressed() -> void:
	get_tree().change_scene_to_file(GameData.start_story_level("prologue"))


func _on_shop_pressed() -> void:
	_shop.open(_btn_shop)


func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file(level_select_scene)


## Mở menu hướng dẫn (cũng chính là thứ phím F1 mở trong màn chơi).
func _on_guide_pressed() -> void:
	_options.close()
	HuongDan.open()


## Mở bảng Tuỳ chọn.
func _on_options_pressed() -> void:
	_options.open(_btn_options)


## Ba hàm dưới đây được gọi TỪ BẢNG TUỲ CHỌN, không phải từ nút trên menu nữa.
func _on_settings_pressed() -> void:
	_options.close()
	_settings.open(_btn_options)


func _fade_code(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_btn_code, "modulate:a", alpha, 0.15)


func _on_code_pressed() -> void:
	_cheat.open(_btn_code)


func _on_credits_pressed() -> void:
	_options.close()
	_credits.open(_btn_options)


func _on_quit_pressed() -> void:
	get_tree().quit()
