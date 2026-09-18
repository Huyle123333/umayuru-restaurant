extends CanvasLayer
## Thanh tiến trình RIÊNG cho từng trạm, nổi ngay trên đầu trạm đó.
##
## ────────────────────────────────── VÌ SAO BỎ THANH CHUNG Ở ĐỈNH MÀN HÌNH
##
## Bản trước có đúng MỘT thanh neo giữa-trên màn hình, kèm dòng chữ "Đang nấu
## — Bep 1" để nói nó đang phục vụ ai. Lý do chọn kiểu đó vẫn đúng và vẫn được
## giữ ở đây: lúc người chơi cần nhìn thanh nhất là lúc họ đang CHẠY ĐI LẤY
## NGUYÊN LIỆU, mà khi đó cái bếp đã ra khỏi khung hình.
##
## Nhưng một thanh cho bốn trạm thì hỏng ngay khi hai trạm cùng chạy — và đó
## là cách chơi bình thường, không phải trường hợp hiếm: bật bếp rồi chạy sang
## thớt là đã hai trạm. Thanh chỉ vẽ được một giá trị, nên nó nhảy qua nhảy
## lại giữa hai trạm, và dòng chữ đổi theo. Người chơi không đọc được cái gì
## cả.
##
## Bốn trạm phát tín hiệu tiến trình: hai cái BẾP, LÒ NƯỚNG và THỚT. Bàn chế
## tạo KHÔNG có thanh — nó ráp bằng phím F, tức thì, không có gì để đếm.
##
## ─────────────────────────────────────────── VÌ SAO BÁM THEO TRẠM, KHÔNG NEO
##
## Thanh nằm ngay trên cái bếp thì CHỖ ĐỨNG đã trả lời câu "thanh này của ai".
## Không cần dòng chữ tên trạm nữa — chữ đó vừa thừa vừa che mất bếp.
##
## Và thanh KHÔNG ẩn khi người chơi đi xa: nó bị KẸP LẠI Ở MÉP khung hình. Nhờ
## vậy giữ được ưu điểm của thanh-ở-đỉnh (chạy đi đâu cũng thấy còn bao lâu)
## mà không mất thông tin "của trạm nào" — thanh bị kẹp ở mép trái thì cái bếp
## đang ở bên trái.
##
## ───────────────────────────────────────────────────────── HAI GIAI ĐOẠN
##
##   NẤU     thanh cam, ĐẦY DẦN 0 → 1
##   CHỜ CHÁY thanh đỏ, VƠI DẦN 1 → 0   (chỉ ham và steak)
##
## Giai đoạn hai là thứ trước đây hoàn toàn không có báo hiệu: nấu xong thanh
## biến mất, trong khi miếng thịt vẫn nằm trên bếp đếm tiếp 8 giây nữa rồi
## cháy. Người chơi không có cách nào biết còn bao lâu ngoài tự đếm nhẩm — mà
## "cứ để đấy rồi tính" lẽ ra phải là một canh bạc CÓ THÔNG TIN, không phải
## một cái bẫy.
##
## Đổi CHIỀU (đầy dần → vơi dần) chứ không chỉ đổi màu: hai giai đoạn là hai
## loại đồng hồ ngược nhau — một cái đếm tới phần thưởng, một cái đếm tới hình
## phạt. Cùng chiều thì người chơi liếc nhanh sẽ nhầm cái sau là cái trước.

## Cỡ thanh, tính theo viewport thiết kế 1920×1080 (chia 1.5 ra cỡ thật ở cửa
## sổ 1280×720 — xem giải thích ở hud_tuong_tac.gd).
const RONG := 92.0
const CAO := 12.0

## Neo thanh cao hơn gốc trạm bấy nhiêu đơn vị. 1,55 là vừa trên mặt bếp mà
## chưa chạm vào bong bóng đơn hàng của khách (những thứ đó ở 2,1 trở lên).
const CAO_NEO := 1.55

## Chừa bấy nhiêu pixel khi kẹp thanh vào mép khung hình.
const LE := 10.0

const MAU_NEN := Color(0.09, 0.11, 0.10, 0.82)
const MAU_NAU := Color(0.95, 0.55, 0.2)
const MAU_CHAY := Color("c4433a")

## Dưới mức này thì thanh cháy bắt đầu nhấp nháy.
const NGUONG_NHAY := 0.35

## trạm -> { "thanh": ProgressBar, "day": StyleBoxFlat, "chay": bool }
var _o: Dictionary = {}


