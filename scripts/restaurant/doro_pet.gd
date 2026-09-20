@tool
extends "res://scripts/interaction/workstation.gd"
## DORO — thú cưng của quán. Vừa là thùng rác biết đi, vừa là thứ để nhìn.
##
## ═══════════════════════════════════════════════ VÌ SAO KẾ THỪA TrạmTươngTác
##
## Doro làm đúng việc của cái thùng rác: bấm E khi đang cầm đồ thì đồ biến
## mất. Toàn bộ luật đó đã nằm trong `tay_cam._bo_di()`, và nó được gọi dựa
## trên MỘT thứ duy nhất — `loai == "mang_bo_do"`.
##
## Nên Doro không cần một hệ thống mới nào cả. Nó chỉ cần LÀ một trạm mang
## loại đó, rồi tự lo phần đi lại. Viết một cơ chế "cho đồ cho thú cưng"
## riêng thì sẽ có hai đường vứt đồ phải sửa song song mãi mãi.
##
## Kế thừa bằng ĐƯỜNG DẪN chứ không viết `extends TramTuongTac`: tên lớp toàn
## cục chỉ phân giải được sau khi trình soạn thảo quét lại bộ nhớ đệm lớp, nên
## chạy từ dòng lệnh trên một file mới toanh sẽ chết với "Could not find type".
## Dự án này đã dính lỗi đó một lần rồi.
##
## ════════════════════════════════════════════ VÌ SAO KHÔNG VA CHẠM VỚI NGƯỜI
##
## Doro nằm ở LỚP VẬT PHẨM (lớp 3) chứ không phải lớp nội thất (lớp 1).
##
## Lớp đó vốn được nghĩ ra cho đồ ăn rơi dưới đất, và yêu cầu của nó giống hệt
## yêu cầu ở đây: bộ chọn mục tiêu PHẢI nhìn thấy (để bấm E được), nhưng nhân
## vật KHÔNG được bị chặn. Một patience_left thú chạy loăng quăng giữa bếp mà đẩy được
## người chơi thì đúng lúc cao điểm nó sẽ chèn người chơi vào góc tường — một
## thứ trang trí không bao giờ được phép làm hỏng lượt chơi.
##
## Nhờ vậy Doro cũng không cần move_and_slide: nó không va vào gì cả, nên chỉ
## việc cộng thẳng vào global_position. Việc giữ nó khỏi đi xuyên tường là
## của navmesh, không phải của vật lý.
##
## ═════════════════════════════════════════════════ VÌ SAO ĐỨNG YÊN KHI GẦN
##
## Tới gần người chơi thì Doro dừng hẳn. Lý do là thao tác: bấm E cần patience_left trỏ
## nằm trên mục tiêu trong đúng khoảnh khắc bấm, mà một mục tiêu đang bò ngang
## thì người chơi phải rượt theo nó. Đứng yên biến việc "cho Doro ăn rác"
## từ một pha đuổi bắt thành một cái bấm nút.
##
## Đứng yên chứ không CHẠY TỚI người chơi: chạy tới thì nó thành cái bóng bám
## theo chân, và lúc người chơi đang vội nó lại chắn ngay trước mặt.

const MODEL := "res://assets/models/doro.glb"

## MỌI CON SỐ chỉnh được của Doro nằm ở file riêng — sửa bên đó, không sửa ở
## đây. Xem `scripts/restaurant/doro_main.gd`.
##
## Vì sao tách: chỉnh cho vừa mắt là việc làm đi làm lại nhiều lượt. Một file
## chỉ có số thì mở ra thấy ngay, và lịch sử git không lẫn giữa "đổi số cho
## đẹp" với "sửa cách nó chạy".
##
## preload chứ không load: bảng số phải có SẴN lúc biên dịch, và gõ sai tên
## file thì lỗi hiện ngay lúc mở project chứ không đợi tới giữa màn chơi.
const Config := preload("res://scripts/restaurant/doro_main.gd")

var _agent: NavigationAgent3D
var _hoat_hinh: AnimationPlayer
var _body: Node3D
var _player: Node3D

var _anim_now := ""
var _rest_left := 0.0
var _moving := false
var _floor_y := 0.0


