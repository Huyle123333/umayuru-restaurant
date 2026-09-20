extends Node3D
## Script chung cho node gốc của mọi màn chơi.
##
## Hai việc: sinh nhân vật người chơi tại PlayerSpawn, và gắn menu Pause.
## Nhân vật KHÔNG được đặt sẵn trong file map, vì như vậy thì menu chọn
## nhân vật sẽ vô nghĩa và mỗi lần sửa nhân vật phải sửa lại từng màn.

## Nhân vật DỰ PHÒNG: chỉ dùng khi chưa qua màn hình chọn nhân vật
## (ví dụ bấm F6 chạy thẳng map trong editor). Bình thường màn chơi lấy
## nhân vật từ GameData.selected_character.
@export var player_scene: PackedScene
## Đường dẫn tới Marker3D đánh dấu chỗ nhân vật xuất hiện.
@export var spawn_path: NodePath = ^"PlayerSpawn"

## Menu Pause gắn vào bằng CODE chứ không đặt sẵn trong từng file map.
## Lý do: mỗi màn mới chỉ cần dùng script này là tự có menu thoát — không ai
## phải nhớ kéo thêm node, và không thể có màn nào bị kẹt không thoát được.
const PAUSE_MENU := preload("res://scenes/menu/pause_menu.tscn")

## CHEAT TUA GIỜ (phím 0) — kéo đồng hồ màn về còn bấy nhiêu giây.
##
## Vì sao 210 chứ không phải 212: 212 đúng là mốc đổi sang nhạc cao điểm
## (GameData ... "moc_nhac"), mà luat_man so bằng `con_lai <= moc_nhac`. Đặt
## đúng 212,0 thì kết quả phụ thuộc vào khung hình nào chạy trước — tua xong
## có thể vẫn còn 212,0 chằn và nhạc chưa đổi. Đặt 210 là ĐÃ VƯỢT mốc, nên
## nhạc chắc chắn đổi ngay khung hình kế tiếp. Ba chữ số trên đồng hồ hiện
## 3:30, vừa đẹp.
const GIAY_TUA := 210.0

## Tham chiếu tới nhân vật đang chơi, để các hệ thống khác (HUD, đơn hàng,
## kỹ năng...) lấy dùng sau này.
var player: CharacterBody3D
## Hệ khách hàng của màn này. Các hệ khác (đơn hàng, tính tiền) sẽ hỏi qua đây.
var quan_ly_khach: Node


func _ready() -> void:
	_spawn_player()
	add_child(PAUSE_MENU.instantiate())


func _spawn_player() -> void:
	var spawn := get_node_or_null(spawn_path) as Marker3D
	if spawn == null:
		push_error("Màn chơi thiếu node PlayerSpawn (hoặc sai spawn_path).")
		return
	var scene_nhan_vat := _scene_nhan_vat_dang_chon()
	if scene_nhan_vat == null:
		push_error("Không có scene nhân vật nào để sinh (cả GameData lẫn Inspector đều trống).")
		return

	player = scene_nhan_vat.instantiate() as CharacterBody3D
	# Thêm vào cây scene TRƯỚC, gán vị trí SAU. Làm ngược lại thì toạ độ
	# toàn cục được tính khi node còn chưa nằm trong cây, kết quả sai.
	add_child(player)
	# Gán cả transform chứ không chỉ position: Marker3D quay hướng nào thì
	# nhân vật xuất hiện quay đúng hướng đó.
	player.global_transform = spawn.global_transform

	_gan_he_tuong_tac()


