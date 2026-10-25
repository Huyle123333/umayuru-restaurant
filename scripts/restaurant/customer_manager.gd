extends Node
## Luật nhà hàng: ai vào, đứng đâu trong hàng, ngồi bàn nào, khi nào về.
##
## Node này do level_base tạo lúc chạy, cùng lý do với bộ chọn mục tiêu và hệ
## bếp: bảy nhân vật người chơi thì nhét vào scene nhân vật là bảy chỗ phải sửa.
##
## Máy trạng thái của MỘT người khách nằm ở đây chứ không nằm trong customer.gd.
## customer.gd chỉ biết "đi tới đó rồi hét lên một tiếng"; còn thứ tự vào hàng →
## nhích lên → ra bàn → ăn → về là LUẬT, mà luật thì đổi liên tục. Gom hết luật
## về một chỗ thì đọc một file là hiểu cả vòng đời người khách.

signal customer_seated(customer: Node, table: Node)
signal customer_ate(customer: Node, table: Node, dish_id: String)
signal customer_left(customer: Node)

## Một đơn vừa sinh ra (khách đã ngồi vào bàn và gọi món).
signal order_created(order_: Order)
## Một đơn kết thúc. ly_do: "xong" (giao đúng) hoặc "bo_di" (hết kiên nhẫn).
signal order_finished(order_: Order, reason: String)
## Ví thay đổi. `cho` là chỗ vừa xảy ra việc, để bắn hiệu ứng tiền bay lên.
signal money_changed(total: int, added: int, spot: Vector3)

const CUSTOMER_SCENE := preload("res://scenes/restaurant/customer.tscn")
const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const Order := preload("res://scripts/restaurant/order.gd")
const COIN_ICON := "res://assets/ui/tien/carrot_tien.png"

## Thời gian ăn, giây. Màn thật sẽ tỉ lệ với độ khó; tutorial để cố định.
@export var eat_seconds: float = 5.0
## Ép mọi khách ngồi đúng bàn này (dùng cho tutorial). 0 = chọn ngẫu nhiên.
@export var force_table: int = 0

## Ép mọi khách gọi đúng món này (dùng cho tutorial). Rỗng = bốc ngẫu nhiên.
##
## Màn hướng dẫn dạy làm món Steak, nên người khách trong đó phải gọi đúng món
## Steak — để ngẫu nhiên thì có lúc bài giảng nói một đằng còn bong bóng trên
## đầu khách hiện một nẻo, và người chơi tin cái bong bóng.
@export var force_dish: String = ""
## Số khách tối đa có mặt cùng lúc, kể cả đang xếp hàng.
@export var max_customers: int = 6

## Số khách tối đa ĐANG NGỒI BÀN cùng lúc. 0 = không giới hạn (dùng hết bàn).
##
## Vì sao cần một trần RIÊNG bên cạnh `max_customers`: `max_customers` đếm tổng số người có
## mặt, nên với sáu bàn trống thì cả sáu người đều được xếp chỗ ngay và người
## chơi phải phục vụ sáu đơn song song. Ngày 1 mà như thế là quá tải ngay từ
## phút đầu — người chơi mới chưa thuộc đường đi trong bếp, sáu đơn cùng lúc
## nghĩa là sáu thanh kiên nhẫn cùng cạn và họ mất hết mà không hiểu vì sao.
##
## Chặn ở SỐ CHỖ NGỒI chứ không tắt bớt bàn: cả sáu bàn vẫn dùng được, khách
## vẫn rải khắp phòng, chỉ là không bao giờ quá ba người ngồi cùng lúc. Tắt
## bớt bàn thì quán trông vắng và nửa gian phòng thành đồ trang trí.
@export var max_tables: int = 0

## Số ô hàng đợi được dùng. 0 = dùng hết số Marker HangDoi có trong map.
##
## Tách khỏi `max_tables` vì hai con số điều khiển hai áp lực khác nhau: trần
## bàn quyết định "phải nấu mấy món cùng lúc", trần hàng đợi quyết định "có
## bao nhiêu người đang giận dần ở cửa". Ngày 1 hạ cả hai xuống 3.
@export var max_queue: int = 0

## Thực đơn RIÊNG của màn: chỉ những món trong đây mới được khách gọi.
##
## RỖNG = cả danh mục (mọi món có giá). Mặc định để rỗng chứ không liệt kê sẵn
## mười lăm món: một danh sách chép lại danh mục là một bản sao sẽ lệch khỏi
## bản gốc ngay lần đầu ai đó thêm món mới.
##
## Vì sao mỗi màn một thực đơn: Ngày 1 là màn THẬT đầu tiên, ngay sau bài học
## dạy đúng một món. Mở cả mười lăm món ở đó thì người chơi vừa học xong một
## chuỗi bốn bước đã phải nấu Bữa tối năm bước, và họ thua vì chưa kịp biết
## công thức chứ không phải vì chậm tay. Mở dần thực đơn theo ngày biến cái
## danh mục món ăn thành đường cong học tập, thay vì một bức tường.
@export var menu: Array[String] = []

## Trọng số bốc món: id -> số. Món không có tên trong đây tính là 1.
##
## Vì sao cần trọng số chứ không bốc đều: giá món trong thực đơn Ngày 1 trải
## từ 15 (kem) tới 95 (hamburger). Bốc đều thì ba loại kem chiếm đúng một nửa
## số đơn, doanh thu trần tụt gần một nửa, và điểm cuối màn phụ thuộc vào việc
## người chơi GẶP MAY được mấy đơn đắt — chứ không phụ thuộc họ nấu nhanh cỡ
## nào. Có trọng số thì "trung bình một khách đáng bao nhiêu tiền" là con số
## người thiết kế đặt ra, và bốn mốc S/A/B/C mới có cơ sở để tính.
##
## Kem vẫn giữ trọng số thấp chứ không bỏ hẳn: một đơn 4 giây xen giữa hai đơn
## 20 giây là quãng nghỉ, và một màn không có quãng nghỉ nào thì mệt đều chứ
## không căng dần.
@export var weights: Dictionary = {}

## Trọng số theo MỨC ĐỘ KHÓ: {"easy": 7, "medium": 3, "hard": 0}. Rỗng = không
## dùng, bốc thẳng theo `weights` như cũ (Endless, Asian, màn không có luật).
##
## Vì sao cần thêm một tầng trên `weights`: `weights` là con số CỐ ĐỊNH cả màn,
## nên món khó có thể là đơn đầu tiên — đúng lúc người chơi còn chưa nhớ công
## thức. Tầng này do level_rules đổi theo từng CHẶNG của màn: chặng đầu mức khó
## bằng 0, rồi tăng dần. Bốc hai bước: chọn MỨC theo bảng này, rồi chọn MÓN
## trong mức đó theo `weights`.
@export var tier_weights: Dictionary = {}

## Sau một món KHÓ, phải qua bấy nhiêu đơn KHÔNG khó thì món khó mới được xuất
## hiện lại. 0 = tắt.
##
## Vì sao cần dù đã có tỉ lệ: tỉ lệ chỉ nói về TRUNG BÌNH. 15% vẫn cho ra hai
## món khó liền nhau khoảng một lần mỗi màn, và hai món khó chồng lên nhau là
## lúc người chơi mất khách — không phải vì chơi kém mà vì xúc xắc. Quãng nghỉ
## bắt buộc biến "trung bình hiếm" thành "không bao giờ dồn".
##
## Bộ đếm BẮT ĐẦU TỪ 0, tức là đầu màn cũng tính như vừa có một món khó: hai
## đơn đầu tiên của màn không bao giờ là món khó, dù chặng đầu có tỉ lệ khó.
@export var hard_cooldown_orders: int = 2
## Số đơn không-khó đã ra kể từ món khó gần nhất.
var _orders_since_hard: int = 0

## Có trừ kiên nhẫn theo thời gian không.
##
## Màn hướng dẫn tắt cờ này: thanh kiên nhẫn vẫn hiện đầy đủ để người chơi làm
## quen với cách đọc nó, nhưng không bao giờ cạn. Bắt học một thứ mới VÀ chịu
## phạt vì nó cùng lúc là cách nhanh nhất để người mới bỏ game.
@export var drain_patience: bool = true

## Tự sinh khách theo nhịp. Màn hướng dẫn tắt đi và gọi spawn_customer() bằng tay
## ở đúng bước cần.
@export var auto_spawn: bool = true
## Giây giữa hai lần thử sinh khách.
@export var spawn_interval: float = 12.0
## Giây chờ trước người khách đầu tiên — cho người chơi kịp nhìn quanh bếp.
@export var first_wait: float = 4.0

