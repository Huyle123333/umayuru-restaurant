extends Node3D
## Script chung cho node gốc của mọi màn chơi.
##
## Hai việc: sinh nhân vật người chơi tại PlayerSpawn, và gắn menu Pause.
## Nhân vật KHÔNG được đặt sẵn trong file map, vì như vậy thì menu chọn
## nhân vật sẽ vô nghĩa và mỗi lần sửa nhân vật phải sửa lại từng màn.

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

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
## (210 giây từng được chọn để vượt mốc đổi nhạc cao điểm 212 giây; cơ chế
## đó đã bỏ 21/10/2026, con số giữ nguyên vì đồng hồ hiện 3:30 dễ đọc.)
const SKIP_SECONDS := 210.0

## Tham chiếu tới nhân vật đang chơi, để các hệ thống khác (HUD, đơn hàng,
## kỹ năng...) lấy dùng sau này.
var player: CharacterBody3D
## Hệ khách hàng của màn này. Các hệ khác (đơn hàng, tính tiền) sẽ hỏi qua đây.
var customers: Node


func _ready() -> void:
	_spawn_player()
	add_child(PAUSE_MENU.instantiate())


## ── LỚP VA CHẠM (cả project) ─────────────────────────────────────────────
##   1  (1)   thế giới: sàn, tường, bàn, phần lớn các trạm
##   3  (4)   vật cầm được + Doro      — Workstation.LAYER_ITEM
##   4  (8)   khách hàng               — customer.tscn
##   5  (16)  tấm chắn navmesh         — customer_manager.NAV_BLOCK_LAYER
##   6  (32)  NGƯỜI CHƠI               — PLAYER_LAYER
##   7  (64)  tường CHỈ chặn người chơi — PLAYER_ONLY_WALL_LAYER
##
## Vì sao người chơi phải ra khỏi lớp 1: trước đây người chơi nằm ở lớp 1
## CHUNG với tường, và khách có mask = 1 để không đi xuyên tường. Hệ quả là
## mask của khách bao luôn cả người chơi — khách đi tới đụng người chơi thì
## khựng lại, hoặc trượt lệch khỏi đường navmesh. Không có cách nào viết mask
## "tường nhưng không phải người chơi" khi hai thứ chung một lớp.
##
## Tách ra lớp 6 thì cả HAI chiều đều không va: mask khách (1) không chứa 32,
## mask người chơi (1 | 64) không chứa 8. Phải chặn cả hai chiều vì Godot chỉ
## cần MỘT bên có mask chứa lớp bên kia là hai vật đã tính va chạm với nhau.
const PLAYER_LAYER := 1 << 5

## Tường vô hình chỉ người chơi thấy — chắn cửa ra vào (node DoorBarrier trong
## map). Khách KHÔNG có lớp này trong mask, và bộ nướng navmesh chỉ đọc lớp
## 1 | 16, nên tấm chắn không làm hẹp đường đi của khách lấy một ô nào.
const PLAYER_ONLY_WALL_LAYER := 1 << 6


func _spawn_player() -> void:
	var spawn := get_node_or_null(spawn_path) as Marker3D
	if spawn == null:
		push_error("Màn chơi thiếu node PlayerSpawn (hoặc sai spawn_path).")
		return
	var character_scene := _selected_character_scene()
	if character_scene == null:
		push_error("Không có scene nhân vật nào để sinh (cả GameData lẫn Inspector đều trống).")
		return

	player = character_scene.instantiate() as CharacterBody3D
	# Thêm vào cây scene TRƯỚC, gán vị trí SAU. Làm ngược lại thì toạ độ
	# toàn cục được tính khi node còn chưa nằm trong cây, kết quả sai.
	add_child(player)
	# Gán cả transform chứ không chỉ position: Marker3D quay hướng nào thì
	# nhân vật xuất hiện quay đúng hướng đó.
	player.global_transform = spawn.global_transform

	# Lớp va chạm riêng cho người chơi. Xem PLAYER_LAYER.
	player.collision_layer = PLAYER_LAYER
	player.collision_mask = 1 | PLAYER_ONLY_WALL_LAYER

	_build_interaction()


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
func _selected_character_scene() -> PackedScene:
	var id := ""
	if Engine.has_singleton("GameData") or get_node_or_null("/root/GameData") != null:
		id = str(GameData.selected_character)

	if not id.is_empty():
		var path := GameData.character_scene_path(id)
		if path.is_empty():
			push_warning("Nhân vật '%s' chưa có scene điều khiển — dùng nhân vật dự phòng." % id)
		elif not ResourceLoader.exists(path):
			push_warning("Không tìm thấy '%s' — dùng nhân vật dự phòng." % path)
		else:
			var res := load(path) as PackedScene
			if res != null:
				return res

	return player_scene


