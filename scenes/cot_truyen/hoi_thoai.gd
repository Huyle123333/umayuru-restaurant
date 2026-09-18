extends Control
## Bộ máy hội thoại 1-chạm kiểu RPG Maker. Dùng chung cho prologue và mọi
## đoạn kể chuyện về sau — kịch bản nạp từ ngoài vào nên bộ máy không biết
## và không cần biết nội dung câu chuyện là gì.
##
## ------------------------------------------------------------- BA QUY TẮC
##
## 1. MỘT CÚ BẤM LÀM HAI VIỆC KHÁC NHAU tuỳ lúc:
##      - đang chạy chữ  -> hiện ngay hết câu
##      - chữ đã hiện đủ -> sang câu tiếp
##    Đây là chuẩn của thể loại (RPG Maker, Ren'Py, phần lớn visual novel).
##    Lý do: người đọc nhanh không bị bắt chờ máy gõ chữ, còn người đọc chậm
##    vẫn giữ được hiệu ứng gõ. Nếu chỉ có một hành vi thì luôn có một nửa
##    người chơi thấy khó chịu.
##
## 2. BẤM Ở ĐÂU CŨNG ĐƯỢC, không phải nhắm vào hộp thoại. Cả màn hình là
##    vùng bấm; chỉ nút "Bỏ qua" nằm đè lên trên mới cướp cú bấm về mình
##    (Godot đưa sự kiện cho node vẽ SAU CÙNG trước, nên chỉ cần đặt nút
##    ở dưới cùng trong cây scene là xong, không phải viết thêm code).
##
## 3. BÀN PHÍM LÀM ĐƯỢC MỌI THỨ CHUỘT LÀM. Space/Enter/E để tiếp, Esc để bỏ
##    qua. Cần cho hội đồng chấm: máy chiếu hay dùng bàn phím, và cũng là
##    một gạch đầu dòng về khả năng tiếp cận (accessibility) khi thuyết trình.

## Giá trị đặc biệt của khoá "ai": lấy tên theo id nhân vật đang hiện ảnh.
const TEN_TU_DONG := "@"

## Kịch bản nạp LÚC CHẠY theo đường dẫn ở @export, không preload cứng.
##
## Vì sao đổi: cùng một bộ máy này giờ chạy hai đoạn kể khác nhau — prologue
## và màn ra mắt của Gold Ship — và sau này còn thêm nữa. preload cứng thì
## mỗi đoạn kể phải một bản sao script, tức là sửa lỗi ở bộ máy phải sửa
## nhiều chỗ. Nạp lúc chạy thì MỘT script, mỗi scene chỉ khác cái đường dẫn
## điền trong Inspector.

## Bảng ảnh chân dung: id trong kịch bản -> file ảnh.
##
## Vì sao dùng BẢNG TRA chứ không ghép chuỗi "res://.../%s.png":
##  1. Tên file thật không khớp id nhân vật. Id trong GameData là "kitamoi",
##     "chiyo"; file ảnh lại là "kita_avt.png", "chiyono_avt.png". Ghép chuỗi
##     thì buộc phải đổi tên một trong hai bên — mà id đã nằm trong file save
##     của người chơi, đổi id là hỏng save cũ.
##  2. Đuôi file không đồng nhất: nhân vật là .png có nền trong, còn ông
##     trainer là .jpg. Ghép chuỗi chỉ đoán được một đuôi.
##  3. Kịch bản có thể gọi cả những nhân vật KHÔNG chơi được (trainer, golshi)
##     — họ không có mặt trong GameData.CHARACTERS nên không có id để ghép.
## Thêm nhân vật mới cho đoạn kể chuyện = thêm một dòng ở đây.
const ANH_NHAN_VAT := {
	# Các nhân vật có chân dung — id trùng với GameData.CHARACTERS.
	# hachimi và chiyo giữ lại dù đã thành nhân vật ẩn: về sau mở khoá xong
	# vẫn cần ảnh để họ nói chuyện được trong các đoạn kể.
	"kitamoi": "res://assets/ui/avatars/kita_avt.png",
	"hachimi": "res://assets/ui/avatars/hachimi_avt.png",
	"chiyo": "res://assets/ui/avatars/chiyono_avt.png",
	"mambo": "res://assets/ui/avatars/mambo_avt.png",
	# Hai người thế chỗ Teio và Chiyono O trong đội hình chính.
	"oui": "res://assets/ui/avatars/oui_avt.png",
	"tuandb": "res://assets/ui/avatars/tuandb_avt.png",
	# Nhân tố G. Không cần bản bóng đen nữa: Gold Ship đã bị gỡ khỏi cốt
	# truyện chính, nên đoạn kể duy nhất cô ấy xuất hiện (golshi_xuat_hien)
	# chỉ chạy khi ĐÃ mở khoá — không còn tình huống nào phải giấu mặt.
	"golshi": "res://assets/ui/avatars/golshi_avt.png",
	# Huấn luyện viên: hai biểu cảm, dùng cái nào tuỳ tình huống.
	"trainer": "res://assets/ui/avatars/trainer_avt1.png",
	"trainer2": "res://assets/ui/avatars/trainer_avt2.png",
}