## Hệ số nhân vào GIÁ BÁN mọi món của màn này. 1.0 = giá gốc trong ItemCatalog.
##
## (2/10/2026) Luật màn đặt: Ngày 1 ×0,95 — Ngày 2 ×1,0 — Ngày 3 ×1,15. Lý do:
## giá món đặt theo thời gian làm, nên tiền kiếm được mỗi giây gần như bằng
## nhau ở mọi ngày — ngày cuối khó hơn hẳn mà không đáng tiền hơn. Hệ số này
## cho doanh thu (và các mốc hạng) TĂNG DẦN theo ngày mà không đổi lối chơi.
##
## Chỉ nhân giá BÁN, không nhân giá vốn nguyên liệu: giá vốn là cái giá của
## một quyết định (lấy nhầm thì mất), không phải thứ cần lớn dần theo ngày.
@export var price_factor: float = 1.0

## Khoảng cách NGẪU NHIÊN giữa hai lượt khách, tính bằng giây: mỗi lần một
## khách vào, lượt kế được hẹn sau một quãng bốc đều trong [min, max].
## Cả hai bằng 0 = không dùng, khách vào đều đặn theo `spawn_interval` như cũ.
##
## Vì sao ngẫu nhiên (2/10/2026, user chơi thử): nhịp cố định thì người chơi
## cảm được đúng một thứ là "càng lúc càng dồn" — chặng cuối cứ bảy giây một
## khách, không có lúc nào thở. Quán thật thì có lúc vắng, có lúc đông nghịt.
## Bốc ngẫu nhiên cho ra đúng cảm giác đó: vài khách tới sát nhau tạo cao
## điểm, rồi một quãng trống để dọn dẹp.
##
## `max` là LỜI HỨA "trong vòng bấy nhiêu giây chắc chắn có khách": không có
## chặn trên thì xúc xắc có thể cho một quãng chết dài, mà màn chỉ có 7 phút
## và mốc hạng tính bằng tiền — vắng khách do xui là mất hạng do xui.
## `min` chặn chiều ngược lại: hai khách không bao giờ vào cùng một lúc.
@export var spawn_interval_min: float = 0.0
@export var spawn_interval_max: float = 0.0

## Kiên nhẫn lúc đứng XẾP HÀNG (chưa có bàn), giây. CỐ ĐỊNH, không theo món.
##
## 45 giây: đủ để người chơi dọn xong một bàn và đón người tiếp theo, nhưng
## không đủ để mặc kệ hàng đợi cả màn. Xem thêm lý do vì sao là con số cố định
## ở Order.wait_in_queue().
@export var queue_patience: float = 45.0

## Khách đứng cáu bao lâu trước khi bỏ ra cửa, giây.
##
## 2,0 = ĐÚNG độ dài clip "angry" trong khach_akikawa.glb (đo từ accessor
## input của animation: angry 2,00 s | eat 3,00 | idle 4,00 | walk 1,00).
## Đặt ngắn hơn thì animation bị cắt ngang giữa chừng; dài hơn thì model đứng
## đơ ở khung cuối vì clip này KHÔNG lặp — và không lặp là cố ý, cáu là một
## cử chỉ diễn một lần chứ không phải một trạng thái.
##
## Đổi model khách khác thì phải đo lại con số này theo clip của model đó.
@export var beg_seconds: float = 2.0

## Thưởng thêm khi giao lúc kiên nhẫn còn trên 50%. 0,35 = +35%.
##
## CHỐT 35% (9/9/2026). Vì sao không phải 20% như bản nháp: Hamburger 95 thành
## 114, tức chạy vội cả màn để được thêm 19 tiền — người chơi tính nhẩm một
## lần rồi thôi không nhắm vào cơ chế này nữa. 35% cho 128, đủ để đáng đánh
## đổi. Vì sao không lên 50%: khi đó "luôn đạt hoàn hảo" thành cách chơi duy
## nhất đúng, và điểm giữa người chơi giỏi với người chơi thường tách gấp đôi.
##
## Bốn kĩ năng bị động (Victory Cheer, Conguamoidaden, Aura farming, Fan tê
## liệt) quy đổi giá trị theo đúng con số này — đổi ở đây là phải tính lại
## bảng kĩ năng trong Bang can bang.xlsx.
@export var perfect_bonus: float = 0.35

## ───────────────────────────── HAI NÚM DO HỆ KĨ NĂNG VẶN ──────────────────
##
## Hai biến dưới đây là số GỐC của game; hệ kĩ năng (quan_ly_ki_nang.gd) đổi
## chúng khi người chơi đang dùng đúng nhân vật có kĩ năng tương ứng. Chọn
## nhân vật khác thì chúng giữ nguyên và màn chơi chạy đúng luật gốc.
##
## File này KHÔNG biết kĩ năng là gì và không đi hỏi bảng kĩ năng — nó chỉ có
## hai biến số. Nhờ vậy hệ khách hàng chạy y hệt nhau dù màn chơi có gắn hệ
## kĩ năng hay không.

## Nhân vào kiên nhẫn của mọi đơn, cả lúc xếp hàng lẫn lúc ngồi bàn.
## Kita — "Kiên nhẫn là một đức tính": 1,30.
@export var patience_factor: float = 1.0

## Bỏ qua thanh kiên nhẫn: MỌI đơn giao ra đều tính là hoàn hảo.
## Kita — "Victory Cheer!", bật khi bấm Space và giữ tới hết màn.
##
## Đơn ép hoàn hảo được tính vào cả TIỀN THƯỞNG lẫn bộ đếm perfect_orders và
## tiếng "hoàn hảo" — tức nó hoàn hảo theo đúng mọi nghĩa mà game đang dùng.
## Làm nửa vời (ăn tiền nhưng không đếm) thì bảng tổng kết nói một đằng, ví
## tiền nói một nẻo.
var force_perfect: bool = false

## Kita — "Victory Cheer!", phần NHÂN ĐÔI TIỀN. 1,0 = không đổi.
##
## Chỉ áp cho đơn THẬT SỰ hoàn hảo, tức kiên nhẫn còn trên ngưỡng lúc giao —
## KHÔNG áp cho đơn chỉ hoàn hảo nhờ `force_perfect`. Hai cờ trả lời hai câu
## khác nhau: `force_perfect` quyết đơn CÓ ĐƯỢC TÍNH là hoàn hảo không (sàn an
## toàn), còn cờ này quyết đơn CÓ ĐƯỢC NHÂN ĐÔI không (phần thưởng cho người
## vẫn chơi nhanh).
##
## Vì sao tách: nếu nhân đôi cả đơn được ép hoàn hảo thì suốt ~68% màn mọi đơn
## đều 3,1 lần giá gốc bất kể chơi thế nào — kĩ năng thành "bấm Space rồi đi
## chậm cũng được", và mốc hạng S/A/B/C phải tính lại toàn bộ. Tách ra thì kĩ
## năng vừa đỡ được lúc bí, vừa còn lý do để chạy nhanh.
var perfect_payout_multiplier: float = 1.0

## Các món giao được cho MỌI đơn, kể cả khi khách gọi món khác. Rỗng = tắt.
## (Special Week — Shooting Star bật lên bằng danh sách các món có ham/steak.)
##
## Tiền trả theo giá của MÓN ĐÃ GIAO, không theo món khách gọi: nếu trả theo
## món gọi thì cách chơi tối ưu là chỉ nấu món rẻ nhất trong danh sách rồi đem
## đổi lấy tiền của Bữa tối — kĩ năng thành máy in tiền thay vì lưới cứu khách.
var wildcard_dishes: Array = []

## Bộ đếm cho điều kiện kĩ năng "giao xong N đơn thuộc một nhóm món".
## `counted_dishes` là nhóm món (theo món KHÁCH GỌI); rỗng = không đếm.
var counted_dishes: Array = []
var counted_orders_done: int = 0

## Mỗi đơn giao ra có `bonus_payout_chance` (0…1) cơ hội được NHÂN tiền với
## `bonus_payout_multiplier`. 0 = tắt. (Special Week — Hốc phó: 20% × 3.)
## Nhân SAU mọi thưởng khác, nên một đơn hoàn hảo trúng thưởng là to nhất.
var bonus_payout_chance: float = 0.0

## Hệ số giá RIÊNG theo món: id món -> hệ số. Rỗng = không món nào đổi giá.
## (Oguri Cap — Alo vũ à vũ: ba loại pizza × 1,6.) Nhân lúc tạo đơn, cùng chỗ
## với hệ số giá của màn, nên con số trên vé đã là giá thật.
var dish_price_factors: Dictionary = {}

