extends Node
## Kịch bản theo THỜI GIAN của một màn chơi — "ca làm việc" của ngày hôm đó.
##
## ─────────────────────────────────────────────── vì sao cần thêm một node nữa
##
## Trước file này, tám màn trong GameData.LEVELS dùng chung một file map VÀ
## chung một bộ số mặc định trong quan_ly_khach.gd. Nghĩa là Ngày 1, Ngày 2,
## Ngày 3 giống hệt nhau: cùng thực đơn 15 món, cùng 12 giây một khách, cùng
## 7 phút. Ba màn mà không có gì phân biệt thì chúng không phải ba màn, chúng
## là một màn chơi ba lần.
##
## Chỗ đặt luật đó KHÔNG thể là quan_ly_khach.gd, vì file đó giữ luật CỦA NHÀ
## HÀNG — những thứ đúng ở mọi màn: khách xếp hàng thế nào, giao đúng món thì
## được bao nhiêu tiền, hết kiên nhẫn thì bỏ đi. Nhét thêm "Ngày 1 thì thế
## này, Ngày 2 thì thế kia" vào đó là trộn luật chơi với nội dung màn, và mỗi
## màn mới sẽ thêm một nhánh if vào giữa hệ thống lõi.
##
## Nên tách: dữ liệu màn nằm trong GameData.LEVELS[id]["luat"], còn node này
## đọc dữ liệu đó rồi vặn các núm của quan_ly_khach theo đồng hồ. Thêm Ngày 4
## chỉ là thêm một Dictionary — không sửa một dòng code nào ở đây.
##
## Đây cũng đúng khuôn mẫu đã dùng cho màn hướng dẫn (tutorial_director.gd):
## một node "đạo diễn" sống bên cạnh các hệ thống và điều khiển chúng, chứ
## không phải các hệ thống tự biết mình đang ở màn nào.
##
## ────────────────────────────────────────────────────── các khoá trong `luat`
##
##   thoi_luong  float   — độ dài màn, giây
##   toi_da      int     — số khách có mặt cùng lúc tối đa (bàn + hàng đợi)
##   ban_toi_da  int     — số khách ĐANG NGỒI BÀN tối đa. 0 = dùng hết bàn
##   o_hang_toi_da int   — số ô hàng đợi được dùng. 0 = dùng hết ô có trong map
##   cho_dau     float   — chờ bao lâu trước người khách đầu tiên
##   thuc_don    Array   — id những món khách được phép gọi. Rỗng = cả danh mục
##   trong_so    Dict    — id -> trọng số bốc món. Thiếu = 1
##   chang       Array   — các chặng độ khó, xem _ap_dung_chang()
##   moc_nhac    float   — còn bao nhiêu giây thì đổi sang nhạc cao điểm
##   moc         Dict    — bốn mốc doanh thu S/A/B/C (GameData tự đọc)

## NHÓM nhạc cao điểm trong AmThanh.TRACK_GROUPS.
##
## (Sửa 19/9/2026) Trước là hằng `NHAC_CAO_DIEM := "nhac_cao_diem"` rồi gọi
## `play_music()` thẳng bằng tên đó. Nhưng KHÔNG có file nào tên như vậy —
## bài nhạc cao điểm thật tên `hashire_umamusume`. `play_music()` không tìm
## thấy file thì THOÁT SỚM và im lặng: nhạc màn chơi cứ chạy tiếp, không lỗi,
## không cảnh báo. Nên đoạn cao điểm chưa bao giờ đổi nhạc.
##
## Dùng NHÓM chứ không gõ thẳng tên bài: AmThanh đã có sẵn nhóm "cao_diem"
## dành riêng cho việc này, và nhóm mới là chỗ khai báo bài nào thuộc giai
## đoạn nào. Đổi bài sau này chỉ sửa một dòng bên AmThanh, không phải đi tìm
## một hằng nằm lẫn trong luật màn.
const NHOM_CAO_DIEM := "cao_diem"

var _ql: Node
var _gio: Node
var _luat: Dictionary = {}

var _chang: Array = []
## Chặng đang áp dụng. -1 = chưa áp chặng nào.
var _chi_so := -1
var _da_doi_nhac := false


