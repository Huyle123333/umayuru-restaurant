extends Node
## Quản lý kĩ năng chủ động của nhân vật người chơi.
##
## Node này sở hữu BA thứ, và chỉ ba thứ đó:
##   1. Trạng thái "kĩ năng chủ động còn dùng được không" (còn mấy lượt, đã
##      đủ điều kiện chưa) và tín hiệu báo ra HUD.
##   2. Điểm vào duy nhất của phím Space.
##   3. Việc ÁP số kĩ năng vào các hệ khác lúc vào màn.
##
## Nó KHÔNG tự thi hành hiệu ứng. Hiệu ứng nằm ở nơi có luật: thanh kiên nhẫn
## là chuyện của quan_ly_khach, mốc cháy là chuyện của bep_nau. Node này chỉ
## VẶN NÚM của chúng một lần lúc vào màn (bị động) hoặc một lần lúc bấm Space
## (chủ động).
##
## Vì sao không để hiệu ứng chạy trong này: nếu ở đây thì mỗi lần tính tiền
## một đơn, quan_ly_khach phải đi hỏi ngược "kĩ năng có đang bật không" — tức
## hệ khách hàng phụ thuộc vào hệ kĩ năng. Vặn núm thì phụ thuộc chỉ đi MỘT
## chiều, đúng một lần, và quan_ly_khach chạy y hệt nhau dù có hệ kĩ năng hay
## không.
##
## ──────────────────────────── KĨ NĂNG CHỈ ĂN KHI DÙNG ĐÚNG NHÂN VẬT ĐÓ
##
## Mọi con số lấy từ BangKiNang theo GameData.selected_character. Chọn nhân
## vật khác — hoặc chạy thẳng map bằng F6 khi chưa chọn ai — thì bảng trả về
## bộ số mặc định (nhân 1,0, cộng 0,0), tức màn chơi chạy đúng bằng số gốc
## của game. Không có nhánh riêng nào cho trường hợp "không có kĩ năng".

## Phát mỗi khi trạng thái sẵn sàng đổi. HUD nghe để tô màu hoặc tô xám ảnh.
signal san_sang_doi(san_sang: bool)

## Phát cùng lúc với san_sang_doi, mang phần SỐ của điều kiện để HUD vẽ thanh.
##   ti_le  0…1, đã kẹp sẵn — 1,0 nghĩa là đủ điều kiện
##   chu    chữ hiện cạnh thanh: "3/5", "SPACE", "Đã dùng", hoặc RỖNG
##
## Chữ RỖNG là tín hiệu cho HUD ẨN hẳn thanh: nhân vật này chưa có kĩ năng chủ
## động, hoặc điều kiện thuộc loại chưa đếm được. Vẽ một thanh luôn đứng ở 0
## thì người chơi tưởng mình đang không tiến bộ, tệ hơn là không vẽ gì cả.
##
## Vì sao TÁCH khỏi san_sang_doi thay vì nhồi thêm tham số: san_sang_doi đã có
## một nơi nghe và chỉ quan tâm bật/tắt. Thêm tham số là sửa cả bên nghe cũ cho
## một thứ nó không dùng.
signal tien_do_doi(ti_le: float, chu: String)

const LopCutIn := "res://scripts/ki_nang/cut_in_ki_nang.gd"
const Bang := preload("res://scripts/ki_nang/bang_ki_nang.gd")

## Mỗi màn được dùng bao nhiêu lần.
##
## Theo bảng kĩ năng đã chốt: hầu hết kĩ năng chủ động dùng MỘT lần mỗi màn.
## Hai ngoại lệ (Triumphant Pulse của Oguri bật/tắt trong ngân sách 30 giây,
## Ambition của Chiyono O không giới hạn) sẽ khai báo riêng khi làm phần hiệu
## ứng — để ở đây một con số chung là đủ cho phần trình diễn.
@export var so_lan_moi_man := 1

var _con_lai := 0
var _dang_chieu := false
## Nhân vật đang điều khiển, để khoá di chuyển trong lúc chiếu.
var _nhan_vat: Node = null

