extends Node
## Quản lý kĩ năng chủ động của nhân vật người chơi.
##
## Node này sở hữu BA thứ, và chỉ ba thứ đó:
##   1. Trạng thái "kĩ năng chủ động còn dùng được không" (còn mấy lượt, đã
##      đủ điều kiện chưa) và tín hiệu báo ra HUD.
##   2. Điểm vào duy nhất của phím Space.
##   3. Việc ÁP số kĩ năng vào các hệ khác lúc vào màn.
##
## Nó KHÔNG tự thi hành hiệu ứng. Hiệu ứng nằm ở nơi có luật: thanh kiên nhẫn
## là chuyện của customer_manager, mốc cháy là chuyện của cooking_system. Node này chỉ
## VẶN NÚM của chúng một lần lúc vào màn (bị động) hoặc một lần lúc bấm Space
## (chủ động).
##
## Vì sao không để hiệu ứng chạy trong này: nếu ở đây thì mỗi lần tính tiền
## một đơn, customer_manager phải đi hỏi ngược "kĩ năng có đang bật không" — tức
## hệ khách hàng phụ thuộc vào hệ kĩ năng. Vặn núm thì phụ thuộc chỉ đi MỘT
## chiều, đúng một lần, và customer_manager chạy y hệt nhau dù có hệ kĩ năng hay
## không.
##
## ──────────────────────────── KĨ NĂNG CHỈ ĂN KHI DÙNG ĐÚNG NHÂN VẬT ĐÓ
##
## Mọi con số lấy từ SkillRegistry theo GameData.selected_character. Chọn nhân
## vật khác — hoặc chạy thẳng map bằng F6 khi chưa chọn ai — thì bảng trả về
## bộ số mặc định (nhân 1,0, cộng 0,0), tức màn chơi chạy đúng bằng số gốc
## của game. Không có nhánh riêng nào cho trường hợp "không có kĩ năng".

## Phát mỗi khi trạng thái sẵn sàng đổi. HUD nghe để tô màu hoặc tô xám ảnh.
signal ready_changed(is_ready: bool)

## Phát cùng lúc với ready_changed, mang phần SỐ của điều kiện để HUD vẽ thanh.
##   ratio  0…1, đã kẹp sẵn — 1,0 nghĩa là đủ điều kiện
##   label    chữ hiện cạnh thanh: "3/5", "SPACE", "Đã dùng", hoặc RỖNG
##
## Chữ RỖNG là tín hiệu cho HUD ẨN hẳn thanh: nhân vật này chưa có kĩ năng chủ
## động, hoặc điều kiện thuộc loại chưa đếm được. Vẽ một thanh luôn đứng ở 0
## thì người chơi tưởng mình đang không tiến bộ, tệ hơn là không vẽ gì cả.
##
## Vì sao TÁCH khỏi ready_changed thay vì nhồi thêm tham số: ready_changed đã có
## một nơi nghe và chỉ quan tâm bật/tắt. Thêm tham số là sửa cả bên nghe cũ cho
## một thứ nó không dùng.
signal progress_changed(ratio: float, label: String)

const CUT_IN_PATH := "res://scripts/skills/skill_cut_in.gd"
const Registry := preload("res://scripts/skills/skill_registry.gd")

## Mỗi màn được dùng bao nhiêu lần.
##
## Theo bảng kĩ năng đã chốt: hầu hết kĩ năng chủ động dùng MỘT lần mỗi màn.
## Hai ngoại lệ (Triumphant Pulse của Oguri bật/tắt trong ngân sách 30 giây,
## Ambition của Chiyono O không giới hạn) sẽ khai báo riêng khi làm phần hiệu
## ứng — để ở đây một con số chung là đủ cho phần trình diễn.
@export var uses_per_level := 1

var _uses_left := 0
var _playing := false
## Nhân vật đang điều khiển, để khoá di chuyển trong lúc chiếu.
var _character: Node = null

