extends Node
## Đôi tay của người chơi: cầm lên, đặt xuống, vứt ra.
##
## Vì sao là một node RIÊNG gắn vào nhân vật, không nhét vào tram_tuong_tac
## hay kitachibi_player:
##  - Trạm tương tác chỉ nên biết mình "là một mục tiêu bấm được". Nó không
##    được biết luật ai cầm được gì — nếu không thì mỗi lần thêm luật lại
##    phải sửa cả chục trạm.
##  - Nhân vật chỉ nên biết đi lại và diễn hoạt hình. Nhét luật cầm đồ vào
##    đó thì bốn nhân vật chơi được phải cùng mang theo một mớ code chẳng
##    liên quan gì tới việc điều khiển.

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Đang cầm gì — HUD nghe để hiện tên trên màn hình.
signal held_name_changed(item_name: String)

## Cùng khoảnh khắc với do_tren_tay_doi nhưng mang ID vật phẩm thay vì CHỮ
## hiển thị. Chuỗi rỗng = tay không.
##
## Vì sao cần tín hiệu thứ hai chứ không dùng lại cái trên: `ten` là chữ cho
## người đọc, và với cái nồi nó còn kèm số lượng ("Nồi (2): Cà rốt"). Bộ dẫn
## dắt màn hướng dẫn cần so khớp CHÍNH XÁC một id, mà so bằng chuỗi hiển thị
## thì đổi một chữ trong DanhMuc là màn hướng dẫn đứng im.
signal held_item_changed(id: String)

## Một câu báo ngắn cho HUD (ghép xong / ghép hụt). `tot` false = tin xấu.
signal notice(text: String, good: bool)
## Xin mở bảng chọn nguyên liệu cho một trạm. level_base nối tới bảng.
signal request_picker(station: Node)

## Hệ thống bếp, do level_base gán vào. Để rỗng thì bếp chỉ là đồ trang trí.
var cooking: Node = null

## Đặt xuống cách nhân vật bao xa.
@export var drop_distance := 1.1
## ============================ CHỈNH VỊ TRÍ VẬT CẦM TẠI ĐÂY ============
## Vật cầm nhô ra trước mặt bao xa, và cao bao nhiêu so với CHÂN nhân vật.
##
## Vì sao 1.05 lại ra ngang mặt: nhân vật là model CHIBI. Người tỉ lệ thật
## có đầu chiếm ~12% chiều cao, còn chibi chiếm gần 40% — nên "ngang ngực"
## tính theo tỉ lệ người thật lại rơi đúng vào mặt của chibi. Cao 0.72 trên
## thân chibi cao ~1.94 mới thật sự là ngang tay.
##
## Hai số này KHÔNG hiện trong Inspector vì node TayCam được level_base.gd
## tạo lúc chạy chứ không đặt sẵn trong scene — muốn chỉnh thì sửa thẳng ở
## đây rồi chạy lại.
@export var hold_distance := 0.70
@export var hold_height := 0.72

## Ảnh 2D lơ lửng trên đầu cao bao nhiêu.
##
## 2.35 để nó nằm HẲN trên đỉnh đầu chibi (~1.94) chứ không đè vào tóc.
@export var sign_height := 2.35
## Bề ngang ảnh 2D, tính bằng đơn vị thế giới.
@export var sign_width := 0.62
## Có hiện ảnh 2D trên đầu không.
##
## Model cầm trên tay đã nói được "đang cầm gì" rồi, nên tấm ảnh là thông tin
## THỨ HAI. Giữ nó vì ở góc top-down xa, model nhỏ như củ cà rốt rất khó
## phân biệt với củ khoai — nhưng để tắt được, phòng khi bày ra thấy rối.
@export var show_2d_sign := true
## Cạnh hộp va chạm của một vật phẩm nằm dưới đất.
##
## Nhỏ hơn hẳn hộp va chạm của nội thất, vì vật phẩm chỉ cần đủ to để bấm
## trúng chứ không được chặn đường — một củ cà rốt rơi giữa lối đi mà chắn
## như cái tủ thì bếp thành mê cung.
@export var item_scale := 0.45

