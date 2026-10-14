extends Control
## CODE No.7 — bảng công cụ dành cho người phát triển.
## Vào bằng mật khẩu, dùng để bật các cheat phục vụ việc test và demo.
##
## ─────────────────────────────────────────── VÌ SAO ĐỔI SANG DẤU TÍCH
##
## Bản trước cho biết cheat đang bật hay tắt bằng HAI cách cùng lúc: đổi ĐỘNG
## TỪ trên nút ("Bật tua giờ" ↔ "Tắt tua giờ") và một khối chữ tổng kết ở
## trên (LblStatus) liệt kê lại toàn bộ trạng thái.
##
## Cả hai đều đọc chậm. Động từ trên nút nói về HÀNH ĐỘNG SẼ XẢY RA khi bấm,
## tức là NGƯỢC với trạng thái hiện tại — thấy chữ "Tắt tua giờ" phải suy một
## bước mới ra "vậy là đang bật". Còn khối chữ thì đúng nhưng phải ĐỐI CHIẾU:
## dòng thứ ba kể về cái nút thứ ba, và người đọc tự ghép.
##
## Dấu tích bỏ cả hai bước đó: ✔ là đang bật, — là đang tắt, nằm ngay trên
## cái nút mà nó nói tới. Nhãn nút giữ NGUYÊN không đổi, nên mắt quen vị trí
## rồi thì lần sau chỉ cần liếc cột dấu bên trái. Khối LblStatus bị xoá hẳn vì
## giờ nó chỉ còn là bản chép lại của những gì đã hiện trên nút.
##
## ────────────────────────────────────────────── VÌ SAO CHO VÀO KHUNG CUỘN
##
## Danh sách cheat dài dần theo thời gian: mở khoá màn, góc nhìn thứ 3, tua
## giờ, kĩ năng vô điều kiện, cộng BA nhân vật ẩn — bảy nút, và còn thêm. Bảng
## nằm trong CenterContainer nên nó cao lên theo, tới lúc nào đó thì nút Đóng
## bị đẩy ra ngoài màn hình và bảng thành cái bẫy.
##
## Khung cuộn khoá chiều cao phần danh sách lại; nút Đóng nằm NGOÀI khung nên
## luôn nhìn thấy dù danh sách dài bao nhiêu. `follow_focus` bật để đi bằng
## bàn phím vẫn cuộn theo.
##
## ─────────────────────────────────── THÊM MỘT CHEAT MỚI CẦN ĐÚNG HAI DÒNG
##
##   1. Trong _ready():  _btn_moi = _nhan_ban_nut("BtnMoi", "Nhãn", ham)
##   2. Trong _ve_lai(): _dat_tick(_btn_moi, GameData.co_gi_do)
##
## Không phải sửa scene, không phải căn lại giao diện.

## Mật khẩu vào bảng. Đây KHÔNG phải cơ chế bảo mật — bất kỳ ai mở file
## này ra đều đọc được. Nó chỉ để tránh người chơi bấm nhầm vào cheat.
const PASSWORD := "777"

## Dấu trạng thái. Dùng "✔" và "—" chứ không "✔"/"✕": dấu tích và gạch ngang
## chắc chắn có trong font đang dùng (thẻ màn đã khoá trong màn chọn màn dùng
## chính hai kí tự này), còn "✕" thì chưa nơi nào thử — mà một kí tự thiếu
## trong font hiện ra thành ô vuông rỗng, đúng chỗ cần rõ ràng nhất.
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
## nên không có dấu tích và không có mặt trong _redraw().
var _btn_replay_intro: Button
## Công tắc ép màn Ending chiếu kết ẩn (để kiểm thử, không lưu vào save).
var _btn_secret_ending: Button

## Nhãn GỐC của từng nút, tức phần chữ KHÔNG kể dấu tích: Button -> String.
##
## Phải nhớ riêng chứ không đọc lại từ nut.text, vì nut.text đã bị gắn dấu ở
## lần vẽ trước — đọc rồi gắn tiếp sẽ ra "✔  ✔  Tua giờ" sau vài lần bấm.
var _base_labels: Dictionary = {}

