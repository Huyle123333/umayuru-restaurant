extends Control
## ------------------------------------------------------------- BA QUY TẮC

## Giá trị đặc biệt của khoá "speaker": lấy tên theo id nhân vật đang hiện ảnh.
const AUTO_NAME := "@"


## Bảng ảnh chân dung: id trong kịch bản -> file ảnh.
const PORTRAITS := {
	"kitamoi": "res://assets/ui/avatars/kita_avt.png",
	"hachimi": "res://assets/ui/avatars/hachimi_avt.png",
	"chiyo": "res://assets/ui/avatars/chiyono_avt.png",
	"mambo": "res://assets/ui/avatars/mambo_avt.png",
	"oui": "res://assets/ui/avatars/oui_avt.png",
	"tuandb": "res://assets/ui/avatars/tuandb_avt.png",
	"golshi": "res://assets/ui/avatars/golshi_avt.png",
	"trainer": "res://assets/ui/avatars/trainer_avt1.png",
	"trainer2": "res://assets/ui/avatars/trainer_avt2.png",
}

## Ảnh BIỂU CẢM (18/11/2026): "emotion" trong một câu thoại chọn ảnh
const EMOTION_FMT := "res://assets/ui/avatars/emotions/%s_%s.png"

## Tốc độ gõ chữ (ký tự mỗi giây).
@export var type_speed: float = 45.0
## Thời gian tối/sáng khi đổi ảnh nền (giây, cho MỘT chiều).
@export var fade_time: float = 0.35

## Nhóm nhạc nền cho đoạn kể này, theo AmThanh.NHOM_NHAC. RỖNG = không đụng
@export var music_group: String = ""
@export_file("*.gd") var cutscene_path: String = "res://scripts/story/cutscene_prologue.gd"

## Màn sẽ vào sau khi kể xong. ĐỂ TRỐNG nghĩa là "đi tiếp tới màn người chơi
@export var next_level: String = ""

## Đánh dấu màn nào đã hoàn thành khi kể xong. Để trống thì không đánh dấu gì.
@export var mark_completed: String = ""

@export_file("*.tscn") var next_scene: String = ""
## BIẾN THỂ của đoạn kể này, do scene đặt. Dòng kịch bản nào ghi
@export var variant: String = ""

## Cho phép bỏ qua (nút "Bỏ qua" và phím Esc). Tắt cho đoạn nào bắt buộc xem
@export var skippable: bool = true

## Tự sang câu sau bao nhiêu giây kể từ lúc câu hiện tại gõ xong. 0 = tắt
@export var auto_advance_seconds: float = 0.0
## Còn bao nhiêu giây thì tự sang câu. Âm = không đếm.
var _auto_left := -1.0

## ── TỰ ĐỘNG CHẠY HỘI THOẠI (người chơi bật/tắt bằng nút "Tự động") ──
## static để giữ lựa chọn khi sang đoạn kể khác trong cùng lần chơi.
static var _auto_on := false
## Thời gian chờ sau khi gõ xong = nền + theo độ dài câu, để câu dài có đủ thời gian đọc.
const AUTO_BASE_SECONDS := 1.2
const AUTO_SECONDS_PER_CHAR := 0.035
var _btn_auto: Button

@onready var _background: TextureRect = %Background
@onready var _tint: ColorRect = %Tint
@onready var _portrait: TextureRect = %Portrait
## Khung xếp NHIỀU chân dung cạnh nhau, dùng cho câu đồng thanh.
@onready var _group_box: HBoxContainer = %GroupPortrait

## Chân dung trong khung nhóm không được cao hơn bấy nhiêu pixel.
const MAX_GROUP_HEIGHT := 620.0
@onready var _lbl_name: Label = %LblSpeaker
@onready var _lbl_line: RichTextLabel = %LblLine
@onready var _arrow: Label = %Arrow
@onready var _btn_skip: Button = %BtnSkip