## Chọn scene nhân vật để sinh ra.
##
## Ưu tiên nhân vật người chơi vừa chọn ở màn hình chọn nhân vật; nếu vì lý do
## gì đó không có (chạy thẳng file map từ editor để thử, id lạ, nhân vật chưa
## dựng scene) thì lùi về ô player_scene gán trong Inspector. Nhờ vậy mở map
## bằng F6 vẫn chơi được ngay mà không phải qua menu.
##
## Dùng ResourceLoader.exists() trước khi load: nếu một nhân vật bị đổi tên file
## hay xoá nhầm thì ta muốn màn chơi vẫn mở lên với nhân vật dự phòng và console
## in rõ file nào thiếu, chứ không phải màn hình đen không rõ lý do.
func _scene_nhan_vat_dang_chon() -> PackedScene:
	var id := ""
	if Engine.has_singleton("GameData") or get_node_or_null("/root/GameData") != null:
		id = str(GameData.selected_character)

	if not id.is_empty():
		var duong_dan := GameData.character_scene_path(id)
		if duong_dan.is_empty():
			push_warning("Nhân vật '%s' chưa có scene điều khiển — dùng nhân vật dự phòng." % id)
		elif not ResourceLoader.exists(duong_dan):
			push_warning("Không tìm thấy '%s' — dùng nhân vật dự phòng." % duong_dan)
		else:
			var res := load(duong_dan) as PackedScene
			if res != null:
				return res

	return player_scene


func _khoa_nhan_vat(is_open: bool) -> void:
	if player != null:
		player.khoa_di_chuyen = is_open