## Hệ khách hàng và hệ bếp của màn. Node này CHỈ ghi vào chúng, không đọc
## trạng thái nào của chúng ngoài mấy bộ đếm dùng để xét điều kiện.
var _ql: Node = null
var _bep: Node = null
## Đồng hồ màn (BangThoiGian). Có thể null — màn hướng dẫn không có đồng hồ.
## Chưa kĩ năng nào của Kita dùng tới; để sẵn cho Oguri, Teio và Chiyono O,
## cả ba đều đụng vào thời gian màn chơi.
var _gio: Node = null

## Hiệu ứng viết riêng đang chạy (thực thể của một file trong hieu_ung/).
## null nghĩa là kĩ năng này dùng hiệu ứng có sẵn, hoặc chưa bấm.
var _hieu_ung: RefCounted = null

## Mô tả kĩ năng chủ động của nhân vật đang chơi, lấy từ BangKiNang. RỖNG
## nghĩa là nhân vật này chưa có kĩ năng chủ động — Space không làm gì cả.
var _chu_dong: Dictionary = {}


func _ready() -> void:
	_con_lai = so_lan_moi_man
	# Node này phải nhận phím kể cả khi cây scene bị dừng thì mới không bị
	# kẹt nếu sau này có thứ khác dừng game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bật/tắt cheat trong bảng CODE No.7 phải làm ảnh trên HUD đổi màu ngay,
	# không đợi tới lần bấm phím tiếp theo.
	GameData.progress_changed.connect(_bao_trang_thai)
	# Đợi một frame rồi mới báo trạng thái đầu tiên: HUD được tạo cùng lúc với
	# node này nên lúc _ready chạy, tín hiệu chưa chắc đã nối xong.
	call_deferred("_bao_trang_thai")


func theo_doi_nhan_vat(nv: Node) -> void:
	_nhan_vat = nv


## Kĩ năng có đang bấm được không.
##
## Cheat "kĩ năng vô hạn" bỏ qua MỌI điều kiện. Ở thời điểm hiện tại đây là
## cách bình thường để xem cut-in, vì điều kiện thật đều gắn với hệ đơn hàng
## mà hệ đó chưa tồn tại.
func co_the_dung() -> bool:
	if _dang_chieu:
		return false
	# Cheat vẫn phải tôn trọng "nhân vật này chưa có kĩ năng": cho bấm được
	# thì cut-in chiếu ra một kĩ năng không tồn tại, và người thử sẽ tưởng nó
	# đã cài xong.
	if _chu_dong.is_empty() and not bo_qua_dieu_kien:
		return false
	if GameData.ki_nang_vo_han:
		return true
	if _con_lai <= 0:
		return false
	return _du_dieu_kien()


## Điều kiện riêng của từng nhân vật đã đạt chưa.
##
## HIỆN TẠI LUÔN TRẢ VỀ FALSE, và đó là câu trả lời ĐÚNG chứ không phải chỗ
## làm dở: điều kiện thật của cả bảy kĩ năng đều đếm đơn hàng (5 đơn hoàn hảo,
## 3 đơn có steak, 5 đơn có dough…) hoặc đếm thời gian màn chơi — không có
## thứ nào tồn tại. Chưa đếm được thì chưa ai đạt.
##
## Bản trước tôi để `return true` cho tiện thử, nhưng như vậy là NÓI DỐI giao
## diện: ảnh kĩ năng sáng lên ngay khi vào màn dù cheat đang tắt, tức là HUD
## báo một trạng thái mà cơ chế không hề có. Một cái đèn báo sai còn tệ hơn
## không có đèn — nó dạy người chơi (và cả người viết code) tin vào thứ không
## đúng.
##
## Muốn thử cut-in thì có hai đường, cả hai đều nói thật về trạng thái:
##   - Bật cheat "Kĩ năng không cần điều kiện" trong bảng CODE No.7.
##   - Hoặc bật cờ dưới đây, dành cho lúc cần test mà không muốn mở cheat.
@export var bo_qua_dieu_kien := false


