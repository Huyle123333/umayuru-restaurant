extends Node

const Cutscene := preload("res://scripts/story/cutscene_tutorial.gd")
const GuidePanel := preload("res://scripts/ui/guide_panel.gd")

## Hướng dẫn kết thúc. `tong_ket` = true thì màn dừng luôn và hiện bảng kết
signal tutorial_finished(tong_ket: bool)

## Trễ một nhịp giữa "làm đúng" và "hiện câu tiếp theo".
const STEP_DELAY := 0.6

## Ba tiền tố của trường "wait_for" — điều kiện có kèm tham số.
const WAIT_HOLD := "hold:"
const WAIT_TABLE_HAS := "table_has:"
const WAIT_SECONDS := "seconds:"
const WAIT_SERVE_COUNT := "serve_count:"

## Bước hỏi cuối bài: "Mở quán" hay "Thử lại".
const WAIT_ASK_FINISH := "ask_finish"

var _panel: CanvasLayer
var _hands: Node
var _cooking: Node
var _customers: Node
var _clock: Node
var _player: Node3D

var _step := -1
var _wait_for := ""
var _seconds_left := 0.0
var _moved := 0.0
var _last_position := Vector3.ZERO
var _stepping := false
## Có tổng kết hay không. Xem chú thích của `tutorial_finished` — hiện cả hai lối
var _learned_all := false
## Phần tự làm thử: đã giao đúng bao nhiêu đơn / cần bao nhiêu.
var _served := 0
var _served_target := 0


## Gắn vào màn chơi. Truyền thẳng các node cần nghe thay vì tự đi tìm trong
func setup(player_node: Node3D, hands: Node, cooking: Node,
		customers: Node, clock: Node) -> void:
	_player = player_node
	_hands = hands
	_cooking = cooking
	_customers = customers
	_clock = clock

	_panel = GuidePanel.new()
	_panel.name = "GuidePanel"
	add_child(_panel)
	_panel.start_choice.connect(_on_select)

	_apply_tutorial_rules()
	_connect_signals()

	if _player != null:
		_last_position = _player.global_position

	_set_interact_locked(true)

	_panel.open()
	_build_reset_link()
	_go_to_step(0)


## Dòng "gặp lỗi thì bấm vào đây" (16/11/2026) — góc dưới bên trái, suốt màn
func _build_reset_link() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var link := LinkButton.new()
	link.text = Lang.t("Game bị lỗi? Bấm vào đây để chơi lại màn hướng dẫn")
	link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	link.add_theme_font_size_override("font_size", 18)
	link.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	link.add_theme_color_override("font_hover_color", Color("ffd27a"))
	link.anchor_top = 1.0
	link.anchor_bottom = 1.0
	link.offset_left = 20.0
	link.offset_top = -40.0
	link.offset_bottom = -14.0
	link.focus_mode = Control.FOCUS_NONE
	link.pressed.connect(func() -> void: get_tree().reload_current_scene())
	layer.add_child(link)


## Giới hạn tương tác theo từng bước, đọc từ khoá "allow"/"allow_item" của
func _apply_step_limits(i: int) -> void:
	var picker: Node = _player.get_node_or_null("TargetPicker") if _player != null else null
	var step: Dictionary = Cutscene.STEPS[i] if i < Cutscene.STEPS.size() else {}
	var allow: Array = step.get("allow", [])
	_set_interact_locked(i < FIRST_HANDS_ON_STEP)
	if picker != null and "allowed_kinds" in picker:
		picker.allowed_kinds = allow
		if not picker.blocked.is_connected(_on_blocked):
			picker.blocked.connect(_on_blocked)
	if _hands != null and "tutorial_item" in _hands:
		_hands.tutorial_item = String(step.get("allow_item", ""))


## Bước đầu tiên người chơi được cầm nắm (lấy steak ở tủ lạnh).
const FIRST_HANDS_ON_STEP := 3


func _on_blocked(_station: Node) -> void:
	if _hands != null and _hands.has_signal("notice"):
		_hands.notice.emit(Lang.t("Làm theo hướng dẫn nhé!"), false)


func _set_interact_locked(on: bool) -> void:
	if _player == null:
		return
	var picker := _player.get_node_or_null("TargetPicker")
	if picker != null and "locked" in picker:
		picker.locked = on


## Luật riêng của màn hướng dẫn. Tất cả đều là ô @export có sẵn, không có cờ
func _apply_tutorial_rules() -> void:
	if _customers != null:
		_customers.drain_patience = false
		_customers.auto_spawn = false
		_customers.force_table = 1
		_customers.force_dish = "mon_steak"
	if _clock != null:
		_clock.counting_down = false


## Trả màn chơi về luật bình thường. Dùng cho CẢ HAI lối ra: học xong, và bấm
func _restore_normal() -> void:
	if _customers != null:
		_customers.drain_patience = true
		_customers.auto_spawn = true
		_customers.force_table = 0
		_customers.force_dish = ""
		_customers.price_factor = 1.0
	if _clock != null:
		_clock.counting_down = true

	if GameData != null:
		GameData.complete_level("tutorial")

	tutorial_finished.emit(_learned_all)


# ------------------------------------------------------------- tín hiệu ---