## Gắn bộ chọn mục tiêu vào nhân vật và bật HUD tương tác.
##
## Cả hai được tạo BẰNG CODE ở đây thay vì đặt sẵn trong player_kitamoi.tscn.
## Lý do: game có bốn nhân vật chơi được. Nếu nhét bộ chọn vào từng scene nhân
## vật thì mỗi lần sửa cơ chế phải sửa bốn chỗ và rất dễ quên một cái. Đặt ở
## màn chơi thì nhân vật nào được sinh ra cũng có, và scene nhân vật giữ đúng
## một việc là "cái người chơi điều khiển".
##
## Dùng load() lúc chạy chứ KHÔNG dùng preload hay tên lớp (class_name).
## Lý do quan trọng: preload và class_name được phân giải lúc BIÊN DỊCH. Nếu
## một trong hai script kia có lỗi cú pháp thì chính level_base.gd cũng không
## biên dịch được — mà nó là script gốc của mọi màn chơi, nên cả cái map sẽ
## không load và màn hình trắng trơn, không có gì để lần ra nguyên nhân.
## Với load() thì lỗi ở hệ tương tác chỉ làm mất HUD, map vẫn chạy và console
## in ra đúng file hỏng.
func _gan_he_tuong_tac() -> void:
	var lop_bo_chon := load("res://scripts/interaction/target_picker.gd") as GDScript
	var lop_hud := load("res://scripts/interaction/interaction_hud.gd") as GDScript
	if lop_bo_chon == null or lop_hud == null:
		push_warning("Hệ tương tác không nạp được — màn chơi vẫn chạy nhưng không có HUD chọn mục tiêu.")
		return

	var bo_chon: Node = lop_bo_chon.new()
	bo_chon.name = "BoChonMucTieu"
	player.add_child(bo_chon)

	var hud: Node = lop_hud.new()
	hud.name = "HudTuongTac"
	add_child(hud)
	hud.listen_to_picker(bo_chon)
	hud.follow_character(player)

	# Đôi tay: cầm/đặt/thả vật thể. Cũng nạp lúc chạy vì cùng lý do với hai
	# script trên — lỗi ở đây không được phép làm cả màn chơi không mở lên.
	var lop_tay := load("res://scripts/interaction/hands.gd") as GDScript
	var lop_bang := load("res://scripts/interaction/picker_menu.gd") as GDScript
	if lop_tay != null:
		var tay: Node = lop_tay.new()
		tay.name = "TayCam"
		player.add_child(tay)
		hud.listen_to_hands(tay)

		# Hệ thống bếp: một node quản lý chung cho mọi cái bếp trong màn.
		var lop_bep := load("res://scripts/interaction/cooking_system.gd") as GDScript
		if lop_bep != null:
			var cooking: Node = lop_bep.new()
			cooking.name = "HeBep"
			add_child(cooking)
			tay.cooking = cooking
			hud.listen_to_cooking(cooking)

			# Thanh tiến trình RIÊNG cho từng trạm, nổi trên đầu trạm đó.
			#
			# Node riêng chứ không nhét vào hud_tuong_tac: HUD kia đã 24 KB và
			# lo bốn thứ không liên quan nhau (danh sách trạm trong tầm, thể
			# lực, ô kĩ năng, bảng bàn chế tạo). Thanh trạm thì chỉ cần biết
			# hệ bếp và cái camera — không đụng gì tới bốn thứ đó, nên tách ra
			# là tách được sạch.
			var lop_thanh := load("res://scripts/ui/station_bars.gd") as GDScript
			if lop_thanh != null:
				var tt: Node = lop_thanh.new()
				tt.name = "ThanhTram"
				add_child(tt)
				tt.listen_to_cooking(cooking)
			else:
				push_warning("Không nạp được thanh tiến trình của trạm.")

		if lop_bang != null:
			var bang: Node = lop_bang.new()
			bang.name = "BangChon"
			add_child(bang)
			# Ba mối nối, mỗi cái một việc: tay xin mở bảng, bảng báo đã
			# chọn xong, và bảng báo mở/đóng để khoá di chuyển nhân vật.
			tay.request_picker.connect(bang.open)
			bang.item_chosen.connect(tay.receive_ingredient)
			bang.open_state_changed.connect(_khoa_nhan_vat)

	# Hệ kĩ năng chủ động (phím Space). Hiện mới lo phần cut-in; hiệu ứng thật
	# cắm vào sau. Đặt ở màn chơi chứ không trong scene nhân vật, cùng lý do
	# với bộ chọn mục tiêu: bảy nhân vật thì bảy chỗ phải sửa.
	_lo_vat_cam_trong_map()

	var lop_ki_nang := load("res://scripts/skills/skill_manager.gd") as GDScript
	if lop_ki_nang != null:
		var ki_nang: Node = lop_ki_nang.new()
		ki_nang.name = "SkillManager"
		add_child(ki_nang)
		ki_nang.track_character(player)
		hud.listen_to_skills(ki_nang)
	else:
		push_warning("Không nạp được hệ kĩ năng — màn chơi vẫn chạy, chỉ thiếu cut-in.")

	# Hệ khách hàng: sinh khách, xếp hàng, chia bàn, và nướng vùng đi lại.
	# Cùng lý do đặt ở màn chơi với mọi hệ thống trên.
	var lop_khach := load("res://scripts/restaurant/customer_manager.gd") as GDScript
	if lop_khach != null:
		quan_ly_khach = lop_khach.new()
		quan_ly_khach.name = "QuanLyKhach"
		add_child(quan_ly_khach)
		# chuan_bi() phải gọi SAU add_child: nó dùng get_tree() để tìm nhóm
		# "dining_table" và gắn vùng navmesh vào cây scene.
		quan_ly_khach.setup(self)
		_gan_hud_don_hang()
	else:
		push_warning("Không nạp được hệ khách hàng — màn chơi vẫn chạy, chỉ không có khách.")

	# Mọi trạm CHỨA được đồ đều phát tín hiệu khi nội dung đổi; HUD vẽ lại
	# ghi chú. Nối tất cả thay vì chỉ bàn chế tạo: thớt, bếp và lò giờ cũng
	# giữ nguyên liệu, và người chơi cần thấy trong đó đang có gì y như với
	# cái bàn — nhất là cái lò, nơi họ phải nhớ đã bỏ đủ topping chưa.
	for n in get_tree().get_nodes_in_group("station"):
		if n.get("kind") in ["crafting_table", "prep_table"]:
			hud.listen_to_table(n)


