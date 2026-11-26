extends Control

const CARD_SIZE := Vector2(200.0, 267.0)

const HOVER_RISE := 30.0
const SELECT_RISE := 48.0

## Thứ tự lớp vẽ. Bảng thông tin PHẢI nằm trên mọi lá bài.
const Z_HOVER := 100
const Z_SELECT := 200

const DIM := Color(0.58, 0.56, 0.58, 1.0)

@export_file("*.tscn") var gameplay_scene: String = "res://restaurant_map_planb.tscn"
@export_file("*.tscn") var back_scene: String = "res://scenes/menu/level_select.tscn"

@onready var _hand: Control = %Hand
@onready var _catcher: Control = %ClickCatcher
@onready var _panel: Control = %InfoPanel

@onready var _lbl_name: Label = %LblName
@onready var _lbl_tagline: Label = %LblTagline
@onready var _lbl_intro: Label = %LblIntro
@onready var _lbl_secrets: Label = %LblSecrets
@onready var _lbl_hint: Label = %LblHint
## Hai bảng SỐ ĐO / HỒ SƠ không có sẵn hàng nào trong scene — mỗi hàng do
@onready var _grid_measure: GridContainer = %GridMeasure
@onready var _grid_profile: GridContainer = %GridProfile
## Ba ô kỹ năng bên phải. Ô 0 là chủ động, ô 1–2 là bị động.
@onready var _skill_names: Array[Label] = [%LblSkill1, %LblSkill2, %LblSkill3]
@onready var _skill_descs: Array[Label] = [
	%LblSkillDesc1, %LblSkillDesc2, %LblSkillDesc3,
]
@onready var _skill_icons: Array[TextureRect] = [%Img1, %Img2, %Img3]
@onready var _size_buttons: Array[Button] = [%BtnSize1, %BtnSize2, %BtnSize3]

@onready var _btn_prev: TextureButton = %BtnPrev
@onready var _btn_next: TextureButton = %BtnNext
@onready var _btn_play: Button = %BtnPlay
@onready var _btn_back: Button = %BtnBack
@onready var _sfx: AudioStreamPlayer = %Sfx

var _cards: Dictionary = {}
## Vị trí và góc nghiêng gốc của từng lá khi nằm yên trong tay bài.
var _base_pos: Dictionary = {}
var _base_rot: Dictionary = {}
var _selected := ""


func _ready() -> void:
	AmThanh.play_random_music("menu", true)

	var index := 0
	for key in GameData.CHARACTER_ORDER:
		var id := str(key)
		var card := _hand.get_child(index) as Control
		_cards[id] = card
		_fill_card(card, id)

		var btn := card.get_node("Btn") as TextureButton
		btn.pressed.connect(_on_card_pressed.bind(id))
		btn.mouse_entered.connect(_on_card_hover.bind(id, true))
		btn.mouse_exited.connect(_on_card_hover.bind(id, false))
		index += 1

	_catcher.gui_input.connect(_on_catcher_input)

	for i in _size_buttons.size():
		_size_buttons[i].pressed.connect(_on_size_pressed.bind(i))

	_btn_prev.pressed.connect(_step.bind(-1))
	_btn_next.pressed.connect(_step.bind(1))
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

	_cover_dlc_cards()
	_add_dlc_ads()

	# Kích thước của Hand chỉ biết được sau khi container xếp xong.
	_hand.resized.connect(_layout_hand)
	_layout_hand()

	_panel.visible = false
	_btn_play.disabled = true


## AAA Mode: chỉ Kitasan Black chơi được, mọi thẻ khác "thuộc gói Deluxe".
func _is_dlc_card(id: String) -> bool:
	return GameData.is_aaa_mode() and id != GameData.STORY_CHARACTER \
		and not GameData.is_character_locked(id)


## AAA Mode: dải 5 thẻ quảng cáo DLC nằm ngang ở đáy màn hình, giữa hai nút.
func _add_dlc_ads() -> void:
	if not GameData.is_aaa_mode():
		return
	var card_script := load("res://scripts/modes/aaa/dlc_card.gd") as GDScript
	var catalog := load("res://scripts/modes/aaa/dlc_catalog.gd") as GDScript
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(row)
	for id in catalog.ORDER:
		var card: Control = card_script.new()
		card.desc_side = "above"
		card.compact = true
		card.setup(String(id), 205.0)
		row.add_child(card)
	row.reset_size()
	row.position = Vector2((1920 - row.size.x) / 2.0, 1080 - row.size.y - 18)


