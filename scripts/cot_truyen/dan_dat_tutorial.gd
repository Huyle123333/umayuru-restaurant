extends Node
## Bộ dẫn dắt màn hướng dẫn: chạy kịch bản, theo dõi người chơi, sang bước.
##
## Chia ba phần rạch ròi, và đây là điểm đáng nói nhất của cả hệ:
##   kich_ban_tutorial.gd  — DẠY CÁI GÌ (dữ liệu, đọc như tờ giấy)
##   bang_huong_dan.gd     — VẼ RA SAO (chỉ hiện chữ, không biết luật)
##   file này              — BIẾT KHI NÀO NGƯỜI CHƠI ĐÃ LÀM ĐƯỢC
## Ba việc đó đổi với ba nhịp khác nhau: lời thoại sửa liên tục, giao diện sửa
## thỉnh thoảng, còn cách phát hiện gần như không đổi. Gộp lại một file thì mỗi
## lần sửa một câu chữ lại phải đọc qua cả đống logic tín hiệu.
##
## VÌ SAO TỰ PHÁT HIỆN CHỨ KHÔNG BẮT BẤM PHÍM ĐỂ SANG BƯỚC: người chơi bấm qua
## được thì họ sẽ bấm qua, và học xong không nhớ gì. Bắt phải LÀM ĐÚNG rồi mới
## đi tiếp thì bài học nằm ở ngón tay chứ không nằm ở mắt. Giá phải trả là bộ
## này cần biết một chút về hệ nấu ăn — nhưng chỉ ở mức NGHE tín hiệu, nó không
## gọi ngược vào ai cả.

const KichBan := preload("res://scripts/cot_truyen/kich_ban_tutorial.gd")
const BangHuongDan := preload("res://scripts/giao_dien/bang_huong_dan.gd")

## Hướng dẫn kết thúc. `tong_ket` = true thì màn dừng luôn và hiện bảng kết
## quả hạng S.
##
## HIỆN TẠI CẢ HAI LỐI RA ĐỀU TRẢ VỀ true (sửa 11/9/2026):
##   • học hết kịch bản  -> tổng kết
##   • bấm "Bỏ qua"      -> tổng kết
##
## Vì sao bỏ lối "chạy tiếp như màn thường": nút đó trước tên là "Tự làm" và
## nó có lý khi màn hướng dẫn là NƠI DUY NHẤT chơi được — người không muốn
## học vẫn cần một cái bếp để nghịch. Giờ đã có Ngày 1, nên chỗ để chơi thật
## là Ngày 1, còn màn hướng dẫn chỉ nên làm đúng một việc: dạy, hoặc đứng
## sang một bên. Để nó chạy tiếp bảy phút không đồng hồ, không khách tự vào,
## thì người bấm "Bỏ qua" rơi vào một cái bếp trống không có gì xảy ra — tệ
## hơn hẳn so với cho họ đi thẳng sang Ngày 1.
##
## GIỮ tham số thay vì bỏ hẳn: ngày nào thêm một lối ra thứ ba (ví dụ thoát
## giữa chừng) thì chỗ nghe đã sẵn sàng, không phải đổi chữ ký tín hiệu.
signal xong_tutorial(tong_ket: bool)

## Trễ một nhịp giữa "làm đúng" và "hiện câu tiếp theo".
##
## Không cho nhảy ngay: người chơi vừa làm xong một việc thì mắt còn đang ở
## chỗ vừa làm, chữ đổi ngay là họ bỏ lỡ. Nửa giây đủ để nhìn lên.
const TRE_SANG_BUOC := 0.6

var _bang: CanvasLayer
var _tay: Node
var _he_bep: Node
var _quan_ly_khach: Node
var _bang_gio: Node
var _nguoi_choi: Node3D

var _buoc := -1
var _cho := ""
var _hen_giay := 0.0
var _da_di := 0.0
var _vi_tri_cu := Vector3.ZERO
var _dang_cho := false
## Có tổng kết hay không. Xem chú thích của `xong_tutorial` — hiện cả hai lối
## ra đều bật cờ này.
var _hoc_het := false