## Nội dung kịch bản đã nạp.
var _scenes: Array = []
## Tóm tắt của đoạn kể (hằng SUMMARY trong file kịch bản, có thể trống).
var _summary: String = ""
## Bảng tóm tắt hiện khi bấm "Bỏ qua"; null = chưa mở.
var _skip_panel: Control
## Id nhân vật đang hiện ảnh, đã quy đổi hết mọi id đặc biệt.
var _shown_id: String = ""
## Ai được bốc làm "người khác". Bốc MỘT LẦN rồi nhớ suốt đoạn kể — nếu bốc
var _other_id: String = ""
var _index: int = -1
## Đang gõ chữ hay đã gõ xong — biến quyết định cú bấm tiếp theo làm gì.
var _typing: bool = false
var _revealed: float = 0.0
## Khoá nhập trong lúc chuyển cảnh, để bấm dồn không làm nhảy mất một câu.
var _fading: bool = false


func _ready() -> void:
	if not music_group.is_empty():
		AmThanh.play_random_music(music_group)
	_load_cutscene()
	_tint.color = Color(0, 0, 0, 1)
	_portrait.modulate.a = 0.0
	_group_box.modulate.a = 0.0
	_lbl_line.visible_characters = 0
	_btn_skip.pressed.connect(_skip)
	_btn_skip.visible = skippable
	_add_auto_button()

	var blink := create_tween().set_loops()
	blink.tween_property(_arrow, "modulate:a", 0.15, 0.55)
	blink.tween_property(_arrow, "modulate:a", 1.0, 0.55)

	# Mở màn bằng một lần sáng dần từ đen, cho đỡ giật khi vừa đổi scene.
	var fade := create_tween()
	fade.tween_property(_tint, "color:a", 0.0, fade_time)
	await fade.finished
	_next_line()


## Nạp kịch bản. Hỏng file thì bỏ qua cả đoạn kể chứ KHÔNG treo game ở màn
func _load_cutscene() -> void:
	var path := _cutscene_for_locale(cutscene_path)
	var cutscene := load(path) as GDScript
	if cutscene == null:
		push_error("Không nạp được kịch bản: %s" % path)
		return
	var v: Variant = cutscene.get("SCENES")
	if v is Array:
		_scenes = v
	var sm: Variant = cutscene.get("SUMMARY")
	if sm is String:
		_summary = sm
	else:
		push_error("Kịch bản %s thiếu hằng SCENES." % path)


## Chọn file kịch bản theo ngôn ngữ đang bật, theo quy ước tên file:
func _cutscene_for_locale(path: String) -> String:
	var lang := TranslationServer.get_locale().substr(0, 2)
	if lang == SettingsManager.DEFAULT_LANGUAGE:
		return path
	var translated := path.get_basename() + "_" + lang + ".gd"
	if ResourceLoader.exists(translated):
		return translated
	push_warning("Chưa có bản dịch '%s' — dùng tạm kịch bản gốc." % translated)
	return path


func _process(delta: float) -> void:
	if not _typing:
		if _auto_left > 0.0 and not _fading and _skip_panel == null:
			_auto_left -= delta
			if _auto_left <= 0.0:
				_auto_left = -1.0
				_next_line()
		return
	_revealed += type_speed * delta
	_lbl_line.visible_characters = int(_revealed)
	if _lbl_line.visible_characters >= _lbl_line.get_total_character_count():
		_finish_typing()


# ----------------------------------------------------------------- nhập ---

## Chuột trái = một cú "chạm". TÊN HÀM PHẢI ĐÚNG LÀ `_gui_input`.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if _skip_panel != null:
		if event.is_action_pressed("ui_cancel"):
			_close_skip_panel()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_skip()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()


## Điểm vào duy nhất của mọi cú "chạm", dù từ chuột hay bàn phím.
func _tap() -> void:
	if _fading or _skip_panel != null:
		return
	if _typing:
		_finish_typing()
	else:
		_next_line()


func _finish_typing() -> void:
	_typing = false
	_start_auto_wait()
	_lbl_line.visible_characters = -1
	_arrow.show()