## Hệ số nhân vào TRỌNG SỐ bốc món: id món -> hệ số. Rỗng = bốc như thường.
## (Mambo — Vua làm nền: ba loại pizza × 1,2, tức pizza được gọi nhiều hơn
## 20% so với bình thường TRONG nhóm độ khó của nó.)
var dish_weight_factors: Dictionary = {}

## BẢNG GIEO THƯỞNG cho đơn HOÀN HẢO của một nhóm món. Rỗng = tắt.
##   "dishes": mảng id món được gieo
##   "rolls":  mảng [xác suất, hệ số] — gieo MỘT lần, rơi vào khoảng nào thì
##             nhân hệ số đó; phần xác suất còn lại là giá thường.
## (Mambo — Go, Go, Mun!: pizza hoàn hảo 36% × 3, 18% × 2.)
var perfect_roll: Dictionary = {}

## ĐÓNG BĂNG toàn bộ hệ khách: không khách mới, không trừ kiên nhẫn, và mọi
## người khách đứng im tại chỗ (đang đi thì dừng, đang ăn thì ngừng ăn).
## (Oguri Cap — Triumphant Pulse.) Đổi bằng set_frozen(), đừng gán thẳng.
var frozen: bool = false

const CUSTOMER_GROUP := "customers"

func set_frozen(value: bool) -> void:
	if frozen == value:
		return
	frozen = value
	# Tắt XỬ LÝ của từng node khách chứ không tự viết cờ "đứng im" trong
	# customer.gd: PROCESS_MODE_DISABLED dừng cả di chuyển, bộ đếm bữa ăn lẫn
	# AnimationPlayer con của nó trong một lệnh, và bật lại là mọi thứ chạy
	# tiếp đúng chỗ dở. Trong lúc đóng băng không có khách mới nào sinh ra,
	# nên không sót ai.
	var mode := Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	for k in get_tree().get_nodes_in_group(CUSTOMER_GROUP):
		k.process_mode = mode
var bonus_payout_multiplier: float = 3.0

## Hệ số giá do KĨ NĂNG đặt, nhân lên MỌI món. 1,0 = không đổi.
## (Sakura Chiyono O — Cute puppy: 1,5.)
## Tách khỏi `price_factor` vì con số kia là của MÀN: level_rules gán nó SAU
## khi kĩ năng đã cài xong, nên viết chung một biến thì luật màn đè mất kĩ năng.
var skill_price_factor: float = 1.0

## Tốc độ trôi của hệ khách: nhân vào nhịp khách đến VÀ tốc độ tụt kiên nhẫn.
## 1,0 = bình thường. (Sakura Chiyono O — Made in haven: 1,25.)
var time_scale: float = 1.0

## Những món đã từng được giao HOÀN HẢO trong màn này: id món -> true.
## (Gold Ship — Anchors Aweigh! cần mọi món trong thực đơn có mặt ở đây.)
var perfect_dishes: Dictionary = {}

## Nguyên liệu miễn phí (cheat). false = trừ tiền như bình thường.
##
## level_base đọc GameData.cheat_free_ingredients rồi gán vào đây. File này KHÔNG
## tự hỏi GameData: nó là hệ cơ chế, còn "người chơi bật cheat gì" là chuyện của
## màn chơi. Nhờ vậy chạy thử customer_manager trong một probe không cần dựng
## GameData nào cả.
var free_ingredients: bool = false

## Khách hết kiên nhẫn vẫn ngồi chờ, không bỏ về (AAA Mode: không thể thua).
## Thanh kiên nhẫn vẫn chạy và vẫn đổi màu; giao muộn chỉ mất thưởng hoàn hảo.
var never_leave: bool = false

## Tổng tiền trong màn. CÓ THỂ ÂM.
##
## Âm là hợp lệ, không phải lỗi: lấy nguyên liệu bị trừ tiền ngay, nên mấy giây
## đầu màn (đã mua đồ, chưa giao được món nào) gần như chắc chắn âm. Kẹp về 0 thì
## chi phí đầu màn biến mất và người chơi không thấy được mình đang đầu tư.
var money: int = 0

## Thống kê một lượt chơi, để bảng kết quả đọc lúc hết giờ.
##
## Đếm Ở ĐÂY chứ không để bảng kết quả tự đếm bằng cách nghe tín hiệu: bảng
## kết quả chỉ được dựng lúc hết giờ, mà lúc đó mọi tín hiệu đã bay qua từ lâu.
## Nơi biết chuyện gì đã xảy ra phải là nơi giữ sổ.
var orders_done: int = 0
var perfect_orders: int = 0
var customers_lost: int = 0

var _orders: Dictionary = {}       # customer -> Order
var _spawn_timer: float = 0.0

var _map: Node3D
var _spawn_points: Node
var _queue: Array[Marker3D] = []          # HangDoi1..N, [0] là đầu hàng
var _door: Marker3D
var _tables: Array = []                     # mọi DiningTable trong màn
var _in_queue: Array = []                  # ai đang đứng ở ô hàng đợi nào
var _table_of: Dictionary = {}       # customer -> DiningTable
var _customer_at: Dictionary = {}       # DiningTable -> customer


func setup(map: Node3D) -> void:
	_map = map
	_spawn_points = map.get_node_or_null("Markers")
	_door = _pick_spawn("Entrance")

	var i := 1
	while true:
		var m := _pick_spawn("Queue%d" % i)
		if m == null:
			break
		_queue.append(m)
		i += 1
	_in_queue.resize(_queue.size())
	_in_queue.fill(null)

	_tables = get_tree().get_nodes_in_group("dining_table")
	_tables.sort_custom(func(a, b): return int(a.table_number) < int(b.table_number))
	for b in _tables:
		if b.has_signal("dish_delivered"):
			b.dish_delivered.connect(_on_dish_delivered)
		if b.has_signal("delivery_rejected"):
			b.delivery_rejected.connect(_on_delivery_rejected)

	_bake_navmesh()
	_spawn_timer = first_wait


func _pick_spawn(marker_name: String) -> Marker3D:
	if _spawn_points == null:
		return null
	return _spawn_points.get_node_or_null(marker_name) as Marker3D


# ------------------------------------------------------- vùng đi lại (navmesh)

## Vùng đi được của khách, NƯỚNG LÚC CHẠY chứ không đặt sẵn trong file map.
##
## Ba lý do:
##  1. Kê thêm hay dời một cái bàn thì đường đi tự đúng theo, không ai phải nhớ
##     bấm lại nút Bake — quên bấm thì khách đi xuyên qua bàn mới và rất khó
##     lần ra vì không có lỗi nào cả.
##  2. Không có mesh nướng sẵn nằm trong file .tscn, nên file map không phình
##     lên vì một thứ suy ra được từ chính nó.
##  3. Cùng nếp với mọi hệ thống khác của màn chơi — tất cả đều do level_base
##     dựng lúc chạy.
##
## HAI vùng chứ không một, vì khu khách hình chữ L: dải bên phải bếp (x 16→32,
## z 0→12) chứa hàng đợi, và sảnh phía nam (x 0→32, z 12→24) chứa sáu cái bàn.
## Một khung bao chỉ vẽ được hình hộp, mà hộp trùm cả chữ L thì trùm luôn cả
## bếp — khách sẽ đi thẳng vào bếp qua lối người chơi ở x=16. Hai hộp chạm nhau
## dọc cạnh z=12, Godot tự nối hai vùng ở cạnh chung nên khách vẫn đi qua lại
## được.
const SOURCE_GROUP := "navmesh_source"

## Lớp va chạm 5 (bit 16) dành RIÊNG cho mấy tấm chắn vô hình chỉ tồn tại với
## navmesh. Người chơi có mask 1 nên đi xuyên qua chúng như không có gì.
const NAV_BLOCK_LAYER := 1 << 4

## Hai lối vào bếp, chắn lại để khách không lang thang vào khu bếp.
## Mỗi mục: [tâm hộp, nửa kích thước].
const BLOCKERS := [
	# Lối người chơi ở x=16, z 4→8.
	[Vector3(16.0, 1.0, 6.0), Vector3(0.4, 1.5, 2.2)],
	# Khe trống ở tường nam khu bếp, z=12, x 0→4.
	[Vector3(2.0, 1.0, 12.0), Vector3(2.2, 1.5, 0.4)],
]

var _nav_region: Array[NavigationRegion3D] = []
## Mặt navmesh nằm cao hơn mặt sàn bấy nhiêu. ĐO lúc chạy chứ không gõ tay:
## con số này do Recast quyết theo cell_height và chiều dày hình va chạm sàn,
## đổi một trong hai là nó đổi theo.
var _height_offset := 0.0