## Tốc độ gõ chữ (ký tự mỗi giây).
##
## 45 là khoảng giữa: chậm hơn thì người đọc nhanh phát bực và bấm liên tục
## để nhảy cóc, nhanh hơn thì mất hẳn cảm giác "có người đang nói".
@export var toc_do_go: float = 45.0
## Thời gian tối/sáng khi đổi ảnh nền (giây, cho MỘT chiều).
@export var thoi_gian_chuyen_canh: float = 0.35

## Nhóm nhạc nền cho đoạn kể này, theo AmThanh.NHOM_NHAC. RỖNG = không đụng
## tới nhạc đang phát.
##
## Vì sao là tên NHÓM chứ không phải tên bài: đoạn cắt cảnh Gold Ship dùng
## chung script này nhưng chen vào GIỮA màn chơi — nó phải để yên bài nhạc
## màn đang chạy, nên ô này của nó để rỗng. Còn Prologue mở đầu game thì cần
## bài riêng. Cùng một script, hai hành vi, không có nhánh if nào.
##
## Dùng nhóm thay vì gõ thẳng "bgm2_ura": sau này muốn Prologue bốc ngẫu nhiên
## trong ba bài thì chỉ thêm tên vào nhóm "prologue" bên AmThanh.
@export var nhom_nhac: String = ""
## File kịch bản của đoạn kể này.
@export_file("*.gd") var duong_dan_kich_ban: String = "res://scripts/cot_truyen/kich_ban_prologue.gd"

## Màn sẽ vào sau khi kể xong. ĐỂ TRỐNG nghĩa là "đi tiếp tới màn người chơi
## đang chọn dở" — đó là trường hợp của đoạn cắt cảnh chen giữa (Gold Ship
## đạp cửa), nó chỉ chèn vào giữa đường chứ không tự quyết định đi đâu.
@export var man_tiep_theo: String = ""

## Đánh dấu màn nào đã hoàn thành khi kể xong. Để trống thì không đánh dấu gì.
## Prologue cần đánh dấu để Tutorial đủ điều kiện mở khoá theo luật "needs";
## đoạn cắt cảnh thì không, vì nó không phải một màn chơi.
@export var danh_dau_hoan_thanh: String = ""

@onready var _nen: TextureRect = %Nen
@onready var _phu_mau: ColorRect = %PhuMau
@onready var _anh: TextureRect = %Anh
## Khung xếp NHIỀU chân dung cạnh nhau, dùng cho câu đồng thanh.
##
## Một node riêng chứ không biến %Anh thành container: 39 trong 41 câu của
## prologue chỉ có MỘT người nói, và %Anh đang được canh sẵn ở góc trái với
## kích thước cố định. Đổi %Anh thành container thì một chân dung sẽ bị căn
## giữa lại — tức là sửa một câu đặc biệt mà làm xê dịch bốn mươi câu bình
## thường. Hai node, mỗi node một việc, không câu nào ảnh hưởng câu nào.
@onready var _anh_nhom: HBoxContainer = %AnhNhom

