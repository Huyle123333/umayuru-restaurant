extends Camera3D
## Camera top-down BÁM THEO nhân vật, kiêm luôn việc đổi góc nhìn.
##
## Trước đây camera đứng yên và ôm trọn cả bản đồ 32 × 24. Vấn đề: để nhét
## vừa cả cái quán vào khung hình thì `size` phải để 19.5, và ở mức đó nhân
## vật cao 1.76 đơn vị chỉ còn khoảng 50 px trên màn 1080p — nhỏ tới mức
## không đọc được hoạt ảnh, không thấy nhân vật đang cầm gì.
##
## Đổi sang bám theo thì thu `size` xuống được, nhân vật to gần gấp đôi. Cái
## mất là không còn nhìn thấy toàn bộ khu khách cùng lúc — đã cân nhắc và
## chấp nhận, vì thông tin về khách sẽ hiển thị qua HUD đơn hàng ở góc màn
## hình chứ không bắt người chơi phải tự nhìn thấy từng cái bàn.
##
## Script này làm ba việc:
##   1. Bám theo nhân vật, có làm mượt và có chặn ở mép bản đồ.
##   2. Giành lại quyền "current" sau khi level_base.gd sinh nhân vật.
##   3. Nghe phím P và tín hiệu đổi góc nhìn, rồi bật đúng camera.
## Phần điều khiển (khoá chuột, hướng đi) do kitachibi_player.gd tự lo khi
## nghe cùng tín hiệu view_mode_changed — hai bên không cần biết nhau.

## Kích thước bản đồ theo trục X và Z, tính từ gốc (0, 0).
## Dùng để chặn camera không trôi ra ngoài tường, xem _chan_trong_map().
@export var map_size := Vector2(32.0, 24.0)

## Độ mượt khi bám. Càng lớn càng bám sát, càng nhỏ càng "trôi" theo sau.
##
## 6.0 là mức camera theo kịp nhịp đi bộ mà vẫn còn một chút trễ — chút trễ
## đó chính là thứ khiến chuyển động đọc được là "camera đang đuổi theo"
## chứ không phải "cả thế giới đang giật".
@export var smoothing: float = 6.0

## Có chặn camera ở mép bản đồ không. Tắt đi khi cần quay phim demo.
@export var clamp_at_edge: bool = true

## Nới thêm bấy nhiêu đơn vị ở MÉP TRÊN của khung hình (phía z nhỏ).
##
## VÌ SAO CHỈ NỚI MỘT PHÍA, và vì sao con số này tồn tại:
##
## Camera nhìn xiên, nên một vật càng CAO thì càng bị chiếu lên phía trên màn
## hình. Với góc nghiêng hiện tại, mỗi đơn vị chiều cao đẩy hình lên tương
## đương 0,885 đơn vị về phía z nhỏ.
##
## Hàng đợi khách nằm ở z = 2, sát mép bắc bản đồ. Bong bóng đơn hàng treo
## trên đầu khách ở độ cao ~2,3, nên nó CHIẾU RA NGOÀI mép bản đồ (2 − 2,03 ≈
## 0) — tức là bị cạnh trên khung hình cắt mất, đúng lúc người chơi cần nó
## nhất: để biết phải nấu gì tiếp theo.
##
## Nới 2,0 (một ô lưới) cho camera lùi lên thêm chừng đó. Cái mất là khi đứng
## sát tường bắc sẽ thấy một dải hẹp bên ngoài quán — đổi lại thông tin quan
## trọng nhất của hàng đợi luôn nằm trong khung.
##
## Chỉ nới mép TRÊN: mép dưới không có vấn đề này (vật cao bị đẩy RA XA mép
## dưới chứ không lại gần), nới cả hai chỉ tổ để lộ thêm khoảng trống vô ích.
@export var extra_top: float = 2.0

var _player_camera: Camera3D = null
var _character: Node3D = null
## Vector từ điểm camera nhìn xuống (trên mặt sàn) tới chỗ camera đứng.
##
## Vì sao ĐO ra chứ không viết cứng: góc nghiêng và độ cao của camera do
## người dựng map đặt trong trình chỉnh. Nếu viết cứng toạ độ ở đây thì mỗi
## lần chỉnh góc trong Godot lại phải sửa cả script cho khớp — và quên một
## lần là camera nhìn sai chỗ. Đo một lần lúc khởi động thì script giữ
## nguyên đúng bố cục người dựng đã đặt, dù đó là góc nào.
var _offset := Vector3.ZERO


func _ready() -> void:
	# Mỗi lần vào màn đều bắt đầu ở top-down, kể cả lần trước thoát ra giữa
	# chừng khi đang bật góc nhìn thứ 3.
	GameData.third_person_active = false
	GameData.view_mode_changed.connect(_apply_view)

	_offset = global_position - _ground_point()

	# Đợi hết một frame trước khi tìm nhân vật: nhân vật KHÔNG nằm sẵn trong
	# file map mà được level_base.gd add_child() lúc chạy, nên nó vào cây
	# scene SAU camera này. Godot cũng luôn lấy camera được kích hoạt sau
	# cùng — không đợi rồi giành lại thì chạy map ra vẫn là góc nhìn thứ 3.
	await get_tree().process_frame
	_character = _find_character()
	_player_camera = _find_player_camera()
	_apply_view(false)

	# Nhảy thẳng tới vị trí đúng ở frame đầu. Không có dòng này thì vào màn
	# sẽ thấy camera trượt từ chỗ đặt sẵn trong file map về chỗ nhân vật —
	# nhìn như lỗi chứ không như hiệu ứng.
	if _character != null:
		global_position = _target_pos()