## Hệ khách hàng và hệ bếp của màn. Node này CHỈ ghi vào chúng, không đọc
## trạng thái nào của chúng ngoài mấy bộ đếm dùng để xét điều kiện.
var _customers: Node = null
var _cooking: Node = null
## Đồng hồ màn (BangThoiGian). Có thể null — màn hướng dẫn không có đồng hồ.
## Chưa kĩ năng nào của Kita dùng tới; để sẵn cho Oguri, Teio và Chiyono O,
## cả ba đều đụng vào thời gian màn chơi.
var _clock: Node = null

## Hiệu ứng viết riêng đang chạy (thực thể của một file trong hieu_ung/).
## null nghĩa là kĩ năng này dùng hiệu ứng có sẵn, hoặc chưa bấm.
var _effect: RefCounted = null

## Mô tả kĩ năng chủ động của nhân vật đang chơi, lấy từ SkillRegistry. RỖNG
## nghĩa là nhân vật này chưa có kĩ năng chủ động — Space không làm gì cả.
var _active: Dictionary = {}


func _ready() -> void:
	_uses_left = uses_per_level
	# Node này phải nhận phím kể cả khi cây scene bị dừng thì mới không bị
	# kẹt nếu sau này có thứ khác dừng game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bật/tắt cheat trong bảng CODE No.7 phải làm ảnh trên HUD đổi màu ngay,
	# không đợi tới lần bấm phím tiếp theo.
	GameData.progress_changed.connect(_emit_state)
	# Đợi một frame rồi mới báo trạng thái đầu tiên: HUD được tạo cùng lúc với
	# node này nên lúc _ready chạy, tín hiệu chưa chắc đã nối xong.
	call_deferred("_emit_state")


func track_character(character: Node) -> void:
	_character = character
	_apply_to_hands()


## Xác suất ghép hỏng ở bàn chế tạo. Bàn chế tạo do node Hands của NHÂN VẬT
## xử lý chứ không do hệ bếp, mà nhân vật có thể được gắn trước hoặc sau
## setup() — nên giữ con số ở đây và gán lại ở cả hai thời điểm.
var _craft_fail_chance := 0.0


func hands() -> Node:
	if _character == null or not is_instance_valid(_character):
		return null
	return _character.get_node_or_null("Hands")


func _apply_to_hands() -> void:
	var h := hands()
	if h != null and "craft_fail_chance" in h:
		h.craft_fail_chance = _craft_fail_chance


## Dựng kĩ năng chủ động thứ hai (nếu nhân vật có). Nó là một node con tự lo
## phím bấm và giao diện của mình; node này chỉ tạo ra và trao đồ nghề.
func _build_secondary(character_id: String) -> void:
	var data := Registry.secondary(character_id)
	if data.is_empty() or get_node_or_null("SecondarySkill") != null:
		return
	var script_class := load(String(data.get("script", ""))) as GDScript
	if script_class == null:
		push_error("Không nạp được kĩ năng phụ: %s" % data.get("script", ""))
		return
	var node: Node = script_class.new()
	node.name = "SecondarySkill"
	add_child(node)
	node.setup(data, _customers, self)


## Kĩ năng có đang bấm được không.
##
## Cheat "kĩ năng vô hạn" bỏ qua MỌI điều kiện. Ở thời điểm hiện tại đây là
## cách bình thường để xem cut-in, vì điều kiện thật đều gắn với hệ đơn hàng
## mà hệ đó chưa tồn tại.
func can_use() -> bool:
	if _playing:
		return false
	if _is_toggle():
		# "Dùng được" với kĩ năng bật/tắt = bấm Space lúc này CÓ tác dụng:
		# đang bật (bấm để tắt), hoặc đã mở và còn ngân sách.
		if _toggle_on or GameData.infinite_skill:
			return true
		return _budget_left > 0.0 and _meets_condition()
	# Cheat vẫn phải tôn trọng "nhân vật này chưa có kĩ năng": cho bấm được
	# thì cut-in chiếu ra một kĩ năng không tồn tại, và người thử sẽ tưởng nó
	# đã cài xong.
	if _active.is_empty() and not ignore_condition:
		return false
	if GameData.infinite_skill:
		return true
	if _uses_left <= 0:
		return false
	return _meets_condition()