## Duyệt mọi vật cầm ĐẶT SẴN trong file map và xử lý hai việc trái ngược nhau.
##
## 1. Vật thuộc nhóm đang bị khoá trong DanhMuc → GIẤU HẲN.
##    Đôi tay đã từ chối cầm chúng rồi, nhưng để nguyên một cái nồi sờ sờ giữa
##    bếp mà bấm E không ra gì thì người chơi tưởng game hỏng chứ không tưởng
##    là tính năng chưa mở.
##    Tắt cả collision_layer chứ không chỉ hide(): node ẩn vẫn còn va chạm,
##    nên nhân vật sẽ đâm vào một bức tường vô hình đúng chỗ cái nồi từng đứng.
##
## 2. Vật KHÔNG bị khoá → DỰNG ĐỦ BỘ cho nó (mesh, hộp va chạm, điểm nhắm).
##    Đây là chỗ vá một lỗi im lặng đã nằm trong map từ đầu: cái nồi trong
##    restaurant_map_planb.tscn là một StaticBody3D TRẦN — không mesh, không
##    CollisionShape3D. Nghĩa là nó vừa vô hình vừa không bấm được, và console
##    không in một dòng nào, vì xét về mặt kỹ thuật thì chẳng có gì sai cả:
##    ở chỗ đó đơn giản là không có gì. Lỗi này sống sót qua nhiều buổi vì
##    triệu chứng của nó ("nồi đâu?") trùng với triệu chứng của việc hệ nồi
##    đang bị khoá.
##
## Làm lúc CHẠY chứ không sửa vào file map: mở/khoá một nhóm vật phẩm sau này
## chỉ cần đổi một công tắc trong DanhMuc, không phải dựng lại node vào đúng
## chỗ cũ trong map.
func _lo_vat_cam_trong_map() -> void:
	var item_catalog := load("res://scripts/interaction/item_catalog.gd") as GDScript
	if item_catalog == null:
		return
	for station in _tim_tram(self):
		# Chồng nồi không phải vật cầm được, nhưng nó là NGUỒN của cái nồi —
		# công tắc NOI_MO tắt thì nó phải biến mất cùng cả nhóm món nồi, nếu
		# không người chơi vẫn lấy được một cái nồi vô dụng.
		if station.kind == "pot_stack" and item_catalog.is_locked("noi"):
			station.hide()
			station.collision_layer = 0
			station.collision_mask = 0
			continue
		if station.kind != "carriable":
			continue
		if item_catalog.is_locked(station.item_id):
			station.hide()
			station.collision_layer = 0
			station.collision_mask = 0
			continue
		station.build_carriable()


func _tim_tram(goc: Node) -> Array[Workstation]:
	var ra: Array[Workstation] = []
	for con in goc.get_children():
		var t := con as Workstation
		if t != null:
			ra.append(t)
		ra.append_array(_tim_tram(con))
	return ra


## Hai bảng HUD của hệ đơn hàng: cột vé bên trái, đồng hồ & ví bên phải.
##
## Tách khỏi _gan_he_tuong_tac() vì chúng phụ thuộc quan_ly_khach chứ không
## phụ thuộc nhân vật người chơi — nối nhầm thứ tự thì tín hiệu nối vào null
## mà không báo lỗi, cái vé chỉ đơn giản là không bao giờ hiện.
##
## Cả hai chỉ NGHE tín hiệu. Chúng không đọc trạng thái khách, không tự đếm
## kiên nhẫn, không tự cộng tiền — luật nằm trọn trong quan_ly_khach.gd.
func _gan_hud_don_hang() -> void:
	var lop_ve := load("res://scripts/ui/order_board.gd") as GDScript
	if lop_ve != null:
		var bang: Node = lop_ve.new()
		bang.name = "BangDonHang"
		add_child(bang)
		bang.listen_to_orders(quan_ly_khach)
	else:
		push_warning("Không nạp được cột vé đơn hàng.")

	var lop_gio := load("res://scripts/ui/hud_clock.gd") as GDScript
	var bang_gio: Node = null
	if lop_gio != null:
		bang_gio = lop_gio.new()
		bang_gio.name = "BangThoiGian"
		add_child(bang_gio)
		bang_gio.listen_to_orders(quan_ly_khach)
		bang_gio.time_up.connect(_ket_thuc_man.bind(""))
	else:
		push_warning("Không nạp được bảng thời gian.")

	_gan_doro()

	# Hệ kĩ năng phải chờ tới ĐÂY mới gắn được: nó vặn núm của hệ khách hàng,
	# hệ bếp và đồng hồ màn, nên cả ba phải tồn tại trước. Node SkillManager
	# được dựng sớm hơn (trong _gan_he_tuong_tac) vì HUD cần nối tín hiệu của
	# nó ngay, còn phần vặn núm tách ra setup() gọi sau — hai việc, hai
	# thời điểm, thay vì phải sắp lại thứ tự dựng node.
	#
	# Đặt TRƯỚC _ap_dung_luat_man: luật màn đặt thời lượng và nhịp khách của
	# riêng màn đó, và nếu sau này có kĩ năng đụng tới hai thứ ấy thì kĩ năng
	# phải là lớp đè lên luật màn, không phải ngược lại.
	var kn := get_node_or_null("SkillManager")
	if kn != null:
		kn.setup(quan_ly_khach, get_node_or_null("HeBep"), bang_gio)

	_ap_dung_luat_man(bang_gio)
	_gan_mo_man(bang_gio)
	_gan_tutorial(bang_gio)