func _lock_player(is_open: bool) -> void:
	if player != null:
		player.movement_locked = is_open


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
func _build_interaction() -> void:
	var cls_target := load("res://scripts/interaction/target_picker.gd") as GDScript
	var cls_hud := load("res://scripts/interaction/interaction_hud.gd") as GDScript
	if cls_target == null or cls_hud == null:
		push_warning("Hệ tương tác không nạp được — màn chơi vẫn chạy nhưng không có HUD chọn mục tiêu.")
		return

	var target_picker: Node = cls_target.new()
	target_picker.name = "TargetPicker"
	player.add_child(target_picker)

	var hud: Node = cls_hud.new()
	hud.name = "InteractionHUD"
	add_child(hud)
	hud.listen_to_picker(target_picker)
	hud.follow_character(player)

	# Đôi tay: cầm/đặt/thả vật thể. Cũng nạp lúc chạy vì cùng lý do với hai
	# script trên — lỗi ở đây không được phép làm cả màn chơi không mở lên.
	var cls_hands := load("res://scripts/interaction/hands.gd") as GDScript
	var cls_picker := load("res://scripts/interaction/picker_menu.gd") as GDScript
	if cls_hands != null:
		var hands: Node = cls_hands.new()
		hands.name = "Hands"
		player.add_child(hands)
		hud.listen_to_hands(hands)

		# Hệ thống bếp: một node quản lý chung cho mọi cái bếp trong màn.
		var cls_cooking := load("res://scripts/interaction/cooking_system.gd") as GDScript
		if cls_cooking != null:
			var cooking: Node = cls_cooking.new()
			cooking.name = "CookingSystem"
			add_child(cooking)
			hands.cooking = cooking
			hud.listen_to_cooking(cooking)

			# Thanh tiến trình RIÊNG cho từng trạm, nổi trên đầu trạm đó.
			#
			# Node riêng chứ không nhét vào interaction_hud: HUD kia đã 24 KB và
			# lo bốn thứ không liên quan nhau (danh sách trạm trong tầm, thể
			# lực, ô kĩ năng, bảng bàn chế tạo). Thanh trạm thì chỉ cần biết
			# hệ bếp và cái camera — không đụng gì tới bốn thứ đó, nên tách ra
			# là tách được sạch.
			var cls_bars := load("res://scripts/ui/station_bars.gd") as GDScript
			if cls_bars != null:
				var bars: Node = cls_bars.new()
				bars.name = "StationBars"
				add_child(bars)
				bars.listen_to_cooking(cooking)
			else:
				push_warning("Không nạp được thanh tiến trình của trạm.")

		if cls_picker != null:
			var picker: Node = cls_picker.new()
			picker.name = "PickerMenu"
			add_child(picker)
			# Ba mối nối, mỗi cái một việc: tay xin mở bảng, bảng báo đã
			# chọn xong, và bảng báo mở/đóng để khoá di chuyển nhân vật.
			hands.request_picker.connect(picker.open)
			picker.item_chosen.connect(hands.receive_ingredient)
			picker.open_state_changed.connect(_lock_player)

	# Hệ kĩ năng chủ động (phím Space). Hiện mới lo phần cut-in; hiệu ứng thật
	# cắm vào sau. Đặt ở màn chơi chứ không trong scene nhân vật, cùng lý do
	# với bộ chọn mục tiêu: bảy nhân vật thì bảy chỗ phải sửa.
	_reveal_map_items()

	# AAA Mode: kĩ năng "thuộc DLC" — không dựng hệ kĩ năng; phím kĩ năng do
	# aaa_mode.gd bắt để hiện quảng cáo.
	var cls_skills := load("res://scripts/skills/skill_manager.gd") as GDScript
	if _is_aaa():
		cls_skills = null
	if cls_skills != null:
		var skills: Node = cls_skills.new()
		skills.name = "SkillManager"
		add_child(skills)
		skills.track_character(player)
		hud.listen_to_skills(skills)
	else:
		push_warning("Không nạp được hệ kĩ năng — màn chơi vẫn chạy, chỉ thiếu cut-in.")

	# Hệ khách hàng: sinh khách, xếp hàng, chia bàn, và nướng vùng đi lại.
	# Cùng lý do đặt ở màn chơi với mọi hệ thống trên.
	var cls_customers := load("res://scripts/restaurant/customer_manager.gd") as GDScript
	if cls_customers != null:
		customers = cls_customers.new()
		customers.name = "CustomerManager"
		add_child(customers)
		# chuan_bi() phải gọi SAU add_child: nó dùng get_tree() để tìm nhóm
		# "dining_table" và gắn vùng navmesh vào cây scene.
		customers.setup(self)

		# GIÁ VỐN NGUYÊN LIỆU: đôi tay báo "vừa lấy thứ này", hệ khách trừ tiền.
		#
		# Nối ở ĐÂY chứ không để hai file tự tìm nhau: đôi tay sinh ra trong
		# _build_interaction() còn hệ khách sinh ra sau, nên bên nào tự đi tìm
		# bên kia cũng phải chịu một lần null. Màn chơi dựng cả hai thì nó là
		# nơi duy nhất biết chắc cả hai đã tồn tại.
		var hands_node := player.get_node_or_null("Hands")
		if hands_node != null and hands_node.has_signal("ingredient_taken"):
			hands_node.ingredient_taken.connect(customers.charge_for_ingredient)
		# AAA Mode bỏ qua cheat nguyên liệu miễn phí.
		customers.free_ingredients = GameData.cheat_free_ingredients and not _is_aaa()
		customers.never_leave = _is_aaa()

		_build_order_hud()
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
## 1. Vật thuộc nhóm đang bị khoá trong ItemCatalog → GIẤU HẲN.
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
## chỉ cần đổi một công tắc trong ItemCatalog, không phải dựng lại node vào đúng
## chỗ cũ trong map.
func _reveal_map_items() -> void:
	var item_catalog := load("res://scripts/interaction/item_catalog.gd") as GDScript
	if item_catalog == null:
		return
	for station in _find_stations(self):
		# Chồng nồi không phải vật cầm được, nhưng nó là NGUỒN của cái nồi —
		# công tắc POT_ENABLED tắt thì nó phải biến mất cùng cả nhóm món nồi, nếu
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