## Chân dung trong khung nhóm không được cao hơn bấy nhiêu pixel.
const CAO_NHOM_TOI_DA := 620.0
@onready var _lbl_ten: Label = %LblTen
@onready var _lbl_loi: RichTextLabel = %LblLoi
@onready var _mui_ten: Label = %MuiTen
@onready var _btn_bo_qua: Button = %BtnBoQua

## Nội dung kịch bản đã nạp.
var _man: Array = []
## Id nhân vật đang hiện ảnh, đã quy đổi hết mọi id đặc biệt.
##
## Phải NHỚ chứ không đọc lại từ câu hiện tại, vì khoá "anh" là tuỳ chọn: một
## người nói liền mấy câu thì chỉ câu đầu ghi "anh". Không nhớ thì từ câu thứ
## hai trở đi bộ máy hết biết ai đang nói và "ai": "@" sẽ trống.
var _id_dang_hien: String = ""
## Ai được bốc làm "người khác". Bốc MỘT LẦN rồi nhớ suốt đoạn kể — nếu bốc
## lại mỗi câu thì hai câu liền nhau của cùng một người lại ra hai khuôn mặt.
var _id_khac: String = ""
var _chi_so: int = -1
## Đang gõ chữ hay đã gõ xong — biến quyết định cú bấm tiếp theo làm gì.
var _dang_go: bool = false
var _da_hien: float = 0.0
## Khoá nhập trong lúc chuyển cảnh, để bấm dồn không làm nhảy mất một câu.
var _dang_chuyen: bool = false


func _ready() -> void:
	if not nhom_nhac.is_empty():
		AmThanh.nhac_ngau_nhien(nhom_nhac)
	_nap_kich_ban()
	_phu_mau.color = Color(0, 0, 0, 1)
	_anh.modulate.a = 0.0
	_anh_nhom.modulate.a = 0.0
	_lbl_loi.visible_characters = 0
	_btn_bo_qua.pressed.connect(_bo_qua)

	# Mũi tên ▼ nhấp nháy báo "đọc xong rồi, bấm đi". Dùng tween lặp vô hạn
	# thay vì tự đếm thời gian trong _process: ít code hơn và không tốn gì
	# khi mũi tên đang ẩn.
	var nhap_nhay := create_tween().set_loops()
	nhap_nhay.tween_property(_mui_ten, "modulate:a", 0.15, 0.55)
	nhap_nhay.tween_property(_mui_ten, "modulate:a", 1.0, 0.55)

	# Mở màn bằng một lần sáng dần từ đen, cho đỡ giật khi vừa đổi scene.
	var mo := create_tween()
	mo.tween_property(_phu_mau, "color:a", 0.0, thoi_gian_chuyen_canh)
	await mo.finished
	_sang_cau_tiep()


## Nạp kịch bản. Hỏng file thì bỏ qua cả đoạn kể chứ KHÔNG treo game ở màn
## hình đen — người chơi vẫn vào được màn chơi, và console nói rõ file nào sai.
func _nap_kich_ban() -> void:
	var duong_dan := _kich_ban_theo_ngon_ngu(duong_dan_kich_ban)
	var kb := load(duong_dan) as GDScript
	if kb == null:
		push_error("Không nạp được kịch bản: %s" % duong_dan)
		return
	var v: Variant = kb.get("MAN")
	if v is Array:
		_man = v
	else:
		push_error("Kịch bản %s thiếu hằng MAN." % duong_dan)