## Áp luật riêng của màn đang chơi (thực đơn, nhịp khách, thời lượng).
##
## Gọi TRƯỚC _gan_mo_man(): màn hình mở đầu đóng băng đồng hồ và việc sinh
## khách, nên nếu áp luật sau nó thì có một khoảng — dù chỉ vài khung hình —
## mà đồng hồ đã bị đặt lại thời lượng trong lúc đang bị đóng băng, và thứ tự
## khôi phục trở nên phụ thuộc vào việc ai chạy trước.
##
## Không có luật (màn hướng dẫn, hoặc F6 chạy thẳng map) thì bỏ node đi luôn
## thay vì để nó nằm im: một node "đạo diễn" không đạo diễn gì cả vẫn chạy
## _process mỗi khung hình, và tệ hơn là nó khiến cây scene nói dối về việc
## màn này có luật riêng.
func _ap_dung_luat_man(bang_gio: Node) -> void:
	if quan_ly_khach == null or get_node_or_null("/root/GameData") == null:
		return
	var luat: Dictionary = GameData.rules_for_level(String(GameData.current_level))
	if luat.is_empty():
		return

	var lop := load("res://scripts/restaurant/level_rules.gd") as GDScript
	if lop == null:
		push_warning("Không nạp được luật màn — màn chơi dùng số mặc định.")
		return

	var lm: Node = lop.new()
	lm.name = "LuatMan"
	add_child(lm)
	if not lm.setup(quan_ly_khach, bang_gio, luat):
		lm.queue_free()


## Doro — thú cưng đi lang thang, kiêm thùng rác thứ hai.
##
## Dựng BẰNG CODE ở đây chứ không đặt sẵn trong file map, cùng lý do với mọi
## hệ thống khác: tám màn dùng chung một map, và Doro cần biết cả navmesh (do
## quan_ly_khach nướng lúc chạy) lẫn nhân vật người chơi (do màn chơi sinh ra)
## — hai thứ chỉ tồn tại lúc chạy, không có cách nào kéo vào Inspector.
##
## Gọi SAU quan_ly_khach.chuan_bi(): Doro hỏi độ lệch cao của navmesh, mà con
## số đó chỉ có sau khi nướng xong.
##
## Chỗ đứng ban đầu: GIỮA vùng đi lại của Doro (khu khách), do chính lớp Doro
## tính — xem `doro_pet.cho_dung_dau()`.
##
## Bản đầu đặt Doro cạnh thùng rác bocchi, với lý lẽ "hai thứ cùng làm một
## việc thì đứng cùng một chỗ". Lý lẽ đó sai vì một chi tiết của bố cục: cái
## thùng rác nằm TRONG BẾP. Mà navmesh của khu bếp là một hòn đảo tách rời
## (hai tấm chắn vô hình ngắt đường nối), nên Doro sinh ra ở đó là mắc kẹt
## trong bếp cả màn — đúng chỗ nó gây vướng nhất.
func _gan_doro() -> void:
	if quan_ly_khach == null or player == null:
		return
	var lop := load("res://scripts/restaurant/doro_pet.gd") as GDScript
	if lop == null:
		push_warning("Không nạp được Doro — màn chơi vẫn chạy, chỉ thiếu pet.")
		return

	var cho: Vector3 = lop.first_stand_point(get_world_3d().navigation_map, 0.0)
	var pet: Node3D = lop.new()
	pet.name = "Doro"
	add_child(pet)
	pet.setup(cho, float(quan_ly_khach.navmesh_height_offset()), player)