func _bake_navmesh() -> void:
	if not _map.is_in_group(SOURCE_GROUP):
		_map.add_to_group(SOURCE_GROUP)
	_build_blockers()

	var mesh_ := NavigationMesh.new()
	# Ba con số này phải là BỘI SỐ của ô lưới, và ô lưới phải TRÙNG với ô lưới
	# của bản đồ điều hướng (mặc định project là 0,25). Lệch thì Godot cảnh báo
	# "cell_size mismatch" và mép navmesh bị rasterize sai; còn agent_radius /
	# agent_max_climb không tròn ô thì bị làm tròn và giá trị thật khác hẳn giá
	# trị mình gõ.
	mesh_.cell_size = 0.25
	mesh_.cell_height = 0.25
	# 0,5 = đúng 2 ô, và vẫn lớn hơn bán kính người khách 0,45 nên navmesh co
	# khỏi mọi vật cản đủ để khách không cọ vào mép bàn rồi kẹt.
	mesh_.agent_radius = 0.5
	mesh_.agent_height = 1.5
	mesh_.agent_max_climb = 0.25
	mesh_.agent_max_slope = 45.0
	# Đọc HÌNH VA CHẠM chứ không đọc mesh hiển thị: trong map này bàn ghế tường
	# đều là StaticBody3D + CollisionShape3D, còn mesh gltf chỉ để nhìn. Đọc
	# mesh thì mấy thứ trang trí không có va chạm cũng chắn đường.
	mesh_.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh_.geometry_collision_mask = 1 | NAV_BLOCK_LAYER
	mesh_.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh_.geometry_source_group_name = SOURCE_GROUP

	var region := NavigationRegion3D.new()
	region.name = "CustomerNavRegion"
	region.navigation_mesh = mesh_
	_map.add_child(region)
	_nav_region.append(region)
	# Nướng đồng bộ: màn chơi chưa bắt đầu nên một nhịp khựng ở đây không ai
	# thấy, đổi lại khách đầu tiên chắc chắn có đường để đi.
	region.bake_navigation_mesh(false)
	_measure_height_offset(mesh_)


## Tấm chắn vô hình bịt hai lối vào bếp.
##
## Vì sao KHÔNG chia khu khách thành hai vùng navmesh hình hộp (bản trước làm
## thế và hỏng): Recast bào lùi mép mỗi vùng đúng bằng agent_radius, nên hai
## vùng dán sát nhau vẫn hở ra 2 × 0,5 = 1,0 đơn vị. Godot chỉ nối hai vùng khi
## mép tự do của chúng cách nhau dưới edge_connection_margin (0,25), nên khách
## đi tới rìa vùng thứ nhất là agent báo "đã tới nơi" rồi đứng lại giữa sảnh —
## đúng triệu chứng đo được: dừng ở z ≈ 10,8 trong khi bàn ở z = 19.
##
## Một vùng duy nhất thì không có mép nào để nối, còn khu bếp thì loại ra bằng
## vật cản thật. Đặt tấm chắn ở lớp riêng để chúng chỉ tồn tại với bộ nướng
## navmesh, người chơi vẫn đi qua lối của mình như cũ.
func _build_blockers() -> void:
	for c in BLOCKERS:
		var body := StaticBody3D.new()
		body.name = "NavBlocker"
		body.collision_layer = NAV_BLOCK_LAYER
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = (c[1] as Vector3) * 2.0
		shape.shape = box
		body.add_child(shape)
		_map.add_child(body)
		body.global_position = c[0]


## Đọc độ cao mặt navmesh THẲNG TỪ LƯỚI vừa nướng.
##
## Bản trước hỏi NavigationServer bằng map_get_closest_point() và nhận về 0,0
## — sai. Lý do: map_get_iteration_id() khác 0 mới chỉ nghĩa là bản đồ đã chạy
## xong MỘT vòng đồng bộ, không bảo đảm vòng đó đã gộp mấy vùng mình vừa thêm.
## Truy vấn trượt thì lại trả (0,0,0) chứ không báo lỗi, đúng cái bẫy đã dính
## một lần ở điểm đích.
##
## Đọc đỉnh của chính cái NavigationMesh thì không phụ thuộc server, không phụ
## thuộc thời điểm, và là dữ liệu gốc chứ không phải kết quả suy ra.
func _measure_height_offset(mesh_: NavigationMesh) -> void:
	var verts := mesh_.get_vertices()
	if verts.is_empty():
		return
	# Sàn phẳng nên mọi đỉnh cùng cao độ; lấy đỉnh đầu là đủ.
	_height_offset = verts[0].y


## Chờ NavigationServer đồng bộ xong bản đồ.
##
## Server chỉ gộp các vùng vừa thêm vào CUỐI một khung hình vật lý, nên mọi
## truy vấn đường đi trước thời điểm đó đều hỏng. Đáng nói là nó hỏng LẶNG LẼ
## kiểu tệ nhất: map_get_closest_point() trả về (0,0,0) chứ không báo gì, nên
## người khách đầu tiên lầm lũi đi về gốc toạ độ thay vì vào hàng đợi.
##
## Đợi bằng map_get_iteration_id() chứ không đợi "vài khung cho chắc": số nhịp
## cần đợi phụ thuộc thời điểm gọi trong khung hình, đoán bao nhiêu cũng có
## ngày trượt.
func is_ready() -> void:
	var nav_map := _map.get_world_3d().navigation_map
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame


## Số đa giác của từng vùng — dùng để kiểm nhanh navmesh có nướng ra gì không.
## Mặt navmesh cao hơn mặt sàn bao nhiêu — ĐO được lúc nướng.
##
## Mở hàm đọc thay vì để nơi khác chọc thẳng vào `_height_offset`: con số này chỉ
## có nghĩa SAU khi navmesh nướng xong, và một hàm công khai là chỗ để ghi
## đúng điều đó. Hiện có hai nơi cần: khách hàng và Doro.
func navmesh_height_offset() -> float:
	return _height_offset


func nav_stats() -> Array:
	var out := []
	for v in _nav_region:
		out.append({"ten": v.name, "da_giac": v.navigation_mesh.get_polygon_count()})
	return out


# --------------------------------------------------------------- vòng đời khách

func spawn_customer() -> Node:
	if _door == null or _queue.is_empty():
		push_warning("Map thiếu Markers/Entrance hoặc Markers/Queue1 — không sinh khách được.")
		return null
	var slot := _free_seat()
	if slot == -1:
		return null

	var k := CUSTOMER_SCENE.instantiate()
	k.add_to_group(CUSTOMER_GROUP)
	_map.add_child(k)
	# Nắn chỗ sinh về navmesh rồi lệch ngẫu nhiên một chút: cửa vào nằm sát
	# tường đông (x=31,5 so với tường x=32) nên điểm gốc rơi ra ngoài vùng đi
	# được, mà sinh mấy người CHỒNG LÊN NHAU ở đúng một toạ độ thì họ đẩy nhau
	# ra và có người bị ép xuyên qua tường.
	var pos: Vector3 = k.snap_to_navmesh(_map.get_world_3d().navigation_map,
		_door.global_position)
	pos.z += randf_range(-0.7, 0.7)
	k.global_position = pos
	k.set_height_offset(_height_offset)
	k.arrived.connect(_on_arrived)
	k.ate.connect(_on_ate)

	_in_queue[slot] = k
	k.set_meta("in_queue", slot)
	AmThanh.play_sfx("customer_in")
	k.go_to(_queue[slot].global_position, "queue")
	return k


## Ô hàng đợi trống gần đầu hàng nhất, hoặc -1 nếu hết chỗ.
##
## Chỉ xét `max_queue` ô ĐẦU TIÊN chứ không cắt bớt mảng `_in_queue`: các ô
## sau vẫn tồn tại và vẫn đúng vị trí, nên Ngày 2 chỉ cần nâng con số lên là
## hàng đợi dài ra ngay, không phải dựng lại gì.
func _free_seat() -> int:
	var limit: int = _in_queue.size()
	if max_queue > 0:
		limit = mini(limit, max_queue)
	for i in limit:
		if _in_queue[i] == null:
			return i
	return -1


## Đã đủ trần số khách ngồi bàn chưa.
func _tables_full() -> bool:
	return max_tables > 0 and _customer_at.size() >= max_tables