func _find_stations(root: Node) -> Array[Workstation]:
	var out: Array[Workstation] = []
	for child in root.get_children():
		var t := child as Workstation
		if t != null:
			out.append(t)
		out.append_array(_find_stations(child))
	return out


## Hai bảng HUD của hệ đơn hàng: cột vé bên trái, đồng hồ & ví bên phải.
##
## Tách khỏi _build_interaction() vì chúng phụ thuộc customer_manager chứ không
## phụ thuộc nhân vật người chơi — nối nhầm thứ tự thì tín hiệu nối vào null
## mà không báo lỗi, cái vé chỉ đơn giản là không bao giờ hiện.
##
## Cả hai chỉ NGHE tín hiệu. Chúng không đọc trạng thái khách, không tự đếm
## kiên nhẫn, không tự cộng tiền — luật nằm trọn trong customer_manager.gd.
func _build_order_hud() -> void:
	var cls_intro := load("res://scripts/ui/order_board.gd") as GDScript
	if cls_intro != null:
		var picker: Node = cls_intro.new()
		picker.name = "OrderBoard"
		add_child(picker)
		picker.listen_to_orders(customers)
	else:
		push_warning("Không nạp được cột vé đơn hàng.")

	var cls_clock := load("res://scripts/ui/hud_clock.gd") as GDScript
	var clock: Node = null
	if cls_clock != null:
		clock = cls_clock.new()
		clock.name = "HudClock"
		add_child(clock)
		clock.listen_to_orders(customers)
		clock.time_up.connect(_end_level.bind(""))
		_watch_lost_customers(clock)
		# Chữ cái mốc hạng trên HUD. Chỉ màn KHAI mốc riêng mới có (Ngày 1–3);
		# tutorial không xếp hạng thật nên không hiện.
		if get_node_or_null("/root/GameData") != null:
			var level_id := String(GameData.current_level)
			if GameData.rules_for_level(level_id).has("rank_thresholds"):
				clock.set_rank_marks(
					GameData.rank_thresholds_for(level_id), GameData.RANK_ORDER)
	else:
		push_warning("Không nạp được bảng thời gian.")

	_attach_doro()

	# Hệ kĩ năng phải chờ tới ĐÂY mới gắn được: nó vặn núm của hệ khách hàng,
	# hệ bếp và đồng hồ màn, nên cả ba phải tồn tại trước. Node SkillManager
	# được dựng sớm hơn (trong _gan_he_tuong_tac) vì HUD cần nối tín hiệu của
	# nó ngay, còn phần vặn núm tách ra setup() gọi sau — hai việc, hai
	# thời điểm, thay vì phải sắp lại thứ tự dựng node.
	#
	# Đặt TRƯỚC _apply_level_rules: luật màn đặt thời lượng và nhịp khách của
	# riêng màn đó, và nếu sau này có kĩ năng đụng tới hai thứ ấy thì kĩ năng
	# phải là lớp đè lên luật màn, không phải ngược lại.
	var skills_node := get_node_or_null("SkillManager")
	if skills_node != null:
		skills_node.setup(customers, get_node_or_null("CookingSystem"), clock)

	_apply_level_rules(clock)
	_build_level_intro(clock)
	_attach_tutorial(clock)
	_attach_aaa_mode()


