extends Node
## Bộ dẫn dắt màn hướng dẫn: chạy kịch bản, theo dõi người chơi, sang bước.
##
## Chia ba phần rạch ròi, và đây là điểm đáng nói nhất của cả hệ:
##   cutscene_tutorial.gd  — DẠY CÁI GÌ (dữ liệu, đọc như tờ giấy)
##   guide_panel.gd     — VẼ RA SAO (chỉ hiện chữ, không biết luật)
##   file này              — BIẾT KHI NÀO NGƯỜI CHƠI ĐÃ LÀM ĐƯỢC
## Ba việc đó đổi với ba nhịp khác nhau: lời thoại sửa liên tục, giao diện sửa
## thỉnh thoảng, còn cách phát hiện gần như không đổi. Gộp lại một file thì mỗi
## lần sửa một câu chữ lại phải đọc qua cả đống logic tín hiệu.
##
## VÌ SAO TỰ PHÁT HIỆN CHỨ KHÔNG BẮT BẤM PHÍM ĐỂ SANG BƯỚC: người chơi bấm qua
## được thì họ sẽ bấm qua, và học xong không nhớ gì. Bắt phải LÀM ĐÚNG rồi mới
## đi tiếp thì bài học nằm ở ngón tay chứ không nằm ở mắt. Giá phải trả là bộ
## này cần biết một chút về hệ nấu ăn — nhưng chỉ ở mức NGHE tín hiệu, nó không
## gọi ngược vào ai cả.

const Cutscene := preload("res://scripts/story/cutscene_tutorial.gd")
const GuidePanel := preload("res://scripts/ui/guide_panel.gd")

## Hướng dẫn kết thúc. `tong_ket` = true thì màn dừng luôn và hiện bảng kết
## quả hạng S.
##
## HIỆN TẠI CẢ HAI LỐI RA ĐỀU TRẢ VỀ true (sửa 11/9/2026):
##   • học hết kịch bản  -> tổng kết
##   • bấm "Bỏ qua"      -> tổng kết
##
## Vì sao bỏ lối "chạy tiếp như màn thường": nút đó trước tên là "Tự làm" và
## nó có lý khi màn hướng dẫn là NƠI DUY NHẤT chơi được — người không muốn
## học vẫn cần một cái bếp để nghịch. Giờ đã có Ngày 1, nên chỗ để chơi thật
## là Ngày 1, còn màn hướng dẫn chỉ nên làm đúng một việc: dạy, hoặc đứng
## sang một bên. Để nó chạy tiếp bảy phút không đồng hồ, không khách tự vào,
## thì người bấm "Bỏ qua" rơi vào một cái bếp trống không có gì xảy ra — tệ
## hơn hẳn so với cho họ đi thẳng sang Ngày 1.
##
## GIỮ tham số thay vì bỏ hẳn: ngày nào thêm một lối ra thứ ba (ví dụ thoát
## giữa chừng) thì chỗ nghe đã sẵn sàng, không phải đổi chữ ký tín hiệu.
signal tutorial_finished(tong_ket: bool)

## Trễ một nhịp giữa "làm đúng" và "hiện câu tiếp theo".
##
## Không cho nhảy ngay: người chơi vừa làm xong một việc thì mắt còn đang ở
## chỗ vừa làm, chữ đổi ngay là họ bỏ lỡ. Nửa giây đủ để nhìn lên.
const STEP_DELAY := 0.6

## Ba tiền tố của trường "wait_for" — điều kiện có kèm tham số.
##
## Viết thành HẰNG rồi cắt chuỗi bằng .length() thay vì gõ số 4 / 9 / 5 như
## trước: con số đó là ĐỘ DÀI của chính tiền tố, nên đổi tên tiền tố mà quên
## sửa số là bài học tutorial im lặng không bao giờ qua được bước đó — không
## lỗi, không cảnh báo, chỉ là người học đứng mãi một chỗ.
##
## Đúng là chuyện vừa suýt xảy ra khi "cam:" (4 kí tự) thành "hold:" (5).
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
## ra đều bật cờ này.
var _learned_all := false
## Phần tự làm thử: đã giao đúng bao nhiêu đơn / cần bao nhiêu.
var _served := 0
var _served_target := 0