## Gắn luật vào màn. Gọi từ level_base ngay sau khi dựng xong đồng hồ.
##
## Trả về false khi màn này không có luật riêng (ví dụ màn hướng dẫn, hoặc
## chạy thẳng map bằng F6) — lúc đó level_base xoá node này đi và màn chạy
## bằng số mặc định như trước.
func chuan_bi(ql: Node, gio: Node, luat: Dictionary) -> bool:
	if ql == null or luat.is_empty():
		return false
	_ql = ql
	_gio = gio
	_luat = luat

	_ap_dung_tinh()
	_chang = _luat.get("chang", [])
	# Áp chặng đầu NGAY, không đợi khung hình sau: giữa lúc này và khung hình
	# kế tiếp, quan_ly_khach có thể đã đặt hẹn sinh khách theo nhịp mặc định.
	_doi_chang(0)
	return true


## Những thứ đặt một lần rồi thôi.
func _ap_dung_tinh() -> void:
	if _luat.has("toi_da"):
		_ql.toi_da = int(_luat["toi_da"])
	if _luat.has("ban_toi_da"):
		_ql.ban_toi_da = int(_luat["ban_toi_da"])
	if _luat.has("o_hang_toi_da"):
		_ql.o_hang_toi_da = int(_luat["o_hang_toi_da"])
	if _luat.has("cho_dau"):
		_ql.cho_dau = float(_luat["cho_dau"])
	if _luat.has("thuc_don"):
		# Ép về Array[String]: ô @export bên quan_ly_khach khai kiểu chặt, mà
		# mảng đọc ra từ Dictionary là mảng trần (phần tử kiểu Variant). Gán
		# thẳng thì Godot báo lỗi kiểu lúc chạy.
		var td: Array[String] = []
		for m in _luat["thuc_don"]:
			td.append(String(m))
		_ql.thuc_don = td
	if _luat.has("trong_so"):
		_ql.trong_so = _luat["trong_so"]

	if _gio != null and _luat.has("thoi_luong"):
		var t := float(_luat["thoi_luong"])
		_gio.duration = t
		# Gán CẢ `con_lai`, không chỉ `thoi_luong`. Bảng thời gian chép
		# thoi_luong sang con_lai trong _ready() của nó, mà _ready() đã chạy
		# xong từ lúc add_child — sửa mỗi thoi_luong thì đồng hồ vẫn đếm từ
		# con số cũ và chỉ có cái thanh tiến trình là sai lệch.
		_gio.time_left = t


## Đổi độ khó theo thời gian đã trôi.
##
## Mỗi chặng là {"den": giây kết thúc, "nhip": giây giữa hai khách}. Đọc theo
## MỐC KẾT THÚC chứ không theo độ dài: sửa một chặng giữa thì các chặng sau
## vẫn giữ nguyên giờ của nó, thay vì bị đẩy đi hết.
##
## Vì sao có chặng: một dòng khách đều tăm tắp suốt bảy phút thì phút thứ nhất
## và phút thứ bảy giống hệt nhau, và người chơi biết hết mọi thứ sẽ xảy ra
## sau ba mươi giây đầu. Chia chặng cho màn chơi một đường cong — mở cửa vắng
## khách, trưa đông dần, cao điểm dồn dập — tức là một CA LÀM VIỆC.
func _process(_delta: float) -> void:
	if _ql == null or _gio == null:
		return

	var da_troi: float = float(_gio.duration) - float(_gio.time_left)

	# Nhạc cao điểm. Đặt theo GIÂY CÒN LẠI chứ không theo giây đã trôi, vì bài
	# hát phải kết thúc đúng lúc hết giờ — mốc của nó là cái đích, không phải
	# vạch xuất phát.
	if not _da_doi_nhac and _luat.has("moc_nhac"):
		if float(_gio.time_left) <= float(_luat["moc_nhac"]):
			_da_doi_nhac = true
			AmThanh.play_random_music(NHOM_CAO_DIEM)

	for i in _chang.size():
		var c: Dictionary = _chang[i]
		if da_troi < float(c.get("den", 0.0)):
			if i != _chi_so:
				_doi_chang(i)
			return
	# Trôi quá chặng cuối (đồng hồ dài hơn tổng các chặng): giữ chặng cuối.
	if not _chang.is_empty() and _chi_so != _chang.size() - 1:
		_doi_chang(_chang.size() - 1)


func _doi_chang(i: int) -> void:
	if i < 0 or i >= _chang.size():
		return
	_chi_so = i
	var c: Dictionary = _chang[i]
	if c.has("nhip"):
		_ql.nhip_sinh = float(c["nhip"])
	if c.has("toi_da"):
		_ql.toi_da = int(c["toi_da"])