var _body: CharacterBody3D = null
var _model: Node3D = null
## Ảnh 2D hiện thứ đang cầm, lơ lửng trên đầu nhân vật.
##
## Vì sao dùng ẢNH 2D thay vì model 3D cầm trên tay: ở góc nhìn top-down
## nghiêng, một model nhỏ nằm trong tay bị chính thân nhân vật che mất một
## phần và bị bàn bếp che nốt phần còn lại — người chơi phải đoán mình đang
## cầm gì. Một tấm ảnh luôn quay mặt về camera thì đọc được ở mọi góc, mọi
## khoảng cách, và dùng lại đúng bộ ảnh đã có trong bảng chọn nguyên liệu
## nên hai chỗ không bao giờ vẽ khác nhau.
var _sign: Sprite3D = null
## Điểm treo model vật phẩm trước ngực nhân vật.
var _hand_point: Node3D = null

## Vật đang cầm. Luôn là node THẬT trong thế giới chứ không phải bản sao —
## nhờ vậy đặt xuống là trả lại đúng vật đó, giữ nguyên mọi trạng thái nó
## đang mang (cái nồi đang chứa dở nguyên liệu chẳng hạn).
var _held: Workstation = null
## Node cha lúc chưa cầm, để đặt xuống thì trả về đúng chỗ cũ trong cây scene.
var _orig_parent: Node = null
## Nơi thả vật phẩm mới sinh ra. Lấy node gốc màn chơi.
var _world: Node = null


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	# Thân CharacterBody3D KHÔNG xoay — chỉ model bên trong xoay — nên phải
	# lấy hướng từ model khi cần biết nhân vật quay mặt về đâu.
	_model = _body.get_node_or_null("Model") as Node3D

	_hand_point = Node3D.new()
	_hand_point.name = "DiemTay"
	_body.add_child(_hand_point)

	_sign = Sprite3D.new()
	_sign.name = "BienDoTrenTay"
	_sign.position = Vector3(0.0, sign_height, 0.0)
	# BILLBOARD_ENABLED: tấm ảnh tự xoay theo camera mỗi frame.
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Không nhận bóng đổ và không bị đèn làm tối: đây là ký hiệu giao diện
	# chứ không phải vật thể trong thế giới, nên nó phải luôn rõ như nhau dù
	# nhân vật đang đứng trong góc tối hay dưới đèn.
	_sign.shaded = false
	# Vẽ đè lên mọi thứ: tủ lạnh hay tường không được phép che mất thông tin
	# "tôi đang cầm gì".
	_sign.no_depth_test = true
	_sign.render_priority = 10
	_sign.pixel_size = 0.002
	_sign.hide()
	_body.add_child(_sign)

	await get_tree().process_frame
	_world = _body.get_parent()
	# Nối vào MỌI trạm qua nhóm "tram" thay vì đi tìm từng node theo đường
	# dẫn. Thêm trạm mới vào map chỉ cần gắn đúng nhóm là tự chạy.
	for n in get_tree().get_nodes_in_group("tram"):
		_listen_station(n as Workstation)

	# ... VÀ nghe tiếp những trạm SINH RA SAU nhân vật.
	#
	# Vòng lặp trên chỉ quét đúng một lần, ngay lúc nhân vật vào màn. Mọi trạm
	# dựng sau thời điểm đó — Doro do level_base tạo bằng code sau khi nướng
	# xong navmesh, là ví dụ đã cắn một lần — lọt hết ra ngoài, và lỗi biểu
	# hiện ra dưới dạng "bấm E vào nó thì không có gì xảy ra", một triệu chứng
	# không chỉ về phía cái vòng lặp này chút nào.
	#
	# Nối vào node_added thì bất kì thứ gì vào cây sau này cũng được xét, nên
	# quy tắc trở lại đúng một câu: VÀO NHÓM "tram" LÀ CHẠY, không kèm thêm
	# điều kiện phải-có-mặt-trước-nhân-vật.
	get_tree().node_added.connect(_on_node_added)


## Bắt mọi node mới vào cây; chỉ quan tâm trạm.
##
## Node vừa vào cây thì nhóm đã được gán trong _ready() của chính nó (Godot
## phát node_added SAU _ready), nên kiểm nhóm ở đây là an toàn. Doro gán nhóm
## trong chuan_bi() — gọi sau add_child — nên bắt bằng kiểu thay vì bằng nhóm
## để không phụ thuộc vào thứ tự đó.
func _on_node_added(n: Node) -> void:
	var t := n as Workstation
	if t != null:
		_listen_station(t)


