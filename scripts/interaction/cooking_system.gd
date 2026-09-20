extends Node
## Hệ thống nấu: bếp (qua cái nồi) và lò nướng (trực tiếp).
##
## Vì sao là một node QUẢN LÝ riêng chứ không gắn script vào từng cái bếp:
## Luật nấu là luật CHUNG — hai cái bếp phải cư xử giống hệt nhau, và sau
## này lò nướng cũng dùng lại phần lớn luật đó. Gắn vào từng bếp thì mỗi lần
## sửa luật phải nhớ sửa đủ mọi cái bếp trong mọi map; quên một cái là có một
## cái bếp cư xử khác các cái còn lại, mà lỗi đó rất khó phát hiện.
##
## ------------------------------------------------------------- LUẬT NẤU
##
##  1. Bỏ MỘT món nấu được lên trạm (bếp hoặc thớt): đồng hồ chạy ngay.
##  2. Thanh đầy: món đổi thành thành phẩm và nằm lại trên trạm.
##  3. Món nấu trên bếp để quá lâu (he_so_chay lần thời gian nấu) thì cháy.
##  4. Lò nướng là trạm NHIỀU nguyên liệu: bỏ đế bánh để bật, bỏ thêm topping
##     trong lúc đang chạy, thanh đầy mà tổ hợp không khớp công thức nào thì
##     cả mẻ thành đồ hỏng.
##
## ------------------------------------------- BỎ KIỂU NẤU "NỒI" — 14/9/2026
##
## Trước đây có kiểu nấu thứ tư: đặt cái nồi lên bếp, bếp MƯỢN kho của nồi,
## người chơi đổ nguyên liệu vào nồi trong lúc bếp đang chạy, nấu xong múc
## canh ra và nồi ở lại. Kèm theo nó là bốn hàm riêng (dat_noi, nhac_noi,
## noi_tren_bep, noi_dat_tren), một nhánh riêng trong _process để phát hiện
## nồi bị nhấc giữa chừng, và một nhánh riêng trong _ket_thuc.
##
## Cái nồi giờ là một VẬT PHẨM nấu được như mọi vật phẩm khác: "nồi canh sống"
## khai `"nau": "stew"` trong danh mục, và đi đúng đường của ham sống hay
## steak sống. Toàn bộ mã riêng cho nồi biến mất — file này ngắn đi khoảng
## sáu chục dòng mà không mất chức năng nào.
##
## Đổi lại: không còn "bỏ thêm nguyên liệu vào nồi đang sôi". Chỗ quyết định
## đó chuyển sang bàn chế tạo (ráp đủ năm thứ trước khi lên bếp).

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")

## Nấu xong một mẻ. `thanh_cong` false nghĩa là ra đồ hỏng.
signal cook_finished(cooker: Node, dish: String, success: bool)
## Tiến trình NẤU đổi. 0..1, đầy dần. Phát 0 nghĩa là "hết việc" — thanh ẩn.
signal progress_changed(cooker: Node, ratio: float)

## Món đã CHÍN và đang nằm chờ trên bếp, đếm tới lúc cháy. 1..0, VƠI dần.
##
## Vì sao một tín hiệu RIÊNG chứ không nhồi tiếp vào tien_trinh_doi: hai giai
## đoạn là hai loại đồng hồ ngược nhau — một cái đếm tới phần thưởng, một cái
## đếm tới hình phạt — và bên nghe phải vẽ chúng khác nhau (đổi màu, đổi
## chiều). Nhồi chung thì bên nghe phải tự đoán "0,7 này là đang nấu hay đang
## sắp cháy", mà nó không có cách nào đoán đúng.
##
## Chỉ phát cho món CÓ khoá `hong` trong danh mục (hiện là ham và steak) —
## những món khác nấu xong là gỡ khỏi bảng đang-nấu luôn.
signal burn_warning(cooker: Node, con_lai: float)

## Nấu một mẻ trên bếp mất bao nhiêu giây.
##
## 8 giây là con số đủ để người chơi chạy được một chuyến lấy nguyên liệu
## (đã đo: một chuyến khứ hồi trong bếp ~4,6 s) nhưng không đủ cho hai
## chuyến — nên phải chọn: bỏ đủ trước rồi bật, hay bật sớm và chạy đua.
@export var cook_seconds := 8.0

## Nướng một cái pizza mất bao nhiêu giây.
##
## Dài hơn bếp vì pizza cần tới ba bốn thứ, tức hai chuyến. Đây cũng là cách
## hai trạm có nhịp khác nhau thay vì là hai bản sao của cùng một thao tác.
@export var bake_seconds := 11.0