func _is_aaa() -> bool:
	return get_node_or_null("/root/GameData") != null and GameData.is_aaa_mode()


## AAA Mode — dựng bộ điều phối của chế độ. Gọi SAU _apply_level_rules (bộ
## điều phối đọc thực đơn đã áp để biết khoá kệ nào) và SAU _build_level_intro
## (nó gắn dải sale vào màn đếm ngược).
func _attach_aaa_mode() -> void:
	if not _is_aaa() or customers == null:
		return
	var cls := load("res://scripts/modes/aaa/aaa_mode.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được AAA Mode — màn chạy như màn thường.")
		return
	var aaa: Node = cls.new()
	aaa.name = "AaaMode"
	add_child(aaa)
	aaa.setup(self, player, player.get_node_or_null("Hands"), customers,
		_find_stations(self), get_node_or_null("LevelIntro"))


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
func _apply_level_rules(clock: Node) -> void:
	if customers == null or get_node_or_null("/root/GameData") == null:
		return
	var rules: Dictionary = GameData.rules_for_level(String(GameData.current_level))
	if rules.is_empty():
		return

	var cls := load("res://scripts/restaurant/level_rules.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được luật màn — màn chơi dùng số mặc định.")
		return

	var rules_node: Node = cls.new()
	rules_node.name = "LevelRules"
	add_child(rules_node)
	if not rules_node.setup(customers, clock, rules):
		rules_node.queue_free()


## Doro — thú cưng đi lang thang, kiêm thùng rác thứ hai.
##
## Dựng BẰNG CODE ở đây chứ không đặt sẵn trong file map, cùng lý do với mọi
## hệ thống khác: tám màn dùng chung một map, và Doro cần biết cả navmesh (do
## customer_manager nướng lúc chạy) lẫn nhân vật người chơi (do màn chơi sinh ra)
## — hai thứ chỉ tồn tại lúc chạy, không có cách nào kéo vào Inspector.
##
## Gọi SAU customer_manager.setup(): Doro hỏi độ lệch cao của navmesh, mà con
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
func _attach_doro() -> void:
	if customers == null or player == null:
		return
	var cls := load("res://scripts/restaurant/doro_pet.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được Doro — màn chơi vẫn chạy, chỉ thiếu pet.")
		return

	var seat: Vector3 = cls.first_stand_point(get_world_3d().navigation_map, 0.0)
	var pet: Node3D = cls.new()
	pet.name = "Doro"
	add_child(pet)
	pet.setup(seat, float(customers.navmesh_height_offset()), player)