## Điều kiện riêng của từng nhân vật đã đạt chưa.
##
## HIỆN TẠI LUÔN TRẢ VỀ FALSE, và đó là câu trả lời ĐÚNG chứ không phải chỗ
## làm dở: điều kiện thật của cả bảy kĩ năng đều đếm đơn hàng (5 đơn hoàn hảo,
## 3 đơn có steak, 5 đơn có dough…) hoặc đếm thời gian màn chơi — không có
## thứ nào tồn tại. Chưa đếm được thì chưa ai đạt.
##
## Bản trước tôi để `return true` cho tiện thử, nhưng như vậy là NÓI DỐI giao
## diện: ảnh kĩ năng sáng lên ngay khi vào màn dù cheat đang tắt, tức là HUD
## báo một trạng thái mà cơ chế không hề có. Một cái đèn báo sai còn tệ hơn
## không có đèn — nó dạy người chơi (và cả người viết code) tin vào thứ không
## đúng.
##
## Muốn thử cut-in thì có hai đường, cả hai đều nói thật về trạng thái:
##   - Bật cheat "Kĩ năng không cần điều kiện" trong bảng CODE No.7.
##   - Hoặc bật cờ dưới đây, dành cho lúc cần test mà không muốn mở cheat.
@export var ignore_condition := false


func _meets_condition() -> bool:
	if ignore_condition:
		return true
	if _active.is_empty() or _customers == null:
		return false
	# Một chỗ đếm, một chỗ lấy ngưỡng: điều kiện "đạt chưa" và con số "n/N"
	# trên HUD đọc CHUNG hai hàm này, nên không thể có chuyện HUD ghi 10/10 mà
	# phím Space vẫn không ăn.
	var n := _count_progress()
	var threshold := _threshold()
	return n >= 0 and threshold > 0 and n >= threshold


## Ngưỡng phải đạt của điều kiện hiện tại.
func _threshold() -> int:
	if String(_active.get("condition", "")) == Registry.COND_MENU_COVERED:
		# Ngưỡng là số món của thực đơn HÔM ĐÓ — Ngày 1 bảy món, Ngày 3 mười ba.
		# Gõ cứng một con số vào file kĩ năng thì chỉ đúng với một màn.
		return _customers.menu_dishes().size() if _customers != null else 0
	return int(_active.get("threshold", 0))


## Tiến độ điều kiện, dạng "3/5". Rỗng khi nhân vật chưa có kĩ năng chủ động
## hoặc điều kiện thuộc loại chưa đếm được.
##
## Đặt ở đây chứ không để HUD tự đếm: luật đếm là luật của kĩ năng, và HUD
## không được phép biết "5 đơn hoàn hảo" nghĩa là gì.
##
## Trả về "3/5". Rỗng khi nhân vật chưa có kĩ năng chủ động hoặc điều kiện
## thuộc loại chưa đếm được — nơi gọi hiểu rỗng là "không có gì để hiện".
func progress_text() -> String:
	var n := _count_progress()
	if n < 0:
		return ""
	return "%d/%d" % [mini(n, _threshold()), _threshold()]


## Tỉ lệ hoàn thành điều kiện, 0…1 đã kẹp sẵn. Trả 0 khi không đếm được.
func condition_ratio() -> float:
	if _is_toggle() and (_toggle_on or _meets_condition()):
		var budget := float(_active.get("budget_seconds", 0.0))
		return clampf(_budget_left / budget, 0.0, 1.0) if budget > 0.0 else 0.0
	var n := _count_progress()
	var threshold := _threshold()
	if n < 0 or threshold <= 0:
		return 0.0
	return clampf(float(n) / float(threshold), 0.0, 1.0)