## Nút mở khoá của TỪNG nhân vật ẩn: id -> Button. Dựng bằng vòng lặp trên
## GameData.NHAN_VAT_AN.
##
## Trước đây chỉ có đúng một nút, viết tay, dành riêng cho Gold Ship — trong
## khi bảng NHAN_VAT_AN có BA người. Hậu quả: Tokai Teio và Sakura Chiyono O
## không có đường nào mở khoá, nên hai thẻ đó vĩnh viễn là bóng đen và hai
## đoạn cắt cảnh ra mắt của họ không bao giờ chạy được.
##
## Dựng từ bảng thì thêm nhân vật ẩn thứ tư là thêm một dòng trong GameData,
## bảng cheat tự có thêm nút.
var _character_buttons: Dictionary = {}


func _ready() -> void:
	hide()
	_btn_ok.pressed.connect(_try_login)
	_btn_cancel.pressed.connect(close)
	_btn_close.pressed.connect(close)
	_btn_unlock.pressed.connect(_on_unlock_pressed)
	# Nhãn của nút này nằm trong scene dưới dạng KHOÁ dịch ("CODE7_UNLOCK_LEVELS").
	# Dịch ra ngay bây giờ rồi cất đi: khi đã tự gắn dấu vào text thì chuỗi
	# không còn là khoá nữa nên Godot thôi dịch hộ.
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
	# Không đi qua _redraw() nên phải tự gán chữ, nếu không nút giữ nguyên chữ
	# của nút gốc mà _make_button() nhân bản ra.
	_btn_replay_intro.text = String(_base_labels[_btn_replay_intro])
	_btn_secret_ending = _make_button(
		"BtnSecretEnding", Lang.t("Ending: luôn chiếu kết ẩn"), _on_secret_ending_pressed)
	# Gõ mật khẩu xong bấm Enter cũng vào được, không bắt phải rê chuột.
	_input.text_submitted.connect(_on_text_submitted)


func open(focus_on_close: Control = null) -> void:
	_focus_on_close = focus_on_close
	# Mỗi lần mở lại đều bắt nhập mật khẩu từ đầu.
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
##
## Nhân bản chứ không tạo Button.new(): bản sao mang y nguyên theme, cỡ chữ,
## padding và size flags của nút gốc, nên không phải căn lại bằng tay; sau này
## đổi giao diện bảng cheat thì cả danh sách cùng đổi theo. Cờ DUPLICATE_GROUPS
## được truyền vào để KHÔNG sao chép các tín hiệu đã nối — nếu không, bấm nút
## mới sẽ chạy luôn hàm của nút cũ.
func _make_button(label_: String, base_label: String, callback: Callable) -> Button:
	var btn := _btn_unlock.duplicate(Node.DUPLICATE_GROUPS) as Button
	btn.name = label_
	btn.pressed.connect(callback)
	_base_labels[btn] = base_label
	_btn_unlock.get_parent().add_child(btn)
	return btn


## Gắn dấu trạng thái vào một nút.
##
## Đổi CẢ dấu lẫn màu chữ chứ không chỉ một trong hai: dấu nói cho người đọc
## kĩ, màu nói cho người chỉ liếc qua — nhìn cả bảng một cái là thấy ngay có
## mấy dòng xanh.
func _set_tick(btn: Button, dang_bat: bool) -> void:
	if btn == null:
		return
	btn.text = (MARK_ON if dang_bat else MARK_OFF) + String(_base_labels.get(btn, ""))
	btn.add_theme_color_override("font_color", COLOR_ON if dang_bat else COLOR_OFF)


func _on_third_person_pressed() -> void:
	GameData.set_third_person_unlocked(not GameData.third_person_unlocked)
	_redraw()


## Bật/tắt một nhân vật ẩn.
##
## Hàm cũ đọc `GameData.golshi_unlocked` — một thuộc tính KHÔNG TỒN TẠI trong
## GameData (chỉ có hàm set_golshi_unlocked và mấy dòng chú thích nhắc tên đó).
## Đọc thuộc tính không có trên một Node là lỗi lúc chạy, nên bấm nút này chưa
## bao giờ mở khoá được ai — và đó là lý do sâu xa khiến đoạn ra mắt Gold Ship
## không chạy: nó đòi "đã mở khoá", mà không có cách nào mở.
func _on_character_pressed(id: String) -> void:
	GameData.set_character_unlocked(id, not GameData.is_character_unlocked(id))
	_redraw()