## Bộ dẫn dắt màn hướng dẫn — CHỈ dựng khi màn đang chơi là "tutorial".
##
## Hỏi GameData.current_level thay vì để một cờ @export trong file map: cả tám
## màn dùng CHUNG một file map (xem GameData.LEVELS), nên một cờ trong map sẽ
## bật hướng dẫn cho cả Ngày 1, Ngày 2, Ngày 3.
##
## Chạy thẳng map bằng F6 từ editor thì current_level rỗng và không có hướng
## dẫn — đúng ý: lúc đó đang thử bếp, không ai muốn bị giảng bài.
func _gan_tutorial(bang_gio: Node) -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	if String(GameData.current_level) != "tutorial":
		return

	var lop := load("res://scripts/story/tutorial_director.gd") as GDScript
	if lop == null:
		push_warning("Không nạp được bộ dẫn dắt hướng dẫn — màn vẫn chơi được như màn thường.")
		return

	var tay := player.get_node_or_null("TayCam")
	var cooking := get_node_or_null("HeBep")
	var dd: Node = lop.new()
	dd.name = "TutorialDirector"
	add_child(dd)
	dd.tutorial_finished.connect(_khi_xong_tutorial)
	dd.setup(player, tay, cooking, quan_ly_khach, bang_gio)


## Hướng dẫn kết thúc.
##
## Học hết kịch bản thì tổng kết NGAY với hạng S ép cứng — màn hướng dẫn không
## có đồng hồ nên không bao giờ tự hết giờ, mà bắt người mới đứng chờ trong một
## cái bếp không còn gì để làm thì chẳng dạy thêm được gì. Ép hạng S vì đây là
## bài học chứ không phải bài thi: người chơi vừa làm đúng từng bước một, chấm
## họ hạng C vì "doanh thu chỉ có 80" là vô lý.
##
## Bấm "Tự làm" thì KHÔNG tổng kết: bộ dẫn dắt đã trả màn về luật bình thường,
## đồng hồ chạy, và màn kết thúc bằng đường hết giờ như mọi màn khác.
func _khi_xong_tutorial(tong_ket: bool) -> void:
	if tong_ket:
		_ket_thuc_man("S")


## Kết thúc màn: đóng cửa quán rồi hiện bảng tổng kết.
##
## `ep_hang` rỗng = tự xếp theo doanh thu.
## Phím 0: nhảy tới cuối màn. CHỈ chạy khi cheat được bật trong bảng cheat.
##
## Đây là công cụ TRÌNH BÀY, không phải cơ chế chơi: buổi bảo vệ đồ án không
## ngồi chờ hết bảy phút để hội đồng nghe được đoạn nhạc cao điểm và nhìn bảng
## tổng kết. Chia làm HAI NẤC (lần một tua, lần hai tổng kết) chứ không nhảy
## thẳng ra bảng kết quả, vì hai thứ cần cho xem là hai thứ khác nhau và ở hai
## thời điểm khác nhau.
##
## Dùng _unhandled_key_input chứ không _input: menu Pause hay ô nhập liệu nào
## đang mở thì chúng ăn phím trước, và cheat không cướp phím của giao diện.
func _unhandled_key_input(event: InputEvent) -> void:
	if get_node_or_null("/root/GameData") == null or not GameData.cheat_time_skip:
		return
	var phim := event as InputEventKey
	if phim == null or not phim.pressed or phim.echo:
		return
	# Nhận cả phím 0 hàng số lẫn phím 0 bàn phím số. Dùng physical_keycode nên
	# bố cục bàn phím nào cũng đúng.
	if phim.physical_keycode != KEY_0 and phim.physical_keycode != KEY_KP_0:
		return
	get_viewport().set_input_as_handled()
	_tua_gio()