## Gắn vào màn chơi. Truyền thẳng các node cần nghe thay vì tự đi tìm trong
## cây scene: tìm bằng đường dẫn thì đổi tên một node là hỏng lặng lẽ, mà lỗi
## kiểu đó chỉ lộ ra khi chơi tới đúng bước dùng nó.
func chuan_bi(nguoi_choi: Node3D, tay: Node, he_bep: Node,
		quan_ly_khach: Node, bang_gio: Node) -> void:
	_nguoi_choi = nguoi_choi
	_tay = tay
	_he_bep = he_bep
	_quan_ly_khach = quan_ly_khach
	_bang_gio = bang_gio

	_bang = BangHuongDan.new()
	_bang.name = "BangHuongDan"
	add_child(_bang)
	_bang.chon_bat_dau.connect(_khi_chon)

	_dat_luat_tutorial()
	_noi_tin_hieu()

	if _nguoi_choi != null:
		_vi_tri_cu = _nguoi_choi.global_position

	_bang.mo()
	_sang_buoc(0)


## Luật riêng của màn hướng dẫn. Tất cả đều là ô @export có sẵn, không có cờ
## "dang_tutorial" nào rải trong code hệ thống — hệ khách và panel thời gian
## không cần biết màn hướng dẫn tồn tại.
func _dat_luat_tutorial() -> void:
	if _quan_ly_khach != null:
		_quan_ly_khach.tru_kien_nhan = false   # thanh kiên nhẫn hiện nhưng không cạn
		_quan_ly_khach.tu_sinh = false         # khách vào đúng lúc kịch bản gọi
		_quan_ly_khach.ep_ban = 1              # bàn gần bếp nhất
		_quan_ly_khach.ep_mon = "mon_steak"    # đúng món đang dạy
	if _bang_gio != null:
		_bang_gio.dem_nguoc = false


## Trả màn chơi về luật bình thường. Dùng cho CẢ HAI lối ra: học xong, và bấm
## "Bỏ qua". Một hàm cho hai lối thì không có lối nào bị quên.
func _tra_ve_binh_thuong() -> void:
	if _quan_ly_khach != null:
		_quan_ly_khach.tru_kien_nhan = true
		_quan_ly_khach.tu_sinh = true
		_quan_ly_khach.ep_ban = 0
		_quan_ly_khach.ep_mon = ""
	if _bang_gio != null:
		_bang_gio.dem_nguoc = true

	# ĐÁNH DẤU HOÀN THÀNH — bắt buộc, không phải tuỳ chọn.
	#
	# Màn "d1_sang" khai `needs: "tutorial"`, nên không gọi dòng này thì Ngày 1
	# khoá vĩnh viễn và người chơi kẹt ở màn hướng dẫn mãi mãi. Lối "Bỏ qua"
	# cũng phải đi qua đây, vì bỏ qua hướng dẫn không có nghĩa là bị phạt.
	if GameData != null:
		GameData.complete_level("tutorial")

	xong_tutorial.emit(_hoc_het)


# ------------------------------------------------------------- tín hiệu ---

func _noi_tin_hieu() -> void:
	if _tay != null and _tay.has_signal("vat_tren_tay_doi"):
		_tay.vat_tren_tay_doi.connect(_khi_tay_doi)
	if _he_bep != null and _he_bep.has_signal("nau_xong"):
		_he_bep.nau_xong.connect(_khi_nau_xong)
	if _quan_ly_khach != null and _quan_ly_khach.has_signal("don_ket_thuc"):
		_quan_ly_khach.don_ket_thuc.connect(_khi_don_ket_thuc)

	# Bàn chế tạo: nghe nội dung đổi để biết người chơi đã đặt được thứ cần đặt.
	# Duyệt nhóm "tram" chứ không đi theo đường dẫn node, vì bàn chế tạo có thể
	# được kê lại chỗ khác trong map bất cứ lúc nào.
	for n in get_tree().get_nodes_in_group("tram"):
		if String(n.loai) == "ban_che_tao" and n.has_signal("noi_dung_thay_doi"):
			n.noi_dung_thay_doi.connect(_khi_ban_doi)


func _khi_tay_doi(id: String) -> void:
	if _cho.begins_with("cam:") and id == _cho.substr(4):
		_xong_buoc()