## Dựng Doro. Gọi từ level_base sau khi hệ khách đã nướng xong navmesh.
##
## `lech_cao` là độ cao mặt navmesh so với mặt sàn — quan_ly_khach ĐO được lúc
## nướng. Không truyền thì NavigationAgent3D thấy mọi điểm đường nằm cách nó
## nửa đơn vị theo trục đứng, không bao giờ nhích sang điểm kế tiếp, và Doro
## đứng rung tại chỗ suốt màn. Đây đúng là cái bẫy đã làm khách hàng đi mãi
## về một cái mốc ngay dưới chân mình.
func setup(seat_marker: Vector3, lech_cao: float, nguoi_choi: Node3D) -> void:
	_player = nguoi_choi
	_floor_y = seat_marker.y
	global_position = seat_marker

	display_name = "Doro"
	kind = "mang_bo_do"

	# NHÓM "tram": đây là thứ duy nhất khiến tay_cam nối được tín hiệu
	# `da_tuong_tac` của Doro vào hàm xử lý của nó. Thiếu dòng này thì bộ chọn
	# vẫn ngắm được Doro (bo_chon_muc_tieu lọc theo LỚP va chạm, không theo
	# nhóm), Doro vẫn nảy lên khi bị bấm E — nhưng đồ trên tay không mất đi,
	# vì nhánh "mang_bo_do" trong tay_cam không bao giờ được gọi. Đúng triệu
	# chứng "Doro không làm được chức năng thùng rác".
	add_to_group("tram")
	# Lớp VẬT PHẨM: bộ chọn nhìn thấy, nhân vật đi xuyên qua. Mặt nạ 0 vì Doro
	# không cần phát hiện va chạm với bất cứ thứ gì — navmesh lo phần đó.
	collision_layer = LAYER_ITEM
	collision_mask = 0

	_build_body()
	_build_collision()
	_build_agent(lech_cao)

	_set_anim("idle")
	_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)

	# Nảy nhẹ mỗi lần được tương tác. Nối ở đây chứ không ở nơi gọi: phản ứng
	# của Doro là việc của Doro.
	if not interacted.is_connected(_on_fed):
		interacted.connect(_on_fed)


# ------------------------------------------------------------------ dựng ---

func _build_body() -> void:
	if not ResourceLoader.exists(MODEL):
		push_warning("Thiếu model Doro: %s — pet sẽ vô hình." % MODEL)
		return
	var goi := load(MODEL) as PackedScene
	if goi == null:
		return
	_body = goi.instantiate() as Node3D
	_body.name = "Mesh"
	# Co theo TỈ LỆ ĐO ĐƯỢC chứ không gõ sẵn 0,28: đổi Config.HEIGHT là xong,
	# không phải bấm máy tính.
	var ti := Config.HEIGHT / Config.BASE_HEIGHT
	_body.scale = Vector3(ti, ti, ti)
	add_child(_body)
	_hoat_hinh = _body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _hoat_hinh == null:
		push_warning("Model Doro không có AnimationPlayer — pet sẽ đứng đơ.")


func _build_collision() -> void:
	var hinh := CollisionShape3D.new()
	var hop := BoxShape3D.new()
	var canh := Config.HEIGHT * Config.BOX_WIDTH
	hop.size = Vector3(canh, Config.HEIGHT, canh)
	hinh.shape = hop
	hinh.position = Vector3(0.0, Config.HEIGHT * 0.5, 0.0)
	add_child(hinh)

	var moc := Marker3D.new()
	moc.name = "DiemNham"
	moc.position = Vector3(0.0, Config.HEIGHT + 0.12, 0.0)
	add_child(moc)
	aim_point = NodePath("DiemNham")


func _build_agent(lech_cao: float) -> void:
	_agent = NavigationAgent3D.new()
	_agent.name = "Agent"
	# Nhỏ hơn bán kính agent của navmesh (0,5): navmesh đã bào lùi khỏi tường
	# đúng 0,5 rồi, khai lớn hơn nữa thì Doro không lách qua được lối đi hẹp.
	_agent.radius = 0.3
	_agent.height = Config.HEIGHT
	_agent.path_desired_distance = 0.3
	_agent.target_desired_distance = 0.35
	_agent.path_height_offset = lech_cao
	_agent.avoidance_enabled = false
	add_child(_agent)


