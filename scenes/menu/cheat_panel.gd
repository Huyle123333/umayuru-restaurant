extends Control
## ─────────────────────────────────────────── VÌ SAO ĐỔI SANG DẤU TÍCH
## ────────────────────────────────────────────── VÌ SAO CHO VÀO KHUNG CUỘN
## ─────────────────────────────────── THÊM MỘT CHEAT MỚI CẦN ĐÚNG HAI DÒNG

## Mật khẩu vào bảng. Đây KHÔNG phải cơ chế bảo mật — bất kỳ ai mở file
const PASSWORD := "777"

## Dấu trạng thái. Dùng "✔" và "—" chứ không "✔"/"✕": dấu tích và gạch ngang
const MARK_ON := "✔  "
const MARK_OFF := "—  "
const COLOR_ON := Color("5ea35a")
const COLOR_OFF := Color(0.55, 0.50, 0.44)

@onready var _login_box: Control = %LoginBox
@onready var _cheat_box: Control = %CheatBox
@onready var _input: LineEdit = %InputPass
@onready var _lbl_error: Label = %LblError
@onready var _btn_ok: Button = %BtnOk
@onready var _btn_cancel: Button = %BtnCancel
@onready var _btn_unlock: Button = %BtnUnlockAll
@onready var _btn_close: Button = %BtnClose

var _focus_on_close: Control = null
## Nút bật góc nhìn thứ 3 — tạo bằng code, xem _nhan_ban_nut().
var _btn_view: Button = null
## Nút bật cheat tua giờ bằng phím 0 — cũng tạo bằng code.
var _btn_time_skip: Button = null
## Nút cho phép bấm kĩ năng chủ động mà không cần đủ điều kiện.
var _btn_skill: Button = null
var _btn_free_ingredients: Button
## Nút XEM LẠI đoạn ra mắt nhân vật ẩn. Bấm một lần, KHÔNG phải công tắc —
var _btn_replay_intro: Button
## Công tắc ép màn Ending chiếu kết ẩn (để kiểm thử, không lưu vào save).
var _btn_secret_ending: Button

## Nhãn GỐC của từng nút, tức phần chữ KHÔNG kể dấu tích: Button -> String.
var _base_labels: Dictionary = {}

## Nút mở khoá của TỪNG nhân vật ẩn: id -> Button. Dựng bằng vòng lặp trên
var _character_buttons: Dictionary = {}


var _btn_shop_coins: Button


func _ready() -> void:
	hide()
	_btn_ok.pressed.connect(_try_login)
	_btn_cancel.pressed.connect(close)
	_btn_close.pressed.connect(close)
	_btn_unlock.pressed.connect(_on_unlock_pressed)
	_base_labels[_btn_unlock] = tr(_btn_unlock.text)

	# Thứ tự thêm quyết định thứ tự hiện trên bảng.
	_btn_view = _make_button(
		"BtnThirdPerson", Lang.t("Góc nhìn thứ 3 (phím P)"), _on_third_person_pressed)
	_btn_time_skip = _make_button(
		"BtnTuaGio", Lang.t("Tua giờ trong màn (phím 0)"), _on_time_skip_pressed)
	_btn_skill = _make_button(
		"BtnKiNang", Lang.t("Kĩ năng không cần điều kiện"), _on_skill_pressed)
	_btn_free_ingredients = _make_button(
		"BtnNguyenLieu", Lang.t("Nguyên liệu miễn phí"), _on_free_ingredients_pressed)
	for id in GameData.HIDDEN_CHARACTERS:
		var code_ := String(id)
		var label_ := String(GameData.CHARACTERS.get(code_, {}).get("label", code_))
		_character_buttons[code_] = _make_button(
			"BtnNV_" + code_, Lang.t("Mở khoá %s") % label_, _on_character_pressed.bind(code_))
	_btn_replay_intro = _make_button(
		"BtnReplayIntro", Lang.t("Xem lại đoạn ra mắt nhân vật ẩn"), _on_replay_intro_pressed)
	_btn_replay_intro.text = String(_base_labels[_btn_replay_intro])
	_btn_shop_coins = _make_button(
		"BtnShopCoins", Lang.t("+1000 tiền shop"), _on_shop_coins_pressed)
	_btn_shop_coins.text = String(_base_labels[_btn_shop_coins])
	_btn_secret_ending = _make_button(
		"BtnSecretEnding", Lang.t("Ending: luôn chiếu kết ẩn"), _on_secret_ending_pressed)
	_input.text_submitted.connect(_on_text_submitted)


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	_input.text = ""
	_lbl_error.hide()
	_login_box.show()
	_cheat_box.hide()
	show()
	_input.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_focus_on_close):
		_focus_on_close.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------- mật khẩu ---