func _listen_station(t: Workstation) -> void:
	if t != null and not t.interacted.is_connected(_on_interact):
		t.interacted.connect(_on_interact)
	if t != null and not t.interacted_alt.is_connected(_on_interact_alt):
		t.interacted_alt.connect(_on_interact_alt)


## Kéo điểm cầm ra trước mặt mỗi frame.
##
## Không treo _diem_tay làm con của node Model dù Model mới là thứ xoay:
## Model đang được phóng to 1.6 lần, mà scale thì di truyền xuống node con —
## vật cầm sẽ to lên 1.6 lần theo. Tự tính vị trí từ góc quay của Model thì
## giữ được hướng mà không dính scale.
func _process(_delta: float) -> void:
	if _hand_point == null:
		return
	var origin := _model.rotation.y if _model != null else 0.0
	_hand_point.position = Vector3(0.0, hold_height, 0.0) \
		+ Vector3(sin(origin), 0.0, cos(origin)) * hold_distance
	_hand_point.rotation.y = origin


func _unhandled_input(event: InputEvent) -> void:
	# Q = vứt vật đang cầm xuống đất.
	#
	# Tách hẳn khỏi phím E: nếu dùng "E khi không có mục tiêu" thì E phụ
	# thuộc chỗ đứng — cạnh bàn là đặt lên bàn, lùi một bước là vứt xuống
	# đất. Cùng một phím cho hai kết quả tuỳ vị trí là thứ người chơi không
	# đoán trước được, mà trong bếp chật thì họ đứng cạnh thứ gì đó liên tục.
	if _held == null:
		return
	if event.is_action_pressed("bo_do"):
		_throw_out()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------ tương tác ---

func _on_interact(station: Node, _index: int) -> void:
	var t := station as Workstation
	if t == null:
		return

	# Trạm có bảng chọn riêng (tủ lạnh, máy kem): tay không quyết định gì cả,
	# chỉ mở bảng rồi chờ. Tách "chọn" khỏi "cầm" như vậy để sau này thêm
	# thời gian trễ khi mở tủ lạnh thì chỉ phải sửa ở bảng.
	if t.use_picker:
		if _held == null:
			request_picker.emit(t)
		return

	match t.kind:
		"vat_cam":
			# Vật thể đang bị khoá (hiện tại là cái nồi) thì bấm vào không ăn
			# thua gì cả. Chặn ngay từ lúc CẦM chứ không chặn lúc dùng: cầm
			# được rồi mới báo "không dùng được" thì người chơi đã đi nửa bếp.
			# Lý do khoá ghi ở đầu DanhMuc, chỗ hằng NOI_MO.
			if ItemCatalog.is_locked(t.item_id):
				return
			if _held == null:
				_pick_up(t)
		"ke_nguyen_lieu":
			if t.item_id.is_empty():
				return
			# (Đã bỏ 14/9/2026) Lối tắt "đang bê nồi thì nguyên liệu rơi
			# thẳng vào nồi, mang nhiều thứ trong một chuyến".
			#
			# Nồi giờ chỉ là một nguyên liệu, mà một nguyên liệu thì không
			# chứa nguyên liệu khác — đúng luật chung của cả game. Mất một
			# tiện lợi thật, nhưng chính tiện lợi đó bắt cái nồi phải có
			# RUỘT, và có ruột là gốc của mọi ngoại lệ còn lại.
			# Thùng nguyên liệu SINH RA một vật phẩm mới mỗi lần bấm — kho
			# nguyên liệu là vô hạn, đúng như đã chốt khi bỏ cơ chế rửa đĩa.
			if _held == null:
				_pick_up(_spawn_item(t.item_id))
		"thot":
			_use_single_station(t, "thot")
		"bep":
			_use_cooker(t)
		"lo_nuong":
			_use_oven(t)
		"chong_dia":
			# Đĩa lấy vô hạn, đúng luật đã chốt khi bỏ cơ chế rửa đĩa.
			if _held == null:
				_pick_up(_spawn_item("bowl"))
		"chong_noi":
			# Nồi cũng lấy vô hạn, cùng một luật với đĩa. Hai nhánh riêng chứ
			# không gộp thành một nhánh đọc `t.vat_pham`: hai trạm này KHÔNG
			# phải kệ nguyên liệu — chúng phát ra ĐỒ ĐỰNG, thứ duy nhất trong
			# game không bao giờ hết. Để hai nhánh cạnh nhau ở đây thì đọc
			# code là thấy ngay "có đúng hai thứ vô hạn".
			# Kiểm bi_khoa() vì công tắc NOI_MO tắt cả nhóm món nồi: không có
			# dòng này thì tắt công tắc xong chồng nồi vẫn phát nồi ra, và
			# người chơi cầm một thứ không nấu được thành gì.
			if _held == null and not ItemCatalog.is_locked("noi"):
				_pick_up(_spawn_item("noi"))
		"mang_bo_do":
			_discard(t)
		"ban_che_tao", "ban_de_tam":
			_put_on_table(t)
		"ban_khach":
			_deliver_dish(t)
		_:
			# Bếp, lò, thớt... do hệ thống nấu ăn lo. Ở đây KHÔNG phát tín
			# hiệu gì: trước đây chỗ này phát tên trạm ra HUD nên bấm E vào
			# cái bếp là hiện "Đang cầm: Bep 1" dù tay vẫn trống.
			pass


