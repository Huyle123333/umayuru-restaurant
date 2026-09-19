extends Node
## Bộ dẫn dắt màn hướng dẫn: chạy kịch bản, theo dõi người chơi, sang bước.
##
## Chia ba phần rạch ròi, và đây là điểm đáng nói nhất của cả hệ:
##   cutscene_tutorial.gd  — DẠY CÁI GÌ (dữ liệu, đọc như tờ giấy)
##   bang_huong_dan.gd     — VẼ RA SAO (chỉ hiện chữ, không biết luật)
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
const GuidePanel := preload("res://scripts/giao_dien/bang_huong_dan.gd")

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


## Gắn vào màn chơi. Truyền thẳng các node cần nghe thay vì tự đi tìm trong
## cây scene: tìm bằng đường dẫn thì đổi tên một node là hỏng lặng lẽ, mà lỗi
## kiểu đó chỉ lộ ra khi chơi tới đúng bước dùng nó.
func setup(nguoi_choi: Node3D, tay: Node, he_bep: Node,
		quan_ly_khach: Node, bang_gio: Node) -> void:
	_player = nguoi_choi
	_hands = tay
	_cooking = he_bep
	_customers = quan_ly_khach
	_clock = bang_gio

	_panel = GuidePanel.new()
	_panel.name = "GuidePanel"
	add_child(_panel)
	_panel.chon_bat_dau.connect(_on_select)

	_apply_tutorial_rules()
	_connect_signals()

	if _player != null:
		_last_position = _player.global_position

	# `mo()` la ten ham cua bang_huong_dan.gd (lo 4, chua doi ten).
	_panel.mo()
	_go_to_step(0)


## Luật riêng của màn hướng dẫn. Tất cả đều là ô @export có sẵn, không có cờ
## "dang_tutorial" nào rải trong code hệ thống — hệ khách và panel thời gian
## không cần biết màn hướng dẫn tồn tại.
func _apply_tutorial_rules() -> void:
	if _customers != null:
		_customers.tru_kien_nhan = false   # thanh kiên nhẫn hiện nhưng không cạn
		_customers.tu_sinh = false         # khách vào đúng lúc kịch bản gọi
		_customers.ep_ban = 1              # bàn gần bếp nhất
		_customers.ep_mon = "mon_steak"    # đúng món đang dạy
	if _clock != null:
		_clock.dem_nguoc = false


## Trả màn chơi về luật bình thường. Dùng cho CẢ HAI lối ra: học xong, và bấm
## "Bỏ qua". Một hàm cho hai lối thì không có lối nào bị quên.
func _restore_normal() -> void:
	if _customers != null:
		_customers.tru_kien_nhan = true
		_customers.tu_sinh = true
		_customers.ep_ban = 0
		_customers.ep_mon = ""
	if _clock != null:
		_clock.dem_nguoc = true

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
	if _hands != null and _hands.has_signal("vat_tren_tay_doi"):
		_hands.vat_tren_tay_doi.connect(_on_hands_changed)
	if _cooking != null and _cooking.has_signal("nau_xong"):
		_cooking.nau_xong.connect(_on_cook_finished)
	if _customers != null and _customers.has_signal("don_ket_thuc"):
		_customers.don_ket_thuc.connect(_on_order_finished)

	# Bàn chế tạo: nghe nội dung đổi để biết người chơi đã đặt được thứ cần đặt.
	# Duyệt nhóm "tram" chứ không đi theo đường dẫn node, vì bàn chế tạo có thể
	# được kê lại chỗ khác trong map bất cứ lúc nào.
	for n in get_tree().get_nodes_in_group("tram"):
		if String(n.loai) == "ban_che_tao" and n.has_signal("noi_dung_thay_doi"):
			n.noi_dung_thay_doi.connect(_on_table_changed)


func _on_hands_changed(id: String) -> void:
	if _wait_for.begins_with(WAIT_HOLD) and id == _wait_for.substr(WAIT_HOLD.length()):
		_finish_step()


func _on_cook_finished(tram: Node, _mon: String, thanh_cong: bool) -> void:
	if not thanh_cong:
		return
	# `loai` van la ten thuoc tinh cua TramTuongTac — lop do thuoc lo 6, chua doi.
	# Doc bang ten CU o day la dung; bien cuc bo thi da la tieng Anh.
	var kind := String(tram.loai)
	if _wait_for == "chop" and kind == "thot":
		_finish_step()
	elif _wait_for == "cook" and kind == "bep":
		_finish_step()


func _on_table_changed(ban: Node) -> void:
	if not _wait_for.begins_with(WAIT_TABLE_HAS):
		return
	if ban.chua.has(_wait_for.substr(WAIT_TABLE_HAS.length())):
		_finish_step()


func _on_order_finished(_don: RefCounted, ly_do: String) -> void:
	if _wait_for == "serve" and ly_do == "xong":
		_finish_step()


## Trả lời câu hỏi mở màn: "Chỉ đi" thì vào bài học, "Bỏ qua" thì tổng kết ngay.
##
## Bỏ qua vẫn đi qua `_restore_normal()` — hàm đó là nơi gọi
## `GameData.complete_level("tutorial")`, mà Ngày 1 khai `needs: "tutorial"`.
## Bỏ qua hướng dẫn không có nghĩa là bị khoá Ngày 1.
func _on_select(dong_y: bool) -> void:
	if dong_y:
		_go_to_step(1)
		return
	_learned_all = true
	_wait_for = ""
	_panel.dong()
	_restore_normal()


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
	if i >= Cutscene.STEPS.size():
		_wait_for = ""
		_learned_all = true
		_panel.dong()
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

	if _wait_for == "ask":
		_panel.hoi(String(step.get("line", "")), Cutscene.BTN_YES, Cutscene.BTN_NO)
	else:
		# Đánh số bỏ qua bước hỏi: người chơi đếm "bước 1" từ bài học đầu tiên,
		# còn câu hỏi mở màn thì không phải một bài học.
		_panel.dat_buoc(String(step.get("line", "")), i, Cutscene.STEPS.size() - 1)

	_do_action(String(step.get("action", "")))


func _do_action(action: String) -> void:
	if action == "spawn_customer" and _customers != null:
		_customers.them_khach()


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