## Chọn file kịch bản theo ngôn ngữ đang bật, theo quy ước tên file:
##     kich_ban_prologue.gd     -> tiếng Việt (bản gốc, không hậu tố)
##     kich_ban_prologue_en.gd  -> tiếng Anh
##
## Vì sao hội thoại KHÔNG đi qua translations.csv như phần giao diện:
##  1. CSV là bảng một dòng một ô. Hội thoại là văn xuôi dài, có dấu phẩy,
##     dấu ngoặc kép, xuống dòng — nhét vào CSV thì vừa phải escape lắt nhắt
##     vừa không đọc nổi để mà biên tập lại lời thoại.
##  2. Kịch bản không chỉ có chữ: mỗi câu còn mang khoá "ai"/"anh"/"nen".
##     Dịch xong vẫn phải giữ nguyên cấu trúc đó, nên giữ nguyên định dạng
##     mảng dữ liệu là cách rẻ nhất.
##  3. Người dịch làm việc trên FILE RIÊNG, không đụng vào bản tiếng Việt —
##     dịch sai cũng không làm hỏng bản gốc.
##
## Chưa có bản dịch thì rơi về bản gốc chứ không để màn hình trống: thiếu
## bản dịch là chuyện bình thường trong lúc làm dở, không phải lỗi chí mạng.
func _kich_ban_theo_ngon_ngu(duong_dan: String) -> String:
	var ma := TranslationServer.get_locale().substr(0, 2)
	if ma == SettingsManager.NGON_NGU_MAC_DINH:
		return duong_dan
	var ban_dich := duong_dan.get_basename() + "_" + ma + ".gd"
	if ResourceLoader.exists(ban_dich):
		return ban_dich
	push_warning("Chưa có bản dịch '%s' — dùng tạm kịch bản gốc." % ban_dich)
	return duong_dan


func _process(delta: float) -> void:
	if not _dang_go:
		return
	_da_hien += toc_do_go * delta
	_lbl_loi.visible_characters = int(_da_hien)
	if _lbl_loi.visible_characters >= _lbl_loi.get_total_character_count():
		_go_xong()


# ----------------------------------------------------------------- nhập ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_cham()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_bo_qua()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_cham()
		get_viewport().set_input_as_handled()


## Điểm vào duy nhất của mọi cú "chạm", dù từ chuột hay bàn phím.
## Gom về một hàm để hai đường nhập không bao giờ lệch hành vi nhau.
func _cham() -> void:
	if _dang_chuyen:
		return
	if _dang_go:
		_go_xong()
	else:
		_sang_cau_tiep()


func _go_xong() -> void:
	_dang_go = false
	_lbl_loi.visible_characters = -1  # -1 = hiện tất cả
	_mui_ten.show()


# ----------------------------------------------------------- diễn kịch ---

func _sang_cau_tiep() -> void:
	_chi_so += 1
	if _chi_so >= _man.size():
		_ket_thuc()
		return

	var cau: Dictionary = _man[_chi_so]

	if cau.has("nen"):
		await _doi_nen(String(cau["nen"]))

	if cau.has("anh"):
		_doi_anh(cau["anh"])

	var ten := String(cau.get("ai", ""))
	if ten == TEN_TU_DONG:
		ten = _ten_hien_thi(_id_dang_hien)
	_lbl_ten.text = ten
	# Lời dẫn truyện không có người nói -> ẩn hẳn thẻ tên thay vì để một ô
	# trống. Ô trống làm hộp thoại nhảy lên nhảy xuống mỗi câu, rất khó chịu.
	_lbl_ten.visible = not ten.is_empty()

	_lbl_loi.text = String(cau.get("loi", ""))
	_lbl_loi.visible_characters = 0
	_da_hien = 0.0
	_dang_go = true

	# Tiếng gõ chữ: ĐÚNG MỘT LẦN cho mỗi câu, và CHỈ khi có người nói.
	#
	# Kịch bản có hai loại câu, phân biệt bằng khoá "ai":
	#   có "ai"     — một nhân vật đang NÓI. Kêu.
	#   không "ai"  — lời dẫn truyện ("Rồi cửa trước bật tung."). Im.
	#
	# Vì sao phân biệt: tiếng đó là tiếng CỦA MỘT NGƯỜI đang nói, nên gắn nó
	# vào lời dẫn là gán giọng cho một người không tồn tại. Trong prologue,
	# lời dẫn xen giữa các câu thoại để đổi nhịp — chính những quãng lặng đó
	# làm nên nhịp, mà kêu ở mọi câu thì quãng lặng biến mất và cả đoạn thành
	# một chuỗi tiếng đều đều.
	#
	# Dùng lại đúng biến `ten` đã tính ở trên chứ không đọc lại cau["ai"]:
	# "ai" có thể là TEN_TU_DONG (tên người chơi đang chọn), và câu đó VẪN là
	# một người đang nói. Đọc lại khoá gốc thì nhánh đó bị coi nhầm là lời dẫn.
	#
	# Đặt ở đây chứ không trong _process: đây là chỗ duy nhất một câu mới bắt
	# đầu, nên không cần cờ "đã kêu chưa" nào cả. Bấm nhảy cóc để hiện hết
	# dòng cũng không kêu thêm lần nữa, vì nhánh đó không đi qua đây.
	#
	# Bản đầu còn phát LẶP theo nhịp trong lúc chữ chạy — đúng kiểu máy chữ
	# nhưng nghe nhức đầu: prologue dài mấy chục dòng, và chuỗi tiếng "cạch"
	# liên tục cạnh tranh trực tiếp với thứ người chơi đang phải làm ở đó —
	# ĐỌC. Tiếng động trong game kể chuyện nên đánh dấu SỰ KIỆN, không mô tả
	# quá trình.
	if not ten.is_empty():
		AmThanh.go_chu()
	_mui_ten.hide()