# ------------------------------------------------------------------ đi lại ---

func _physics_process(delta: float) -> void:
	# @tool ở dòng đầu CHỈ để tắt cảnh báo "lớp cha có @tool mà lớp patience_left thì
	# không" — TrạmTươngTác phải là @tool vì lớp con DiningTable cần hiện số bàn lúc
	# đang kê map. Doro thì ngược lại: nó chỉ được dựng lúc chạy, không bao giờ
	# nằm sẵn trong file map, nên không có việc gì để làm trong trình soạn thảo.
	# Chặn ngay đây cho chắc, phòng khi sau này có ai kéo nó vào một scene.
	if Engine.is_editor_hint():
		return
	if _agent == null:
		return

	# 1. Người chơi tới gần -> đứng yên, quay mặt về phía họ.
	if _near_player():
		if _moving:
			_moving = false
		_set_anim("idle")
		var ve := _player.global_position - global_position
		ve.y = 0.0
		_turn_towards(ve, delta)
		return

	# 2. Đang nghỉ -> đếm ngược rồi chọn chỗ mới.
	if not _moving:
		_rest_left -= delta
		if _rest_left <= 0.0:
			_wander()
		return

	# 3. Đang đi.
	if _agent.is_navigation_finished():
		_moving = false
		_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)
		_set_anim("idle")
		return

	var toi := _agent.get_next_path_position()
	var huong := toi - global_position
	huong.y = 0.0
	if huong.length_squared() < 0.0001:
		return
	huong = huong.normalized()
	# Cộng thẳng vào vị trí: Doro là StaticBody3D nên không có move_and_slide,
	# và cũng không cần — nó không va vào gì cả.
	global_position += huong * Config.SPEED * delta
	# Khoá độ cao về mặt sàn. Điểm đường của agent nằm trên mặt navmesh, cao
	# hơn sàn một chút; đi theo cả trục Y thì Doro trôi dần lên trên.
	global_position.y = _floor_y
	_turn_towards(huong, delta)


func _near_player() -> bool:
	if not is_instance_valid(_player):
		return false
	var d := _player.global_position - global_position
	d.y = 0.0
	return d.length() <= Config.NEAR_PLAYER


## Chọn chỗ đi tiếp: bốc quanh chỗ đang đứng, KẸP vào vùng cho phép, rồi nắn
## về navmesh.
##
## Thứ tự ba bước đó quan trọng. Kẹp TRƯỚC khi nắn: nắn trước thì
## map_get_closest_point có thể kéo điểm sang hòn đảo navmesh của khu bếp, và
## kẹp sau đó chỉ sửa được toạ độ chứ không sửa được việc nó đã ở sai vùng.
##
## Vẫn KIỂM TRA LẠI sau khi nắn: mép navmesh không trùng mép vùng, nên điểm
## đã kẹp vẫn có thể bị nắn ra ngoài. Ra ngoài thì bỏ lượt này, nghỉ rồi bốc
## lại — rẻ hơn nhiều so với việc thử lặp cho tới khi trúng, và Doro đứng
## nghỉ thêm một nhịp thì không ai nhận ra.
func _wander() -> void:
	var ban_do := get_world_3d().navigation_map
	if not ban_do.is_valid():
		return

	var goc := randf() * TAU
	var xa := randf_range(1.5, Config.WANDER_RADIUS)
	var dich := global_position + Vector3(cos(goc) * xa, 0.0, sin(goc) * xa)
	dich = _clamp_to_area(dich)
	dich = NavigationServer3D.map_get_closest_point(ban_do, dich)

	if dich.is_equal_approx(Vector3.ZERO) or not _inside_area(dich):
		_rest_left = randf_range(Config.REST_MIN, Config.REST_MAX)
		return

	_agent.target_position = dich
	_moving = true
	_set_anim("walk")


## Kéo một điểm vào trong hình chữ nhật cho phép (giữ nguyên độ cao).
static func _clamp_to_area(diem: Vector3) -> Vector3:
	return Vector3(
		clampf(diem.x, Config.AREA_MIN.x, Config.AREA_MAX.x),
		diem.y,
		clampf(diem.z, Config.AREA_MIN.y, Config.AREA_MAX.y))