## Nhịp tim của cả nhà hàng: sinh khách và đếm kiên nhẫn.
##
## Đếm ở MỘT vòng lặp chung thay vì cho mỗi khách một Timer riêng: sáu Timer
## thì sáu chỗ có thể quên tắt lúc khách bị xoá, và một Timer sống sót sẽ gọi
## vào node đã biến mất. Một vòng lặp thì danh sách đơn chính là nguồn sự thật.
func _process(delta: float) -> void:
	if _map == null or frozen:
		return

	if auto_spawn:
		_spawn_timer -= delta * time_scale
		if _spawn_timer <= 0.0:
			_spawn_timer = _next_spawn_gap()
			spawn_customer()

	if not drain_patience:
		return
	# Duyệt trên BẢN SAO danh sách: _leave_angry() xoá phần tử khỏi _don ngay
	# trong vòng lặp, mà sửa Dictionary đang duyệt thì Godot bỏ sót phần tử.
	for order_ in _orders.values().duplicate():
		# Khai kiểu tường minh: `don` lấy từ Dictionary nên kiểu tĩnh là Variant,
		# `:=` không suy được kiểu trả về và Godot báo lỗi biên dịch.
		var expired: bool = order_.tick(delta * time_scale)
		# Vẽ thanh chờ trên đầu người đang xếp hàng. Chỉ giai đoạn hàng đợi mới
		# vẽ ở đây; ngồi vào bàn rồi thì tấm vé trên HUD lo phần đó.
		if order_.in_queue and is_instance_valid(order_.customer):
			order_.customer.set_patience_bar(order_.patience_ratio())
		if expired and not never_leave:
			_leave_angry(order_)


## Bao lâu nữa thì lượt khách kế tiếp vào.
func _next_spawn_gap() -> float:
	if spawn_interval_max <= 0.0:
		return spawn_interval
	return randf_range(minf(spawn_interval_min, spawn_interval_max), spawn_interval_max)


func _on_arrived(customer: Node, task: String) -> void:
	match task:
		"queue":
			# Tới chỗ xếp hàng. Quay mặt về phía quầy rồi thử ra bàn ngay —
			# nếu còn bàn trống thì không phải đợi ai.
			customer.stop_moving(Vector3.LEFT)
			# Gọi món NGAY khi vào hàng, trước cả khi biết có bàn hay không.
			# Đúng ý đã chốt: kể cả lúc hết bàn trống thì đơn vẫn hiện trên
			# đầu khách — người chơi nhìn thấy công việc đang dồn tới, đó là
			# phần áp lực mà cái hàng đợi tồn tại để tạo ra.
			_place_order(customer)
			# Đứng luôn vào ô đầu hàng (quán đang vắng) thì đơn lên bảng ngay.
			if int(customer.get_meta("in_queue", -1)) == 0:
				_push_to_board(customer)
			_try_seat(customer)
		"table":
			var table = _table_of.get(customer)
			if table == null:
				return
			# Quay mặt vào tâm bàn.
			# Khai kiểu tường minh: `table` lấy từ Dictionary nên kiểu tĩnh là
			# Variant, `:=` không suy được kiểu và Godot báo lỗi biên dịch.
			var dir_: Vector3 = table.global_position - customer.global_position
			dir_.y = 0.0
			customer.stop_moving(dir_.normalized())
			customer_seated.emit(customer, table)
			_seat_at_table(customer, table)
		"leave":
			_clear_customer(customer)


## Tìm bàn trống cho một người đang đứng ở hàng đợi.
##
## Chỉ người ĐẦU HÀNG mới được đi. Không có luật này thì người thứ ba có thể
## vọt lên bàn trước người thứ nhất, và cái hàng đợi mất hết ý nghĩa.
func _try_seat(customer: Node) -> void:
	if _in_queue.is_empty() or _in_queue[0] != customer:
		return
	var table = _empty_table()
	if table == null:
		return

	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0:
		_in_queue[slot] = null
	customer.remove_meta("in_queue")

	_table_of[customer] = table
	_customer_at[table] = customer

	# ĐÓNG BĂNG đồng hồ chờ ngay khi có bàn, chứ không đợi tới lúc ngồi xuống.
	# Quãng đường từ cửa tới bàn xa nhất là 33 đơn vị, đi mất hơn mười giây —
	# để đồng hồ chạy tiếp thì có khách đã được xếp bàn vẫn bỏ đi giữa đường,
	# và người chơi không hiểu vì sao vì họ đã thấy khách được gọi vào rồi.
	var order_: Order = _orders.get(customer)
	if order_ != null:
		order_.draining = false

	customer.go_to((table.seat_marker(0) as Marker3D).global_position, "table")
	_shift_queue()


## Dồn hàng lên một ô sau khi người đầu hàng rời đi.
func _shift_queue() -> void:
	for i in range(1, _in_queue.size()):
		var k = _in_queue[i]
		if k == null:
			continue
		var before := i - 1
		if _in_queue[before] != null:
			continue
		_in_queue[before] = k
		_in_queue[i] = null
		k.set_meta("in_queue", before)
		# Vừa nhích lên đầu hàng -> đơn lên bảng NGAY, không đợi đi tới nơi.
		# Người chơi nhìn bảng chứ không nhìn chân khách, nên sớm vài giây ở
		# đây chính là vài giây họ dùng để bắc nồi trước.
		if before == 0:
			_push_to_board(k)
		k.go_to(_queue[before].global_position, "queue")


func _empty_table():
	# Trần số chỗ ngồi. Kiểm tra ở ĐÂY, chỗ duy nhất trả lời "có bàn cho người
	# này không", nên mọi đường đi vào bàn đều bị chặn cùng một luật — kể cả
	# nhánh ép bàn của màn hướng dẫn.
	if _tables_full():
		return null
	if force_table > 0:
		for b in _tables:
			if int(b.table_number) == force_table and not _customer_at.has(b):
				return b
		return null
	var free := []
	for b in _tables:
		if not _customer_at.has(b):
			free.append(b)
	if free.is_empty():
		return null
	return free.pick_random()


## Bàn nhận được món. Chỉ người đang ngồi ở CHÍNH bàn đó mới ăn.
func _on_dish_delivered(table: Node, dish_id: String) -> void:
	var customer = _customer_at.get(table)
	if customer == null:
		return
	var order_: Order = _orders.get(customer)
	if order_ == null:
		return

	# GIAO NHẦM MÓN: không làm gì cả.
	#
	# Cố ý im lặng chứ không phạt: món vẫn nằm trên mặt bàn và người chơi bấm
	# E lần nữa là nhấc lại được (xem _giao_mon trong hands.gd). Hình phạt
	# duy nhất là thời gian — mà trong một màn 7 phút thì thời gian đã là đồng
	# tiền đắt nhất. Tịch thu cả món lẫn đơn thì một lần bấm nhầm lúc vội đủ
	# làm hỏng cả màn, và người chơi học được điều sai: "đừng vội" thay vì
	# "nhìn vé trước khi bê".
	#
	# NGOẠI LỆ: món nằm trong `wildcard_dishes` thì đơn nào cũng nhận.
	var is_wildcard := dish_id != order_.dish and wildcard_dishes.has(dish_id)
	if dish_id != order_.dish and not is_wildcard:
		# (25/10/2026) Vẫn không phạt tiền/thời gian, nhưng KHÔNG còn im lặng:
		# khách cáu + nói ra, để người chơi biết ngay là nhầm chứ không tưởng
		# game bị đơ. Món vẫn nằm trên bàn để nhấc lại như cũ.
		if _waiting_at_table(order_):
			_complain(customer, Lang.t("Đây không phải món tôi gọi!"))
		return

	# Chốt tiền NGAY LÚC GIAO, trả vào ví lúc khách ăn xong.
	#
	# Phải chốt ở đây vì "hoàn hảo" đo bằng kiên nhẫn còn lại, mà trong 5 giây
	# ngồi ăn thì thanh đó vẫn đang chạy. Tính lúc ăn xong thì mọi đơn đều
	# thành không hoàn hảo, và cái thưởng 20% coi như không tồn tại.
	order_.draining = false

	# ĐO "thật sự hoàn hảo" TRƯỚC khi force_perfect che mất. Đảo hai dòng này
	# là phần nhân đôi âm thầm ăn cả đơn giao muộn — không lỗi, chỉ sai tiền.
	var truly_perfect := order_.is_perfect()
	order_.was_perfect = force_perfect or truly_perfect
	# Giá gốc của lần giao này: giá đơn, hoặc — khi giao món thế chỗ — giá
	# của chính món được giao (đã nhân hệ số giá của màn như mọi đơn khác).
	var base_price: int = order_.price
	if is_wildcard:
		base_price = maxi(1, int(round(ItemCatalog.price(dish_id) * price_factor * skill_price_factor \
			* float(dish_price_factors.get(dish_id, 1.0)))))
	order_.payout = base_price
	if order_.was_perfect:
		order_.payout = int(round(base_price * (1.0 + perfect_bonus)))
	if truly_perfect and not is_equal_approx(perfect_payout_multiplier, 1.0):
		# Nhân vào tiền ĐÃ CỘNG thưởng, không nhân riêng phần giá: "gấp đôi giá
		# trị đơn hàng" nói gọn được thành một câu trong bảng thông tin nhân vật,
		# và người chơi nhìn số tiền bay lên là hiểu ngay.
		order_.payout = int(round(order_.payout * perfect_payout_multiplier))
		order_.was_doubled = true

	if order_.was_perfect and not perfect_roll.is_empty() \
			and (perfect_roll.get("dishes", []) as Array).has(dish_id):
		# Gieo MỘT số rồi dò dần qua bảng, chứ không gieo riêng cho từng dòng:
		# gieo riêng thì "36% × 3" và "18% × 2" có thể cùng trúng, và tỉ lệ
		# thật không còn là con số ghi trong mô tả kĩ năng.
		var roll := randf()
		for entry in perfect_roll.get("rolls", []):
			roll -= float(entry[0])
			if roll < 0.0:
				order_.payout = int(round(order_.payout * float(entry[1])))
				break

	if bonus_payout_chance > 0.0 and randf() < bonus_payout_chance:
		order_.payout = int(round(order_.payout * bonus_payout_multiplier))

	orders_done += 1
	if counted_dishes.has(order_.dish):
		counted_orders_done += 1
	if order_.was_perfect:
		perfect_orders += 1
		perfect_dishes[order_.dish] = true
		# Chồng LÊN TRÊN tiếng giao món, không thay thế: người chơi vẫn nghe
		# tiếng giao quen thuộc, cộng thêm một tiếng nữa báo "lần này hoàn hảo".
		AmThanh.play_sfx("perfect")

	customer.set_meta("dish", dish_id)
	customer.eat(eat_seconds)
	order_finished.emit(order_, "served")


