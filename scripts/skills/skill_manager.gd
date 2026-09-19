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
## là chuyện của quan_ly_khach, mốc cháy là chuyện của bep_nau. Node này chỉ
## VẶN NÚM của chúng một lần lúc vào màn (bị động) hoặc một lần lúc bấm Space
## (chủ động).
##
## Vì sao không để hiệu ứng chạy trong này: nếu ở đây thì mỗi lần tính tiền
## một đơn, quan_ly_khach phải đi hỏi ngược "kĩ năng có đang bật không" — tức
## hệ khách hàng phụ thuộc vào hệ kĩ năng. Vặn núm thì phụ thuộc chỉ đi MỘT
## chiều, đúng một lần, và quan_ly_khach chạy y hệt nhau dù có hệ kĩ năng hay
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


## Kĩ năng có đang bấm được không.
##
## Cheat "kĩ năng vô hạn" bỏ qua MỌI điều kiện. Ở thời điểm hiện tại đây là
## cách bình thường để xem cut-in, vì điều kiện thật đều gắn với hệ đơn hàng
## mà hệ đó chưa tồn tại.
func can_use() -> bool:
	if _playing:
		return false
	# Cheat vẫn phải tôn trọng "nhân vật này chưa có kĩ năng": cho bấm được
	# thì cut-in chiếu ra một kĩ năng không tồn tại, và người thử sẽ tưởng nó
	# đã cài xong.
	if _active.is_empty() and not ignore_condition:
		return false
	if GameData.ki_nang_vo_han:
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
	var threshold := int(_active.get("threshold", 0))
	match String(_active.get("condition", "")):
		Registry.COND_PERFECT_ORDERS:
			return int(_customers.so_don_hoan_hao) >= threshold
		Registry.COND_ORDERS_DONE:
			return int(_customers.so_don_xong) >= threshold
	# Bốn kiểu điều kiện còn lại (đếm món nấu, đếm giây, cho pet ăn, phủ kín
	# thực đơn) chưa có bộ đếm nào trong game. Trả false là câu trả lời ĐÚNG:
	# chưa đếm được thì chưa ai đạt. Trả true cho tiện thử là nói dối giao
	# diện — ảnh kĩ năng sáng lên trong khi cơ chế không hề có.
	return false


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
	return "%d/%d" % [mini(n, int(_active.get("threshold", 0))),
		int(_active.get("threshold", 0))]


## Tỉ lệ hoàn thành điều kiện, 0…1 đã kẹp sẵn. Trả 0 khi không đếm được.
func condition_ratio() -> float:
	var n := _count_progress()
	var threshold := int(_active.get("threshold", 0))
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
			return int(_customers.so_don_hoan_hao)
		Registry.COND_ORDERS_DONE:
			return int(_customers.so_don_xong)
	return -1


## Gắn vào màn chơi: áp các kĩ năng BỊ ĐỘNG và bắt đầu theo dõi điều kiện.
##
## Gọi SAU khi quan_ly_khach và cooking đã tồn tại — cả hai đều là thứ node này
## vặn núm. level_base lo thứ tự đó.
##
## Vì sao áp bị động ở đây chứ không để mỗi hệ tự đi hỏi bảng kĩ năng: nếu mỗi
## hệ tự hỏi thì quan_ly_khach phải biết tới SkillRegistry, bep_nau cũng vậy, và
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
	_apply_passive(Registry.passive(id))

	# Điều kiện của Kita đếm ĐƠN, nên chỉ cần xem lại trạng thái mỗi khi một
	# đơn kết thúc — không phải kiểm tra mỗi frame hình. Với những điều kiện
	# đếm THỜI GIAN sau này (Oguri) thì sẽ cần thêm một nhịp kiểm tra riêng.
	if _customers != null and _customers.has_signal("don_ket_thuc"):
		_customers.don_ket_thuc.connect(_on_order_finished)
	_emit_state()


## Vặn núm của các hệ khác theo bộ số bị động.
##
## Dùng CỘNG/NHÂN vào giá trị đang có chứ không GÁN ĐÈ: luật màn (luat_man.gd)
## cũng đặt vài con số của quan_ly_khach, và gán đè thì thứ tự gọi quyết định
## ai thắng — một phụ thuộc ngầm sẽ hỏng lặng lẽ vào ngày ai đó đổi thứ tự
## dựng node trong level_base.
func _apply_passive(p: Dictionary) -> void:
	if _customers != null:
		_customers.he_so_kien_nhan = float(p["patience_factor"])
		_customers.thuong_hoan_hao += float(p["perfect_bonus_add"])
	if _cooking != null:
		_cooking.bot_giay_chay += float(p["burn_time_cut"])


func _on_order_finished(_order: Variant, _reason: String) -> void:
	_emit_state()


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
				_customers.ep_hoan_hao = true


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
## (bang_chon.gd) đang dùng _input để cướp phím trước, và trong lúc bảng đó
## mở thì bấm Space không được phép kích hoạt kĩ năng.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("skill"):
		return
	get_viewport().set_input_as_handled()
	activate()


func activate() -> void:
	if not can_use():
		return
	var id := str(GameData.selected_character)
	var cut_in := _make_cut_in()
	if cut_in == null:
		return
	# Thêm vào cây TRƯỚC khi gọi play(): VideoStreamPlayer chỉ phát được khi
	# đã nằm trong cây scene.
	get_tree().current_scene.add_child(cut_in)
	if not cut_in.play(id):
		# Không có file cut-in cho nhân vật này. KHÔNG trừ lượt — người chơi
		# không đáng bị mất lượt vì asset còn thiếu.
		cut_in.queue_free()
		return

	# Chỉ trừ lượt khi cheat TẮT, để cheat đúng nghĩa "không giới hạn".
	if not GameData.ki_nang_vo_han:
		_uses_left -= 1
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
	if _character != null and "khoa_di_chuyen" in _character:
		_character.khoa_di_chuyen = locked


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
	if usable:
		return "SPACE"
	# Hết lượt: phân biệt với "chưa đủ điều kiện", vì hai thứ đó đòi người chơi
	# làm hai việc khác nhau — một cái là cố thêm, một cái là thôi đừng chờ.
	# Cheat bật thì không bao giờ hết lượt nên không rơi vào nhánh này.
	if _uses_left <= 0 and not GameData.ki_nang_vo_han:
		return "Đã dùng"
	var text := progress_text()
	return text if not text.is_empty() else "..."


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