## Điểm có nằm trong vùng cho phép không.
##
## Nới thêm AREA_MARGIN ở mọi phía: navmesh bị Recast bào lùi khỏi tường, nên một
## điểm hợp lệ sát mép vùng rất hay bị nắn ra ngoài vài chục centimet. Không
## nới thì Doro bỏ gần hết số lượt bốc và đứng nghỉ gần như suốt màn.
const AREA_MARGIN := 0.6

static func _inside_area(diem: Vector3) -> bool:
	return diem.x >= Config.AREA_MIN.x - AREA_MARGIN \
		and diem.x <= Config.AREA_MAX.x + AREA_MARGIN \
		and diem.z >= Config.AREA_MIN.y - AREA_MARGIN \
		and diem.z <= Config.AREA_MAX.y + AREA_MARGIN


## Chỗ Doro đứng lúc màn bắt đầu: GIỮA vùng cho phép, nắn về navmesh.
##
## Hàm static để level_base hỏi được mà không phải dựng node trước — chỗ đứng
## phải biết TRƯỚC khi gọi setup().
static func first_stand_point(ban_do: RID, cao_san: float) -> Vector3:
	var giua := Vector3(
		(Config.AREA_MIN.x + Config.AREA_MAX.x) * 0.5,
		cao_san,
		(Config.AREA_MIN.y + Config.AREA_MAX.y) * 0.5)
	# `is_valid()` CHƯA đủ. Bản đồ điều hướng chỉ trả lời được sau lần đồng bộ
	# đầu tiên; hỏi sớm thì NavigationServer in một dòng lỗi đỏ rồi trả về
	# (0,0,0). Đây đúng là cái bẫy đã làm người khách đầu tiên đứng chết ở cửa
	# hồi tháng 9 — `map_get_iteration_id() == 0` là cách kiểm tra mà
	# `Khach.snap_to_navmesh()` đang dùng.
	#
	# Chưa sẵn sàng thì lấy thẳng tâm vùng: nó nằm giữa khu khách nên gần như
	# chắc chắn đi được, và ngay nhịp đi đầu tiên Doro sẽ tự nắn về navmesh.
	if not ban_do.is_valid() or NavigationServer3D.map_get_iteration_id(ban_do) == 0:
		return giua
	var nan := NavigationServer3D.map_get_closest_point(ban_do, giua)
	if nan.is_equal_approx(Vector3.ZERO):
		return giua
	nan.y = cao_san
	return nan


func _turn_towards(huong: Vector3, delta: float) -> void:
	if huong.length_squared() < 0.0001:
		return
	var dich := atan2(huong.x, huong.z)
	rotation.y = rotate_toward(rotation.y, dich, Config.TURN_SPEED * delta)


# ------------------------------------------------------------------ diễn ---

func _set_anim(ten: String) -> void:
	if _anim_now == ten:
		return
	if _hoat_hinh == null or not _hoat_hinh.has_animation(ten):
		return
	_anim_now = ten
	_hoat_hinh.play(ten)


## Nảy một cái khi người chơi bấm E vào Doro.
##
## Nảy bằng SCALE của node thân chứ không bằng animation: model chỉ có hai clip
## (idle, walk), không có clip "ăn". Một cú nảy 0,18 giây đủ để người chơi biết
## thao tác đã ăn — mà đó mới là việc cần làm, không phải diễn cho đẹp.
func _on_fed(_station: Node, _index: int) -> void:
	if _body == null:
		return
	# KHÔNG phát tiếng ở đây: `tay_cam._bo_di()` đã phát "vut_rac" khi thật sự
	# có đồ bị vứt. Phát thêm ở đây thì tiếng kêu hai lần chồng nhau.
	#
	# Và vì thế, bấm E lúc tay TRỐNG chỉ có cú nảy mà không có tiếng — hoá ra
	# lại đúng: đó thành ra thao tác VUỐT VE patience_left thú, không phải vứt rác.
	var ti := Config.HEIGHT / Config.BASE_HEIGHT
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "scale", Vector3(ti * 1.2, ti * 0.8, ti * 1.2), 0.09)
	tw.tween_property(_body, "scale", Vector3(ti, ti, ti), 0.09)