## Phím F: hiện chỉ có bàn chế tạo dùng — RÁP những thứ đang nằm trên bàn.
func _on_interact_alt(station: Node, _index: int) -> void:
	var t := station as Workstation
	if t == null:
		return
	if t.kind == "ban_che_tao":
		_assemble_table(t)


## Ráp món từ những thứ đang có trên bàn chế tạo.
##
## VÌ SAO TÁCH RA MỘT PHÍM RIÊNG, thay vì tự ráp ngay khi đủ như bản trước:
##
## Tự ráp sinh ra cả một LỚP lỗi — "công thức lồng nhau". Món nào có công thức
## chứa trọn công thức của món khác thì không bao giờ làm ra được, vì cái bàn
## đã ráp thành món nhỏ trước khi người chơi kịp bỏ nốt nguyên liệu. Bữa tối
## (đĩa + ham chín + canh) từng KHÔNG làm được bằng bất kỳ thứ tự nào, và cách
## chữa lúc đó là khai thêm "công thức nối tiếp" bằng tay cho từng cặp — một
## luật phải nhớ mỗi lần thêm món, mà quên thì món đó im lặng không làm được.
##
## Có nút ráp riêng thì cả lớp lỗi đó biến mất: bàn chỉ chứa, người chơi quyết
## định khi nào đủ. Đổi lại là một cú bấm thêm — nhưng cú bấm đó chính là chỗ
## đặt được PHẢN HỒI, thứ trước đây không có: bỏ thừa một nguyên liệu thì bảng
## im re và người chơi không biết mình sai ở đâu.
##
## Dùng F chứ không phải E vì E ở cái bàn này đã có việc rồi — ĐẶT đồ xuống.
func _assemble_table(table: Workstation) -> void:
	if table.contents.is_empty():
		notice.emit("Bàn đang trống", false)
		return

	var dish: String = ItemCatalog.combine_on_table(table.contents)
	if dish.is_empty():
		# Nói rõ đang có gì trên bàn: gần như mọi lần ghép hụt đều là thừa
		# hoặc thiếu đúng một thứ, mà người chơi thì không nhớ mình đã bỏ gì.
		var list_: Array[String] = []
		for x in table.contents:
			list_.append(ItemCatalog.display_name(String(x)))
		notice.emit("Không thành món: " + ", ".join(list_), false)
		AmThanh.play_sfx("craft_fail")
		return

	table.clear_all()
	table.add_item(dish)
	table.show_model(dish)
	notice.emit("Ghép xong: " + ItemCatalog.display_name(dish), true)
	AmThanh.play_sfx("craft_ok")


## Bảng chọn trả về một id vật phẩm. Sinh vật rồi cầm lên, cùng đường với
## thùng nguyên liệu — hai nguồn khác nhau nhưng kết quả phải giống hệt.
func receive_ingredient(_station: Node, id: String) -> void:
	if _held != null or id.is_empty():
		return
	_pick_up(_spawn_item(id))


# ---------------------------------------------------------- sinh vật phẩm ---