func _du_dieu_kien() -> bool:
	if bo_qua_dieu_kien:
		return true
	if _chu_dong.is_empty() or _ql == null:
		return false
	var moc := int(_chu_dong.get("moc", 0))
	match String(_chu_dong.get("dieu_kien", "")):
		Bang.DK_DON_HOAN_HAO:
			return int(_ql.so_don_hoan_hao) >= moc
		Bang.DK_DON_XONG:
			return int(_ql.so_don_xong) >= moc
	# Bốn kiểu điều kiện còn lại (đếm món nấu, đếm giây, cho pet ăn, phủ kín
	# thực đơn) chưa có bộ đếm nào trong game. Trả false là câu trả lời ĐÚNG:
	# chưa đếm được thì chưa ai đạt. Trả true cho tiện thử là nói dối giao
	# diện — ảnh kĩ năng sáng lên trong khi cơ chế không hề có.
	return false


## Tiến độ điều kiện, dạng "3/5". Rỗng khi nhân vật chưa có kĩ năng chủ động
## hoặc điều kiện thuộc loại chưa đếm được.
##
## Đặt ở đây chứ không để HUD tự đếm: luật đếm là luật của kĩ năng, và HUD
## không được phép biết "5 đơn hoàn hảo" nghĩa là gì.
##
## Trả về "3/5". Rỗng khi nhân vật chưa có kĩ năng chủ động hoặc điều kiện
## thuộc loại chưa đếm được — nơi gọi hiểu rỗng là "không có gì để hiện".
func tien_do() -> String:
	var n := _dem_dieu_kien()
	if n < 0:
		return ""
	return "%d/%d" % [mini(n, int(_chu_dong.get("moc", 0))),
		int(_chu_dong.get("moc", 0))]


## Tỉ lệ hoàn thành điều kiện, 0…1 đã kẹp sẵn. Trả 0 khi không đếm được.
func ti_le_dieu_kien() -> float:
	var n := _dem_dieu_kien()
	var moc := int(_chu_dong.get("moc", 0))
	if n < 0 or moc <= 0:
		return 0.0
	return clampf(float(n) / float(moc), 0.0, 1.0)


## Bộ đếm hiện tại của điều kiện, hoặc -1 nếu không đếm được.
##
## Gom vào MỘT hàm rồi để tien_do() và ti_le_dieu_kien() cùng gọi, thay vì mỗi
## hàm tự `match` một lần: hai bản sao của cùng một bảng tra thì thêm một loại
## điều kiện mới là hai chỗ phải nhớ sửa, và quên một chỗ thì thanh với con số
## nói hai điều khác nhau.
func _dem_dieu_kien() -> int:
	if _chu_dong.is_empty() or _ql == null:
		return -1
	match String(_chu_dong.get("dieu_kien", "")):
		Bang.DK_DON_HOAN_HAO:
			return int(_ql.so_don_hoan_hao)
		Bang.DK_DON_XONG:
			return int(_ql.so_don_xong)
	return -1


## Gắn vào màn chơi: áp các kĩ năng BỊ ĐỘNG và bắt đầu theo dõi điều kiện.
##
## Gọi SAU khi quan_ly_khach và he_bep đã tồn tại — cả hai đều là thứ node này
## vặn núm. level_base lo thứ tự đó.
##
## Vì sao áp bị động ở đây chứ không để mỗi hệ tự đi hỏi bảng kĩ năng: nếu mỗi
## hệ tự hỏi thì quan_ly_khach phải biết tới BangKiNang, bep_nau cũng vậy, và
## thêm một kĩ năng mới là thêm một hệ nữa phải biết. Vặn núm từ một chỗ thì
## các hệ kia chỉ cần có sẵn một biến số — chúng không biết kĩ năng là gì.
func chuan_bi(ql_khach: Node, he_bep: Node, dong_ho: Node = null) -> void:
	_ql = ql_khach
	_bep = he_bep
	_gio = dong_ho
	var id := String(GameData.selected_character)
	_chu_dong = Bang.chu_dong(id)
	# Số lượt lấy từ file kĩ năng của nhân vật, không phải từ @export ở đây:
	# hai kĩ năng có luật riêng (Oguri bật/tắt trong ngân sách 30 giây,
	# Chiyono O không giới hạn) và luật đó thuộc về kĩ năng chứ không thuộc
	# về cái node quản lý.
	_con_lai = int(_chu_dong.get("so_lan", so_lan_moi_man))
	_ap_dung_bi_dong(Bang.bi_dong(id))

	# Điều kiện của Kita đếm ĐƠN, nên chỉ cần xem lại trạng thái mỗi khi một
	# đơn kết thúc — không phải kiểm tra mỗi khung hình. Với những điều kiện
	# đếm THỜI GIAN sau này (Oguri) thì sẽ cần thêm một nhịp kiểm tra riêng.
	if _ql != null and _ql.has_signal("don_ket_thuc"):
		_ql.don_ket_thuc.connect(_khi_don_ket_thuc)
	_bao_trang_thai()