## Bàn từ chối đồ người chơi bê tới (chưa thành món, vd. thiếu đĩa).
func _on_delivery_rejected(table: Node, reason: String) -> void:
	var customer = _customer_at.get(table)
	if customer == null:
		return
	var order_: Order = _orders.get(customer)
	if order_ == null or not _waiting_at_table(order_):
		return
	if reason == "no_plate":
		_complain(customer, Lang.t("Món của tôi đâu có đĩa?!"))


## Khách đã NGỒI vào bàn và đang chờ món. Bàn được giữ chỗ ngay khi khách
## bắt đầu đi tới (_customer_at có từ lúc đó), nên phải kiểm thêm: người còn
## đang đi trên đường hay đã ăn xong thì không cáu.
func _waiting_at_table(order_: Order) -> bool:
	return not order_.in_queue and order_.draining


## Khách nổi cáu tại chỗ: animation angry + một câu nói nổi trên đầu.
##
## Chỉ là PHẢN HỒI, không phải hình phạt — không trừ tiền, không trừ kiên
## nhẫn. Lý do giữ nguyên luật cũ: một lần bấm nhầm lúc vội không được làm
## hỏng cả màn; cái người chơi cần là BIẾT mình sai ở đâu.
## Dùng lại beg_seconds (= đúng độ dài clip angry) cho thời gian cáu.
func _complain(customer: Node, text: String) -> void:
	if not is_instance_valid(customer):
		return
	AmThanh.play_sfx("customer_out")
	customer.beg()
	_speech_popup(customer, text)
	await get_tree().create_timer(beg_seconds).timeout
	if is_instance_valid(customer) and customer.is_inside_tree():
		customer.calm()


## Câu nói đỏ nổi trên đầu khách. Gắn làm CON của khách để đi theo người;
## mỗi khách chỉ một câu — cáu lần nữa thì thay câu cũ, không chồng chữ.
func _speech_popup(customer: Node, text: String) -> void:
	var old := customer.get_node_or_null("ComplaintText")
	if old != null:
		old.name = "ComplaintTextOld"
		old.queue_free()
	var label := Label3D.new()
	label.name = "ComplaintText"
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color("ff5a4a")
	label.outline_modulate = Color(0.15, 0.0, 0.0)
	label.outline_size = 24
	# Cao hơn bong bóng đơn (~2,3) để không đè lên nhau.
	label.position = Vector3(0.0, 2.9, 0.0)
	customer.add_child(label)
	var tw := label.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.finished.connect(label.queue_free)


func _on_ate(customer: Node) -> void:
	var table = _table_of.get(customer)
	var dish_id := str(customer.get_meta("dish", ""))
	if table != null:
		table.clear_all()
		table.clear_model()
	var order_: Order = _orders.get(customer)
	if order_ != null:
		_orders.erase(customer)
		if order_.payout > 0:
			money += order_.payout
			var spot: Vector3 = table.global_position if table != null \
				else customer.global_position
			money_changed.emit(money, order_.payout, spot)
			AmThanh.play_sfx("coin")
			_money_popup(spot, order_.payout, order_.was_perfect)

	customer_ate.emit(customer, table, dish_id)
	if _door != null:
		customer.go_to(_door.global_position, "leave")


## Xoá hẳn người khách và trả lại cái bàn.
func _clear_customer(customer: Node) -> void:
	var table = _table_of.get(customer)
	if table != null:
		_customer_at.erase(table)
		_table_of.erase(customer)
	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0 and slot < _in_queue.size() and _in_queue[slot] == customer:
		_in_queue[slot] = null
		_shift_queue()
	# Lưới eat toàn: nếu vì lý do nào đó người khách biến mất khi đơn còn treo
	# (đổi màn, gọi don_khach thẳng tay), cái vé phải đi theo. Đơn mồ côi thì
	# vé nằm lại trên HUD vĩnh viễn và trỏ vào một node đã bị xoá.
	var order_: Order = _orders.get(customer)
	if order_ != null:
		_orders.erase(customer)
		order_finished.emit(order_, "left")

	customer_left.emit(customer)
	customer.queue_free()
	# Người đầu hàng có thể đã chờ sẵn một cái bàn vừa trống ra.
	if not _in_queue.is_empty() and _in_queue[0] != null:
		_try_seat(_in_queue[0])


# ------------------------------------------------------------- đơn hàng ---

## Người khách vừa ngồi xuống thì gọi món.
##
## Món bốc NGẪU NHIÊN từ ItemCatalog.sellable_dishes() chứ không từ một danh
## sách gõ tay ở đây. Nhờ vậy thêm một món có giá vào danh mục là nó tự vào
## thực đơn, còn khoá một món (như cả nhóm món nồi hiện giờ) là khách tự động
## thôi gọi — không có chỗ thứ hai để quên cập nhật.
func _place_order(customer: Node) -> void:
	if _orders.has(customer):
		return
	var available := _actual_menu()
	if available.is_empty():
		push_warning("Thực đơn rỗng — không món nào có giá trong ItemCatalog.")
		return

	var picked := _pick_dish(available)
	# Chỉ ép khi món đó THẬT SỰ bán được. Gõ nhầm tên món vào ô ép thì quay về
	# ngẫu nhiên chứ không sinh ra một đơn không bao giờ giao được.
	if not force_dish.is_empty() and available.has(force_dish):
		picked = force_dish

	var order_ := Order.new(customer, picked)
	# Hệ số giá của màn. Nhân NGAY LÚC TẠO ĐƠN, không phải lúc trả tiền: con
	# số trên tấm vé là con số người chơi sẽ nhận, và thưởng hoàn hảo (tính
	# từ order_.price) tự ăn theo mà không cần biết có hệ số.
	var factor := price_factor * skill_price_factor * float(dish_price_factors.get(picked, 1.0))
	if not is_equal_approx(factor, 1.0):
		order_.price = maxi(1, int(round(order_.price * factor)))
	# Gán hệ số TRƯỚC wait_in_queue(): hàm đó chốt ngân sách kiên nhẫn ngay tại chỗ.
	order_.patience_factor = patience_factor
	order_.wait_in_queue(queue_patience)
	order_.draining = drain_patience
	_orders[customer] = order_

	# Bong bóng trên đầu. Vé ở HUD do `_push_to_board()` lo, và chỉ cho
	# người ĐỨNG ĐẦU HÀNG — xem giải thích ở hàm đó.
	customer.show_order(_dish_icon(order_.dish))


