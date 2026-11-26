extends Node3D

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Nhân vật DỰ PHÒNG: chỉ dùng khi chưa qua màn hình chọn nhân vật
@export var player_scene: PackedScene
## Đường dẫn tới Marker3D đánh dấu chỗ nhân vật xuất hiện.
@export var spawn_path: NodePath = ^"PlayerSpawn"

## Menu Pause gắn vào bằng CODE chứ không đặt sẵn trong từng file map.
const PAUSE_MENU := preload("res://scenes/menu/pause_menu.tscn")

## CHEAT TUA GIỜ (phím 0) — kéo đồng hồ màn về còn bấy nhiêu giây.
const SKIP_SECONDS := 210.0

## Tham chiếu tới nhân vật đang chơi, để các hệ thống khác (HUD, đơn hàng,
var player: CharacterBody3D
## Hệ khách hàng của màn này. Các hệ khác (đơn hàng, tính tiền) sẽ hỏi qua đây.
var customers: Node


func _ready() -> void:
	AmThanh.stop_all_sfx()
	_spawn_player()
	add_child(PAUSE_MENU.instantiate())


## ── LỚP VA CHẠM (cả project) ─────────────────────────────────────────────
const PLAYER_LAYER := 1 << 5

## Tường vô hình chỉ người chơi thấy — chắn cửa ra vào (node DoorBarrier trong
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
	_apply_skin(player)
	add_child(player)
	player.global_transform = spawn.global_transform

	# Lớp va chạm riêng cho người chơi. Xem PLAYER_LAYER.
	player.collision_layer = PLAYER_LAYER
	player.collision_mask = 1 | PLAYER_ONLY_WALL_LAYER

	_build_interaction()


## Gỡ kẹt: đưa nhân vật về lại PlayerSpawn. Pause menu gọi hàm này.
## Dùng đúng điểm sinh của màn vì chỗ đó chắc chắn thoáng; giữ nguyên đồ trên tay.
func unstuck_player() -> void:
	var spawn := get_node_or_null(spawn_path) as Marker3D
	if player == null or spawn == null:
		return
	player.velocity = Vector3.ZERO
	player.global_position = spawn.global_position
	player.reset_physics_interpolation()


## Thay node "Model" bằng model ngoại trang nếu người chơi đang mặc skin.
func _apply_skin(p: Node) -> void:
	var path := GameData.equipped_model_for(String(GameData.selected_character))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var old := p.get_node_or_null("Model") as Node3D
	if old == null:
		return
	var skin := (load(path) as PackedScene).instantiate() as Node3D
	skin.transform = old.transform
	p.remove_child(old)
	old.free()
	skin.name = "Model"
	p.add_child(skin)
	p.move_child(skin, 0)


## Chọn scene nhân vật để sinh ra.
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
			hands.request_picker.connect(picker.open)
			picker.item_chosen.connect(hands.receive_ingredient)
			picker.open_state_changed.connect(_lock_player)

	_reveal_map_items()

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

	var cls_customers := load("res://scripts/restaurant/customer_manager.gd") as GDScript
	if cls_customers != null:
		customers = cls_customers.new()
		customers.name = "CustomerManager"
		add_child(customers)
		customers.setup(self)

		var hands_node := player.get_node_or_null("Hands")
		if hands_node != null and hands_node.has_signal("ingredient_taken"):
			hands_node.ingredient_taken.connect(customers.charge_for_ingredient)
		customers.free_ingredients = not GameData.is_asian_mode() \
			or (GameData.cheat_free_ingredients and not _is_aaa())
		customers.never_leave = _is_aaa()

		_build_order_hud()
	else:
		push_warning("Không nạp được hệ khách hàng — màn chơi vẫn chạy, chỉ không có khách.")

	for n in get_tree().get_nodes_in_group("station"):
		if n.get("kind") in ["crafting_table", "prep_table"]:
			hud.listen_to_table(n)


## Duyệt mọi vật cầm ĐẶT SẴN trong file map và xử lý hai việc trái ngược nhau.
func _reveal_map_items() -> void:
	var item_catalog := load("res://scripts/interaction/item_catalog.gd") as GDScript
	if item_catalog == null:
		return
	for station in _find_stations(self):
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
		if get_node_or_null("/root/GameData") != null:
			var level_id := String(GameData.current_level)
			if GameData.rules_for_level(level_id).has("rank_thresholds"):
				clock.set_rank_marks(
					GameData.rank_thresholds_for(level_id), GameData.RANK_ORDER)
	else:
		push_warning("Không nạp được bảng thời gian.")

	_attach_doro()

	# Bảng phím cơ bản ở góc dưới-phải — cho người chơi bỏ qua hướng dẫn.
	var cls_keys := load("res://scripts/ui/key_hints.gd") as GDScript
	if cls_keys != null:
		var keys: Node = cls_keys.new()
		keys.name = "KeyHints"
		add_child(keys)

	var skills_node := get_node_or_null("SkillManager")
	if skills_node != null:
		skills_node.setup(customers, get_node_or_null("CookingSystem"), clock)

	_apply_level_rules(clock)
	_build_level_intro(clock)
	_attach_tutorial(clock)
	_attach_aaa_mode()
	_attach_endless_mode(clock)
	_attach_asian_mode(clock)