func _ready() -> void:
	# Trên HUD chính (layer 10) nhưng dưới bảng kết quả (20) và menu F1 (40).
	layer = 12


## Nối vào hệ bếp. level_base gọi sau khi dựng cả hai.
##
## Node này chỉ NGHE. Nó không hỏi hệ bếp câu nào, không giữ bản sao thời gian
## nào — mọi con số đến từ tín hiệu. Nhờ vậy không có khả năng thanh trên màn
## hình lệch với đồng hồ thật, kiểu lỗi không bao giờ báo mà chỉ làm người
## chơi thấy "rõ ràng thanh chưa đầy mà món đã cháy".
func nghe_he_bep(he: Node) -> void:
	he.tien_trinh_doi.connect(_khi_nau)
	he.nguy_co_chay.connect(_khi_cho_chay)


func _khi_nau(tram: Node, ti_le: float) -> void:
	if ti_le <= 0.0:
		_bo(tram)
		return
	_dat(tram, ti_le, false)


func _khi_cho_chay(tram: Node, con_lai: float) -> void:
	if con_lai <= 0.0:
		_bo(tram)
		return
	_dat(tram, con_lai, true)


func _dat(tram: Node, ti_le: float, dang_cho_chay: bool) -> void:
	var muc: Dictionary = _o.get(tram, {})
	if muc.is_empty():
		muc = _tao_thanh()
		_o[tram] = muc
	var thanh: ProgressBar = muc["thanh"]
	thanh.value = ti_le
	if bool(muc["chay"]) != dang_cho_chay:
		muc["chay"] = dang_cho_chay
		(muc["day"] as StyleBoxFlat).bg_color = MAU_CHAY if dang_cho_chay else MAU_NAU
	# Nhấp nháy khi sắp cháy. Chỉ ở giai đoạn cháy, và chỉ khi đã gần hết —
	# nhấp nháy suốt thì mắt quen và thôi để ý, đúng lúc cần để ý nhất.
	if dang_cho_chay and ti_le < NGUONG_NHAY:
		thanh.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.008))
	else:
		thanh.modulate.a = 1.0


func _bo(tram: Node) -> void:
	var muc: Dictionary = _o.get(tram, {})
	if muc.is_empty():
		return
	(muc["thanh"] as ProgressBar).queue_free()
	_o.erase(tram)


func _tao_thanh() -> Dictionary:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(RONG, CAO)
	t.size = Vector2(RONG, CAO)
	t.max_value = 1.0
	t.value = 0.0
	t.show_percentage = false
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nen := StyleBoxFlat.new()
	nen.bg_color = MAU_NEN
	nen.set_corner_radius_all(5)
	var day := StyleBoxFlat.new()
	day.bg_color = MAU_NAU
	day.set_corner_radius_all(5)
	t.add_theme_stylebox_override("background", nen)
	t.add_theme_stylebox_override("fill", day)
	add_child(t)
	return {"thanh": t, "day": day, "chay": false}


## Đặt lại vị trí mọi thanh theo vị trí trạm trên màn hình.
##
## Làm trong _process chứ không nối vào một tín hiệu nào: camera di chuyển
## theo người chơi mỗi khung hình, nên vị trí chiếu ra màn hình đổi mỗi khung
## hình dù cái bếp đứng yên tuyệt đối.
func _process(_delta: float) -> void:
	if _o.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var vung := get_viewport().get_visible_rect().size

	for tram in _o.keys():
		if not is_instance_valid(tram):
			_o.erase(tram)
			continue
		var muc: Dictionary = _o[tram]
		var thanh: ProgressBar = muc["thanh"]
		var diem: Vector3 = (tram as Node3D).global_position + Vector3(0.0, CAO_NEO, 0.0)
		var man := cam.unproject_position(diem)
		# Trạm nằm SAU LƯNG camera: unproject trả về toạ độ lộn ngược, chiếu
		# thẳng là thanh nhảy sang phía đối diện màn hình. Lấy đối xứng qua tâm
		# rồi mới kẹp, để nó bị đẩy về đúng mép mà trạm thật sự đang nằm.
		if cam.is_position_behind(diem):
			man = vung - man
		thanh.position = Vector2(
			clampf(man.x - RONG * 0.5, LE, vung.x - RONG - LE),
			clampf(man.y - CAO * 0.5, LE, vung.y - CAO - LE))
