extends Node
## Hệ thống nấu: bếp (qua cái nồi) và lò nướng (trực tiếp).
##
## Vì sao là một node QUẢN LÝ riêng chứ không gắn script vào từng cái bếp:
## Luật nấu là luật CHUNG — hai cái bếp phải cư xử giống hệt nhau, và sau
## này lò nướng cũng dùng lại phần lớn luật đó. Gắn vào từng bếp thì mỗi lần
## sửa luật phải nhớ sửa đủ mọi cái bếp trong mọi map; quên một cái là có một
## cái bếp cư xử khác các cái còn lại, mà lỗi đó rất khó phát hiện.
##
## ------------------------------------------------------------- LUẬT NẤU
##
##  1. Bỏ MỘT món nấu được lên trạm (bếp hoặc thớt): đồng hồ chạy ngay.
##  2. Thanh đầy: món đổi thành thành phẩm và nằm lại trên trạm.
##  3. Món nấu trên bếp để quá lâu (he_so_chay lần thời gian nấu) thì cháy.
##  4. Lò nướng là trạm NHIỀU nguyên liệu: bỏ đế bánh để bật, bỏ thêm topping
##     trong lúc đang chạy, thanh đầy mà tổ hợp không khớp công thức nào thì
##     cả mẻ thành đồ hỏng.
##
## ------------------------------------------- BỎ KIỂU NẤU "NỒI" — 14/9/2026
##
## Trước đây có kiểu nấu thứ tư: đặt cái nồi lên bếp, bếp MƯỢN kho của nồi,
## người chơi đổ nguyên liệu vào nồi trong lúc bếp đang chạy, nấu xong múc
## canh ra và nồi ở lại. Kèm theo nó là bốn hàm riêng (dat_noi, nhac_noi,
## noi_tren_bep, noi_dat_tren), một nhánh riêng trong _process để phát hiện
## nồi bị nhấc giữa chừng, và một nhánh riêng trong _ket_thuc.
##
## Cái nồi giờ là một VẬT PHẨM nấu được như mọi vật phẩm khác: "nồi canh sống"
## khai `"nau": "stew"` trong danh mục, và đi đúng đường của ham sống hay
## steak sống. Toàn bộ mã riêng cho nồi biến mất — file này ngắn đi khoảng
## sáu chục dòng mà không mất chức năng nào.
##
## Đổi lại: không còn "bỏ thêm nguyên liệu vào nồi đang sôi". Chỗ quyết định
## đó chuyển sang bàn chế tạo (ráp đủ năm thứ trước khi lên bếp).

const DanhMuc := preload("res://scripts/tuong_tac/danh_muc.gd")

## Nấu xong một mẻ. `thanh_cong` false nghĩa là ra đồ hỏng.
signal nau_xong(bep: Node, mon: String, thanh_cong: bool)
## Tiến trình NẤU đổi. 0..1, đầy dần. Phát 0 nghĩa là "hết việc" — thanh ẩn.
signal tien_trinh_doi(bep: Node, ti_le: float)

## Món đã CHÍN và đang nằm chờ trên bếp, đếm tới lúc cháy. 1..0, VƠI dần.
##
## Vì sao một tín hiệu RIÊNG chứ không nhồi tiếp vào tien_trinh_doi: hai giai
## đoạn là hai loại đồng hồ ngược nhau — một cái đếm tới phần thưởng, một cái
## đếm tới hình phạt — và bên nghe phải vẽ chúng khác nhau (đổi màu, đổi
## chiều). Nhồi chung thì bên nghe phải tự đoán "0,7 này là đang nấu hay đang
## sắp cháy", mà nó không có cách nào đoán đúng.
##
## Chỉ phát cho món CÓ khoá `hong` trong danh mục (hiện là ham và steak) —
## những món khác nấu xong là gỡ khỏi bảng đang-nấu luôn.
signal nguy_co_chay(bep: Node, con_lai: float)

## Nấu một mẻ trên bếp mất bao nhiêu giây.
##
## 8 giây là con số đủ để người chơi chạy được một chuyến lấy nguyên liệu
## (đã đo: một chuyến khứ hồi trong bếp ~4,6 s) nhưng không đủ cho hai
## chuyến — nên phải chọn: bỏ đủ trước rồi bật, hay bật sớm và chạy đua.
@export var thoi_gian_nau := 8.0

## Nướng một cái pizza mất bao nhiêu giây.
##
## Dài hơn bếp vì pizza cần tới ba bốn thứ, tức hai chuyến. Đây cũng là cách
## hai trạm có nhịp khác nhau thay vì là hai bản sao của cùng một thao tác.
@export var thoi_gian_nuong := 11.0