## Bộ đếm hiện tại của điều kiện, hoặc -1 nếu không đếm được.
##
## Gom vào MỘT hàm rồi để progress_text() và condition_ratio() cùng gọi, thay vì mỗi
## hàm tự `match` một lần: hai bản sao của cùng một bảng tra thì thêm một loại
## điều kiện mới là hai chỗ phải nhớ sửa, và quên một chỗ thì thanh với con số
## nói hai điều khác nhau.
func _count_progress() -> int:
	if _active.is_empty() or _customers == null:
		return -1
	match String(_active.get("condition", "")):
		Registry.COND_PERFECT_ORDERS:
			return int(_customers.perfect_orders)
		Registry.COND_ORDERS_DONE:
			# Trừ mốc của lần dùng trước: kĩ năng dùng lại được (Chiyono O)
			# phải đếm lại từ 0 sau mỗi lần bấm.
			return int(_customers.orders_done) - _progress_base
		Registry.COND_ORDERS_WITH_DISHES:
			return int(_customers.counted_orders_done)
		Registry.COND_TIME_ELAPSED:
			return _elapsed_seconds()
		Registry.COND_MONEY_EARNED:
			return maxi(0, int(_customers.money))
		Registry.COND_MENU_COVERED:
			var covered := 0
			for dish in _customers.menu_dishes():
				if _customers.perfect_dishes.has(dish):
					covered += 1
			return covered
	return -1


## Số đơn đã có lúc dùng kĩ năng lần gần nhất. Chỉ kĩ năng khai "repeat" đụng tới.
var _progress_base := 0


## Số giây ĐÃ TRÔI của màn, đọc từ đồng hồ màn. 0 nếu màn không có đồng hồ.
func _elapsed_seconds() -> int:
	if _clock == null:
		return 0
	return int(float(_clock.duration) - float(_clock.time_left))


## Gắn vào màn chơi: áp các kĩ năng BỊ ĐỘNG và bắt đầu theo dõi điều kiện.
##
## Gọi SAU khi customer_manager và cooking đã tồn tại — cả hai đều là thứ node này
## vặn núm. level_base lo thứ tự đó.
##
## Vì sao áp bị động ở đây chứ không để mỗi hệ tự đi hỏi bảng kĩ năng: nếu mỗi
## hệ tự hỏi thì customer_manager phải biết tới SkillRegistry, cooking_system cũng vậy, và
## thêm một kĩ năng mới là thêm một hệ nữa phải biết. Vặn núm từ một chỗ thì
## các hệ kia chỉ cần có sẵn một biến số — chúng không biết kĩ năng là gì.
func setup(customers: Node, cooking: Node, clock: Node = null) -> void:
	_customers = customers
	_cooking = cooking
	_clock = clock
	var id := String(GameData.selected_character)
	_active = Registry.active(id)
	# Số lượt lấy từ file kĩ năng của nhân vật, không phải từ @export ở đây:
	# hai kĩ năng có luật riêng (Oguri bật/tắt trong ngân sách 30 giây,
	# Chiyono O không giới hạn) và luật đó thuộc về kĩ năng chứ không thuộc
	# về cái node quản lý.
	_uses_left = int(_active.get("uses", uses_per_level))
	_budget_left = float(_active.get("budget_seconds", 0.0))
	_apply_passive(Registry.passive(id))
	# Điều kiện "giao N đơn thuộc một nhóm món": báo cho hệ khách biết nhóm
	# nào cần đếm. Hệ khách tự đếm, node này chỉ đọc con số.
	if _customers != null \
			and String(_active.get("condition", "")) == Registry.COND_ORDERS_WITH_DISHES:
		_customers.counted_dishes = _active.get("dishes", [])

	# Điều kiện của Kita đếm ĐƠN, nên chỉ cần xem lại trạng thái mỗi khi một
	# đơn kết thúc — không phải kiểm tra mỗi frame hình. Với những điều kiện
	# đếm THỜI GIAN sau này (Oguri) thì sẽ cần thêm một nhịp kiểm tra riêng.
	if _customers != null and _customers.has_signal("order_finished"):
		_customers.order_finished.connect(_on_order_finished)
	# Điều kiện đếm TIỀN (Teio): tiền vào ví lúc khách ăn xong, tức SAU tín hiệu
	# order_finished vài giây. Không nghe riêng tín hiệu tiền thì HUD chậm một
	# đơn so với ví.
	if _customers != null and _customers.has_signal("money_changed"):
		_customers.money_changed.connect(func(_t: int, _a: int, _s: Vector3) -> void:
			_emit_state())
	_build_secondary(id)
	_emit_state()