## Bộ dẫn dắt màn hướng dẫn — CHỈ dựng khi màn đang chơi là "tutorial".
##
## Hỏi GameData.current_level thay vì để một cờ @export trong file map: cả tám
## màn dùng CHUNG một file map (xem GameData.LEVELS), nên một cờ trong map sẽ
## bật hướng dẫn cho cả Ngày 1, Ngày 2, Ngày 3.
##
## Chạy thẳng map bằng F6 từ editor thì current_level rỗng và không có hướng
## dẫn — đúng ý: lúc đó đang thử bếp, không ai muốn bị giảng bài.
func _attach_tutorial(clock: Node) -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	if String(GameData.current_level) != "tutorial":
		return

	var cls := load("res://scripts/story/tutorial_director.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được bộ dẫn dắt hướng dẫn — màn vẫn chơi được như màn thường.")
		return

	var hands := player.get_node_or_null("Hands")
	var cooking := get_node_or_null("CookingSystem")
	var director: Node = cls.new()
	director.name = "TutorialDirector"
	add_child(director)
	director.tutorial_finished.connect(_on_tutorial_done)
	director.setup(player, hands, cooking, customers, clock)


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
func _on_tutorial_done(_summary: bool) -> void:
	_go_to_first_character_select()


## (1/10/2026) Hết tutorial — học xong HAY bấm bỏ qua — là sang thẳng màn chọn
## nhân vật cho Ngày 1, không hiện bảng tổng kết nữa.
##
## Vì sao bỏ bảng tổng kết: nó chỉ có hai nút "Chơi lại" và "Chọn màn", tức là
## người vừa học xong phải tự đi tìm Ngày 1. Mà tutorial chơi bằng Kitasan cố
## định, nên đây là LẦN ĐẦU người chơi được chọn nhân vật — đúng lúc họ vừa
## biết game chơi thế nào để mà chọn.
##
## Không cần gọi complete_level("tutorial") ở đây: bộ dẫn dắt đã gọi trong
## _restore_normal() trước khi phát tín hiệu, nên Ngày 1 đã mở.
func _go_to_first_character_select() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameData.current_level = GameData.FIRST_REAL_LEVEL
	# Nút "Trở lại" ở màn chọn nhân vật về màn chọn màn, không về tutorial.
	GameData.return_scene = "res://scenes/menu/level_select.tscn"
	get_tree().change_scene_to_file("res://scenes/menu/character_select.tscn")


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
# ------------------------------------------------ tương tác ẩn ở cửa ra vào
## Đứng trong bán kính này quanh cửa thì phím Tương tác mở bảng "Đóng quán?".
const DOOR_RADIUS := 2.2


## TƯƠNG TÁC ẨN: đứng sát cửa ra vào và bấm Tương tác → hỏi có đóng quán
## (kết thúc màn sớm) không. Không có gợi ý nào trên HUD — cố ý.
##
## Vì sao KHÔNG làm thành một trạm (Workstation) như mọi chỗ tương tác khác:
## trạm thì bộ chọn mục tiêu tự liệt kê tên nó kèm chữ E ở đáy màn hình, tức
## là hết ẩn. Ở đây chỉ đo khoảng cách tới điểm Markers/Entrance — không node
## mới trong map, không dòng nào trên HUD.
##
## Kết thúc bằng _end_level("") như đường hết giờ: xếp hạng theo đúng số
## tiền đang có, không phải thua ép.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if player == null or customers == null:
		return
	# Tutorial không có đồng hồ và có lối ra riêng; bảng tổng kết / bảng hỏi
	# đang mở thì không mở thêm.
	if get_node_or_null("/root/GameData") != null \
			and String(GameData.current_level) == "tutorial":
		return
	if get_node_or_null("ResultsPanel") != null or get_node_or_null("CloseShopPrompt") != null:
		return
	var door := get_node_or_null("Markers/Entrance") as Node3D
	if door == null:
		return
	var offset := player.global_position - door.global_position
	if Vector2(offset.x, offset.z).length() > DOOR_RADIUS:
		return

	var cls := load("res://scripts/ui/close_shop_prompt.gd") as GDScript
	if cls == null:
		return
	get_viewport().set_input_as_handled()
	var prompt: Node = cls.new()
	prompt.name = "CloseShopPrompt"
	add_child(prompt)
	prompt.confirmed.connect(_end_level.bind(""))