# --------------------------------------------------------- tự động chạy ---

## Nút "Tự động" đặt ngay bên trái nút "Bỏ qua", nhân bản từ nút đó để cùng kiểu.
func _add_auto_button() -> void:
	_btn_auto = _btn_skip.duplicate(0) as Button
	_btn_auto.unique_name_in_owner = false
	_btn_auto.name = "BtnAuto"
	_btn_auto.visible = true
	_btn_auto.focus_mode = Control.FOCUS_NONE
	_btn_skip.add_sibling(_btn_auto)
	_btn_auto.pressed.connect(_toggle_auto)
	_refresh_auto_button()
	_place_auto_button.call_deferred()


## Dời nút sang trái nút "Bỏ qua" (chờ một khung hình để nút đã có kích thước thật).
func _place_auto_button() -> void:
	var shift := _btn_skip.size.x + 16.0 if _btn_skip.visible else 0.0
	_btn_auto.offset_left = _btn_skip.offset_left - shift
	_btn_auto.offset_right = _btn_skip.offset_right - shift


func _toggle_auto() -> void:
	_auto_on = not _auto_on
	_refresh_auto_button()
	if _auto_on and not _typing and not _fading:
		_start_auto_wait()
	elif not _auto_on and auto_advance_seconds <= 0.0:
		_auto_left = -1.0


func _refresh_auto_button() -> void:
	_btn_auto.text = Lang.t("Tự động: Bật") if _auto_on else Lang.t("Tự động")
	_btn_auto.modulate = Color(1.0, 0.92, 0.6) if _auto_on else Color(1, 1, 1)


## Bắt đầu đếm giờ tự sang câu. Thiết lập của scene (auto_advance_seconds) được ưu tiên.
func _start_auto_wait() -> void:
	if auto_advance_seconds > 0.0:
		_auto_left = auto_advance_seconds
	elif _auto_on:
		_auto_left = AUTO_BASE_SECONDS + AUTO_SECONDS_PER_CHAR * _lbl_line.get_total_character_count()


# ----------------------------------------------------------- diễn kịch ---

## Chọn câu thoại của một dòng kịch bản. Thứ tự ưu tiên:
func _pick_line(entry: Dictionary) -> String:
	var by_player: Dictionary = entry.get("line_by_player", {})
	var who := String(GameData.selected_character)
	if by_player.has(who):
		return String(by_player[who])
	var by_level: Dictionary = entry.get("line_by_level", {})
	var lvl := String(GameData.current_level)
	if by_level.has(lvl):
		return String(by_level[lvl])
	return String(entry.get("line", ""))

## Dòng này có bị BỎ QUA không. Ba loại điều kiện, dòng phải đạt CẢ BA:
func _should_skip(entry: Dictionary) -> bool:
	var only: Array = entry.get("only_for_player", [])
	if not only.is_empty() and not only.has(String(GameData.selected_character)):
		return true

	var only_variant := String(entry.get("only_for_variant", ""))
	if not only_variant.is_empty() and only_variant != variant:
		return true

	if entry.has("only_for_hidden_cast"):
		var wanted: Array = entry["only_for_hidden_cast"]
		var present := GameData.hidden_cast_seen()
		if wanted.size() != present.size():
			return true
		for id in wanted:
			if not present.has(String(id)):
				return true

	if entry.has("with_hidden_cast"):
		var needed: Array = entry["with_hidden_cast"]
		var seen := GameData.hidden_cast_seen()
		for id in needed:
			if not seen.has(String(id)):
				return true
	return false