## Gắn vào màn chơi. Truyền thẳng các node cần nghe thay vì tự đi tìm trong
## cây scene: tìm bằng đường dẫn thì đổi tên một node là hỏng lặng lẽ, mà lỗi
## kiểu đó chỉ lộ ra khi chơi tới đúng bước dùng nó.
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

	# Khoá tương tác cho tới khi người chơi chọn HỌC (bước 1). Trước đó họ
	# vẫn đi lại được để làm quen, nhưng không nhặt được gì.
	_set_interact_locked(true)

	_panel.open()
	_build_reset_link()
	_go_to_step(0)


## Dòng "gặp lỗi thì bấm vào đây" (16/11/2026) — góc dưới bên trái, suốt màn
## hướng dẫn. Màn này là lần ĐẦU người chơi chạm vào game: nếu kẹt (đồ rơi
## mất, khách đứng sai chỗ...) mà không có lối thoát thì họ chỉ còn cách tắt
## game. Bấm vào là nạp lại chính màn hướng dẫn, học lại từ đầu.
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
## kịch bản. Bước 0–2 (hỏi, tập đi, chờ khách) khoá hẳn; các bước có "allow"
## chỉ cho bấm đúng loại trạm đang dạy — người chơi không nhặt được món khác
## rồi kẹt tay. Bước không khai "allow" sau bài dạy (lời chào cuối) thì mở hết.
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
## "dang_tutorial" nào rải trong code hệ thống — hệ khách và panel thời gian
## không cần biết màn hướng dẫn tồn tại.
func _apply_tutorial_rules() -> void:
	if _customers != null:
		_customers.drain_patience = false   # thanh kiên nhẫn hiện nhưng không cạn
		_customers.auto_spawn = false         # khách vào đúng lúc kịch bản gọi
		_customers.force_table = 1              # bàn gần bếp nhất
		_customers.force_dish = "mon_steak"    # đúng món đang dạy
	if _clock != null:
		_clock.counting_down = false


## Trả màn chơi về luật bình thường. Dùng cho CẢ HAI lối ra: học xong, và bấm
## "Bỏ qua". Một hàm cho hai lối thì không có lối nào bị quên.
func _restore_normal() -> void:
	if _customers != null:
		_customers.drain_patience = true
		_customers.auto_spawn = true
		_customers.force_table = 0
		_customers.force_dish = ""
		_customers.price_factor = 1.0
	if _clock != null:
		_clock.counting_down = true

	# ĐÁNH DẤU HOÀN THÀNH — bắt buộc, không phải tuỳ chọn.
	#
	# Màn "d1_sang" khai `needs: "tutorial"`, nên không gọi dòng này thì Ngày 1
	# khoá vĩnh viễn và người chơi kẹt ở màn hướng dẫn mãi mãi. Lối "Bỏ qua"
	# cũng phải đi qua đây, vì bỏ qua hướng dẫn không có nghĩa là bị phạt.
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

	# Bàn chế tạo: nghe nội dung đổi để biết người chơi đã đặt được thứ cần đặt.
	# Duyệt nhóm "station" chứ không đi theo đường dẫn node, vì bàn chế tạo có thể
	# được kê lại chỗ khác trong map bất cứ lúc nào.
	for n in get_tree().get_nodes_in_group("station"):
		if String(n.kind) == "crafting_table" and n.has_signal("contents_changed"):
			n.contents_changed.connect(_on_table_changed)


func _on_hands_changed(id: String) -> void:
	if _wait_for.begins_with(WAIT_HOLD) and id == _wait_for.substr(WAIT_HOLD.length()):
		_finish_step()


