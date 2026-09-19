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
const DAU_BAT := "✔  "
const DAU_TAT := "—  "
const MAU_BAT := Color("5ea35a")
const MAU_TAT := Color(0.55, 0.50, 0.44)

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
var _btn_tua: Button = null
## Nút cho phép bấm kĩ năng chủ động mà không cần đủ điều kiện.
var _btn_ki_nang: Button = null

## Nhãn GỐC của từng nút, tức phần chữ KHÔNG kể dấu tích: Button -> String.
##
## Phải nhớ riêng chứ không đọc lại từ nut.text, vì nut.text đã bị gắn dấu ở
## lần vẽ trước — đọc rồi gắn tiếp sẽ ra "✔  ✔  Tua giờ" sau vài lần bấm.
var _nhan_goc: Dictionary = {}

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
var _nut_nhan_vat: Dictionary = {}


func _ready() -> void:
	hide()
	_btn_ok.pressed.connect(_try_login)
	_btn_cancel.pressed.connect(close)
	_btn_close.pressed.connect(close)
	_btn_unlock.pressed.connect(_on_unlock_pressed)
	# Nhãn của nút này nằm trong scene dưới dạng KHOÁ dịch ("CODE7_UNLOCK_LEVELS").
	# Dịch ra ngay bây giờ rồi cất đi: khi đã tự gắn dấu vào text thì chuỗi
	# không còn là khoá nữa nên Godot thôi dịch hộ.
	_nhan_goc[_btn_unlock] = tr(_btn_unlock.text)

	# Thứ tự thêm quyết định thứ tự hiện trên bảng.
	_btn_view = _nhan_ban_nut(
		"BtnThirdPerson", "Góc nhìn thứ 3 (phím P)", _on_third_person_pressed)
	_btn_tua = _nhan_ban_nut(
		"BtnTuaGio", "Tua giờ trong màn (phím 0)", _on_tua_gio_pressed)
	_btn_ki_nang = _nhan_ban_nut(
		"BtnKiNang", "Kĩ năng không cần điều kiện", _on_ki_nang_pressed)
	for id in GameData.NHAN_VAT_AN:
		var ma := String(id)
		var ten := String(GameData.CHARACTERS.get(ma, {}).get("label", ma))
		_nut_nhan_vat[ma] = _nhan_ban_nut(
			"BtnNV_" + ma, "Mở khoá %s" % ten, _on_nhan_vat_pressed.bind(ma))
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
		_ve_lai()
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
func _nhan_ban_nut(ten: String, nhan: String, ham: Callable) -> Button:
	var nut := _btn_unlock.duplicate(Node.DUPLICATE_GROUPS) as Button
	nut.name = ten
	nut.pressed.connect(ham)
	_nhan_goc[nut] = nhan
	_btn_unlock.get_parent().add_child(nut)
	return nut


## Gắn dấu trạng thái vào một nút.
##
## Đổi CẢ dấu lẫn màu chữ chứ không chỉ một trong hai: dấu nói cho người đọc
## kĩ, màu nói cho người chỉ liếc qua — nhìn cả bảng một cái là thấy ngay có
## mấy dòng xanh.
func _dat_tick(nut: Button, dang_bat: bool) -> void:
	if nut == null:
		return
	nut.text = (DAU_BAT if dang_bat else DAU_TAT) + String(_nhan_goc.get(nut, ""))
	nut.add_theme_color_override("font_color", MAU_BAT if dang_bat else MAU_TAT)


func _on_third_person_pressed() -> void:
	GameData.set_third_person_unlocked(not GameData.third_person_unlocked)
	_ve_lai()


## Bật/tắt một nhân vật ẩn.
##
## Hàm cũ đọc `GameData.golshi_unlocked` — một thuộc tính KHÔNG TỒN TẠI trong
## GameData (chỉ có hàm set_golshi_unlocked và mấy dòng chú thích nhắc tên đó).
## Đọc thuộc tính không có trên một Node là lỗi lúc chạy, nên bấm nút này chưa
## bao giờ mở khoá được ai — và đó là lý do sâu xa khiến đoạn ra mắt Gold Ship
## không chạy: nó đòi "đã mở khoá", mà không có cách nào mở.
func _on_nhan_vat_pressed(id: String) -> void:
	GameData.set_mo_nhan_vat(id, not GameData.da_mo_nhan_vat(id))
	_ve_lai()


## Bật/tắt cheat tua giờ bằng phím 0 trong màn chơi.
##
## Cheat này dành cho người XEM chứ không phải người chơi: một màn dài 7 phút,
## mà nhạc cao điểm (còn 3:32) và bảng tổng kết — hai thứ đáng xem nhất — đều
## nằm ở cuối. Bật lên rồi bấm 0 một lần là nhảy tới 3:30, bấm lần nữa là
## tổng kết.
func _on_tua_gio_pressed() -> void:
	GameData.set_cheat_tua_gio(not GameData.cheat_tua_gio)
	_ve_lai()


## Bật/tắt việc bỏ qua điều kiện của kĩ năng chủ động.
##
## Cùng lý do với tua giờ: kĩ năng của Kita đòi 5 đơn hoàn hảo, tức khoảng hai
## phút chơi giỏi mới xem được một lần. Bật cheat này thì bấm Space là chạy
## ngay, đủ để kiểm tra hiệu ứng và để quay lại đoạn cut-in.
func _on_ki_nang_pressed() -> void:
	GameData.set_ki_nang_vo_han(not GameData.ki_nang_vo_han)
	_ve_lai()


func _on_unlock_pressed() -> void:
	# Đảo trạng thái: bấm lần nữa là tắt cheat đi.
	GameData.set_unlock_all(not GameData.unlock_all)
	_ve_lai()


## Vẽ lại dấu tích của MỌI nút theo trạng thái thật trong GameData.
##
## Vẽ lại tất cả sau mỗi lần bấm, chứ không chỉ sửa cái nút vừa bấm: rẻ (bảy
## phép gán chuỗi) và loại hẳn một lớp lỗi — cheat nào sau này ảnh hưởng tới
## cheat khác thì bảng vẫn luôn khớp với sự thật.
func _ve_lai() -> void:
	_dat_tick(_btn_unlock, GameData.unlock_all)
	_dat_tick(_btn_view, GameData.third_person_unlocked)
	_dat_tick(_btn_tua, GameData.cheat_tua_gio)
	_dat_tick(_btn_ki_nang, GameData.ki_nang_vo_han)
	for id in _nut_nhan_vat:
		var ma := String(id)
		_dat_tick(_nut_nhan_vat[ma] as Button, GameData.da_mo_nhan_vat(ma))