## Bật/tắt cheat tua giờ bằng phím 0 trong màn chơi.
##
## Cheat này dành cho người XEM chứ không phải người chơi: một màn dài 7 phút,
## mà nhạc cao điểm (còn 3:32) và bảng tổng kết — hai thứ đáng xem nhất — đều
## nằm ở cuối. Bật lên rồi bấm 0 một lần là nhảy tới 3:30, bấm lần nữa là
## tổng kết.
func _on_time_skip_pressed() -> void:
	GameData.set_cheat_time_skip(not GameData.cheat_time_skip)
	_redraw()


## Bật/tắt việc bỏ qua điều kiện của kĩ năng chủ động.
##
## Cùng lý do với tua giờ: kĩ năng của Kita đòi 5 đơn hoàn hảo, tức khoảng hai
## phút chơi giỏi mới xem được một lần. Bật cheat này thì bấm Space là chạy
## ngay, đủ để kiểm tra hiệu ứng và để quay lại đoạn cut-in.
func _on_skill_pressed() -> void:
	GameData.set_infinite_skill(not GameData.infinite_skill)
	_redraw()


## Bật/tắt GIÁ VỐN NGUYÊN LIỆU.
##
## Bật cheat = nguyên liệu miễn phí, tức TẮT cơ chế. Đặt tên theo hướng "cheat
## cho dễ" giống hai nút trên, không đặt "bật giá nguyên liệu" — mọi nút trong
## bảng này bật lên là dễ đi, đọc một lượt không phải nhớ nút nào ngược chiều.
##
## Có tác dụng từ LẦN VÀO MÀN SAU: màn chơi đọc cờ này một lần lúc dựng hệ
## khách. Đổi giữa màn thì cái ví đang chạy dở sẽ không khớp với luật mới, mà
## một màn nửa có giá nửa miễn phí thì số liệu đo được không nói lên gì.
func _on_free_ingredients_pressed() -> void:
	GameData.set_cheat_free_ingredients(not GameData.cheat_free_ingredients)
	_redraw()


## Đặt lại "đã xem" cho cả ba nhân vật ẩn rồi báo ngay trên chính cái nút.
##
## Báo bằng cách đổi chữ nút trong 1,5 giây chứ không thêm dấu tích: dấu tích
## trên bảng này nghĩa là "đang bật", mà nút này không bật cái gì cả — gắn
## dấu thì người đọc tưởng phải bấm lần nữa để tắt.
func _on_replay_intro_pressed() -> void:
	GameData.reset_intro_seen()
	var base := String(_base_labels.get(_btn_replay_intro, ""))
	_btn_replay_intro.text = Lang.t("Đã đặt lại — chọn nhân vật ẩn để xem")
	_btn_replay_intro.disabled = true
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(_btn_replay_intro):
		_btn_replay_intro.text = base
		_btn_replay_intro.disabled = false


## Bật: nút Ending luôn vào kết ẩn. Tắt: quay về luật thật (ba chữ S).
##
## Là CÔNG TẮC có dấu tích chứ không phải nút bấm một lần như nút xem lại
## đoạn ra mắt: cần xem được cả hai kết qua lại nhiều lần, và dấu tích cho
## biết lần bấm Ending sắp tới sẽ ra kết nào.
func _on_secret_ending_pressed() -> void:
	GameData.cheat_force_secret_ending = not GameData.cheat_force_secret_ending
	_redraw()


func _on_unlock_pressed() -> void:
	# Đảo trạng thái: bấm lần nữa là tắt cheat đi.
	GameData.set_unlock_all(not GameData.unlock_all)
	_redraw()


## Vẽ lại dấu tích của MỌI nút theo trạng thái thật trong GameData.
##
## Vẽ lại tất cả sau mỗi lần bấm, chứ không chỉ sửa cái nút vừa bấm: rẻ (bảy
## phép gán chuỗi) và loại hẳn một lớp lỗi — cheat nào sau này ảnh hưởng tới
## cheat khác thì bảng vẫn luôn khớp với sự thật.
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