## Vặn núm của các hệ khác theo bộ số bị động.
##
## Dùng CỘNG/NHÂN vào giá trị đang có chứ không GÁN ĐÈ: luật màn (luat_man.gd)
## cũng đặt vài con số của quan_ly_khach, và gán đè thì thứ tự gọi quyết định
## ai thắng — một phụ thuộc ngầm sẽ hỏng lặng lẽ vào ngày ai đó đổi thứ tự
## dựng node trong level_base.
func _ap_dung_bi_dong(bs: Dictionary) -> void:
	if _ql != null:
		_ql.he_so_kien_nhan = float(bs["he_so_kien_nhan"])
		_ql.thuong_hoan_hao += float(bs["cong_thuong_hoan_hao"])
	if _bep != null:
		_bep.bot_giay_chay += float(bs["bot_giay_chay"])


func _khi_don_ket_thuc(_don: Variant, _ly_do: String) -> void:
	_bao_trang_thai()


## Bật hiệu ứng của kĩ năng chủ động.
##
## Gọi NGAY LÚC BẤM, không đợi cut-in chiếu xong — nếu buộc đợi hết phim thì
## người bỏ qua đoạn phim sẽ được lợi (hoặc thiệt) hơn người ngồi xem, tức
## cùng một kĩ năng cho hai kết quả khác nhau tuỳ thói quen bấm phím.
func _ap_dung_hieu_ung() -> void:
	# HIỆU ỨNG VIẾT RIÊNG thắng hiệu ứng có sẵn.
	#
	# Hai đường vào thay vì một là chủ ý: kĩ năng chỉ đổi một con số (cả ba
	# của Kita) không đáng phải có một file riêng, còn kĩ năng là cả một cơ
	# chế (Oguri dừng thời gian, Chiyono reset màn) thì không nhét vừa một
	# nhánh `match`. Bắt mọi kĩ năng đi chung một đường thì một trong hai loại
	# phải chịu thiệt.
	var duong_dan := String(_chu_dong.get("script", ""))
	if not duong_dan.is_empty():
		_chay_hieu_ung_rieng(duong_dan)
		return

	match String(_chu_dong.get("hieu_ung", "")):
		Bang.HU_EP_HOAN_HAO:
			if _ql != null:
				_ql.ep_hoan_hao = true


## Nạp và chạy một hiệu ứng trong thư mục hieu_ung/. Xem hieu_ung/_mau.gd để
## biết giao ước (hàm bat/tat và nội dung của ctx).
##
## Nạp lúc CHẠY chứ không preload: một lỗi cú pháp trong hiệu ứng của Oguri
## không được phép làm cả hệ kĩ năng không biên dịch được, tức làm Kita cũng
## hỏng theo.
func _chay_hieu_ung_rieng(duong_dan: String) -> void:
	var lop := load(duong_dan) as GDScript
	if lop == null:
		push_error("Không nạp được hiệu ứng kĩ năng: %s" % duong_dan)
		return
	_hieu_ung = lop.new()
	if not _hieu_ung.has_method("bat"):
		push_error("Hiệu ứng %s thiếu hàm bat()." % duong_dan)
		_hieu_ung = null
		return
	_hieu_ung.bat(_boi_canh())


## Gói mọi thứ một hiệu ứng có thể cần. Danh sách khoá ghi ở hieu_ung/_mau.gd.
func _boi_canh() -> Dictionary:
	return {
		"ql": _ql,
		"bep": _bep,
		"gio": _gio,
		"man": get_parent(),
		"nhan_vat": _nhan_vat,
		"so": _chu_dong,
	}