## Vặn núm của các hệ khác theo bộ số bị động.
##
## Dùng CỘNG/NHÂN vào giá trị đang có chứ không GÁN ĐÈ: luật màn (level_rules.gd)
## cũng đặt vài con số của customer_manager, và gán đè thì thứ tự gọi quyết định
## ai thắng — một phụ thuộc ngầm sẽ hỏng lặng lẽ vào ngày ai đó đổi thứ tự
## dựng node trong level_base.
func _apply_passive(p: Dictionary) -> void:
	if _customers != null:
		_customers.patience_factor = float(p["patience_factor"])
		_customers.perfect_bonus += float(p["perfect_bonus_add"])
		_customers.bonus_payout_chance = float(p["bonus_payout_chance"])
		_customers.bonus_payout_multiplier = float(p["bonus_payout_multiplier"])
		_customers.dish_price_factors = p["dish_price_factors"]
		_customers.dish_weight_factors = p["dish_weight_factors"]
		_customers.skill_price_factor = float(p["all_price_factor"])
		_customers.time_scale = float(p["time_scale"])
		if bool(p["force_perfect"]):
			_customers.force_perfect = true
	if _clock != null:
		_clock.time_scale = float(p["time_scale"])
	_craft_fail_chance = float(p["cook_fail_chance"])
	_apply_to_hands()
	_refill_stamina_on_order = bool(p["refill_stamina_on_order"])
	if _cooking != null:
		_cooking.fail_chance = float(p["cook_fail_chance"])
		_cooking.speed_factor = float(p["time_scale"])
		_cooking.burn_time_cut += float(p["burn_time_cut"])
		_cooking.cook_time_cut += float(p["cook_time_cut"])
		_cooking.cook_time_cut_items = p["cook_time_cut_items"]
		_cooking.bake_time_cut += float(p["bake_time_cut"])


func _on_order_finished(_order: Variant, reason: String) -> void:
	# Hốc trưởng: giao xong một đơn là thanh chạy nhanh đầy lại. Chỉ đơn ĐÃ
	# PHỤC VỤ ("served") — khách bỏ về không tính.
	if _refill_stamina_on_order and reason == "served" \
			and _character != null and _character.has_method("refill_stamina"):
		_character.refill_stamina()
	_emit_state()


# ═══════════════════════════════════ KĨ NĂNG BẬT/TẮT TRONG NGÂN SÁCH
#
# Kĩ năng khai `"toggle": true` (Triumphant Pulse) không phải loại "bấm một
# lần, có tác dụng tới hết màn": Space BẬT rồi Space lần nữa TẮT, và tổng thời
# gian được bật trong cả màn bị chặn bởi `"budget_seconds"`. Hết ngân sách là
# tự tắt và không bật lại được.
#
# Đoạn phim cut-in chỉ chiếu ở LẦN BẬT ĐẦU TIÊN. Các lần sau bật/tắt tức thì:
# một kĩ năng sinh ra để bấm nhiều lần mà lần nào cũng chặn màn hình hai giây
# thì người chơi sẽ thôi không bấm nữa.

var _refill_stamina_on_order := false
var _toggle_on := false
var _budget_left := 0.0
var _cut_in_shown := false
## Nhịp cập nhật HUD cho điều kiện đếm THỜI GIAN và cho ngân sách đang chạy.
var _hud_tick := 0.0


## Rời màn khi kĩ năng còn đang bật (thoát ra menu, chơi lại): phải TẮT hiệu
## ứng, nếu không thứ nó đã đụng ở ngoài màn chơi — nhạc nền đang bị cho im —
## sẽ kẹt nguyên như vậy sang màn sau.
func _exit_tree() -> void:
	if _toggle_on:
		disable_effect()


## Màn chơi kết thúc (hết giờ, thua, đóng quán sớm): tắt kĩ năng bật/tắt nếu
## nó còn đang bật. level_base gọi ngay trước khi dựng bảng tổng kết — không
## có bước này thì bảng tổng kết hiện lên trên một màn hình còn phủ xanh,
## nhạc vẫn im, khách vẫn đóng băng.
func end_of_level() -> void:
	if _toggle_on:
		_set_toggle(false)