## Đẩy đơn của một người lên BẢNG ĐƠN HÀNG (phím 1), nếu chưa có.
##
## Gọi cho người ĐỨNG ĐẦU HÀNG, tức trước cả khi họ có bàn. Đây là một ưu ái
## có chủ ý cho người chơi: biết trước món kế tiếp thì họ nấu sẵn được trong
## lúc bàn còn bận, thay vì đứng chờ khách ngồi xuống rồi mới bắt đầu.
##
## Chỉ ĐẦU HÀNG chứ không cả hàng: cho xem hết thì bảng thành danh sách việc
## dài dằng dặc và mất luôn cảm giác "đơn tới dồn dập". Một đơn nhìn trước là
## đủ để chuẩn bị, không đủ để chơi thành game xếp lịch.
##
## Phát lại `order_created` cho cùng một đơn là AN TOÀN: bảng bỏ qua đơn đã có
## (`them()` kiểm tra `_ve.has(don)`), nên lúc người này ngồi vào bàn và
## `_seat_at_table()` phát lần nữa thì không sinh vé thứ hai.
func _push_to_board(customer: Node) -> void:
	var order_: Order = _orders.get(customer)
	if order_ != null:
		order_created.emit(order_)


## Thực đơn thật sự dùng để bốc món.
##
## LỌC qua danh mục chứ không tin thẳng ô `menu`: gõ sai một id trong bảng
## luật màn (hoặc để sót một món thuộc nhóm đang bị khoá, ví dụ nhóm món nồi)
## thì khách sẽ gọi một món KHÔNG THỂ nấu ra, và cái đơn đó đứng đó cho tới
## khi hết kiên nhẫn. Lỗi kiểu này không có thông báo nào và rất khó nhìn ra
## khi đang chơi — nên chặn ngay ở đây, kèm cảnh báo chỉ đúng tên món sai.
func _actual_menu() -> Array[String]:
	var full := ItemCatalog.sellable_dishes()
	if menu.is_empty():
		return full

	var out: Array[String] = []
	for m in menu:
		var id := String(m)
		if full.has(id):
			out.append(id)
		else:
			push_warning("Thực đơn màn có món '%s' không bán được — bỏ qua." % id)

	if out.is_empty():
		push_warning("Thực đơn màn lọc xong thành rỗng — dùng cả danh mục.")
		return full
	return out


## Bốc một món theo trọng số.
##
## Cách làm: cộng dồn tổng trọng số, bắn một số ngẫu nhiên trong [0, tổng),
## rồi trừ dần cho tới khi âm. Ngắn hơn cách dựng sẵn một mảng lặp lại phần tử
## theo trọng số, và quan trọng hơn là nhận được trọng số THẬP PHÂN — sau này
## muốn chỉnh "hamburger hiếm hơn steak một chút" thì đổi 3 thành 2.5, không
## phải nhân cả bảng lên mười lần.
func _pick_dish(list_: Array[String]) -> String:
	var picked := _pick_weighted(_narrow_to_tier(_without_hard_if_cooling(list_)))
	if ItemCatalog.difficulty(picked) == "hard":
		_orders_since_hard = 0
	else:
		_orders_since_hard += 1
	return picked


## Đang trong quãng nghỉ sau món khó thì bỏ hẳn các món khó khỏi danh sách.
##
## Lọc DANH SÁCH chứ không sửa tier_weights: cách này đúng cho cả những màn
## không dùng tầng mức độ (Endless, Asian), và không đụng vào bảng tỉ lệ mà
## level_rules đang quản. Nếu lọc xong không còn món nào (thực đơn toàn món
## khó) thì trả lại danh sách gốc — thà phá luật nghỉ còn hơn không có đơn.
func _without_hard_if_cooling(list_: Array[String]) -> Array[String]:
	if _orders_since_hard >= hard_cooldown_orders:
		return list_
	var out: Array[String] = []
	for id in list_:
		if ItemCatalog.difficulty(id) != "hard":
			out.append(id)
	return out if not out.is_empty() else list_


## Thu danh sách món về MỘT mức độ khó, bốc theo tier_weights. Trả nguyên danh
## sách nếu không dùng tầng mức độ, hoặc nếu không mức nào bốc được.
##
## Chỉ xét những mức ĐANG CÓ MÓN trong thực đơn: Ngày 1 không có món khó, nên
## trọng số của "hard" ở đó phải bị bỏ qua chứ không được bốc trúng một mức
## rỗng rồi trả về không có gì.
func _narrow_to_tier(list_: Array[String]) -> Array[String]:
	if tier_weights.is_empty():
		return list_
	var by_tier: Dictionary = {}
	for id in list_:
		var tier := ItemCatalog.difficulty(id)
		if not by_tier.has(tier):
			var fresh: Array[String] = []
			by_tier[tier] = fresh
		(by_tier[tier] as Array[String]).append(id)

	var total := 0.0
	for tier in by_tier:
		total += maxf(0.0, float(tier_weights.get(tier, 0)))
	if total <= 0.0:
		return list_

	var pick := randf() * total
	var last: Array[String] = list_
	for tier in by_tier:
		var w := maxf(0.0, float(tier_weights.get(tier, 0)))
		if w <= 0.0:
			continue
		last = by_tier[tier]
		pick -= w
		if pick <= 0.0:
			return last
	return last


## Trọng số bốc của một món: số trong bảng `weights` của màn, nhân với hệ số
## riêng của kĩ năng (nếu có).
func _dish_weight(id: String) -> float:
	return maxf(0.0, float(weights.get(id, 1)) * float(dish_weight_factors.get(id, 1.0)))


func _pick_weighted(list_: Array[String]) -> String:
	var total := 0.0
	for id in list_:
		total += _dish_weight(id)
	# Không có trọng số nào (hoặc toàn số 0): quay về bốc đều.
	if total <= 0.0:
		return String(list_.pick_random())

	var pick := randf() * total
	for id in list_:
		pick -= _dish_weight(id)
		if pick <= 0.0:
			return id
	# Lưới eat toàn cho sai số dấu phẩy động: randf() trả về gần đúng 1.0 thì
	# vòng trên có thể chạy hết mà chưa chạm 0.
	return list_[list_.size() - 1]


## Khách đã tới bàn: tắt bong bóng, nạp đầy kiên nhẫn, bật vé trên HUD.
func _seat_at_table(customer: Node, table: Node) -> void:
	var order_: Order = _orders.get(customer)
	if order_ == null:
		# Lưới eat toàn: nếu vì lý do nào đó khách tới bàn mà chưa có đơn (bị
		# gọi thẳng spawn_customer rồi ép ngồi trong lúc thử), vẫn tạo đơn để bàn
		# không kẹt vĩnh viễn với một người không bao giờ gọi món.
		_place_order(customer)
		order_ = _orders.get(customer)
		if order_ == null:
			return

	customer.hide_order()
	order_.sit_at_table(table)
	order_.draining = drain_patience
	order_created.emit(order_)


## Ảnh 2D của một món, hoặc null nếu thiếu file.
##
## Nạp qua ResourceLoader.exists() chứ không load() thẳng: thiếu một ảnh thì
## chỉ mất cái hình trong bong bóng, còn cả màn chơi vẫn chạy. Ảnh món là thứ
## đang được vẽ dần, nên thiếu là chuyện bình thường trong lúc làm.
func _dish_icon(id: String) -> Texture2D:
	var icon_file := ItemCatalog.icon_path(id)
	if not ResourceLoader.exists(icon_file):
		push_warning("Bong bóng đơn: thiếu ảnh %s" % icon_file)
		return null
	return load(icon_file) as Texture2D