func _on_text_submitted(_text: String) -> void:
	_try_login()


func _try_login() -> void:
	if _input.text.strip_edges() == PASSWORD:
		_login_box.hide()
		_cheat_box.show()
		_redraw()
		_btn_unlock.grab_focus()
	else:
		_lbl_error.show()
		_input.text = ""
		_input.grab_focus()


# --------------------------------------------------------------- cheat ---

## Nhân bản nút mở khoá thành một nút cheat mới.
func _make_button(label_: String, base_label: String, callback: Callable) -> Button:
	var btn := _btn_unlock.duplicate(Node.DUPLICATE_GROUPS) as Button
	btn.name = label_
	btn.pressed.connect(callback)
	_base_labels[btn] = base_label
	_btn_unlock.get_parent().add_child(btn)
	return btn


## Gắn dấu trạng thái vào một nút.
func _set_tick(btn: Button, dang_bat: bool) -> void:
	if btn == null:
		return
	btn.text = (MARK_ON if dang_bat else MARK_OFF) + String(_base_labels.get(btn, ""))
	btn.add_theme_color_override("font_color", COLOR_ON if dang_bat else COLOR_OFF)


func _on_third_person_pressed() -> void:
	GameData.set_third_person_unlocked(not GameData.third_person_unlocked)
	_redraw()


## Bật/tắt một nhân vật ẩn.
func _on_character_pressed(id: String) -> void:
	GameData.set_character_unlocked(id, not GameData.is_character_unlocked(id))
	_redraw()


## Bật/tắt cheat tua giờ bằng phím 0 trong màn chơi.
func _on_time_skip_pressed() -> void:
	GameData.set_cheat_time_skip(not GameData.cheat_time_skip)
	_redraw()


## Bật/tắt việc bỏ qua điều kiện của kĩ năng chủ động.
func _on_skill_pressed() -> void:
	GameData.set_infinite_skill(not GameData.infinite_skill)
	_redraw()


## Bật/tắt GIÁ VỐN NGUYÊN LIỆU.
func _on_free_ingredients_pressed() -> void:
	GameData.set_cheat_free_ingredients(not GameData.cheat_free_ingredients)
	_redraw()


## Đặt lại "đã xem" cho cả ba nhân vật ẩn rồi báo ngay trên chính cái nút.
func _on_replay_intro_pressed() -> void:
	GameData.reset_intro_seen()
	var base := String(_base_labels.get(_btn_replay_intro, ""))
	_btn_replay_intro.text = Lang.t("Đã đặt lại — chọn nhân vật ẩn để xem")
	_btn_replay_intro.disabled = true
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(_btn_replay_intro):
		_btn_replay_intro.text = base
		_btn_replay_intro.disabled = false


## Nút bấm một lần như "Xem lại đoạn ra mắt", KHÔNG có dấu tích: cộng tiền
func _on_shop_coins_pressed() -> void:
	GameData.add_shop_coins(1000)
	var base := String(_base_labels.get(_btn_shop_coins, ""))
	_btn_shop_coins.text = Lang.t("Ví shop: %d") % GameData.shop_coins
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(_btn_shop_coins):
		_btn_shop_coins.text = base


## Bật: nút Ending luôn vào kết ẩn. Tắt: quay về luật thật (ba chữ S).
func _on_secret_ending_pressed() -> void:
	GameData.cheat_force_secret_ending = not GameData.cheat_force_secret_ending
	_redraw()


func _on_unlock_pressed() -> void:
	GameData.set_unlock_all(not GameData.unlock_all)
	_redraw()


## Vẽ lại dấu tích của MỌI nút theo trạng thái thật trong GameData.
func _redraw() -> void:
	_set_tick(_btn_unlock, GameData.unlock_all)
	_set_tick(_btn_view, GameData.third_person_unlocked)
	_set_tick(_btn_time_skip, GameData.cheat_time_skip)
	_set_tick(_btn_skill, GameData.infinite_skill)
	_set_tick(_btn_free_ingredients, GameData.cheat_free_ingredients)
	_set_tick(_btn_secret_ending, GameData.cheat_force_secret_ending)
	for id in _character_buttons:
		var code_ := String(id)
		_set_tick(_character_buttons[code_] as Button, GameData.is_character_unlocked(code_))