## Dựng một vật phẩm cầm được từ id trong danh mục.
##
## Dựng BẰNG CODE chứ không làm sẵn 30 file .tscn: mọi vật phẩm có cấu trúc
## y hệt nhau (thân tĩnh + mesh + hộp va chạm), chỉ khác mỗi file model. Ba
## chục scene giống nhau thì mỗi lần đổi kích thước hộp va chạm phải mở lại
## ba chục file.
func _spawn_item(id: String) -> Workstation:
	var item := Workstation.new()
	item.name = "VatPham_" + id
	item.display_name = ItemCatalog.display_name(id)
	item.kind = "vat_cam"
	item.item_id = id
	item.add_to_group("tram")
	# Vật phẩm nằm ở lớp riêng để không chặn đường nhân vật; xem giải thích
	# ở TramTuongTac.LOP_VAT_PHAM.
	item.collision_layer = Workstation.LAYER_ITEM
	# Không cần dò gì cả: vật phẩm là thứ bị nhìn thấy, không phải thứ nhìn.
	item.collision_mask = 0

	# Dựng model qua danh mục chứ KHÔNG tự gọi instantiate() ở đây.
	#
	# Đây từng là lỗi thật: hàm này tự nạp scene và bỏ qua khoá "ti_le", nên
	# pizza thu nhỏ trên mặt bàn (đường đi qua TramTuongTac.hien_mo_hinh)
	# nhưng vẫn to như cũ khi cầm trên tay. Cùng một vật phẩm được "mặc đồ"
	# ở hai nơi thì phải dùng chung MỘT hàm, nếu không hai nơi sẽ trôi khỏi
	# nhau đúng vào lúc thêm thuộc tính mới.
	var m: Node3D = ItemCatalog.make_model(id)
	if m != null:
		m.name = "Mesh"
		item.add_child(m)
	else:
		push_warning("Vật phẩm '%s' chưa có model." % id)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(item_scale, item_scale, item_scale)
	shape.shape = box
	shape.position = Vector3(0.0, item_scale * 0.5, 0.0)
	item.add_child(shape)

	# Điểm nhắm nhô lên trên một chút để bộ chọn đo hướng cho đúng khi vật
	# nằm sát chân người chơi.
	var mark := Marker3D.new()
	mark.name = "DiemNham"
	mark.position = Vector3(0.0, 0.25, 0.0)
	item.add_child(mark)

	_world.add_child(item)
	_listen_station(item)
	return item


# ------------------------------------------------------------ cầm / đặt ---

## Cầm một vật lên: treo model thật vào điểm trước ngực nhân vật.
##
## Node được GIỮ NGUYÊN chứ không xoá đi rồi sinh lại — đặt xuống là trả về
## đúng vật đó cùng mọi thứ nó đang chứa (cái nồi đang có dở ba nguyên liệu
## chẳng hạn).
##
## Phải TẮT VA CHẠM trước khi đổi cha: vật đang cầm mà còn va chạm thì nó đẩy
## chính nhân vật đang cầm nó, và nhân vật bị hất bay đi.
func _pick_up(t: Workstation) -> void:
	if t == null:
		return
	_held = t
	_orig_parent = t.get_parent()
	# Cao độ lệch ngẫu nhiên một chút: tiếng nhặt đồ phát mấy chục lần một màn,
	# phát y hệt nhau thì tai nghe ra ngay là máy móc.
	AmThanh.play_sfx("pick_up", randf_range(0.94, 1.06))

	_set_collision(t, false)
	if _orig_parent != null:
		_orig_parent.remove_child(t)
	_hand_point.add_child(t)
	t.transform = Transform3D.IDENTITY
	t.visible = true

	_body.carrying = true
	_draw_sign()


## Bật/tắt mọi hình va chạm con của một vật.
##
## Dùng set_deferred: đang trong lúc engine duyệt vật lý mà đổi thẳng thì
## Godot báo lỗi "Can't change this state while flushing queries".
func _set_collision(t: Node3D, on: bool) -> void:
	for c in t.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", not on)


