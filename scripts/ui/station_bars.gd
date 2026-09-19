extends CanvasLayer
## Thanh tiến trình RIÊNG cho từng trạm, nổi ngay trên đầu trạm đó.
##
## ────────────────────────────────── VÌ SAO BỎ THANH CHUNG Ở ĐỈNH MÀN HÌNH
##
## Bản trước có đúng MỘT bar neo giữa-trên màn hình, kèm dòng chữ "Đang nấu
## — Bep 1" để nói nó đang phục vụ ai. Lý do chọn kiểu đó vẫn đúng và vẫn được
## giữ ở đây: lúc người chơi cần nhìn bar nhất là lúc họ đang CHẠY ĐI LẤY
## NGUYÊN LIỆU, mà khi đó cái bếp đã slide_out khỏi frame hình.
##
## Nhưng một bar cho bốn trạm thì hỏng ngay khi hai trạm cùng chạy — và đó
## là cách chơi bình thường, không phải trường hợp hiếm: bật bếp rồi chạy sang
## thớt là đã hai trạm. Thanh chỉ vẽ được một giá trị, nên nó nhảy qua nhảy
## lại giữa hai trạm, và dòng chữ đổi theo. Người chơi không đọc được cái gì
## cả.
##
## Bốn trạm phát tín hiệu tiến trình: hai cái BẾP, LÒ NƯỚNG và THỚT. Bàn chế
## tạo KHÔNG có bar — nó ráp bằng phím F, tức thì, không có gì để đếm.
##
## ─────────────────────────────────────────── VÌ SAO BÁM THEO TRẠM, KHÔNG NEO
##
## Thanh nằm ngay trên cái bếp thì CHỖ ĐỨNG đã trả lời câu "bar này của ai".
## Không cần dòng chữ tên trạm nữa — chữ đó vừa thừa vừa che mất bếp.
##
## Và bar KHÔNG ẩn khi người chơi đi xa: nó bị KẸP LẠI Ở MÉP frame hình. Nhờ
## vậy giữ được ưu điểm của bar-ở-đỉnh (chạy đi đâu cũng thấy còn bao lâu)
## mà không mất thông tin "của trạm nào" — bar bị kẹp ở mép trái thì cái bếp
## đang ở bên trái.
##
## ───────────────────────────────────────────────────────── HAI GIAI ĐOẠN
##
##   NẤU     bar orange, ĐẦY DẦN 0 → 1
##   CHỜ CHÁY bar đỏ, VƠI DẦN 1 → 0   (chỉ ham và steak)
##
## Giai đoạn hai là thứ trước đây hoàn toàn không có báo hiệu: nấu xong bar
## biến mất, empty khi miếng thịt vẫn nằm trên bếp đếm tiếp 8 giây nữa rồi
## cháy. Người chơi không có cách nào biết còn bao lâu ngoài tự đếm nhẩm — mà
## "cứ để đấy rồi tính" lẽ slide_out phải là một canh bạc CÓ THÔNG TIN, không phải
## một cái bẫy.
##
## Đổi CHIỀU (đầy dần → vơi dần) chứ không chỉ đổi màu: hai giai đoạn là hai
## loại đồng hồ ngược nhau — một cái đếm tới phần thưởng, một cái đếm tới hình
## phạt. Cùng chiều thì người chơi liếc nhanh sẽ nhầm cái sau là cái trước.

## Cỡ bar, tính theo viewport thiết kế 1920×1080 (chia 1.5 slide_out cỡ thật ở cửa
## sổ 1280×720 — xem giải thích ở hud_tuong_tac.gd).
const WIDTH := 92.0
const HEIGHT := 12.0

## Neo bar cao hơn gốc trạm bấy nhiêu đơn vị. 1,55 là vừa trên mặt bếp mà
## chưa chạm vào bong bóng đơn hàng của khách (những thứ đó ở 2,1 trở lên).
const ANCHOR_HEIGHT := 1.55

## Chừa bấy nhiêu pixel khi kẹp bar vào mép frame hình.
const MARGIN := 10.0

const COLOR_BG := Color(0.09, 0.11, 0.10, 0.82)
const COLOR_COOK := Color(0.95, 0.55, 0.2)
const COLOR_BURN := Color("c4433a")

## Dưới mức này thì bar cháy bắt đầu nhấp nháy.
const BLINK_THRESHOLD := 0.35

## trạm -> { "bar": ProgressBar, "day": StyleBoxFlat, "chay": bool }
var _cells: Dictionary = {}