## Phủ lớp đen mờ lên thẻ "Deluxe". Mờ chứ không đen kịt: thấy được nhân vật
func _cover_dlc_cards() -> void:
	for id in _cards:
		if not _is_dlc_card(id):
			continue
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.6)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(_cards[id] as Control).add_child(shade)


## Vẽ một lá bài trong tay quạt.
func _fill_card(card: Control, id: String) -> void:
	var btn := card.get_node("Btn") as TextureButton
	btn.texture_normal = load(GameData.card_image(id))
	btn.disabled = false


# --------------------------------------------------------------- tay bài ---

## Xếp các lá thành một hàng ngang, chia đều bề ngang khung.
func _layout_hand() -> void:
	var order: Array = GameData.CHARACTER_ORDER
	var card_count: int = order.size()
	var step_x: float = 0.0
	if card_count > 1:
		step_x = (_hand.size.x - CARD_SIZE.x) / float(card_count - 1)
	var bottom := _hand.size.y - CARD_SIZE.y

	for i in card_count:
		var id := str(order[i])
		if not _cards.has(id):
			continue
		var card: Control = _cards[id]

		card.size = CARD_SIZE
		card.pivot_offset = CARD_SIZE * 0.5

		var pos := Vector2(step_x * i, bottom)
		_base_pos[id] = pos
		_base_rot[id] = 0.0

		card.position = pos
		card.rotation_degrees = 0.0
		card.z_index = i


# ------------------------------------------------------------- tương tác ---

func _on_card_hover(id: String, entered: bool) -> void:
	if id == _selected:
		return
	_animate_card(id, HOVER_RISE if entered else 0.0, float(_base_rot[id]),
		Z_HOVER if entered else -1)


func _on_card_pressed(id: String) -> void:
	if id == _selected:
		return
	if _is_dlc_card(id):
		var offer: CanvasLayer = (load("res://scripts/modes/aaa/dlc_offer_panel.gd") as GDScript).new()
		add_child(offer)
		offer.show_offer("deluxe")
		return
	var previous := _selected
	_selected = id

	var locked := GameData.is_character_locked(id)
	if locked:
		GameData.selected_character = ""
	else:
		GameData.set_selected_character(id)
		_play_voice(id)

	if not previous.is_empty():
		_animate_card(previous, 0.0, float(_base_rot[previous]), -1)
	_animate_card(id, SELECT_RISE, 0.0, Z_SELECT)
	_dim_others()
	_fill_panel(id)
	_open_panel()
	_btn_play.disabled = locked


func _on_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_deselect()


func _step(delta: int) -> void:
	var order: Array = GameData.CHARACTER_ORDER
	var from := order.find(_selected)
	if from == -1:
		from = -1 if delta > 0 else 0
	_on_card_pressed(str(order[wrapi(from + delta, 0, order.size())]))


func _deselect() -> void:
	if _selected.is_empty():
		return
	var previous := _selected
	_selected = ""
	GameData.selected_character = ""
	_animate_card(previous, 0.0, float(_base_rot[previous]), -1)
	_dim_others()
	_btn_play.disabled = true
	_close_panel()


func _dim_others() -> void:
	for key in _cards:
		var id := str(key)
		var chosen: bool = (id == _selected)
		var target := Color.WHITE if chosen or _selected.is_empty() else DIM
		var tw := create_tween()
		tw.tween_property(_cards[id], "modulate", target, 0.14)
		(_cards[id].get_node("Selection") as Control).visible = chosen


## rise: nhấc lên bao nhiêu pixel. angle: góc nghiêng đích.
func _animate_card(id: String, rise: float, angle: float, layer: int) -> void:
	var card: Control = _cards[id]
	card.z_index = layer if layer >= 0 else GameData.CHARACTER_ORDER.find(id)

	var home: Vector2 = _base_pos[id]
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "position", home - Vector2(0.0, rise), 0.18)
	tw.tween_property(card, "rotation_degrees", angle, 0.18)


# ----------------------------------------------------- bảng thông tin ---