## Bấm E vào bếp.
##
## Từ 14/9/2026 cái bếp KHÔNG còn luật riêng nào — nó là một trạm một-món y
## hệt cái thớt: bỏ vào, chờ, lấy ra.
##
## Chỗ này trước đây dài bốn chục dòng vì cái nồi: đặt nồi lên, chặn không cho
## đặt món lẻ khi đã có nồi, không cho nhấc nồi lúc đang sôi, múc canh ra mà
## để nồi ở lại, dọn model cái bát bày trên nắp nồi, rồi mới tới nhánh món lẻ.
## Nồi thành một vật phẩm nấu được thì cả bốn chục dòng đó là một dòng.
##
## Giữ lại hàm thay vì gọi thẳng `_dung_tram_mot_mon` trong `match`: bếp là
## trạm dễ có thêm luật nhất (nồi áp suất, hai ngăn...), và khi đó đây là chỗ
## để viết mà không phải tách lại hàm.
func _use_cooker(cooker: Workstation) -> void:
	_use_single_station(cooker, "don")


## Thớt và bếp-nấu-món-lẻ dùng chung một luật: bỏ vào, chờ, lấy ra.
##
## Viết chung một hàm vì hai trạm khác nhau đúng mỗi bảng tra (thái hay nấu)
## — đã truyền vào qua tham số `kieu`. Tách ra hai hàm thì hai bản sao gần
## giống hệt nhau, và sửa một bên quên bên kia là chuyện sớm muộn.
func _use_single_station(station: Workstation, mode: String) -> void:
	if cooking == null:
		return
	if _held != null:
		if cooking.put_item(station, _held.item_id, mode):
			_clear_held()
		return
	var id: String = cooking.take_out(station)
	if not id.is_empty():
		_pick_up(_spawn_item(id))


## Bấm E vào lò nướng.
##
## Ba tình huống, phân biệt bằng TRẠNG THÁI TAY và trạng thái lò — không
## tình huống nào phụ thuộc chỗ đứng, nên người chơi luôn đoán được:
##   - cầm đế bánh, lò rỗng      -> bỏ đế vào và bật lò
##   - cầm topping, lò đang chạy -> bỏ thêm vào
##   - tay không, lò có thành phẩm -> lấy ra
func _use_oven(oven: Workstation) -> void:
	if cooking == null:
		return

	if _held != null:
		var id: String = _held.item_id
		if id == ItemCatalog.PIZZA_BASE and oven.contents.is_empty():
			if cooking.start_oven(oven):
				_clear_held()
		elif cooking.is_burning(oven) and ItemCatalog.can_go_in_oven(id):
			if cooking.add_to_oven(oven, id):
				_clear_held()
		return

	# Lò đã xong: lấy thành phẩm ra. Còn đang chạy thì không lấy được — dở
	# dang mà bốc ra thì chẳng khác gì huỷ mẻ, mà huỷ mẻ đã có nút khác.
	if not cooking.is_burning(oven) and not oven.contents.is_empty():
		var id: String = String(oven.contents[0])
		oven.clear_all()
		_pick_up(_spawn_item(id))


## Bấm E vào máng bỏ đồ — thùng rác VÀ Doro.
##
## KHÔNG còn ngoại lệ nào. Trước đây cái nồi được miễn: bấm vào thùng rác chỉ
## đổ sạch ruột nồi chứ không xoá nồi, vì cả màn chỉ có MỘT cái — vứt nhầm là
## mất khả năng nấu canh tới hết màn, một hình phạt nặng hơn hẳn lỗi vừa gây
## ra.
##
## Nồi vô hạn thì hình phạt đó chỉ còn là một chuyến đi lấy cái khác, đúng
## bằng khi lỡ vứt một củ cà rốt. Bỏ ngoại lệ đi cũng có nghĩa Doro và thùng
## rác cư xử giống hệt nhau với MỌI thứ — không còn thứ nào "vứt được ở chỗ
## này mà không vứt được ở chỗ kia".
func _discard(_bin: Workstation) -> void:
	if _held == null:
		return
	AmThanh.play_sfx("trash")
	_clear_held()


## Bỏ hẳn thứ đang cầm khỏi thế giới.
func _clear_held() -> void:
	if _held == null:
		return
	var t := _held
	_held = null
	_orig_parent = null
	_body.carrying = false
	_draw_sign()
	t.queue_free()


func _throw_out() -> void:
	# Vứt ra phía trước mặt chứ không phải ngay dưới chân: dưới chân thì vật
	# nằm lọt trong hộp va chạm của nhân vật, và ngay frame sau nhân vật bị
	# nó đẩy văng ra.
	var dir := Vector3(sin(_model.rotation.y), 0.0, cos(_model.rotation.y)) \
		if _model != null else Vector3.FORWARD
	var dest := _body.global_position + dir * drop_distance
	dest.y = 0.0
	_place_at(_held, dest)