func _next_line() -> void:
	_auto_left = -1.0
	_index += 1
	if _index >= _scenes.size():
		_finish()
		return

	var entry: Dictionary = _scenes[_index]

	if _should_skip(entry):
		_next_line()
		return

	if entry.has("music"):
		AmThanh.set_music_hushed(String(entry["music"]) == "off")

	if entry.has("background"):
		await _change_background(String(entry["background"]))

	if entry.has("portrait"):
		_change_portrait(entry["portrait"], String(entry.get("emotion", "")))
	elif not _shown_id.is_empty():
		_portrait.texture = _portrait_texture(_shown_id, String(entry.get("emotion", "")))

	var speaker := String(entry.get("speaker", ""))
	if speaker == AUTO_NAME:
		speaker = _display_name(_shown_id)
	speaker = Lang.t(speaker)
	_lbl_name.text = speaker
	_lbl_name.visible = not speaker.is_empty()

	_lbl_line.text = Lang.t(_pick_line(entry))
	_lbl_line.visible_characters = 0
	_revealed = 0.0
	_typing = true

	_arrow.hide()


## Tên hiện trên thẻ tên ứng với một id nhân vật.
func _display_name(id: String) -> String:
	if id.is_empty():
		return ""
	return String(GameData.CHARACTERS.get(id, {}).get("label", id))


func _change_background(path: String) -> void:
	_fading = true
	var tex := load(path) as Texture2D
	var tween := create_tween()
	tween.tween_property(_tint, "color:a", 1.0, fade_time)
	await tween.finished
	if tex != null:
		_background.texture = tex
	var tween2 := create_tween()
	tween2.tween_property(_tint, "color:a", 0.0, fade_time)
	await tween2.finished
	_fading = false


## Quy đổi các id đặc biệt trong kịch bản thành id nhân vật thật.
func _resolve_id(id: String) -> String:
	if id == "player":
		return GameData.selected_character
	if id == "other":
		return _other_speaker()
	return id


## Bốc một nhân vật chơi được, khác người chơi, và có sẵn ảnh chân dung.
func _other_speaker() -> String:
	if not _other_id.is_empty():
		return _other_id
	var candidates: Array[String] = []
	for k in GameData.CHARACTER_ORDER:
		var id := str(k)
		if id == GameData.selected_character:
			continue
		if GameData.is_character_locked(id):
			continue
		if not PORTRAITS.has(id):
			continue
		candidates.append(id)
	if candidates.is_empty():
		push_warning("Không tìm được nhân vật nào khác người chơi.")
		return GameData.selected_character
	_other_id = candidates.pick_random()
	return _other_id


## Đổi chân dung đang hiện.
func _change_portrait(value: Variant, emotion: String = "") -> void:
	var list: Array = value if value is Array else [value]
	var actual: Array[String] = []
	for x in list:
		var id := _resolve_id(String(x))
		if id.is_empty() or actual.has(id):
			continue
		if not PORTRAITS.has(id):
			push_warning("Kịch bản gọi id nhân vật không có trong PORTRAITS: '%s'" % id)
			continue
		var path := String(PORTRAITS[id])
		if not ResourceLoader.exists(path):
			push_warning("Thiếu file ảnh: %s" % path)
			continue
		actual.append(id)

	_shown_id = actual[0] if actual.size() == 1 else ""

	if actual.is_empty():
		_hide_portrait()
		return

	if actual.size() == 1:
		_reveal_gradually(_group_box, false)
		_portrait.texture = _portrait_texture(actual[0], emotion)
		_reveal_gradually(_portrait, true)
		return

	_reveal_gradually(_portrait, false)
	_build_group(actual)
	_reveal_gradually(_group_box, true)


## Dựng lại dãy chân dung của câu đồng thanh.
func _build_group(list: Array[String]) -> void:
	for child in _group_box.get_children():
		_group_box.remove_child(child)
		child.free()
	_align_group_bottom(list.size())
	for id in list:
		var cell := TextureRect.new()
		cell.texture = load(String(PORTRAITS[id]))
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_group_box.add_child(cell)


## Kéo MÉP TRÊN của khung nhóm lên đúng bằng bề ngang một ảnh.
func _align_group_bottom(count: int) -> void:
	if count <= 0:
		return
	var gap := float(_group_box.get_theme_constant("separation"))
	var width := get_viewport_rect().size.x + _group_box.offset_right - _group_box.offset_left
	var new_width := (width - gap * (count - 1)) / float(count)
	_group_box.offset_top = _group_box.offset_bottom - minf(new_width, MAX_GROUP_HEIGHT)