func _unhandled_key_input(event: InputEvent) -> void:
	if get_node_or_null("/root/GameData") == null or not GameData.cheat_time_skip:
		return
	if GameData.is_aaa_mode():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Nhận cả phím 0 hàng số lẫn phím 0 bàn phím số. Dùng physical_keycode nên
	# bố cục bàn phím nào cũng đúng.
	if key.physical_keycode != KEY_0 and key.physical_keycode != KEY_KP_0:
		return
	get_viewport().set_input_as_handled()
	_skip_time()


func _skip_time() -> void:
	# Bảng kết quả đã hiện thì không còn gì để tua.
	if get_node_or_null("ResultsPanel") != null:
		return
	var clock_node := get_node_or_null("HudClock")
	if clock_node == null:
		# Màn không có đồng hồ (hướng dẫn): bấm một cái là tổng kết luôn.
		_end_level("")
		return
	if float(clock_node.time_left) > SKIP_SECONDS:
		# Gán thẳng con_lai thay vì gọi một hàm riêng: _process của đồng hồ đọc
		# biến này mỗi khung hình và tự so trước-sau để bắn tín hiệu mốc, nên
		# đổi giá trị là mọi thứ ăn theo đúng như thời gian trôi tự nhiên.
		clock_node.time_left = SKIP_SECONDS
	else:
		_end_level("")


## Giới hạn khách bỏ về của màn này. 0 = không giới hạn.
var _lost_limit := 0


## Theo dõi số khách bỏ về: cập nhật HUD, và VƯỢT giới hạn thì thua ngay.
##
## "Vượt" là LỚN HƠN: Ngày 1 ghi "không quá 10" thì người thứ 10 bỏ về vẫn
## còn chơi, người thứ 11 mới thua.
##
## Thua NGAY chứ không đợi hết giờ rồi mới báo trượt: đã chắc chắn trượt mà
## vẫn bắt chơi nốt mấy phút thì phần còn lại của màn vô nghĩa, và người
## chơi chỉ muốn bấm chơi lại.
##
## Nghe order_finished của hệ khách chứ không tự đếm: hệ khách đã có sẵn bộ
## đếm customers_lost dùng cho bảng tổng kết — đếm lần hai ở đây là hai con
## số có thể lệch nhau.
func _watch_lost_customers(clock: Node) -> void:
	if get_node_or_null("/root/GameData") == null or customers == null:
		return
	_lost_limit = GameData.max_left_for(String(GameData.current_level))
	if clock.has_method("set_lost"):
		clock.set_lost(0, _lost_limit)
	if _lost_limit <= 0:
		return
	customers.order_finished.connect(func(_order: RefCounted, reason: String) -> void:
		if reason != "left":
			return
		var lost := int(customers.customers_lost)
		if clock.has_method("set_lost"):
			clock.set_lost(lost, _lost_limit)
		if lost > _lost_limit:
			_end_level("", Lang.t("Thua: %d khách bỏ về, quá giới hạn %d của màn này.") % [lost, _lost_limit]))


func _end_level(rank: String, fail_note: String = "") -> void:
	# Chặn gọi hai lần: hết giờ và hướng dẫn xong về lý thuyết có thể trùng
	# nhau, và hai tấm bảng chồng lên nhau thì cái dưới không bao giờ đóng.
	if get_node_or_null("ResultsPanel") != null:
		return
	# AAA Mode có bảng điểm riêng và không ghi gì vào file lưu.
	var aaa := get_node_or_null("AaaMode")
	if aaa != null:
		aaa.show_review()
		return

	var cls := load("res://scripts/ui/results_panel.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được bảng kết quả — màn chơi kết thúc mà không tổng kết.")
		return

	var skills_node := get_node_or_null("SkillManager")
	if skills_node != null and skills_node.has_method("end_of_level"):
		skills_node.end_of_level()

	var money := 0
	var done := 0
	var perfect := 0
	var leaving := 0
	if customers != null:
		customers.close_shop()
		money = int(customers.money)
		done = int(customers.orders_done)
		perfect = int(customers.perfect_orders)
		leaving = int(customers.customers_lost)

	var results: Node = cls.new()
	results.name = "ResultsPanel"
	add_child(results)
	results.fail_note = fail_note
	results.show_results(money, done, perfect, leaving, rank)