## Bàn chế tạo: bỏ nguyên liệu vào, và khi tay không thì lấy món ra.
##
## KHÔNG tự động biến thành món ngay khi đủ nguyên liệu. Người chơi phải bấm
## thêm một lần nữa để nhấc lên — nhờ vậy họ luôn nhìn thấy danh sách nguyên
## liệu mình vừa ghép trước khi nó biến mất, và cái ghi chú trên màn hình mới
## có tác dụng dạy công thức.
## Bàn chế tạo: bỏ nguyên liệu vào, tự ráp khi đủ, tay không thì nhấc món ra.
##
## Chỉ CÁI ĐĨA được bày model lên mặt bàn, các nguyên liệu khác thì không.
## Lý do: bày hết thì bốn năm model chồng lên nhau ở cùng một chỗ, nhìn thành
## một đống không đọc được. Cái đĩa là vật chứa — nó ở dưới cùng và nằm yên
## suốt quá trình, nên nó là thứ duy nhất đáng bày. Danh sách nguyên liệu đã
## có bảng bên cạnh bàn lo.
func _put_on_table(table: Workstation) -> void:
	if _held == null:
		_take_dish_from_table(table)
		return

	var id: String = _held.item_id
	if id.is_empty():
		id = _held.display_name
	# (Đã bỏ 14/9/2026) "Bàn từ chối cái nồi".
	#
	# Nhánh này từng chặn cái nồi: `them_vao()` ghi id vào mặt bàn rồi
	# `_xoa_do_tren_tay()` gọi queue_free() trên node đang cầm — với vật thể
	# độc nhất của cả màn thì đó là xoá vĩnh viễn. Nồi vô hạn thì bị nuốt
	# không còn là mất mát, và ĐẶT NỒI LÊN BÀN chính là bước đầu của công
	# thức nấu canh mới — nên nhánh chặn phải đi.
	# Lưới an toàn cho đồ đang bị khoá bởi công tắc NOI_MO.
	if ItemCatalog.is_locked(id):
		return
	table.add_item(id)
	_clear_held()
	AmThanh.play_sfx("put_down", randf_range(0.94, 1.06))

	# KHÔNG tự ráp nữa — người chơi bấm F để ráp. Xem lý do đầy đủ ở _rap_ban().
	# Ở đây cái bàn chỉ làm đúng một việc: giữ đồ.
	#
	# (Đã bỏ 17/9/2026) `hien_mo_hinh("bowl" if ban.chua.has("bowl") else "")`.
	# Luật cũ chỉ bày mỗi cái đĩa, nên bỏ năm nguyên liệu lên bàn vẫn thấy một
	# cái đĩa rỗng y như lúc mới đặt — mặt bàn không nói được gì về thứ người
	# chơi vừa làm. Giờ bày cả chồng, mỗi món một tầng; xem DanhMuc.make_stack().
	table.show_stack(table.contents)


## Giao món cho một bàn khách.
##
## Chỉ nhận thứ BÁN ĐƯỢC, tức có giá trong danh mục.
##
## Trước đây kiểm bằng DanhMuc.is_dish(), và điều kiện đó SAI theo cả hai chiều:
##  - Ba loại kem lẻ lấy thẳng từ máy, không qua bàn chế tạo, nên không nằm ở
##    vế phải của CONG_THUC_BAN → la_mon() trả false → không giao ra bàn được,
##    dù chúng có giá 15 và đã chốt là bán thẳng không cần đĩa.
##  - Ngược lại, chả rau củ SỐNG là vế phải của một công thức bàn chế tạo (để
##    nhấc lên được) nên la_mon() trả true → giao được cả đồ chưa nấu.
##
## Hỏi giá là hỏi đúng câu cần hỏi: "khách trả tiền cho thứ này không".
##
## Bàn đã có món rồi thì không nhận thêm — một bàn phục vụ một đơn tại một
## thời điểm. Không có luật này thì người chơi chất chồng món lên cùng một
## bàn và hệ đơn hàng sau này không biết món nào ứng với đơn nào.
func _deliver_dish(table: Workstation) -> void:
	# Tay không: nhấc món đã đặt nhầm ra. Cần thiết vì đặt nhầm bàn là lỗi
	# rất dễ mắc lúc đang vội, mà không lấy lại được thì mất luôn cả món lẫn
	# thời gian đã bỏ ra làm nó.
	if _held == null:
		if table.contents.is_empty():
			return
		var taken: String = table.pop_last()
		table.clear_model()
		_pick_up(_spawn_item(taken))
		return

	var id: String = _held.item_id
	if ItemCatalog.price(id) <= 0:
		return
	if not table.contents.is_empty():
		return

	table.add_item(id)
	table.show_model(id)
	_clear_held()

	# CHỖ CẮM: hệ đơn hàng sau này nghe tín hiệu này để đối chiếu món vừa
	# giao với đơn của bàn, tính tiền và tính "hoàn hảo".
	AmThanh.play_sfx("serve")
	if table.has_signal("dish_delivered"):
		table.emit_signal("dish_delivered", table, id)