## Ảnh của một nhân vật với một biểu cảm; rỗng hoặc thiếu file -> ảnh mặc định.
func _portrait_texture(id: String, emotion: String) -> Texture2D:
	if not emotion.is_empty():
		var path := EMOTION_FMT % [id, emotion]
		if ResourceLoader.exists(path):
			return load(path)
		push_warning("Thiếu ảnh biểu cảm: %s" % path)
	return load(String(PORTRAITS[id]))


func _hide_portrait() -> void:
	_reveal_gradually(_portrait, false)
	_reveal_gradually(_group_box, false)


## Mờ dần vào/ra.
func _reveal_gradually(btn: CanvasItem, show_it: bool) -> void:
	btn.visible = true
	var tween := create_tween()
	tween.tween_property(btn, "modulate:a", 1.0 if show_it else 0.0, 0.25 if show_it else 0.2)


# --------------------------------------------------------------- kết thúc ---

## Bấm "Bỏ qua" chưa bỏ ngay: hiện bảng tóm tắt, người chơi xác nhận lần nữa mới bỏ.
func _skip() -> void:
	if _fading or not skippable or _skip_panel != null:
		return
	_open_skip_panel()


func _open_skip_panel() -> void:
	_skip_panel = ColorRect.new()
	(_skip_panel as ColorRect).color = Color(0, 0, 0, 0.55)
	_skip_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_skip_panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skip_panel.add_child(center)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(900, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.09, 0.08, 0.96)
	style.border_color = Color(0.85, 0.66, 0.38)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(32)
	box.add_theme_stylebox_override("panel", style)
	center.add_child(box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	box.add_child(col)

	var title := Label.new()
	title.text = Lang.t("Tóm tắt đoạn này")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45))
	col.add_child(title)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.add_theme_font_size_override("normal_font_size", 26)
	var text := Lang.t(_summary) if not _summary.is_empty() \
			else Lang.t("Đoạn này chưa có tóm tắt.")
	body.text = text + "\n\n[color=#bfae96]" + Lang.t("Bạn có chắc muốn bỏ qua đoạn hội thoại này?") + "[/color]"
	col.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)

	var btn_back := _btn_skip.duplicate(0) as Button
	btn_back.unique_name_in_owner = false
	btn_back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_back.visible = true
	btn_back.text = Lang.t("Xem tiếp")
	btn_back.pressed.connect(_close_skip_panel)
	row.add_child(btn_back)

	var btn_ok := _btn_skip.duplicate(0) as Button
	btn_ok.unique_name_in_owner = false
	btn_ok.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_ok.visible = true
	btn_ok.text = Lang.t("Bỏ qua")
	btn_ok.pressed.connect(_confirm_skip)
	row.add_child(btn_ok)
	btn_back.grab_focus()


func _close_skip_panel() -> void:
	if _skip_panel != null:
		_skip_panel.queue_free()
		_skip_panel = null


func _confirm_skip() -> void:
	_close_skip_panel()
	_finish()


## Lưới an toàn thứ hai cho nhạc: scene bị đổi bằng đường KHÔNG qua _finish()
func _exit_tree() -> void:
	AmThanh.set_music_hushed(false)


func _finish() -> void:
	_fading = true
	_typing = false
	AmThanh.set_music_hushed(false)
	var tween := create_tween()
	tween.tween_property(_tint, "color:a", 1.0, fade_time)
	await tween.finished

	if not mark_completed.is_empty():
		GameData.complete_level(mark_completed)
	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)
		return
	if not next_level.is_empty():
		GameData.current_level = next_level

	var path := GameData.enter_level(GameData.current_level)
	if path.is_empty():
		push_error("Màn '%s' chưa khai báo scene trong GameData.LEVELS." % GameData.current_level)
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		return
	get_tree().change_scene_to_file(path)