func _is_toggle() -> bool:
	return bool(_active.get("toggle", false))


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	# Hiệu ứng viết riêng nào có hàm tick() thì được gọi mỗi khung hình trong
	# lúc game đang chạy thật (không tạm dừng, không chiếu phim). Dành cho
	# hiệu ứng có phần "diễn ra theo thời gian" — Go, Go, Mun! gieo choáng
	# theo từng giây di chuyển.
	if _effect != null and not _playing and not get_tree().paused \
			and _effect.has_method("tick"):
		_effect.tick(delta, _context())
	# Ngân sách chỉ chạy khi kĩ năng ĐANG BẬT và game không bị dừng (menu
	# tạm dừng, đoạn phim cut-in): thời gian người chơi không điều khiển được
	# thì không được trừ vào ngân sách của họ.
	if _toggle_on and not _playing and not get_tree().paused:
		_budget_left -= delta
		if _budget_left <= 0.0:
			_budget_left = 0.0
			_set_toggle(false)
	# Điều kiện đếm giây và con số ngân sách đổi liên tục mà không có sự kiện
	# nào báo, nên phải tự hỏi lại theo nhịp. Bốn lần mỗi giây là đủ mượt cho
	# một con số đếm giây, và rẻ hơn nhiều so với mỗi khung hình.
	_hud_tick -= delta
	if _hud_tick <= 0.0:
		_hud_tick = 0.25
		if _is_toggle() or String(_active.get("condition", "")) == Registry.COND_TIME_ELAPSED:
			_emit_state()


func _set_toggle(on: bool) -> void:
	if _toggle_on == on:
		return
	_toggle_on = on
	if on:
		_apply_effect()
	else:
		disable_effect()
	_emit_state()


## Space với kĩ năng bật/tắt. Trả về true nếu đã xử lý.
func _activate_toggle() -> void:
	if _toggle_on:
		_set_toggle(false)
		return
	if _budget_left <= 0.0 and not GameData.infinite_skill:
		return
	if not (_meets_condition() or GameData.infinite_skill):
		return
	if GameData.infinite_skill and _budget_left <= 0.0:
		_budget_left = float(_active.get("budget_seconds", 30.0))
	if not _cut_in_shown:
		_cut_in_shown = true
		var cut_in := _make_cut_in()
		if cut_in != null:
			get_tree().current_scene.add_child(cut_in)
			if cut_in.play(str(GameData.selected_character)):
				_playing = true
				_lock_character(true)
				cut_in.finished.connect(_on_cut_in_finished)
			else:
				cut_in.queue_free()
	_set_toggle(true)


## Bật hiệu ứng của kĩ năng chủ động.
##
## Gọi NGAY LÚC BẤM, không đợi cut-in chiếu xong — nếu buộc đợi hết phim thì
## người bỏ qua đoạn phim sẽ được lợi (hoặc thiệt) hơn người ngồi xem, tức
## cùng một kĩ năng cho hai kết quả khác nhau tuỳ thói quen bấm phím.
func _apply_effect() -> void:
	# HIỆU ỨNG VIẾT RIÊNG thắng hiệu ứng có sẵn.
	#
	# Hai đường vào thay vì một là chủ ý: kĩ năng chỉ đổi một con số (cả ba
	# của Kita) không đáng phải có một file riêng, còn kĩ năng là cả một cơ
	# chế (Oguri dừng thời gian, Chiyono reset màn) thì không nhét vừa một
	# nhánh `match`. Bắt mọi kĩ năng đi chung một đường thì một trong hai loại
	# phải chịu thiệt.
	var path := String(_active.get("script", ""))
	if not path.is_empty():
		_run_custom_effect(path)
		return

	match String(_active.get("effect", "")):
		Registry.FX_FORCE_PERFECT:
			if _customers != null:
				_customers.force_perfect = true
		Registry.FX_WILDCARD_DISHES:
			if _customers != null:
				_customers.wildcard_dishes = _active.get("wildcard_dishes", [])

	# NÚM PHỤ, áp ĐỘC LẬP với khoá "effect" ở trên.
	#
	# Vì sao không gộp vào một hiệu ứng mới tên FX_CHEER: một kĩ năng chủ động
	# chỉ khai được MỘT khoá "effect", nên gộp thì mỗi lần thêm một tác dụng
	# lại phải đặt tên hiệu ứng mới và sửa cả `match` — trong khi bản chất mấy
	# thứ này chỉ là vặn thêm một con số. Để rời thì kĩ năng nào cần cứ khai
	# thêm khoá, không cần biết tới `match`, và hai tác dụng không dính nhau.
	var multiplier := float(_active.get("perfect_payout_multiplier", 1.0))
	if _customers != null and not is_equal_approx(multiplier, 1.0):
		_customers.perfect_payout_multiplier = multiplier