## Tay không, bấm E ở bàn: nhấc món đã ráp, hoặc LẤY LẠI nguyên liệu vừa bỏ.
##
## Phần "lấy lại" là bắt buộc, không phải tiện ích.
##
## Bản trước chỉ cho nhấc món đã hoàn chỉnh, với lý do "đừng để người chơi
## bấm nhầm mất cái đĩa". Nhưng như vậy là bỏ nhầm MỘT nguyên liệu sai thì
## công thức không bao giờ khớp được nữa, mà cũng không có cách nào dọn bàn
## — cái bàn kẹt vĩnh viễn cho tới hết màn. Một lỗi nhỏ dẫn tới hậu quả
## không sửa được là thứ tệ hơn nhiều so với việc thỉnh thoảng bấm nhầm.
##
## Lấy theo thứ tự NGƯỢC (thứ bỏ sau cùng ra trước): đó là thứ tự người chơi
## nhớ được, và cũng là cách mọi thao tác hoàn tác hoạt động.
func _take_dish_from_table(table: Workstation) -> void:
	if table.contents.is_empty():
		return

	var id: String = table.pop_last()

	# Bày lại mặt bàn. Không còn phải phân biệt "món hoàn chỉnh" với "đang ghép
	# dở": tao_chong() thấy đúng một thứ thì dựng nó y như tao_mo_hinh(), nên
	# cả hai trường hợp đi chung một dòng.
	table.show_stack(table.contents)

	_pick_up(_spawn_item(id))


func _place_at(t: Workstation, dest: Vector3) -> void:
	var parent: Node = _orig_parent if _orig_parent != null else _world
	if t.get_parent() != null:
		t.get_parent().remove_child(t)
	parent.add_child(t)
	t.global_position = dest
	t.visible = true
	_set_collision(t, true)
	_release()


func _release() -> void:
	_held = null
	_orig_parent = null
	_body.carrying = false
	_draw_sign()


## Vẽ lại tấm ảnh trên đầu theo thứ đang cầm.
##
## Nồi có nguyên liệu bên trong thì hiện ảnh NGUYÊN LIỆU MỚI NHẤT chứ không
## phải ảnh cái nồi: người chơi cần biết vừa bỏ trúng thứ gì vào, còn việc
## mình đang bê nồi thì đã nhìn thấy rồi.
func _draw_sign() -> void:
	if _sign == null:
		return
	if _held == null:
		_sign.hide()
		held_name_changed.emit("")
		held_item_changed.emit("")
		return

	var id: String = _held.item_id
	var label := _held.display_name
	if not _held.contents.is_empty():
		id = String(_held.contents[_held.contents.size() - 1])
		label = "%s (%d): %s" % [_held.display_name,
			_held.contents.size(), ItemCatalog.display_name(id)]

	var path: String = ItemCatalog.icon_path(id)
	if show_2d_sign and ResourceLoader.exists(path):
		_sign.texture = load(path)
		# Quy về đúng bề ngang mong muốn dù ảnh gốc to nhỏ khác nhau.
		var w := float(_sign.texture.get_width())
		_sign.pixel_size = sign_width / maxf(w, 1.0)
		_sign.show()
	else:
		_sign.hide()
	held_name_changed.emit(label)
	held_item_changed.emit(id)