func _tua_gio() -> void:
	# Bảng kết quả đã hiện thì không còn gì để tua.
	if get_node_or_null("BangKetQua") != null:
		return
	var gio := get_node_or_null("BangThoiGian")
	if gio == null:
		# Màn không có đồng hồ (hướng dẫn): bấm một cái là tổng kết luôn.
		_ket_thuc_man("")
		return
	if float(gio.time_left) > GIAY_TUA:
		# Gán thẳng con_lai thay vì gọi một hàm riêng: _process của đồng hồ đọc
		# biến này mỗi khung hình và tự so trước-sau để bắn tín hiệu mốc, nên
		# đổi giá trị là mọi thứ ăn theo đúng như thời gian trôi tự nhiên.
		gio.time_left = GIAY_TUA
	else:
		_ket_thuc_man("")


func _ket_thuc_man(ep_hang: String) -> void:
	# Chặn gọi hai lần: hết giờ và hướng dẫn xong về lý thuyết có thể trùng
	# nhau, và hai tấm bảng chồng lên nhau thì cái dưới không bao giờ đóng.
	if get_node_or_null("BangKetQua") != null:
		return

	var lop := load("res://scripts/ui/results_panel.gd") as GDScript
	if lop == null:
		push_warning("Không nạp được bảng kết quả — màn chơi kết thúc mà không tổng kết.")
		return

	var tien := 0
	var xong := 0
	var hoan_hao := 0
	var bo_di := 0
	if quan_ly_khach != null:
		quan_ly_khach.close_shop()
		tien = int(quan_ly_khach.money)
		xong = int(quan_ly_khach.orders_done)
		hoan_hao = int(quan_ly_khach.perfect_orders)
		bo_di = int(quan_ly_khach.customers_lost)

	var bang: Node = lop.new()
	bang.name = "BangKetQua"
	add_child(bang)
	bang.show_results(tien, xong, hoan_hao, bo_di, ep_hang)


## Màn hình mở đầu: hiện tên màn, đếm ngược, rồi mới thả đồng hồ và khách vào.
##
## ĐÓNG BĂNG ĐÚNG HAI THỨ — đồng hồ màn và việc sinh khách — chứ không tạm dừng
## cả game. Mười giây đó để người chơi ĐI THỬ MỘT VÒNG BẾP: có mười tám trạm
## nằm rải khắp phòng, và người mới cần biết cái tủ lạnh ở đâu trước khi có
## khách. Tạm dừng thì họ chỉ đứng nhìn một con số đếm lùi.
##
## Màn hướng dẫn KHÔNG có màn mở đầu: ở đó trainer đã dẫn từng bước, chèn thêm
## một lớp chữ nữa chỉ làm loãng.
func _gan_mo_man(bang_gio: Node) -> void:
	if get_node_or_null("/root/GameData") != null \
			and String(GameData.current_level) == "tutorial":
		return

	var lop := load("res://scripts/ui/level_intro.gd") as GDScript
	if lop == null:
		return

	var ten := "BẮT ĐẦU"
	if get_node_or_null("/root/GameData") != null:
		var t := GameData.level_name(String(GameData.current_level))
		if not t.is_empty():
			ten = t

	# Đóng băng TRƯỚC khi hiện chữ, không phải sau: giữa hai việc đó có ít nhất
	# một khung hình, và một khung hình đủ để đồng hồ trừ mất thời gian.
	if bang_gio != null:
		bang_gio.counting_down = false
	if quan_ly_khach != null:
		quan_ly_khach.auto_spawn = false

	var mo: Node = lop.new()
	mo.name = "MoMan"
	add_child(mo)
	mo.started.connect(func() -> void:
		if bang_gio != null:
			bang_gio.counting_down = true
		if quan_ly_khach != null:
			quan_ly_khach.auto_spawn = true
		# Bốc ngẫu nhiên trong sáu bài, KHÔNG giữ liền mạch: vào một ca làm
		# việc mới thì phải nghe như một ca mới, chứ không phải như đoạn giữa
		# của bài nhạc đang chạy ở menu.
		AmThanh.play_random_music("level"))
	mo.start_countdown(ten)