func _fill_panel(id: String) -> void:
	var info: Dictionary = GameData.card_info(id)
	_lbl_name.text = str(info["label"])
	_lbl_tagline.text = str(info.get("tagline", ""))
	_lbl_intro.text = str(info.get("intro", ""))
	_build_table(_grid_measure, info.get("measure", {}))
	_build_table(_grid_profile, info.get("profile", {}))
	_fill_skills(info)

	var secrets: Array = info.get("secrets", [])
	var lines: PackedStringArray = []
	for v in secrets:
		lines.append("・%s" % Lang.t(str(v)))
	_lbl_secrets.text = "\n".join(lines)

	# Dòng gợi ý chỉ dành cho nhân vật chưa mở khóa.
	var hint := str(info.get("hint", ""))
	_lbl_hint.visible = GameData.is_character_locked(id)
	_lbl_hint.text = hint if not hint.is_empty() else Lang.t("Gợi ý: sẽ cập nhật sau")

	# Số đo 3 vòng luôn bị che lại mỗi lần đổi nhân vật.
	var sizes: Array = info.get("sizes", ["", "", ""])
	for i in _size_buttons.size():
		var btn := _size_buttons[i]
		btn.set_meta("value", str(sizes[i]) if i < sizes.size() else "")
		btn.set_pressed_no_signal(false)
		btn.text = ""


## Dựng lại một bảng NHÃN / GIÁ TRỊ từ Dictionary trong GameData.
func _build_table(grid: GridContainer, table: Dictionary) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	for key in table:
		grid.add_child(_table_cell(str(key), true))
		grid.add_child(_table_cell(str(table[key]), false))


## Bề ngang tối thiểu của ô GIÁ TRỊ. Đây là con số đã làm nổ bảng info.
const VALUE_COL_WIDTH := 300.0


## Một ô trong bảng NHÃN / GIÁ TRỊ. nhan = true là cột trái (chữ nâu, rộng cố
func _table_cell(text: String, highlight: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	if highlight:
		lbl.custom_minimum_size = Vector2(104.0, 0.0)
		lbl.add_theme_color_override("font_color", Color(0.827, 0.639, 0.408))
	else:
		lbl.custom_minimum_size = Vector2(VALUE_COL_WIDTH, 0.0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.969, 0.929, 0.871))
	return lbl


## Cấp độ được ghép thẳng vào chuỗi tên chứ không tách ra một Label riêng:
func _fill_skills(info: Dictionary) -> void:
	var skills: Array = info.get("skills", [])
	for i in _skill_names.size():
		var slot: Dictionary = skills[i] if i < skills.size() else {}
		var skill_name := str(slot.get("name", ""))
		var level := int(slot.get("level", 0))

		if skill_name.is_empty():
			_skill_names[i].text = "—"
		elif level > 0:
			_skill_names[i].text = "%s   Lv%d" % [Lang.t(skill_name), level]
		else:
			_skill_names[i].text = skill_name

		_skill_descs[i].text = str(slot.get("desc", ""))
		_set_skill_icon(i, str(slot.get("icon", "")))


## Nạp ảnh minh họa cho một ô kỹ năng.
func _set_skill_icon(index: int, icon_name: String) -> void:
	var rect := _skill_icons[index]
	if icon_name.is_empty():
		rect.texture = null
		return
	var path := "res://assets/ui/ki_nang/%s.png" % icon_name
	if not ResourceLoader.exists(path):
		push_warning("Thiếu ảnh kỹ năng: %s" % path)
		rect.texture = null
		return
	rect.texture = load(path)


func _on_size_pressed(index: int) -> void:
	var btn := _size_buttons[index]
	var value := str(btn.get_meta("value", ""))
	btn.text = (value if not value.is_empty() else "--") if btn.button_pressed else ""


## Mở bảng thông tin.
func _open_panel() -> void:
	if _panel.visible:
		return
	_panel.visible = true
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _close_panel() -> void:
	if not _panel.visible:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.14)
	await tw.finished
	if _selected.is_empty():
		_panel.visible = false


func _play_voice(id: String) -> void:
	var path := "res://assets/sfx/select/%s.mp3" % id
	if not ResourceLoader.exists(path):
		return
	_sfx.stream = load(path)
	_sfx.play()


# ----------------------------------------------------------- điều hướng ---

func _on_play_pressed() -> void:
	if _selected.is_empty() or GameData.is_character_locked(_selected):
		return
	var scene := GameData.enter_level(GameData.current_level)
	if scene.is_empty():
		scene = gameplay_scene
	get_tree().change_scene_to_file(scene)


func _on_back_pressed() -> void:
	var target := GameData.return_scene
	get_tree().change_scene_to_file(target if not target.is_empty() else back_scene)