## Asian Mode — gắn bộ điều phối luật (mạng, vốn, phí, thắng/thua). Gọi SAU
func _attach_asian_mode(clock: Node) -> void:
	if get_node_or_null("/root/GameData") == null or not GameData.is_asian_mode():
		return
	if customers == null or clock == null:
		return
	var cls := load("res://scripts/modes/asian/asian_mode.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được Asian Mode — màn chạy như màn thường.")
		return
	var asian: Node = cls.new()
	asian.name = "AsianMode"
	add_child(asian)
	asian.setup(self, customers, clock, get_node_or_null("CookingSystem"),
		get_node_or_null("PickerMenu"),
		player.get_node_or_null("Hands") if player != null else null)


## Endless Mode — gắn bộ điều phối cộng/trừ giờ. Gọi SAU _apply_level_rules:
func _attach_endless_mode(clock: Node) -> void:
	if get_node_or_null("/root/GameData") == null or not GameData.is_endless_mode():
		return
	if customers == null or clock == null:
		return
	var cls := load("res://scripts/modes/endless/endless_mode.gd") as GDScript
	if cls == null:
		push_warning("Không nạp được Endless Mode — màn chạy như màn thường.")
		return
	var endless: Node = cls.new()
	endless.name = "EndlessMode"
	add_child(endless)
	endless.setup(customers, clock)


func _is_aaa() -> bool:
	return get_node_or_null("/root/GameData") != null and GameData.is_aaa_mode()


## AAA Mode — dựng bộ điều phối của chế độ. Gọi SAU _apply_level_rules (bộ
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
func _on_tutorial_done(_summary: bool) -> void:
	_go_to_first_character_select()


## (1/10/2026) Hết tutorial — học xong HAY bấm bỏ qua — là sang thẳng màn chọn
func _go_to_first_character_select() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameData.current_level = GameData.FIRST_REAL_LEVEL
	GameData.return_scene = "res://scenes/menu/level_select.tscn"
	get_tree().change_scene_to_file("res://scenes/menu/character_select.tscn")


# ------------------------------------------------ tương tác ẩn ở cửa ra vào
const DOOR_RADIUS := 2.2


## TƯƠNG TÁC ẨN: đứng sát cửa ra vào và bấm Tương tác → hỏi có đóng quán
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if player == null or customers == null:
		return
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
	if key.physical_keycode != KEY_0 and key.physical_keycode != KEY_KP_0:
		return
	get_viewport().set_input_as_handled()
	_skip_time()


func _skip_time() -> void:
	if get_node_or_null("ResultsPanel") != null:
		return
	var clock_node := get_node_or_null("HudClock")
	if clock_node == null:
		_end_level("")
		return
	if float(clock_node.time_left) > SKIP_SECONDS:
		clock_node.time_left = SKIP_SECONDS
	else:
		_end_level("")


## Giới hạn khách bỏ về của màn này. 0 = không giới hạn.
var _lost_limit := 0


## Theo dõi số khách bỏ về: cập nhật HUD, và VƯỢT giới hạn thì thua ngay.
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
	if get_node_or_null("ResultsPanel") != null:
		return
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
	var endless := get_node_or_null("EndlessMode")
	if endless != null:
		results.endless_seconds = endless.survived_seconds()
	var asian := get_node_or_null("AsianMode")
	if asian != null:
		results.asian_result = asian.result(fail_note)
	add_child(results)
	results.fail_note = fail_note
	results.show_results(money, done, perfect, leaving, rank)


## Màn hình mở đầu: hiện tên màn, đếm ngược, rồi mới thả đồng hồ và khách vào.
func _build_level_intro(clock: Node) -> void:
	if get_node_or_null("/root/GameData") != null \
			and ["tutorial", "plan_b"].has(String(GameData.current_level)):
		return

	var cls := load("res://scripts/ui/level_intro.gd") as GDScript
	if cls == null:
		return

	var label_ := Lang.t("BẮT ĐẦU")
	if get_node_or_null("/root/GameData") != null:
		var t := GameData.level_name(String(GameData.current_level))
		if not t.is_empty():
			label_ = t

	if clock != null:
		clock.counting_down = false
	if customers != null:
		customers.auto_spawn = false

	var intro: Node = cls.new()
	intro.name = "LevelIntro"
	add_child(intro)
	var menu_panel: Node = null
	if menu_panel != null:
		menu_panel.set_open(true)
	intro.started.connect(func() -> void:
		if is_instance_valid(menu_panel):
			menu_panel.set_open(false)
		if clock != null:
			clock.counting_down = true
		if customers != null:
			customers.auto_spawn = true
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