## Tên hiện trên thẻ tên ứng với một id nhân vật.
##
## LUÔN trả về tên riêng, kể cả với nhân vật người chơi đang điều khiển.
##
## Bản trước đổi tên người chơi thành "Bạn" để tránh cảnh một nhân vật vừa
## xưng "Bạn" vừa mang tên riêng trong cùng một đoạn. Nhưng cách đó đánh đổi
## quá đắt: người chơi không còn thấy nhân vật mình chọn CÓ TÊN trong cốt
## truyện, và mọi câu thoại phải viết sao cho vừa hợp ngôi thứ nhất vừa hợp
## ngôi thứ ba. Các game nhập vai có nhân vật chọn được (Fire Emblem,
## Persona, Octopath) đều gọi thẳng tên riêng và xử lý mạch lạc bằng cách
## VIẾT KỊCH BẢN cho khéo — không ai gọi nhân vật chính là "Bạn".
##
## Đổi lại, kịch bản phải giữ một luật: câu nào mà người nói không thể là
## chính người chơi (khen chính mình, chỉ trích chính mình) thì dùng
## "anh": "khac" để bốc người khác. Luật đó nằm ở tầng dữ liệu, đúng chỗ của
## nó — bộ máy không phải đoán ngôi xưng hộ người viết truyện nữa.
func _ten_hien_thi(id: String) -> String:
	if id.is_empty():
		return ""
	return String(GameData.CHARACTERS.get(id, {}).get("label", id))


func _doi_nen(duong_dan: String) -> void:
	_dang_chuyen = true
	var tex := load(duong_dan) as Texture2D
	# Tối dần -> đổi ảnh -> sáng lại. Đổi thẳng thì hình nhảy phựt một cái,
	# nhìn như lỗi chứ không như chuyển cảnh.
	var tw := create_tween()
	tw.tween_property(_phu_mau, "color:a", 1.0, thoi_gian_chuyen_canh)
	await tw.finished
	if tex != null:
		_nen.texture = tex
	var tw2 := create_tween()
	tw2.tween_property(_phu_mau, "color:a", 0.0, thoi_gian_chuyen_canh)
	await tw2.finished
	_dang_chuyen = false


## Quy đổi các id đặc biệt trong kịch bản thành id nhân vật thật.
##
## "player" — nhân vật người chơi đã chọn. Nhờ quy ước này mà kịch bản viết
##            MỘT lần dùng được cho cả bốn nhân vật, không phải chép ra bốn
##            bản chỉ khác mỗi cái ảnh.
## "khac"   — BẤT KỲ AI TRỪ người chơi. Cần cho những câu mà nội dung không
##            cho phép người nói là chính mình: câu khen "cậu nấu ngon nhất
##            team" mà người chơi chọn Kitasan thì thành Kitasan tự khen
##            mình. Đây là loại lỗi không bao giờ lộ ra khi thử một lượt —
##            phải chơi đúng nhân vật đó mới thấy — nên để kịch bản tự tránh
##            bằng cách viết cứng tên là không đủ an toàn.
func _giai_id(id: String) -> String:
	if id == "player":
		return GameData.selected_character
	if id == "khac":
		return _nguoi_khac()
	return id