func _on_cook_finished(station: Node, _dish: String, success: bool) -> void:
	if not success:
		return
	# `loai` van la ten thuoc tinh cua Workstation — lop do thuoc lo 6, chua doi.
	# Doc bang ten CU o day la dung; bien cuc bo thi da la tieng Anh.
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
##
## Bỏ qua vẫn đi qua `_restore_normal()` — hàm đó là nơi gọi
## `GameData.complete_level("tutorial")`, mà Ngày 1 khai `needs: "tutorial"`.
## Bỏ qua hướng dẫn không có nghĩa là bị khoá Ngày 1.
func _on_select(yes: bool) -> void:
	# Câu hỏi CUỐI bài (mở quán / thử lại) đi chung tín hiệu với câu hỏi đầu
	# bài, phân biệt bằng bước đang đứng — bảng chỉ có một kiểu hỏi hai nút,
	# không cần dựng kiểu thứ hai.
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
##   Mở quán  — đi đúng lối ra cũ: _restore_normal() đánh dấu xong tutorial và
##              phát tutorial_finished, level_base chuyển sang chọn nhân vật.
##   Thử lại  — nạp lại chính màn hướng dẫn, bài học chạy lại từ đầu.
##
## Thử lại VẪN đánh dấu hoàn thành trước khi nạp lại: người chơi đã học hết
## bài, chỉ muốn ôn. Không đánh dấu thì lỡ họ thoát ra menu giữa lượt ôn là
## Ngày 1 lại bị khoá — phạt người chăm chỉ nhất.
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
		# Cộng dồn QUÃNG ĐƯỜNG chứ không đo khoảng cách tới điểm xuất phát: đo
		# khoảng cách thì đi một vòng tròn về chỗ cũ lại thành chưa đi đâu cả,
		# mà đi vòng tròn đúng là thứ người ta làm khi thử phím lần đầu.
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
		# Học xong các bước: mở bảng F1 cho người chơi xem lại toàn bộ một lượt
		# TRƯỚC câu hỏi "Mở quán / Thử lại" — lúc này họ đã tự tay làm, nên đọc
		# bảng là ôn lại chứ không phải học chay. Bảng tự tạm dừng game.
		if get_node_or_null("/root/HuongDan") != null:
			_panel.hide()
			HuongDan.open()
			await HuongDan.closed
			_panel.show()
		_panel.ask(String(step.get("line", "")), Cutscene.BTN_OPEN, Cutscene.BTN_RETRY)
	else:
		# Đánh số bỏ qua bước hỏi: người chơi đếm "bước 1" từ bài học đầu tiên,
		# còn câu hỏi mở màn thì không phải một bài học.
		# Trừ 2: câu hỏi đầu bài và câu hỏi cuối bài đều không phải bài học.
		_panel.set_step(String(step.get("line", "")), i, Cutscene.STEPS.size() - 2)

	_do_action(String(step.get("action", "")))


func _do_action(action: String) -> void:
	if action == "spawn_customer" and _customers != null:
		_customers.spawn_customer()
	elif action == "practice":
		_start_practice()


## Phần TỰ LÀM THỬ sau bài Steak.
##
## Chỉ vặn các núm @export có sẵn của hệ khách, như _apply_tutorial_rules():
##   - bỏ ép món / ép bàn  -> khách gọi ngẫu nhiên, ngồi bàn trống bất kì
##   - menu = thực đơn Ngày 1 -> "ngẫu nhiên" nhưng trong tầm người mới (không
##     ra soup hay hamburger 5 thành phần ngay buổi đầu)
##   - price_factor = 0    -> KHÔNG TÍNH TIỀN (giá đơn chốt lúc tạo đơn)
##   - drain_patience vẫn false từ đầu bài -> thanh kiên nhẫn không cạn
## Khách vào lệch nhau PRACTICE_GAP giây (xem cutscene_tutorial).
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
	# Khoá NGAY: một bước có thể thoả điều kiện hai lần trong cùng khung hình
	# (ví dụ tay đổi đồ hai lần liên tiếp), và khi đó nó sẽ nhảy vọt hai bước
	# — người chơi mất trắng một bài học mà không hiểu vì sao.
	_stepping = true
	_wait_for = ""
	await get_tree().create_timer(STEP_DELAY).timeout
	if is_instance_valid(self) and is_inside_tree():
		_go_to_step(_step + 1)