## Thái ở thớt mất bao nhiêu giây.
##
## Ngắn hơn hẳn nấu, vì thái là thao tác BẮT BUỘC và không có quyết định nào
## bên trong: đứng đó chờ lâu chỉ là thời gian chết. Cái đáng để người chơi
## cân nhắc là bếp và lò, nơi họ chọn giữa chờ và chạy.
@export var thoi_gian_thai := 2.5

## Để trên bếp quá bao nhiêu LẦN thời gian nấu thì cháy.
##
## 2.0 nghĩa là người chơi có thêm đúng một khoảng bằng thời gian nấu nữa để
## quay lại lấy. Đủ rộng để không phạt oan khi đang bận chỗ khác, nhưng vẫn
## đủ hẹp để "cứ để đấy rồi tính" là một canh bạc thật.
@export var he_so_chay := 2.0

## BỚT bấy nhiêu giây vào mốc cháy. 0 = số gốc của game.
##
## Núm này do hệ kĩ năng vặn — Kita, "Dòng tiền mờ ám": 2,0 giây, đổi lấy
## tiền thưởng đơn hoàn hảo cao hơn. Chọn nhân vật khác thì nó là 0 và mốc
## cháy đúng bằng he_so_chay lần thời gian nấu.
##
## File này không biết kĩ năng là gì, chỉ có một biến số — xem giải thích
## đầy đủ ở quan_ly_ki_nang.gd.
@export var bot_giay_chay := 0.0

## trạm -> { "kho": TramTuongTac, "t": float, "kieu": String }
##
## "kho" là nơi giữ nguyên liệu. Từ khi bỏ kiểu nấu "nồi" thì kho LUÔN chính
## là cái trạm — nhưng khoá này được giữ lại chứ không rút gọn, vì nó là chỗ
## duy nhất phải sửa nếu sau này có thêm một trạm mượn kho của vật khác.
##
## "kieu" quyết định tra bảng nào lúc kết thúc:
##   "lo"   — nướng pizza        -> CONG_THUC_LO
##   "don"  — nấu một món lẻ     -> DanhMuc.nau_don()
##   "thot" — thái một món lẻ    -> DanhMuc.so_che()
var _dang_nau: Dictionary = {}


func _process(delta: float) -> void:
	for tram in _dang_nau.keys():
		var m: Dictionary = _dang_nau[tram]
		var kho: TramTuongTac = m["kho"]
		var kieu: String = m["kieu"]

		# Kho bị xoá khỏi cây scene giữa chừng thì huỷ mẻ.
		if not is_instance_valid(kho):
			_huy(tram)
			continue
		if kho.chua.is_empty():
			continue

		var han: float = _han_gio(kieu)
		m["t"] += delta

		# Hai giai đoạn, hai tín hiệu. Phân nhánh TRƯỚC khi xét mốc thời gian:
		# cờ "xong" đã nói rõ đang ở giai đoạn nào, không cần suy từ con số.
		if not bool(m.get("xong", false)):
			tien_trinh_doi.emit(tram, clampf(m["t"] / han, 0.0, 1.0))
		else:
			var han_chay: float = _moc_chay(han)
			# maxf(0.001, …) chặn chia cho 0 khi bot_giay_chay bị đặt lớn tới
			# mức mốc cháy trùng luôn với lúc chín.
			var quang: float = maxf(0.001, han_chay - han)
			nguy_co_chay.emit(tram, clampf((han_chay - m["t"]) / quang, 0.0, 1.0))

		if m["t"] < han:
			continue
		if not bool(m.get("xong", false)):
			m["xong"] = true
			_ket_thuc(tram, kho, kieu)
			# Món lẻ nấu xong vẫn nằm trên bếp và VẪN ĐẾM TIẾP, để quá lâu
			# thì cháy. Các kiểu khác dừng hẳn ở đây.
			if kieu != "don" or DanhMuc.trang_thai_hong(String(m["goc"])).is_empty():
				_dang_nau.erase(tram)
				# Phát 0 Ở ĐÂY chứ không ở _ket_thuc: chỉ khi mẻ thật sự kết
				# thúc mới được ẩn thanh. Phát trong _ket_thuc thì món còn
				# chờ cháy cũng bị ẩn mất một khung hình rồi hiện lại.
				tien_trinh_doi.emit(tram, 0.0)
		# maxf(han, ...) là chốt chặn: đặt bot_giay_chay lớn hơn quãng ân hạn
		# thì mốc cháy sẽ tụt xuống DƯỚI thời gian nấu, tức món cháy trước cả
		# khi chín — một trạng thái không có đường thoát.
		elif m["t"] >= _moc_chay(han):
			_chay(tram, kho, String(m["goc"]))