## Tắt hiệu ứng đang chạy, nếu nó là loại bật/tắt được.
##
## Chưa nơi nào gọi — để sẵn cho Triumphant Pulse của Oguri, kĩ năng duy nhất
## trong bảng bật/tắt tự do trong một ngân sách thời gian.
func tat_hieu_ung() -> void:
	if _hieu_ung != null and _hieu_ung.has_method("tat"):
		_hieu_ung.tat(_boi_canh())


## Người chơi bấm Space.
##
## Dùng _unhandled_input chứ không phải _input: bảng chọn nguyên liệu
## (bang_chon.gd) đang dùng _input để cướp phím trước, và trong lúc bảng đó
## mở thì bấm Space không được phép kích hoạt kĩ năng.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ki_nang"):
		return
	get_viewport().set_input_as_handled()
	kich_hoat()


func kich_hoat() -> void:
	if not co_the_dung():
		return
	var id := str(GameData.selected_character)
	var cut_in := _tao_cut_in()
	if cut_in == null:
		return
	# Thêm vào cây TRƯỚC khi gọi chieu(): VideoStreamPlayer chỉ phát được khi
	# đã nằm trong cây scene.
	get_tree().current_scene.add_child(cut_in)
	if not cut_in.chieu(id):
		# Không có file cut-in cho nhân vật này. KHÔNG trừ lượt — người chơi
		# không đáng bị mất lượt vì asset còn thiếu.
		cut_in.queue_free()
		return

	# Chỉ trừ lượt khi cheat TẮT, để cheat đúng nghĩa "không giới hạn".
	if not GameData.ki_nang_vo_han:
		_con_lai -= 1
	_dang_chieu = true
	_khoa_nhan_vat(true)
	_bao_trang_thai()
	cut_in.xong.connect(_khi_chieu_xong)

	_ap_dung_hieu_ung()


func _khi_chieu_xong() -> void:
	_dang_chieu = false
	_khoa_nhan_vat(false)
	_bao_trang_thai()


func _khoa_nhan_vat(khoa: bool) -> void:
	if _nhan_vat != null and "khoa_di_chuyen" in _nhan_vat:
		_nhan_vat.khoa_di_chuyen = khoa


func _bao_trang_thai() -> void:
	var dung_duoc := co_the_dung()
	san_sang_doi.emit(dung_duoc)
	tien_do_doi.emit(ti_le_dieu_kien(), _chu_tien_do(dung_duoc))


## Chữ hiện cạnh thanh tiến trình. Ba trạng thái, ba câu khác hẳn nhau — không
## dùng chung một câu có thêm dấu chấm than, vì người chơi liếc HUD chứ không
## đọc.
##
##   ""         nhân vật chưa có kĩ năng chủ động → HUD ẩn thanh
##   "3/5"      đang gom điều kiện
##   "SPACE"    đủ rồi, bấm đi — nói thẳng PHÍM chứ không nói "sẵn sàng",
##              vì thứ người chơi cần lúc đó là biết bấm cái gì
##   "Đã dùng"  hết lượt của màn này
func _chu_tien_do(dung_duoc: bool) -> String:
	if _chu_dong.is_empty():
		return ""
	if dung_duoc:
		return "SPACE"
	# Hết lượt: phân biệt với "chưa đủ điều kiện", vì hai thứ đó đòi người chơi
	# làm hai việc khác nhau — một cái là cố thêm, một cái là thôi đừng chờ.
	# Cheat bật thì không bao giờ hết lượt nên không rơi vào nhánh này.
	if _con_lai <= 0 and not GameData.ki_nang_vo_han:
		return "Đã dùng"
	var so := tien_do()
	return so if not so.is_empty() else "..."


## Nạp lúc chạy chứ không preload, cùng lý do với level_base.gd: lỗi cú pháp
## trong màn cut-in không được phép làm cả hệ kĩ năng không biên dịch được.
func _tao_cut_in() -> Node:
	var lop := load(LopCutIn) as GDScript
	if lop == null:
		push_error("Không nạp được %s" % LopCutIn)
		return null
	var n: Node = lop.new()
	n.name = "CutInKiNang"
	return n