func _connect_signals() -> void:
	if _hands != null and _hands.has_signal("held_item_changed"):
		_hands.held_item_changed.connect(_on_hands_changed)
	if _cooking != null and _cooking.has_signal("cook_finished"):
		_cooking.cook_finished.connect(_on_cook_finished)
	if _customers != null and _customers.has_signal("order_finished"):
		_customers.order_finished.connect(_on_order_finished)

	for n in get_tree().get_nodes_in_group("station"):
		if String(n.kind) == "crafting_table" and n.has_signal("contents_changed"):
			n.contents_changed.connect(_on_table_changed)


func _on_hands_changed(id: String) -> void:
	if _wait_for.begins_with(WAIT_HOLD) and id == _wait_for.substr(WAIT_HOLD.length()):
		_finish_step()


func _on_cook_finished(station: Node, _dish: String, success: bool) -> void:
	if not success:
		return
	var kind := String(station.kind)
	if _wait_for == "chop" and kind == "cutting_board":
		_finish_step()
	elif _wait_for == "cook" and kind == "stove":
		_finish_step()


func _on_table_changed(table: Node) -> void:
	if not _wait_for.begins_with(WAIT_TABLE_HAS):
		return
	if table.contents.has(_wait_for.substr(WAIT_TABLE_HAS.length())):
		_finish_step()


func _on_order_finished(_orders: RefCounted, reason: String) -> void:
	if reason != "served":
		return
	if _wait_for == "serve":
		_finish_step()
	elif _wait_for.begins_with(WAIT_SERVE_COUNT):
		_served += 1
		if _served >= _served_target:
			_finish_step()


## Trả lời câu hỏi mở màn: "Chỉ đi" thì vào bài học, "Bỏ qua" thì tổng kết ngay.
func _on_select(yes: bool) -> void:
	if _wait_for == WAIT_ASK_FINISH:
		_on_finish_choice(yes)
		return
	if yes:
		_go_to_step(1)
		return
	_learned_all = true
	_wait_for = ""
	_panel.close()
	_restore_normal()


## Câu hỏi cuối bài.
func _on_finish_choice(open_shop: bool) -> void:
	_wait_for = ""
	_learned_all = true
	_panel.close()
	if open_shop:
		_restore_normal()
		return
	if GameData != null:
		GameData.complete_level("tutorial")
	get_tree().reload_current_scene()


# --------------------------------------------------------------- vòng chạy ---

func _process(delta: float) -> void:
	if _wait_for.is_empty():
		return

	if _wait_for.begins_with(WAIT_SECONDS):
		_seconds_left -= delta
		if _seconds_left <= 0.0:
			_finish_step()
		return

	if _wait_for == "move" and _player != null:
		var now := _player.global_position
		_moved += Vector2(now.x - _last_position.x, now.z - _last_position.z).length()
		_last_position = now
		if _moved >= Cutscene.LEARN_DISTANCE:
			_finish_step()


# ----------------------------------------------------------- chuyển bước ---

func _go_to_step(i: int) -> void:
	_step = i
	_stepping = false
	_apply_step_limits(i)
	if i >= Cutscene.STEPS.size():
		_wait_for = ""
		_learned_all = true
		_panel.close()
		_restore_normal()
		return

	var step: Dictionary = Cutscene.STEPS[i]
	_wait_for = String(step.get("wait_for", ""))
	_seconds_left = 0.0
	_moved = 0.0
	if _player != null:
		_last_position = _player.global_position

	if _wait_for.begins_with(WAIT_SECONDS):
		_seconds_left = float(_wait_for.substr(WAIT_SECONDS.length()))
	if _wait_for.begins_with(WAIT_SERVE_COUNT):
		_served = 0
		_served_target = int(_wait_for.substr(WAIT_SERVE_COUNT.length()))

	if _wait_for == "ask":
		_panel.ask(String(step.get("line", "")), Cutscene.BTN_YES, Cutscene.BTN_NO)
	elif _wait_for == WAIT_ASK_FINISH:
		if get_node_or_null("/root/HuongDan") != null:
			_panel.hide()
			HuongDan.open()
			await HuongDan.closed
			_panel.show()
		_panel.ask(String(step.get("line", "")), Cutscene.BTN_OPEN, Cutscene.BTN_RETRY)
	else:
		_panel.set_step(String(step.get("line", "")), i, Cutscene.STEPS.size() - 2)

	_do_action(String(step.get("action", "")))


func _do_action(action: String) -> void:
	if action == "spawn_customer" and _customers != null:
		_customers.spawn_customer()
	elif action == "practice":
		_start_practice()


## Phần TỰ LÀM THỬ sau bài Steak.
func _start_practice() -> void:
	if _customers == null:
		return
	_customers.force_dish = ""
	_customers.force_table = 0
	_customers.price_factor = 0.0
	if GameData != null:
		_customers.menu = GameData.RULES_D1.get("menu", [])
	for i in Cutscene.PRACTICE_GUESTS:
		if i > 0:
			await get_tree().create_timer(Cutscene.PRACTICE_GAP).timeout
		if not is_instance_valid(self) or not is_inside_tree():
			return
		_customers.spawn_customer()


## Bước hiện tại coi như xong. Chặn gọi hai lần rồi trễ một nhịp mới sang bước.
func _finish_step() -> void:
	if _stepping:
		return
	_stepping = true
	_wait_for = ""
	await get_tree().create_timer(STEP_DELAY).timeout
	if is_instance_valid(self) and is_inside_tree():
		_go_to_step(_step + 1)