## Thái ở thớt mất bao nhiêu giây.
##
## Ngắn hơn hẳn nấu, vì thái là thao tác BẮT BUỘC và không có quyết định nào
## bên trong: đứng đó chờ lâu chỉ là thời gian chết. Cái đáng để người chơi
## cân nhắc là bếp và lò, nơi họ chọn giữa chờ và chạy.
@export var chop_seconds := 2.5

## Để trên bếp quá bao nhiêu LẦN thời gian nấu thì cháy.
##
## 2.0 nghĩa là người chơi có thêm đúng một khoảng bằng thời gian nấu nữa để
## quay lại lấy. Đủ rộng để không phạt oan khi đang bận chỗ khác, nhưng vẫn
## đủ hẹp để "cứ để đấy rồi tính" là một canh bạc thật.
@export var burn_factor := 2.0

## BỚT bấy nhiêu giây vào mốc cháy. 0 = số gốc của game.
##
## Núm này do hệ kĩ năng vặn — Kita, "Dòng tiền mờ ám": 2,0 giây, đổi lấy
## tiền thưởng đơn hoàn hảo cao hơn. Chọn nhân vật khác thì nó là 0 và mốc
## cháy đúng bằng he_so_chay lần thời gian nấu.
##
## File này không biết kĩ năng là gì, chỉ có một biến số — xem giải thích
## đầy đủ ở quan_ly_ki_nang.gd.
@export var burn_time_cut := 0.0

## trạm -> { "kho": TramTuongTac, "t": float, "kieu": String }
##
## "kho" là nơi giữ nguyên liệu. Từ khi bỏ kiểu nấu "nồi" thì kho LUÔN chính
## là cái trạm — nhưng khoá này được giữ lại chứ không rút gọn, vì nó là chỗ
## duy nhất phải sửa nếu sau này có thêm một trạm mượn kho của vật khác.
##
## "kieu" quyết định tra bảng nào lúc kết thúc:
##   "lo"   — nướng pizza        -> CONG_THUC_LO
##   "don"  — nấu một món lẻ     -> DanhMuc.cook_step()
##   "thot" — thái một món lẻ    -> DanhMuc.prep_step()
var _running: Dictionary = {}


func _process(delta: float) -> void:
	for station in _running.keys():
		var m: Dictionary = _running[station]
		var store: Workstation = m["store"]
		var mode: String = m["mode"]

		# Kho bị xoá khỏi cây scene giữa chừng thì huỷ mẻ.
		if not is_instance_valid(store):
			_cancel(station)
			continue
		if store.contents.is_empty():
			continue

		var limit: float = _duration_for(mode)
		m["elapsed"] += delta

		# Hai giai đoạn, hai tín hiệu. Phân nhánh TRƯỚC khi xét mốc thời gian:
		# cờ "xong" đã nói rõ đang ở giai đoạn nào, không cần suy từ con số.
		if not bool(m.get("done", false)):
			progress_changed.emit(station, clampf(m["elapsed"] / limit, 0.0, 1.0))
		else:
			var burn_limit: float = _burn_mark(limit)
			# maxf(0.001, …) chặn chia cho 0 khi bot_giay_chay bị đặt lớn tới
			# mức mốc cháy trùng luôn với lúc chín.
			var span: float = maxf(0.001, burn_limit - limit)
			burn_warning.emit(station, clampf((burn_limit - m["elapsed"]) / span, 0.0, 1.0))

		if m["elapsed"] < limit:
			continue
		if not bool(m.get("done", false)):
			m["done"] = true
			_finish(station, store, mode)
			# Món lẻ nấu xong vẫn nằm trên bếp và VẪN ĐẾM TIẾP, để quá lâu
			# thì cháy. Các kiểu khác dừng hẳn ở đây.
			if mode != "don" or ItemCatalog.burnt_state(String(m["source_id"])).is_empty():
				_running.erase(station)
				# Phát 0 Ở ĐÂY chứ không ở _ket_thuc: chỉ khi mẻ thật sự kết
				# thúc mới được ẩn thanh. Phát trong _ket_thuc thì món còn
				# chờ cháy cũng bị ẩn mất một khung hình rồi hiện lại.
				progress_changed.emit(station, 0.0)
		# maxf(han, ...) là chốt chặn: đặt bot_giay_chay lớn hơn quãng ân hạn
		# thì mốc cháy sẽ tụt xuống DƯỚI thời gian nấu, tức món cháy trước cả
		# khi chín — một trạng thái không có đường thoát.
		elif m["elapsed"] >= _burn_mark(limit):
			_burn(station, store, String(m["source_id"]))