## Hết kiên nhẫn: cáu, bỏ đơn, ĐỢI DIỄN XONG rồi mới đi ra cửa.
##
## LỖI ĐÃ SỬA: bản trước gọi `beg()` rồi gọi `go_to()` ngay dòng sau, nên
## animation "angry" bị "walk" đè lên trong CÙNG một khung hình — người chơi
## không bao giờ thấy khách cáu. Hỏng lặng lẽ: không có lỗi nào báo, chỉ là
## một phản hồi quan trọng biến mất.
##
## Chỗ chờ đặt Ở ĐÂY chứ không trong customer.gd, đúng theo phân vai đã chốt:
## customer.gd chỉ biết ĐI và DIỄN, còn "cáu bao lâu rồi mới bỏ đi" là LUẬT nhà
## hàng. Bỏ luật vào customer.gd thì sau này muốn màn khó cho khách bỏ đi nhanh
## hơn lại phải sửa cả hai file.
##
## Hàm thành coroutine (có await) nhưng bên gọi trong _process KHÔNG await:
## nó chạy tới chỗ await rồi trả quyền về ngay, nên vòng đếm kiên nhẫn không
## bị khựng lại 2 giây. Đơn đã bị xoá khỏi `_don` TRƯỚC khi chờ, nên trong lúc
## chờ không có nguy cơ hàm này bị gọi lần hai cho cùng một người.
func _leave_angry(order_: Order) -> void:
	var customer: Node = order_.customer
	_orders.erase(customer)
	# (2/10/2026) Khách bỏ về lúc còn ĐỨNG XẾP HÀNG thì KHÔNG tính là mất
	# khách. Người chơi chưa được phép phục vụ họ — bàn còn kín — nên bắt chịu
	# phạt vì họ là phạt một việc không nằm trong tay mình. Chỉ khách ĐÃ NGỒI
	# BÀN mà không được món mới vào bộ đếm (bộ đếm này quyết định thua màn và
	# hiện trên bảng tổng kết).
	#
	# Họ vẫn bỏ đi thật, vẫn kêu, vé vẫn biến mất: mất một đơn hàng là đủ đau
	# rồi, chỉ là không cộng thêm vào giới hạn "khách bỏ về".
	#
	# Tiếng báo cũng chỉ kêu cho khách đã ngồi bàn: tiếng đó nghĩa là "bạn vừa
	# mất một khách", mà khách rời hàng chờ thì không còn tính như vậy nữa —
	# kêu lên là báo động giả, người chơi liếc HUD thấy bộ đếm không nhảy.
	if not bool(order_.in_queue):
		customers_lost += 1
		AmThanh.play_sfx("customer_out")
	order_finished.emit(order_, "left")
	if not is_instance_valid(customer):
		return

	# Nhả ô hàng đợi NGAY, đừng đợi tới lúc ra tới cửa.
	#
	# Không phải để hàng nhích nhanh hơn cho đẹp, mà để chặn một lỗi thật:
	# người vừa bỏ cuộc vẫn là _in_queue[0], nên hễ có bàn trống là _try_seat
	# lại gọi chính họ vào bàn — một người đã cáu bỏ đi bỗng quay lại ngồi
	# xuống và gọi món mới. Dòng meta này chỉ có ở người đang xếp hàng, nên
	# khách đang ngồi bàn không bị đụng tới.
	var slot: int = int(customer.get_meta("in_queue", -1))
	if slot >= 0 and slot < _in_queue.size() and _in_queue[slot] == customer:
		_in_queue[slot] = null
		customer.remove_meta("in_queue")
		_shift_queue()

	customer.hide_order()
	customer.beg()
	await get_tree().create_timer(beg_seconds).timeout

	# Kiểm tra lại sau khi chờ: 2 giây là cả một quãng đời trong game — đổi
	# màn, thoát ra menu hay dọn khách bằng tay đều có thể đã xoá node này.
	# Gọi vào node đã giải phóng là lỗi làm sập game.
	if not is_instance_valid(customer) or not customer.is_inside_tree():
		return
	if _door != null:
		customer.go_to(_door.global_position, "leave")


## Số tiền bay lên ở chỗ vừa phục vụ xong.
##
## Đặt trong không gian 3D chứ không ở góc HUD: phần thưởng phải hiện ra ĐÚNG
## CHỖ vừa xảy ra việc tốt, nếu không người chơi phải tự nối "tôi vừa làm gì"
## với "con số ở góc màn hình vừa nhảy". Ở góc còn có ví tiền nảy lên một cái
## nữa — hai phản hồi, một ngay tại chỗ, một ở nơi lưu tổng.
## TRỪ TIỀN một nguyên liệu vừa được lấy. Nối từ hands.ingredient_taken.
##
## Trừ NGAY LÚC LẤY chứ không lúc món bán được: người chơi phải thấy cái giá ở
## đúng khoảnh khắc họ quyết định, không phải ba mươi giây sau. Đây cũng là lý
## do đồ vứt vào thùng rác không được hoàn tiền — tiền đã đi rồi, cái kệ không
## phải cửa hàng nhận trả lại.
func charge_for_ingredient(id: String, at: Vector3) -> void:
	if free_ingredients:
		return
	var amount := ItemCatalog.cost(id)
	if amount <= 0:
		return
	money -= amount
	money_changed.emit(money, -amount, at)
	_money_popup(at, -amount, false)


## Số tiền bay lên chỗ vừa xảy ra chuyện. amount ÂM = vừa bị trừ.
func _money_popup(spot: Vector3, amount: int, is_perfect: bool) -> void:
	if _map == null:
		return
	var anchor := Node3D.new()
	anchor.position = spot + Vector3(0.0, 1.9, 0.0)
	_map.add_child(anchor)

	var icon: Sprite3D = null
	if ResourceLoader.exists(COIN_ICON):
		icon = Sprite3D.new()
		icon.texture = load(COIN_ICON)
		icon.pixel_size = 0.0022
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.position.x = -0.28
		anchor.add_child(icon)

	var text_ := Label3D.new()
	# Dấu và màu nói cùng một chuyện hai lần, cố ý: lúc cao điểm người chơi chỉ
	# liếc một phần mười giây, một tín hiệu dễ trượt.
	text_.text = ("+%d" % amount) if amount >= 0 else ("−%d" % absi(amount))
	text_.font_size = 128
	text_.pixel_size = 0.0028
	text_.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text_.no_depth_test = true
	text_.outline_size = 28
	if amount < 0:
		text_.modulate = Color("e08a7a")      # đỏ nhạt: vừa mất tiền
	else:
		text_.modulate = Color("ffd76a") if is_perfect else Color("d8f0c8")
	text_.position.x = 0.22
	anchor.add_child(text_)

	# Bay lên 0,9 đơn vị rồi mờ dần. Mờ CHẬM HƠN lúc bay: biến mất cùng lúc
	# với lúc dừng thì con số như bị cắt ngang, còn mờ nốt ở đỉnh thì mắt kịp
	# đọc xong rồi mới mất.
	var tw := create_tween().set_parallel(true)
	tw.tween_property(anchor, "position:y", anchor.position.y + 0.9, 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(text_, "modulate:a", 0.0, 0.5).set_delay(0.7)
	if icon != null:
		tw.tween_property(icon, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.finished.connect(anchor.queue_free)


## Đóng cửa: ngừng sinh khách và ngừng đếm kiên nhẫn.
##
## Gọi lúc hết giờ, TRƯỚC khi hiện bảng kết quả. Không có bước này thì trong
## lúc người chơi đang đọc bảng, đồng hồ kiên nhẫn vẫn chạy ngầm và con số
## "khách bỏ đi" trên bảng cứ tăng lên trước mắt họ.
##
## Không đụng tới người khách đang có mặt: họ cứ đứng đó cho tới khi đổi màn.
## Xoá sạch thì phía sau tấm bảng bỗng thành một cái quán trống trơn.
## Thực đơn thật của màn này (đã lọc món bị khoá). Cho kĩ năng đọc.
## Mọi đơn đang mở (cả khách xếp hàng lẫn khách đã ngồi). Bản sao — sửa
## mảng trả về không ảnh hưởng gì tới hệ khách.
func active_orders() -> Array:
	return _orders.values()


func menu_dishes() -> Array[String]:
	return _actual_menu()


## Cộng thẳng một khoản tiền vào ví, có báo cho HUD.
func add_money(amount: int, spot: Vector3 = Vector3.ZERO) -> void:
	money += amount
	money_changed.emit(money, amount, spot)


## Cho TOÀN BỘ khách biến mất ngay và đưa nhịp khách về như đầu màn.
## (Sakura Chiyono O — Ambition to Surpass the Sakura.)
##
## KHÔNG ai bị tính là "bỏ về": customers_lost đứng yên, không có tiếng báo mất
## khách. Người chơi tự bấm kĩ năng, phạt họ vì chính tác dụng của kĩ năng là
## vô lý.
##
## Khách ĐANG ĂN thì được trả tiền ngay: món đã giao xong, tiền đã chốt lúc
## giao (xem _on_dish_delivered), chỉ còn chờ họ ăn hết. Kĩ năng ghi "giữ
## nguyên số tiền đã kiếm" — nuốt mất khoản đó là trái với chính câu mô tả.
func clear_all_customers() -> void:
	for customer in _orders.keys():
		var order_: Order = _orders[customer]
		if order_.payout > 0 and not order_.draining and is_instance_valid(customer) \
				and customer.has_meta("dish"):
			add_money(order_.payout, customer.global_position)
		order_finished.emit(order_, "left")
	_orders.clear()

	# Bàn có khách đang ăn thì dọn món đi; bàn trống giữ nguyên thứ người chơi
	# đang để trên đó.
	for table in _customer_at.keys():
		if is_instance_valid(table):
			table.clear_all()
			table.clear_model()
	_customer_at.clear()
	_table_of.clear()
	for i in _in_queue.size():
		_in_queue[i] = null

	for k in get_tree().get_nodes_in_group(CUSTOMER_GROUP):
		customer_left.emit(k)
		k.queue_free()

	_spawn_timer = first_wait
	_orders_since_hard = 0


func close_shop() -> void:
	auto_spawn = false
	drain_patience = false
	for order_ in _orders.values():
		order_.draining = false