func _khi_nau_xong(tram: Node, _mon: String, thanh_cong: bool) -> void:
	if not thanh_cong:
		return
	var loai := String(tram.loai)
	if _cho == "thai" and loai == "thot":
		_xong_buoc()
	elif _cho == "nau" and loai == "bep":
		_xong_buoc()


func _khi_ban_doi(ban: Node) -> void:
	if not _cho.begins_with("ban_chua:"):
		return
	if ban.chua.has(_cho.substr(9)):
		_xong_buoc()


func _khi_don_ket_thuc(_don: RefCounted, ly_do: String) -> void:
	if _cho == "giao" and ly_do == "xong":
		_xong_buoc()


## Trả lời câu hỏi mở màn: "Chỉ đi" thì vào bài học, "Bỏ qua" thì tổng kết ngay.
##
## Bỏ qua vẫn đi qua `_tra_ve_binh_thuong()` — hàm đó là nơi gọi
## `GameData.complete_level("tutorial")`, mà Ngày 1 khai `needs: "tutorial"`.
## Bỏ qua hướng dẫn không có nghĩa là bị khoá Ngày 1.
func _khi_chon(dong_y: bool) -> void:
	if dong_y:
		_sang_buoc(1)
		return
	_hoc_het = true
	_cho = ""
	_bang.dong()
	_tra_ve_binh_thuong()


# --------------------------------------------------------------- vòng chạy ---

func _process(delta: float) -> void:
	if _cho.is_empty():
		return

	if _cho.begins_with("giay:"):
		_hen_giay -= delta
		if _hen_giay <= 0.0:
			_xong_buoc()
		return

	if _cho == "di_chuyen" and _nguoi_choi != null:
		# Cộng dồn QUÃNG ĐƯỜNG chứ không đo khoảng cách tới điểm xuất phát: đo
		# khoảng cách thì đi một vòng tròn về chỗ cũ lại thành chưa đi đâu cả,
		# mà đi vòng tròn đúng là thứ người ta làm khi thử phím lần đầu.
		var moi := _nguoi_choi.global_position
		_da_di += Vector2(moi.x - _vi_tri_cu.x, moi.z - _vi_tri_cu.z).length()
		_vi_tri_cu = moi
		if _da_di >= KichBan.QUANG_DUONG_HOC:
			_xong_buoc()


# ----------------------------------------------------------- chuyển bước ---

func _sang_buoc(i: int) -> void:
	_buoc = i
	_dang_cho = false
	if i >= KichBan.BUOC.size():
		_cho = ""
		_hoc_het = true
		_bang.dong()
		_tra_ve_binh_thuong()
		return

	var b: Dictionary = KichBan.BUOC[i]
	_cho = String(b.get("cho", ""))
	_hen_giay = 0.0
	_da_di = 0.0
	if _nguoi_choi != null:
		_vi_tri_cu = _nguoi_choi.global_position

	if _cho.begins_with("giay:"):
		_hen_giay = float(_cho.substr(5))

	if _cho == "hoi":
		_bang.hoi(String(b.get("loi", "")), KichBan.NUT_CO, KichBan.NUT_KHONG)
	else:
		# Đánh số bỏ qua bước hỏi: người chơi đếm "bước 1" từ bài học đầu tiên,
		# còn câu hỏi mở màn thì không phải một bài học.
		_bang.dat_buoc(String(b.get("loi", "")), i, KichBan.BUOC.size() - 1)

	_lam_viec(String(b.get("viec", "")))


func _lam_viec(viec: String) -> void:
	if viec == "goi_khach" and _quan_ly_khach != null:
		_quan_ly_khach.them_khach()


## Bước hiện tại coi như xong. Chặn gọi hai lần rồi trễ một nhịp mới sang bước.
func _xong_buoc() -> void:
	if _dang_cho:
		return
	# Khoá NGAY: một bước có thể thoả điều kiện hai lần trong cùng khung hình
	# (ví dụ tay đổi đồ hai lần liên tiếp), và khi đó nó sẽ nhảy vọt hai bước
	# — người chơi mất trắng một bài học mà không hiểu vì sao.
	_dang_cho = true
	_cho = ""
	await get_tree().create_timer(TRE_SANG_BUOC).timeout
	if is_instance_valid(self) and is_inside_tree():
		_sang_buoc(_buoc + 1)