## Bốc một nhân vật chơi được, khác người chơi, và có sẵn ảnh chân dung.
func _nguoi_khac() -> String:
	if not _id_khac.is_empty():
		return _id_khac
	var ung_vien: Array[String] = []
	for k in GameData.CHARACTER_ORDER:
		var id := str(k)
		if id == GameData.selected_character:
			continue
		# Bỏ qua nhân vật đang khoá: Gold Ship không có mặt trong cốt truyện
		# chính, để cô ấy chen vào một câu thoại bình thường là hỏng cả ý đồ
		# giấu nhân vật.
		if GameData.is_character_locked(id):
			continue
		if not ANH_NHAN_VAT.has(id):
			continue
		ung_vien.append(id)
	if ung_vien.is_empty():
		# Không còn ai khác — chỉ xảy ra nếu sau này chỉ còn một nhân vật
		# chơi được. Thà hiện chính người chơi còn hơn mất cả câu thoại.
		push_warning("Không tìm được nhân vật nào khác người chơi.")
		return GameData.selected_character
	_id_khac = ung_vien.pick_random()
	return _id_khac


## Đổi chân dung đang hiện.
##
## Nhận MỘT id (chuỗi) như cũ, hoặc MỘT MẢNG id cho câu đồng thanh. Cho phép
## cả hai kiểu chứ không bắt kịch bản lúc nào cũng viết mảng: gần như mọi câu
## chỉ có một người nói, ["kitamoi"] dài dòng hơn "kitamoi" mà chẳng rõ hơn.
func _doi_anh(gia_tri: Variant) -> void:
	var ds: Array = gia_tri if gia_tri is Array else [gia_tri]
	# Giải id TRƯỚC rồi mới lọc: "player" và "khac" chỉ tới lúc chạy mới biết
	# là ai, mà "khac" còn có thể trùng với một id đã ghi thẳng trong mảng.
	var thuc: Array[String] = []
	for x in ds:
		var id := _giai_id(String(x))
		if id.is_empty() or thuc.has(id):
			continue
		if not ANH_NHAN_VAT.has(id):
			# Gõ sai id thì chỉ bỏ qua ảnh đó chứ KHÔNG dừng đoạn kể. Kịch bản
			# là dữ liệu do người viết truyện gõ tay, sai một id không đáng để
			# cả game đứng lại — nhưng vẫn phải kêu lên console để còn biết mà
			# sửa.
			push_warning("Kịch bản gọi id nhân vật không có trong ANH_NHAN_VAT: '%s'" % id)
			continue
		var duong_dan := String(ANH_NHAN_VAT[id])
		if not ResourceLoader.exists(duong_dan):
			push_warning("Thiếu file ảnh: %s" % duong_dan)
			continue
		thuc.append(id)

	# Câu đồng thanh không có MỘT người nói, nên "ai": "@" phải ra chuỗi rỗng
	# (thẻ tên tự ẩn) thay vì chọn bừa một trong mấy người đang hiện mặt.
	_id_dang_hien = thuc[0] if thuc.size() == 1 else ""

	if thuc.is_empty():
		_an_chan_dung()
		return

	if thuc.size() == 1:
		_hien_dan(_anh_nhom, false)
		_anh.texture = load(String(ANH_NHAN_VAT[thuc[0]]))
		_hien_dan(_anh, true)
		return

	_hien_dan(_anh, false)
	_dung_nhom(thuc)
	_hien_dan(_anh_nhom, true)


## Dựng lại dãy chân dung của câu đồng thanh.
##
## remove_child + free() chứ không queue_free(): queue_free chỉ xoá ở CUỐI
## khung hình, nên ảnh của câu trước vẫn còn trong hàng khi ảnh mới được thêm
## vào — hai câu đồng thanh liền nhau sẽ thấy tám khuôn mặt trong một khung.
func _dung_nhom(ds: Array[String]) -> void:
	for con in _anh_nhom.get_children():
		_anh_nhom.remove_child(con)
		con.free()
	_canh_day_nhom(ds.size())
	for id in ds:
		var o := TextureRect.new()
		o.texture = load(String(ANH_NHAN_VAT[id]))
		o.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		o.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_anh_nhom.add_child(o)