## Nạp và chạy một hiệu ứng trong thư mục hieu_ung/. Xem effects/_template.gd để
## biết giao ước (hàm enable/disable và nội dung của ctx).
##
## Nạp lúc CHẠY chứ không preload: một lỗi cú pháp trong hiệu ứng của Oguri
## không được phép làm cả hệ kĩ năng không biên dịch được, tức làm Kita cũng
## hỏng theo.
func _run_custom_effect(path: String) -> void:
	var script_class := load(path) as GDScript
	if script_class == null:
		push_error("Không nạp được hiệu ứng kĩ năng: %s" % path)
		return
	# Hiệu ứng cũ còn đó (bật lại nhờ cheat không giới hạn lượt): TẮT nó trước
	# khi thay bằng thực thể mới. Bỏ rơi nó thì thứ nó đang giữ dở — Mambo
	# đang bị choáng, nhân vật đang bị khoá di chuyển — không ai trả lại nữa.
	if _effect != null and _effect.has_method("disable"):
		_effect.disable(_context())
	_effect = script_class.new()
	if not _effect.has_method("enable"):
		push_error("Hiệu ứng %s thiếu hàm enable()." % path)
		_effect = null
		return
	_effect.enable(_context())


## Gói mọi thứ một hiệu ứng có thể cần. Danh sách khoá ghi ở effects/_template.gd.
func _context() -> Dictionary:
	return {
		"customers": _customers,
		"cooking": _cooking,
		"clock": _clock,
		"level": get_parent(),
		"character": _character,
		"data": _active,
	}


## Tắt hiệu ứng đang chạy, nếu nó là loại bật/tắt được.
##
## Chưa nơi nào gọi — để sẵn cho Triumphant Pulse của Oguri, kĩ năng duy nhất
## trong bảng bật/tắt tự do trong một ngân sách thời gian.
func disable_effect() -> void:
	if _effect != null and _effect.has_method("disable"):
		_effect.disable(_context())


## Người chơi bấm Space.
##
## Dùng _unhandled_input chứ không phải _input: bảng chọn nguyên liệu
## (picker_menu.gd) đang dùng _input để cướp phím trước, và trong lúc bảng đó
## mở thì bấm Space không được phép kích hoạt kĩ năng.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("skill"):
		return
	get_viewport().set_input_as_handled()
	activate()


func activate() -> void:
	# Chưa vào ca (màn đếm ngược đầu màn còn đó) thì KHÔNG kĩ năng nào bật
	# được. Điều kiện thật không bao giờ đạt sớm thế, nhưng cheat "kĩ năng
	# không cần điều kiện" thì có — và bật dừng-thời-gian trong lúc đồng hồ
	# đang bị màn đếm ngược giữ sẽ làm hai bên giành nhau cái đồng hồ: tắt kĩ
	# năng xong đồng hồ đứng luôn tới hết màn.
	if get_parent() != null and get_parent().get_node_or_null("LevelIntro") != null:
		return
	if _is_toggle():
		if not _playing:
			_activate_toggle()
		return
	if not can_use():
		return
	var id := str(GameData.selected_character)
	# Kĩ năng dùng lại được chỉ chiếu phim LẦN ĐẦU. Chiyono O bấm cứ mười đơn
	# một lần; lần nào cũng chặn màn hình hai giây thì người chơi sẽ ngại bấm.
	var skip_film := bool(_active.get("repeat", false)) and _cut_in_shown
	var cut_in: Node = null if skip_film else _make_cut_in()
	if cut_in != null:
		# Thêm vào cây TRƯỚC khi gọi play(): VideoStreamPlayer chỉ phát được
		# khi đã nằm trong cây scene.
		get_tree().current_scene.add_child(cut_in)
		if not cut_in.play(id):
			cut_in.queue_free()
			cut_in = null

	# Chỉ trừ lượt khi cheat TẮT, để cheat đúng nghĩa "không giới hạn".
	if not GameData.infinite_skill:
		_uses_left -= 1
	if bool(_active.get("repeat", false)) and _customers != null:
		_progress_base = int(_customers.orders_done)

	if cut_in == null:
		# Không có phim (thiếu file, hoặc cố ý bỏ qua): VẪN bật kĩ năng. "Thiếu
		# một file video" không được phép khoá cả một cơ chế. Không khoá nhân
		# vật, không dừng game: không có phim thì không có gì để chờ.
		AmThanh.play_sfx("perfect")
		_apply_effect()
		_emit_state()
		return

	_cut_in_shown = true
	_playing = true
	_lock_character(true)
	_emit_state()
	cut_in.finished.connect(_on_cut_in_finished)

	_apply_effect()