## Mốc CHÁY, tính bằng giây kể từ lúc bỏ món lên.
##
## Gom vào một hàm vì ba nơi cần đúng con số này: chỗ vẽ thanh đỏ, chỗ quyết
## định cháy, và phép chia tính tỉ lệ còn lại. Ba bản sao của cùng một công
## thức thì sửa he_so_chay mà quên một chỗ là thanh chạy hết trước khi món
## cháy — sai kiểu không báo lỗi.
##
## maxf(han, …) là chốt chặn: đặt bot_giay_chay lớn hơn quãng ân hạn thì mốc
## cháy sẽ tụt xuống DƯỚI thời gian nấu, tức món cháy trước cả khi chín — một
## trạng thái không có đường thoát.
func _burn_mark(limit: float) -> float:
	return maxf(limit, limit * burn_factor - burn_time_cut)


func _duration_for(mode: String) -> float:
	match mode:
		"lo": return bake_seconds
		"thot": return chop_seconds
		_: return cook_seconds


# --------------------------------------------------------------- lò nướng ---

## Bỏ đế bánh vào lò và bật lò.
func start_oven(oven: Workstation) -> bool:
	if oven == null or _running.has(oven) or not oven.contents.is_empty():
		return false
	oven.add_item(ItemCatalog.PIZZA_BASE)
	_running[oven] = {"store": oven, "elapsed": 0.0, "mode": "lo", "source_id": ""}
	progress_changed.emit(oven, 0.0)
	return true


## Thêm topping vào lò đang chạy.
func add_to_oven(oven: Workstation, id: String) -> bool:
	if not _running.has(oven) or not ItemCatalog.can_go_in_oven(id):
		return false
	oven.add_item(id)
	return true


func is_burning(station: Workstation) -> bool:
	return _running.has(station) and not bool(_running[station].get("done", false))


# ------------------------------------------------- thao tác trên một món ---

## Đặt một món lẻ lên trạm để thái (thớt) hoặc nấu (bếp).
##
## Món nằm trong `chua` của chính trạm chứ không sinh node 3D đặt lên mặt
## bàn: ở góc top-down, một củ cà rốt nhỏ nằm trên cái thớt bị chính cái thớt
## che gần hết. Người chơi đọc trạng thái qua thanh tiến trình và ghi chú,
## không qua việc soi mặt bàn.
func put_item(station: Workstation, id: String, mode: String) -> bool:
	if station == null or _running.has(station) or not station.contents.is_empty():
		return false
	var out: String = ItemCatalog.prep_step(id) if mode == "thot" else ItemCatalog.cook_step(id)
	if out.is_empty():
		return false
	station.add_item(id)
	station.show_model(id)
	_running[station] = {"store": station, "elapsed": 0.0, "mode": mode, "source_id": id}
	progress_changed.emit(station, 0.0)
	return true


## Lấy thành phẩm khỏi trạm. Trả về id, hoặc "" nếu chưa có gì để lấy.
func take_out(station: Workstation) -> String:
	if station == null or station.contents.is_empty() or is_burning(station):
		return ""
	var id: String = String(station.contents[0])
	station.clear_all()
	station.clear_model()
	_running.erase(station)
	progress_changed.emit(station, 0.0)
	return id


func _cancel(cooker: Node) -> void:
	_running.erase(cooker)
	progress_changed.emit(cooker, 0.0)


## Chỗ DUY NHẤT bốn kiểu rẽ nhánh: tra bảng nào.
func _finish(station: Node, store: Workstation, mode: String) -> void:
	var dish: String = ""
	match mode:
		"lo": dish = ItemCatalog.bake_in_oven(store.contents)
		"thot": dish = ItemCatalog.prep_step(String(store.contents[0]))
		_: dish = ItemCatalog.cook_step(String(store.contents[0]))

	var success := not dish.is_empty()
	store.clear_all()
	var out: String = dish if success else "do_hong"
	store.add_item(out)
	# Đổi model trên mặt trạm sang thành phẩm: người chơi thấy ngay miếng
	# thịt đã đổi màu, không phải đọc chữ mới biết xong.
	store.show_model(out)
	AmThanh.play_sfx("cook_done" if success else "cook_fail")
	cook_finished.emit(station, dish, success)


## Để trên bếp quá lâu.
func _burn(station: Node, store: Workstation, source_id: String) -> void:
	var burnt: String = ItemCatalog.burnt_state(source_id)
	if burnt.is_empty():
		burnt = "do_hong"
	store.clear_all()
	store.add_item(burnt)
	store.show_model(burnt)
	_running.erase(station)
	AmThanh.play_sfx("burn")
	progress_changed.emit(station, 0.0)
	cook_finished.emit(station, "", false)