## Màn hình mở đầu: hiện tên màn, đếm ngược, rồi mới thả đồng hồ và khách vào.
##
## ĐÓNG BĂNG ĐÚNG HAI THỨ — đồng hồ màn và việc sinh khách — chứ không tạm dừng
## cả game. Mười giây đó để người chơi ĐI THỬ MỘT VÒNG BẾP: có mười tám trạm
## nằm rải khắp phòng, và người mới cần biết cái tủ lạnh ở đâu trước khi có
## khách. Tạm dừng thì họ chỉ đứng nhìn một con số đếm lùi.
##
## Màn hướng dẫn KHÔNG có màn mở đầu: ở đó trainer đã dẫn từng bước, chèn thêm
## một lớp chữ nữa chỉ làm loãng.
func _build_level_intro(clock: Node) -> void:
	if get_node_or_null("/root/GameData") != null \
			and String(GameData.current_level) == "tutorial":
		return

	var cls := load("res://scripts/ui/level_intro.gd") as GDScript
	if cls == null:
		return

	var label_ := Lang.t("BẮT ĐẦU")
	if get_node_or_null("/root/GameData") != null:
		var t := GameData.level_name(String(GameData.current_level))
		if not t.is_empty():
			label_ = t

	# Đóng băng TRƯỚC khi hiện chữ, không phải sau: giữa hai việc đó có ít nhất
	# một khung hình, và một khung hình đủ để đồng hồ trừ mất thời gian.
	if clock != null:
		clock.counting_down = false
	if customers != null:
		customers.auto_spawn = false

	var intro: Node = cls.new()
	intro.name = "LevelIntro"
	add_child(intro)
	# Bảng thực đơn: mở trong lúc đếm ngược, tự cất khi vào ca, và từ đó người
	# chơi gọi lại bằng phím (mặc định 2).
	var menu_panel := _build_menu_panel()
	if menu_panel != null:
		menu_panel.set_open(true)
	intro.started.connect(func() -> void:
		if is_instance_valid(menu_panel):
			menu_panel.set_open(false)
		if clock != null:
			clock.counting_down = true
		if customers != null:
			customers.auto_spawn = true
		# Bốc ngẫu nhiên trong sáu bài, KHÔNG giữ liền mạch: vào một ca làm
		# việc mới thì phải nghe như một ca mới, chứ không phải như đoạn giữa
		# của bài nhạc đang chạy ở menu.
		AmThanh.play_random_music("level"))
	intro.start_countdown(label_)


func _build_menu_panel() -> Node:
	var cls := load("res://scripts/ui/menu_panel.gd") as GDScript
	if cls == null:
		return null
	var panel: Node = cls.new()
	panel.name = "MenuPanel"
	add_child(panel)
	panel.setup(_todays_menu())
	return panel


## Các món khách CÓ THỂ gọi trong màn này, để bảng thực đơn lúc chờ liệt kê.
##
## Đọc `customers.menu` — thứ luật màn đã gán — chứ không đọc lại RULES trong
## GameData: bảng phải nói đúng cái mà hệ khách sẽ bốc, kể cả khi sau này có
## chỗ khác sửa thực đơn lúc chạy. Rỗng (Endless, Asian) nghĩa là "mọi món".
func _todays_menu() -> Array[String]:
	var dishes: Array[String] = []
	if customers == null:
		return dishes
	var source: Array = customers.menu
	if source.is_empty():
		source = ItemCatalog.sellable_dishes()
	for id in source:
		var dish := String(id)
		if ItemCatalog.price(dish) > 0 and not ItemCatalog.is_locked(dish):
			dishes.append(dish)
	return dishes
