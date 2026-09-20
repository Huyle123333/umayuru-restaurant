extends Node
## Kịch bản theo THỜI GIAN của một màn chơi — "ca làm việc" của ngày hôm đó.
##
## ─────────────────────────────────────────────── vì sao cần thêm một node nữa
##
## Trước file này, tám màn trong GameData.LEVELS dùng chung một file map VÀ
## chung một bộ số mặc định trong customer_manager.gd. Nghĩa là Ngày 1, Ngày 2,
## Ngày 3 giống hệt nhau: cùng thực đơn 15 món, cùng 12 giây một khách, cùng
## 7 phút. Ba màn mà không có gì phân biệt thì chúng không phải ba màn, chúng
## là một màn chơi ba lần.
##
## Chỗ đặt luật đó KHÔNG thể là customer_manager.gd, vì file đó giữ luật CỦA NHÀ
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
##   max_customers      int     — số khách có mặt cùng lúc tối đa (bàn + hàng đợi)
##   max_tables  int     — số khách ĐANG NGỒI BÀN tối đa. 0 = dùng hết bàn
##   max_queue int   — số ô hàng đợi được dùng. 0 = dùng hết ô có trong map
##   first_wait     float   — chờ bao lâu trước người khách đầu tiên
##   menu    Array   — id những món khách được phép gọi. Rỗng = cả danh mục
##   weights    Dict    — id -> trọng số bốc món. Thiếu = 1
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
const PEAK_GROUP := "peak"

var _customers: Node
var _clock: Node
var _rules: Dictionary = {}

var _stages: Array = []
## Chặng đang áp dụng. -1 = chưa áp chặng nào.
var _index := -1
var _music_switched := false


## Gắn luật vào màn. Gọi từ level_base ngay sau khi dựng xong đồng hồ.
##
## Trả về false khi màn này không có luật riêng (ví dụ màn hướng dẫn, hoặc
## chạy thẳng map bằng F6) — lúc đó level_base xoá node này đi và màn chạy
## bằng số mặc định như trước.
func setup(customers: Node, clock: Node, rules: Dictionary) -> bool:
	if customers == null or rules.is_empty():
		return false
	_customers = customers
	_clock = clock
	_rules = rules

	_apply_static()
	_stages = _rules.get("stages", [])
	# Áp chặng đầu NGAY, không đợi khung hình sau: giữa lúc này và khung hình
	# kế tiếp, quan_ly_khach có thể đã đặt hẹn sinh khách theo nhịp mặc định.
	_go_to_stage(0)
	return true


## Những thứ đặt một lần rồi thôi.
##
## ⚠ KHOÁ bên trái (_rules["max_customers"]...) là khoá của bảng RULES_D1 trong
## GameData. Hai chỗ này PHẢI đổi cùng một lúc: `.has()` không khớp thì trả về
## false và TOÀN BỘ luật màn lặng lẽ không được áp — Ngày 1 chạy bằng số mặc
## định mà không có một dòng cảnh báo nào. Lỗi đó đã xảy ra thật ngày 19/9.
func _apply_static() -> void:
	if _rules.has("max_customers"):
		_customers.max_customers = int(_rules["max_customers"])
	if _rules.has("max_tables"):
		_customers.max_tables = int(_rules["max_tables"])
	if _rules.has("max_queue"):
		_customers.max_queue = int(_rules["max_queue"])
	if _rules.has("first_wait"):
		_customers.first_wait = float(_rules["first_wait"])
	if _rules.has("menu"):
		# Ép về Array[String]: ô @export bên quan_ly_khach khai kiểu chặt, mà
		# mảng đọc ra từ Dictionary là mảng trần (phần tử kiểu Variant). Gán
		# thẳng thì Godot báo lỗi kiểu lúc chạy.
		var td: Array[String] = []
		for m in _rules["menu"]:
			td.append(String(m))
		_customers.menu = td
	if _rules.has("weights"):
		_customers.weights = _rules["weights"]

	if _clock != null and _rules.has("duration"):
		var t := float(_rules["duration"])
		_clock.duration = t
		# Gán CẢ `con_lai`, không chỉ `thoi_luong`. Bảng thời gian chép
		# thoi_luong sang con_lai trong _ready() của nó, mà _ready() đã chạy
		# xong từ lúc add_child — sửa mỗi thoi_luong thì đồng hồ vẫn đếm từ
		# con số cũ và chỉ có cái thanh tiến trình là sai lệch.
		_clock.time_left = t


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
	if _customers == null or _clock == null:
		return

	var elapsed: float = float(_clock.duration) - float(_clock.time_left)

	# Nhạc cao điểm. Đặt theo GIÂY CÒN LẠI chứ không theo giây đã trôi, vì bài
	# hát phải kết thúc đúng lúc hết giờ — mốc của nó là cái đích, không phải
	# vạch xuất phát.
	if not _music_switched and _rules.has("music_cue"):
		if float(_clock.time_left) <= float(_rules["music_cue"]):
			_music_switched = true
			AmThanh.play_random_music(PEAK_GROUP)

	for i in _stages.size():
		var c: Dictionary = _stages[i]
		if elapsed < float(c.get("until", 0.0)):
			if i != _index:
				_go_to_stage(i)
			return
	# Trôi quá chặng cuối (đồng hồ dài hơn tổng các chặng): giữ chặng cuối.
	if not _stages.is_empty() and _index != _stages.size() - 1:
		_go_to_stage(_stages.size() - 1)


func _go_to_stage(i: int) -> void:
	if i < 0 or i >= _stages.size():
		return
	_index = i
	var c: Dictionary = _stages[i]
	if c.has("interval"):
		_customers.spawn_interval = float(c["interval"])
	if c.has("max_customers"):
		_customers.max_customers = int(c["max_customers"])