## Bám trong _physics_process chứ không phải _process, vì nhân vật là
## CharacterBody3D và di chuyển trong bước vật lý. Bám ở nhịp khác nhịp của
## mục tiêu thì mỗi frame camera đọc được một vị trí hơi cũ hoặc hơi mới,
## kết quả là hình rung lăn tăn dù cả hai đều chạy đúng.
func _physics_process(delta: float) -> void:
	if _character == null or not current:
		return
	# Làm mượt theo hàm mũ chứ không lerp thẳng với hệ số cố định: cách này
	# cho ra cùng một tốc độ bám ở mọi khung hình/giây. Dùng lerp(_, 0.1)
	# kiểu hay gặp thì máy chạy 144 fps camera sẽ bám nhanh gấp đôi máy chạy
	# 72 fps — cân bằng thử ở máy này sang máy khác là sai.
	var factor := 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(_target_pos(), factor)


# ------------------------------------------------------------- bám theo ---

## Chỗ camera cần đứng để nhân vật nằm giữa khung hình.
func _target_pos() -> Vector3:
	var center := _character.global_position
	center.y = 0.0
	if clamp_at_edge:
		center = _clamp_to_map(center)
	return center + _offset


## Kéo tâm khung hình vào trong lòng bản đồ.
##
## Không chặn thì đi tới sát tường là nửa màn hình thành khoảng trống ngoài
## quán — vừa xấu vừa làm người chơi tưởng còn phòng khác ở đó. Chặn theo
## đúng NỬA KHUNG HÌNH nên khi nhân vật đi vào góc, camera dừng lại còn
## nhân vật tiếp tục đi lệch ra khỏi tâm — đúng cách mọi game top-down làm.
func _clamp_to_map(center: Vector3) -> Vector3:
	# Camera trực giao: `size` là chiều CAO khung hình tính bằng đơn vị thế
	# giới. Chiều ngang suy ra từ tỉ lệ khung hình. Chiều sâu nhìn thấy trên
	# mặt sàn thì lớn hơn `size` vì camera nhìn xiên — chia cho sin của góc
	# nghiêng để quy về mặt phẳng ngang.
	var aspect := float(get_viewport().get_visible_rect().size.aspect())
	var half_width := size * aspect * 0.5
	var sin_angle := absf((-global_transform.basis.z).y)
	var half_depth := (size / maxf(sin_angle, 0.05)) * 0.5

	# Bản đồ nhỏ hơn khung hình theo chiều nào thì khoá cứng vào giữa chiều
	# đó — nếu không, hai cận trên/dưới đảo nhau và clamp() trả về giá trị vô
	# nghĩa.
	if half_width * 2.0 >= map_size.x:
		center.x = map_size.x * 0.5
	else:
		center.x = clampf(center.x, half_width, map_size.x - half_width)

	# Cận trên (phía z nhỏ) lùi thêm `no_them_mep_tren` — xem chú thích của ô
	# đó để biết vì sao chỉ một phía.
	var top_limit := half_depth - extra_top
	var bottom_limit := map_size.y - half_depth
	if top_limit >= bottom_limit:
		# Khung hình sâu hơn bản đồ: khoá cứng vào giữa. Không có nhánh này
		# thì hai cận đảo nhau và clampf() trả về giá trị vô nghĩa.
		center.z = (top_limit + bottom_limit) * 0.5
	else:
		center.z = clampf(center.z, top_limit, bottom_limit)
	return center


## Điểm camera đang nhìn tới trên mặt sàn (y = 0), tính bằng giao tuyến của
## tia nhìn với mặt phẳng sàn.
func _ground_point() -> Vector3:
	var dir_ := -global_transform.basis.z
	if dir_.y >= -0.01:
		# Camera không chúc xuống thì không có giao điểm — đây gần như chắc
		# chắn là lỗi đặt góc trong file map, nên báo ra thay vì im lặng.
		push_warning("CameraTopDown không chúc xuống mặt sàn, hướng = %s" % dir_)
		return Vector3(global_position.x, 0.0, global_position.z)
	return global_position + dir_ * (global_position.y / -dir_.y)


func _find_character() -> Node3D:
	var level := get_parent()
	if level == null or not ("player" in level):
		return null
	return level.player as Node3D


# ---------------------------------------------------------- đổi góc nhìn ---

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_view"):
		return
	# Chưa mở khoá thì phím P không làm gì cả — và cũng KHÔNG nuốt sự kiện,
	# để sau này nếu P được dùng vào việc khác thì không bị chặn ngầm ở đây.
	# AAA Mode bỏ qua mọi cheat, kể cả góc nhìn thứ 3.
	if not GameData.third_person_unlocked or GameData.is_aaa_mode():
		return
	GameData.toggle_view_mode()
	get_viewport().set_input_as_handled()


func _apply_view(is_third_person: bool) -> void:
	if is_third_person and is_instance_valid(_player_camera):
		_player_camera.make_current()
	else:
		make_current()


## Tìm Camera3D bên trong scene nhân vật.
##
## Dò theo KIỂU node chứ không theo đường dẫn cứng ("CameraPivot/SpringArm3D/
## Camera3D"), vì bốn nhân vật chơi được có thể có cây scene hơi khác nhau.
## Tham số cuối của find_children là owned = false — bắt buộc, vì nhân vật
## được tạo lúc chạy nên các node con của nó không thuộc quyền sở hữu
## (owner) của scene màn chơi.
func _find_player_camera() -> Camera3D:
	if _character == null:
		return null
	for n in _character.find_children("*", "Camera3D", true, false):
		return n as Camera3D
	return null