## Kéo MÉP TRÊN của khung nhóm lên đúng bằng bề ngang một ảnh.
##
## Chân dung là ảnh VUÔNG (512×512) và vẽ bằng KEEP_ASPECT_CENTERED, nên nó
## chỉ cao đúng bằng bề ngang ô chứa nó. Khung cao hơn thế thì phần dư chia
## đều trên–dưới, và cái nửa dư phía DƯỚI đẩy ảnh lên lơ lửng giữa không khí,
## để lộ nguyên đường cắt ngang ngực. Ảnh đơn không bị vì khung của nó vừa
## khít sẵn.
##
## Tính chứ không gõ cứng một con số: bề ngang mỗi ảnh phụ thuộc SỐ ẢNH (bốn
## người thì mỗi ảnh 445 px, hai người thì 910 px), nên một con số cố định chỉ
## đúng cho đúng một trường hợp.
##
## Mép DƯỚI thì giữ nguyên ở -210, cùng mốc với ảnh đơn: đáy ảnh nằm thấp hơn
## nóc hộp thoại vài chục pixel nên đường cắt bị hộp che đi.
func _canh_day_nhom(so_anh: int) -> void:
	if so_anh <= 0:
		return
	var cach := float(_anh_nhom.get_theme_constant("separation"))
	# Khung neo trái 0 / phải 1, nên bề ngang = rộng màn hình trừ hai lề.
	var rong := get_viewport_rect().size.x + _anh_nhom.offset_right - _anh_nhom.offset_left
	var rong_moi := (rong - cach * (so_anh - 1)) / float(so_anh)
	# Chặn trên để hai người không thành hai bức chân dung cao quá đầu.
	_anh_nhom.offset_top = _anh_nhom.offset_bottom - minf(rong_moi, CAO_NHOM_TOI_DA)


func _an_chan_dung() -> void:
	_hien_dan(_anh, false)
	_hien_dan(_anh_nhom, false)


## Mờ dần vào/ra.
##
## Ẩn bằng ALPHA chứ không tắt visible. Bản đầu có tắt: `await` cho tween mờ
## hết rồi mới `visible = false`. Nhưng như thế là gài sẵn một lỗi — cái lệnh
## tắt đó chạy TRỄ 0,2 giây so với lúc gọi, nên nếu trong quãng đó có câu mới
## bật cùng node lên thì lệnh tắt cũ vẫn nổ và làm biến mất bức ảnh vừa hiện.
## Loại lỗi chỉ lộ ra khi bấm nhanh, tức là gần như không bao giờ lộ lúc mình
## tự thử.
##
## Bỏ hẳn phần tắt thì không còn trạng thái nào để lệch: node cứ nằm đó với
## alpha 0. Không tốn gì cả — nó neo tuyệt đối chứ không nằm trong container
## nên chẳng chiếm chỗ của ai, và mouse_filter đã đặt IGNORE nên không chắn
## cú bấm nào.
func _hien_dan(nut: CanvasItem, hien: bool) -> void:
	nut.visible = true
	var tw := create_tween()
	tw.tween_property(nut, "modulate:a", 1.0 if hien else 0.0, 0.25 if hien else 0.2)


# --------------------------------------------------------------- kết thúc ---

func _bo_qua() -> void:
	if _dang_chuyen:
		return
	_ket_thuc()


func _ket_thuc() -> void:
	_dang_chuyen = true
	_dang_go = false
	var tw := create_tween()
	tw.tween_property(_phu_mau, "color:a", 1.0, thoi_gian_chuyen_canh)
	await tw.finished

	# Đánh dấu đã xem xong thì màn kế mới đủ điều kiện mở khoá theo đúng luật
	# "needs" trong GameData.LEVELS — không phá lệ, không đi cửa sau.
	if not danh_dau_hoan_thanh.is_empty():
		GameData.complete_level(danh_dau_hoan_thanh)
	if not man_tiep_theo.is_empty():
		GameData.current_level = man_tiep_theo

	var duong_dan := GameData.vao_man(GameData.current_level)
	if duong_dan.is_empty():
		push_error("Màn '%s' chưa khai báo scene trong GameData.LEVELS." % GameData.current_level)
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		return
	get_tree().change_scene_to_file(duong_dan)