## Mốc CHÁY, tính bằng giây kể từ lúc bỏ món lên.
##
## Gom vào một hàm vì ba nơi cần đúng con số này: chỗ vẽ thanh đỏ, chỗ quyết
## định cháy, và phép chia tính tỉ lệ còn lại. Ba bản sao của cùng một công
## thức thì sửa he_so_chay mà quên một chỗ là thanh chạy hết trước khi món
## cháy — sai kiểu không báo lỗi.
##
## maxf(han, …) là chốt chặn: đặt bot_giay_chay lớn hơn quãng ân hạn thì mốc
## cháy sẽ tụt xuống DƯỚI thời gian nấu, tức món cháy trước cả khi chín — một
## trạng thái không có đường thoát.
func _moc_chay(han: float) -> float:
	return maxf(han, han * he_so_chay - bot_giay_chay)


func _han_gio(kieu: String) -> float:
	match kieu:
		"lo": return thoi_gian_nuong
		"thot": return thoi_gian_thai
		_: return thoi_gian_nau


# --------------------------------------------------------------- lò nướng ---

## Bỏ đế bánh vào lò và bật lò.
func bat_lo(lo: TramTuongTac) -> bool:
	if lo == null or _dang_nau.has(lo) or not lo.chua.is_empty():
		return false
	lo.them_vao(DanhMuc.DE_BANH)
	_dang_nau[lo] = {"kho": lo, "t": 0.0, "kieu": "lo", "goc": ""}
	tien_trinh_doi.emit(lo, 0.0)
	return true


## Thêm topping vào lò đang chạy.
func them_vao_lo(lo: TramTuongTac, id: String) -> bool:
	if not _dang_nau.has(lo) or not DanhMuc.cho_vao_lo(id):
		return false
	lo.them_vao(id)
	return true


func dang_chay(tram: TramTuongTac) -> bool:
	return _dang_nau.has(tram) and not bool(_dang_nau[tram].get("xong", false))


# ------------------------------------------------- thao tác trên một món ---

## Đặt một món lẻ lên trạm để thái (thớt) hoặc nấu (bếp).
##
## Món nằm trong `chua` của chính trạm chứ không sinh node 3D đặt lên mặt
## bàn: ở góc top-down, một củ cà rốt nhỏ nằm trên cái thớt bị chính cái thớt
## che gần hết. Người chơi đọc trạng thái qua thanh tiến trình và ghi chú,
## không qua việc soi mặt bàn.
func dat_mon(tram: TramTuongTac, id: String, kieu: String) -> bool:
	if tram == null or _dang_nau.has(tram) or not tram.chua.is_empty():
		return false
	var ra: String = DanhMuc.so_che(id) if kieu == "thot" else DanhMuc.nau_don(id)
	if ra.is_empty():
		return false
	tram.them_vao(id)
	tram.hien_mo_hinh(id)
	_dang_nau[tram] = {"kho": tram, "t": 0.0, "kieu": kieu, "goc": id}
	tien_trinh_doi.emit(tram, 0.0)
	return true


## Lấy thành phẩm khỏi trạm. Trả về id, hoặc "" nếu chưa có gì để lấy.
func lay_ra(tram: TramTuongTac) -> String:
	if tram == null or tram.chua.is_empty() or dang_chay(tram):
		return ""
	var id: String = String(tram.chua[0])
	tram.don_sach()
	tram.xoa_mo_hinh()
	_dang_nau.erase(tram)
	tien_trinh_doi.emit(tram, 0.0)
	return id


func _huy(bep: Node) -> void:
	_dang_nau.erase(bep)
	tien_trinh_doi.emit(bep, 0.0)


## Chỗ DUY NHẤT bốn kiểu rẽ nhánh: tra bảng nào.
func _ket_thuc(tram: Node, kho: TramTuongTac, kieu: String) -> void:
	var mon: String = ""
	match kieu:
		"lo": mon = DanhMuc.nuong_lo(kho.chua)
		"thot": mon = DanhMuc.so_che(String(kho.chua[0]))
		_: mon = DanhMuc.nau_don(String(kho.chua[0]))

	var thanh_cong := not mon.is_empty()
	kho.don_sach()
	var ra: String = mon if thanh_cong else "do_hong"
	kho.them_vao(ra)
	# Đổi model trên mặt trạm sang thành phẩm: người chơi thấy ngay miếng
	# thịt đã đổi màu, không phải đọc chữ mới biết xong.
	kho.hien_mo_hinh(ra)
	AmThanh.phat("nau_xong" if thanh_cong else "nau_hong")
	nau_xong.emit(tram, mon, thanh_cong)


## Để trên bếp quá lâu.
func _chay(tram: Node, kho: TramTuongTac, goc: String) -> void:
	var chay: String = DanhMuc.trang_thai_hong(goc)
	if chay.is_empty():
		chay = "do_hong"
	kho.don_sach()
	kho.them_vao(chay)
	kho.hien_mo_hinh(chay)
	_dang_nau.erase(tram)
	AmThanh.phat("chay")
	tien_trinh_doi.emit(tram, 0.0)
	nau_xong.emit(tram, "", false)
