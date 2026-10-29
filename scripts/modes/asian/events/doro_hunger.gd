extends RefCounted
## ASIAN MODE: CƠN ĐÓI CỦA DORO (luật đã chốt từ bản thiết kế, mục 3.4).
##
## Mỗi 70–120 giây Doro đói: kêu, hiện chữ "ĐÓI!" kèm đếm ngược 15 giây trên
## đầu. Cho Doro ăn BẤT KỲ món hoàn chỉnh nào (món có giá) là hết đói — tức mỗi
## cơn đói tốn một món lẽ ra bán được.
## Hết 15 giây chưa cho ăn: Doro đuổi TOÀN BỘ khách đang có (ngồi bàn lẫn xếp
## hàng), mỗi khách 1 mạng (đã chốt). Có từ 3 khách trở lên là thua ngay.
##
## Cho ăn đi qua đúng đường "vứt vào Doro" có sẵn (hands.item_discarded), nên
## không phải thêm thao tác mới.

const ItemCatalog := preload("res://scripts/interaction/item_catalog.gd")
const SECONDS := 15.0

var _d: Node
var _doro: Node3D
var _left := SECONDS
var _label: Label3D
## Doro kêu LIÊN TỤC suốt lúc đói (user yêu cầu 29/10/2026): người chơi đang
## cắm mặt trong bếp vẫn nghe được là có chuyện, không cần nhìn chữ trên đầu.
## Nhịp 1,3 giây ≈ độ dài tiếng kêu (1,07 s) + một quãng nghỉ ngắn.
const CRY_EVERY := 1.3
var _cry_in := 0.0


func start(director: Node) -> void:
	_d = director
	_doro = director._level.get_node_or_null("Doro")
	if _doro == null or director._hands == null:
		director.finish("doro_hunger")
		return
	_label = Label3D.new()
	_label.font_size = 96
	_label.pixel_size = 0.004
	_label.modulate = Color(1.0, 0.35, 0.3)
	_label.outline_size = 20
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position = Vector3(0, 1.4, 0)
	_doro.add_child(_label)
	director._hands.item_discarded.connect(_on_discarded)
	AmThanh.play_sfx("time_warning")


func _on_discarded(id: String, station: Node) -> void:
	if station != _doro:
		return
	if ItemCatalog.price(id) > 0:
		_d.finish("doro_hunger")


func tick(delta: float) -> void:
	if _label == null:
		return
	_left -= delta
	_cry_in -= delta
	if _cry_in <= 0.0:
		_cry_in = CRY_EVERY
		# Cao độ nhích lên dần khi sắp hết giờ: càng gần lúc đuổi khách càng gấp.
		AmThanh.play_sfx("doro", 1.0 + 0.2 * (1.0 - clampf(_left / SECONDS, 0.0, 1.0)))
	_label.text = Lang.t("ĐÓI!  %d") % ceili(maxf(_left, 0.0))
	if _left > 0.0:
		return
	# Doro đuổi hết khách: mỗi khách đang có mặt mất 1 mạng.
	var cm: Node = _d._customers
	var count := int(cm._orders.size())
	cm.clear_all_customers()
	var asian: Node = _d.get_parent()
	asian.lives -= count
	asian._draw_lives(true)
	if asian.lives <= 0:
		asian.lose(Lang.t("Thua: Doro đói nên đuổi hết khách."))
	_d.finish("doro_hunger")


func stop(director: Node) -> void:
	if director._hands != null and director._hands.item_discarded.is_connected(_on_discarded):
		director._hands.item_discarded.disconnect(_on_discarded)
	if _label != null and is_instance_valid(_label):
		_label.queue_free()
	_label = null