func _on_cut_in_finished() -> void:
	_playing = false
	_lock_character(false)
	_emit_state()


func _lock_character(locked: bool) -> void:
	if _character != null and "movement_locked" in _character:
		_character.movement_locked = locked


func _emit_state() -> void:
	var usable := can_use()
	ready_changed.emit(usable)
	progress_changed.emit(condition_ratio(), _progress_label(usable))


## Chữ hiện cạnh thanh tiến trình. Ba trạng thái, ba câu khác hẳn nhau — không
## dùng chung một câu có thêm dấu chấm than, vì người chơi liếc HUD chứ không
## đọc.
##
##   ""         nhân vật chưa có kĩ năng chủ động → HUD ẩn thanh
##   "3/5"      đang gom điều kiện
##   "SPACE"    đủ rồi, bấm đi — nói thẳng PHÍM chứ không nói "sẵn sàng",
##              vì thứ người chơi cần lúc đó là biết bấm cái gì
##   "Đã dùng"  hết lượt của màn này
func _progress_label(usable: bool) -> String:
	if _active.is_empty():
		return ""
	if _is_toggle():
		return _toggle_label()
	if usable:
		return "SPACE"
	# Hết lượt: phân biệt với "chưa đủ điều kiện", vì hai thứ đó đòi người chơi
	# làm hai việc khác nhau — một cái là cố thêm, một cái là thôi đừng chờ.
	# Cheat bật thì không bao giờ hết lượt nên không rơi vào nhánh này.
	if _uses_left <= 0 and not GameData.infinite_skill:
		return "Đã dùng"
	var text := progress_text()
	return text if not text.is_empty() else "..."


## Chữ trên HUD của kĩ năng bật/tắt:
##   "2:35"    chưa tới giờ mở — đếm ngược tới lúc dùng được
##   "SPACE"   mở rồi, đang tắt, còn ngân sách
##   "18s"     đang BẬT — số giây ngân sách còn lại
##   "Đã dùng" hết ngân sách
func _toggle_label() -> String:
	if _toggle_on:
		return "%ds" % int(ceilf(_budget_left))
	if _budget_left <= 0.0 and not GameData.infinite_skill:
		return "Đã dùng"
	if _meets_condition() or GameData.infinite_skill:
		return "SPACE"
	var wait := maxi(0, int(_active.get("threshold", 0)) - _elapsed_seconds())
	# floori(x / 60.0) chứ không `wait / 60`: chia hai số nguyên trong GDScript
	# chạy đúng nhưng in một cảnh báo mỗi lần nạp script.
	return "%d:%02d" % [floori(wait / 60.0), wait % 60]


## Nạp lúc chạy chứ không preload, cùng lý do với level_base.gd: lỗi cú pháp
## trong màn cut-in không được phép làm cả hệ kĩ năng không biên dịch được.
func _make_cut_in() -> Node:
	var script_class := load(CUT_IN_PATH) as GDScript
	if script_class == null:
		push_error("Không nạp được %s" % CUT_IN_PATH)
		return null
	var n: Node = script_class.new()
	n.name = "SkillCutIn"
	return n