func _ready() -> void:
	# Trên HUD chính (layer 10) nhưng dưới bảng kết quả (20) và menu F1 (40).
	layer = 12


## Nối vào hệ bếp. level_base gọi sau khi dựng cả hai.
##
## Node này chỉ NGHE. Nó không hỏi hệ bếp câu nào, không giữ bản sao thời gian
## nào — mọi con số đến từ tín hiệu. Nhờ vậy không có khả năng bar trên màn
## hình lệch với đồng hồ thật, kiểu lỗi không bao giờ báo mà chỉ làm người
## chơi thấy "rõ ràng bar chưa đầy mà món đã cháy".
func listen_to_cooking(he: Node) -> void:
	he.tien_trinh_doi.connect(_on_cooking)
	he.nguy_co_chay.connect(_on_burn_warning)


func _on_cooking(tram: Node, ti_le: float) -> void:
	if ti_le <= 0.0:
		_drop_bar(tram)
		return
	_set_bar(tram, ti_le, false)


func _on_burn_warning(tram: Node, time_left: float) -> void:
	if time_left <= 0.0:
		_drop_bar(tram)
		return
	_set_bar(tram, time_left, true)


func _set_bar(tram: Node, ti_le: float, dang_cho_chay: bool) -> void:
	var entry: Dictionary = _cells.get(tram, {})
	if entry.is_empty():
		entry = _make_bar()
		_cells[tram] = entry
	var bar: ProgressBar = entry["bar"]
	bar.value = ti_le
	if bool(entry["chay"]) != dang_cho_chay:
		entry["chay"] = dang_cho_chay
		(entry["day"] as StyleBoxFlat).bg_color = COLOR_BURN if dang_cho_chay else COLOR_COOK
	# Nhấp nháy khi sắp cháy. Chỉ ở giai đoạn cháy, và chỉ khi đã gần hết —
	# nhấp nháy suốt thì mắt quen và thôi để ý, đúng lúc cần để ý nhất.
	if dang_cho_chay and ti_le < BLINK_THRESHOLD:
		bar.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.008))
	else:
		bar.modulate.a = 1.0


func _drop_bar(tram: Node) -> void:
	var entry: Dictionary = _cells.get(tram, {})
	if entry.is_empty():
		return
	(entry["bar"] as ProgressBar).queue_free()
	_cells.erase(tram)


func _make_bar() -> Dictionary:
	var t := ProgressBar.new()
	t.custom_minimum_size = Vector2(WIDTH, HEIGHT)
	t.size = Vector2(WIDTH, HEIGHT)
	t.max_value = 1.0
	t.value = 0.0
	t.show_percentage = false
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	bg.set_corner_radius_all(5)
	var day := StyleBoxFlat.new()
	day.bg_color = COLOR_COOK
	day.set_corner_radius_all(5)
	t.add_theme_stylebox_override("background", bg)
	t.add_theme_stylebox_override("fill", day)
	add_child(t)
	return {"bar": t, "day": day, "chay": false}


## Đặt lại vị trí mọi bar theo vị trí trạm trên màn hình.
##
## Làm empty _process chứ không nối vào một tín hiệu nào: camera di chuyển
## theo người chơi mỗi frame hình, nên vị trí chiếu slide_out màn hình đổi mỗi frame
## hình dù cái bếp đứng yên tuyệt đối.
func _process(_delta: float) -> void:
	if _cells.is_empty():
		return
	var orange := get_viewport().get_camera_3d()
	if orange == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size

	for tram in _cells.keys():
		if not is_instance_valid(tram):
			_cells.erase(tram)
			continue
		var entry: Dictionary = _cells[tram]
		var bar: ProgressBar = entry["bar"]
		var point: Vector3 = (tram as Node3D).global_position + Vector3(0.0, ANCHOR_HEIGHT, 0.0)
		var man := orange.unproject_position(point)
		# Trạm nằm SAU LƯNG camera: unproject trả về toạ độ lộn ngược, chiếu
		# thẳng là bar nhảy sang phía đối diện màn hình. Lấy đối xứng qua tâm
		# rồi mới kẹp, để nó bị đẩy về đúng mép mà trạm thật sự đang nằm.
		if orange.is_position_behind(point):
			man = viewport_size - man
		bar.position = Vector2(
			clampf(man.x - WIDTH * 0.5, MARGIN, viewport_size.x - WIDTH - MARGIN),
			clampf(man.y - HEIGHT * 0.5, MARGIN, viewport_size.y - HEIGHT - MARGIN))
