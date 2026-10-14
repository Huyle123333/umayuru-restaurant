extends Control
## Màn hình chọn nhân vật: một HÀNG NGANG thẻ ở trên, bảng thông tin ở dưới.
##
## Trước đây hàng thẻ xòe theo cung tròn kiểu quạt bài. Bỏ vì cung tròn kéo
## theo cả một chuỗi rắc rối hình học không đáng: lá đã xoay thì góc thấp nhất
## của nó thò xuống thêm (rộng/2)·sin(góc) so với tâm đáy, nên tính chiều cao
## khung bao nhiêu cũng hụt, và bề ngang thật của quạt lớn hơn hẳn bề ngang
## hàng thẻ. Hàng ngang thì chiều cao khung đúng bằng chiều cao lá, không có
## trường hợp biên nào cả — và phần diện tích tiết kiệm được đem cho bảng info.
##
## Rê chuột vào lá nào thì lá đó nhấc lên. Bấm vào lá thì lá nhấc cao hơn,
## phát tiếng nhân vật, và bảng thông tin hiện lên.
## Lá khóa vẫn bấm xem được thông tin, nhưng nút Chơi không sáng.

const CARD_SIZE := Vector2(200.0, 267.0)

const HOVER_RISE := 30.0
const SELECT_RISE := 48.0

## Thứ tự lớp vẽ. Bảng thông tin PHẢI nằm trên mọi lá bài.
##
## Godot vẽ theo z_index; cùng z_index thì node nào đứng sau trong cây được vẽ
## đè lên. InfoPanel để z_index = 300 trong scene, nên mọi con số ở đây phải
## nhỏ hơn 300 — trước đây lá đang chọn để 400 nên nó trồi lên che mất góc
## bảng, đúng thứ người chơi nhìn thấy là "thẻ đè lên bảng info".
##
## Ba mức chứ không phải hai: lá đang rê chuột phải nổi trên các lá còn lại,
## nhưng lá ĐANG CHỌN vẫn phải nổi trên cả lá đang rê, nếu không thì rê chuột
## qua lá bên cạnh sẽ che mất lá mình vừa chọn.
const Z_HOVER := 100
const Z_SELECT := 200

const DIM := Color(0.58, 0.56, 0.58, 1.0)

## Map dùng khi màn đang chọn CHƯA khai báo map riêng trong GameData.LEVELS
## — ví dụ bấm "Chơi mới" từ menu chính, lúc đó chưa chọn màn nào cả.
@export_file("*.tscn") var gameplay_scene: String = "res://restaurant_map_planb.tscn"
@export_file("*.tscn") var back_scene: String = "res://scenes/menu/level_select.tscn"

@onready var _hand: Control = %Hand
@onready var _catcher: Control = %ClickCatcher
@onready var _panel: Control = %InfoPanel

@onready var _lbl_name: Label = %LblName
@onready var _lbl_tagline: Label = %LblTagline
@onready var _lbl_intro: Label = %LblIntro
@onready var _lbl_secrets: Label = %LblSecrets
@onready var _lbl_hint: Label = %LblHint
## Hai bảng SỐ ĐO / HỒ SƠ không có sẵn hàng nào trong scene — mỗi hàng do
## _dung_bang() sinh ra lúc chạy. Xem giải thích ở hàm đó.
@onready var _grid_measure: GridContainer = %GridMeasure
@onready var _grid_profile: GridContainer = %GridProfile
## Ba ô kỹ năng bên phải. Ô 0 là chủ động, ô 1–2 là bị động.
## Gom thành mảng để _fill_panel chỉ cần một vòng lặp, thêm ô thứ tư sau này
## chỉ là thêm node vào scene rồi thêm một dòng ở đây.
@onready var _skill_names: Array[Label] = [%LblSkill1, %LblSkill2, %LblSkill3]
@onready var _skill_descs: Array[Label] = [
	%LblSkillDesc1, %LblSkillDesc2, %LblSkillDesc3,
]
@onready var _skill_icons: Array[TextureRect] = [%Img1, %Img2, %Img3]
@onready var _size_buttons: Array[Button] = [%BtnSize1, %BtnSize2, %BtnSize3]

@onready var _btn_prev: TextureButton = %BtnPrev
@onready var _btn_next: TextureButton = %BtnNext
@onready var _btn_play: Button = %BtnPlay
@onready var _btn_back: Button = %BtnBack
@onready var _sfx: AudioStreamPlayer = %Sfx

var _cards: Dictionary = {}
## Vị trí và góc nghiêng gốc của từng lá khi nằm yên trong tay bài.
var _base_pos: Dictionary = {}
var _base_rot: Dictionary = {}
var _selected := ""


func _ready() -> void:
	# Nhạc menu: bốc ngẫu nhiên MỘT lần cho cả cụm menu.
	#
	# keep_playing = true nghĩa là nếu bài đang phát đã thuộc nhóm "menu" thì
	# không đổi gì cả. Người chơi bấm Menu chính → Chọn màn → Chọn nhân vật →
	# quay lại, cả bốn màn hình dùng chung một bài đang chạy dở. Bốc lại ở mỗi
	# màn hình thì chỉ cần bấm qua lại vài lần là nhạc giật liên tục.
	AmThanh.play_random_music("menu", true)

	var index := 0
	for key in GameData.CHARACTER_ORDER:
		var id := str(key)
		var card := _hand.get_child(index) as Control
		_cards[id] = card
		_fill_card(card, id)

		var btn := card.get_node("Btn") as TextureButton
		btn.pressed.connect(_on_card_pressed.bind(id))
		btn.mouse_entered.connect(_on_card_hover.bind(id, true))
		btn.mouse_exited.connect(_on_card_hover.bind(id, false))
		index += 1

	# Lớp phủ nằm DƯỚI tay bài trong cây scene, nên chỉ nhận được cú bấm khi
	# người chơi bấm trượt ra ngoài mọi lá.
	_catcher.gui_input.connect(_on_catcher_input)

	for i in _size_buttons.size():
		_size_buttons[i].pressed.connect(_on_size_pressed.bind(i))

	_btn_prev.pressed.connect(_step.bind(-1))
	_btn_next.pressed.connect(_step.bind(1))
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

	# Kích thước của Hand chỉ biết được sau khi container xếp xong.
	_hand.resized.connect(_layout_hand)
	_layout_hand()

	_panel.visible = false
	_btn_play.disabled = true



## Vẽ một lá bài trong tay quạt.
##
## Lá bài giờ CHỈ có ảnh. Tên và câu mô tả trước kia in đè lên ảnh đã bỏ hẳn:
## chữ nằm trên ảnh nhân vật thì hoặc che mất mặt, hoặc phải viền dày mới đọc
## được, mà trong quạt bài các lá chồng mép nên tên lá này lại bị lá kia che.
## Hai thông tin đó giờ nằm ở đầu bảng info (LblName + LblTagline) — một chỗ
## duy nhất, chữ to, không ai che ai.
##
## Ảnh lấy qua GameData.anh_the() chứ KHÔNG ghép thẳng đường dẫn từ id: hàm
## đó mới là chỗ biết nhân vật nào đang bị giấu và trả về file ảnh bóng đen
## riêng. Ghép tay thì mọi cơ chế giấu nhân vật thành vô nghĩa. (Phần chữ đã
## che nằm ở _fill_panel, qua GameData.thong_tin_the().)
func _fill_card(card: Control, id: String) -> void:
	var btn := card.get_node("Btn") as TextureButton
	btn.texture_normal = load(GameData.card_image(id))
	# Lá khóa vẫn bấm được để xem thông tin — chỉ nút Chơi là không sáng.
	btn.disabled = false


# --------------------------------------------------------------- tay bài ---

## Xếp các lá thành một hàng ngang, chia đều bề ngang khung.
##
## Bước nhảy tính từ bề ngang khung chứ không phải một hằng số: (rộng - rộng
## một lá) / (số lá - 1) luôn cho lá đầu chạm mép trái và lá cuối chạm mép
## phải, dù thêm hay bớt nhân vật. Bước nhảy nhỏ hơn bề ngang lá thì các lá
## chồng mép nhau — đó là chủ ý, và z_index = i lo phần lá phải đè lên lá trái.
func _layout_hand() -> void:
	var order: Array = GameData.CHARACTER_ORDER
	var card_count: int = order.size()
	var step_x: float = 0.0
	if card_count > 1:
		step_x = (_hand.size.x - CARD_SIZE.x) / float(card_count - 1)
	# Chừa sẵn khoảng nhấc lên ở phía trên, để lá đang chọn không bị cắt ngọn.
	var bottom := _hand.size.y - CARD_SIZE.y

	for i in card_count:
		var id := str(order[i])
		if not _cards.has(id):
			continue
		var card: Control = _cards[id]

		card.size = CARD_SIZE
		card.pivot_offset = CARD_SIZE * 0.5

		var pos := Vector2(step_x * i, bottom)
		_base_pos[id] = pos
		# Giữ lại _base_rot dù hàng ngang không nghiêng lá nào: _animate_card
		# vẫn nhận một góc đích, để sau này muốn thêm hiệu ứng nghiêng nhẹ lúc
		# rê chuột thì chỉ sửa một chỗ.
		_base_rot[id] = 0.0

		card.position = pos
		card.rotation_degrees = 0.0
		# Lá bên phải đè lên lá bên trái, đúng kiểu xòe bài trên tay.
		card.z_index = i


# ------------------------------------------------------------- tương tác ---

func _on_card_hover(id: String, entered: bool) -> void:
	if id == _selected:
		return
	_animate_card(id, HOVER_RISE if entered else 0.0, float(_base_rot[id]),
		Z_HOVER if entered else -1)


func _on_card_pressed(id: String) -> void:
	if id == _selected:
		return
	var previous := _selected
	_selected = id

	var locked := GameData.is_character_locked(id)
	if locked:
		# Xem được thông tin nhưng không chọn để chơi.
		GameData.selected_character = ""
	else:
		GameData.set_selected_character(id)
		_play_voice(id)

	if not previous.is_empty():
		_animate_card(previous, 0.0, float(_base_rot[previous]), -1)
	# Lá được chọn dựng thẳng và nhấc cao nhất trong tay bài — nhưng vẫn nằm
	# DƯỚI bảng thông tin, xem Z_SELECT.
	_animate_card(id, SELECT_RISE, 0.0, Z_SELECT)
	_dim_others()
	_fill_panel(id)
	_open_panel()
	_btn_play.disabled = locked


func _on_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_deselect()


func _step(delta: int) -> void:
	var order: Array = GameData.CHARACTER_ORDER
	var from := order.find(_selected)
	if from == -1:
		from = -1 if delta > 0 else 0
	_on_card_pressed(str(order[wrapi(from + delta, 0, order.size())]))


func _deselect() -> void:
	if _selected.is_empty():
		return
	var previous := _selected
	_selected = ""
	GameData.selected_character = ""
	_animate_card(previous, 0.0, float(_base_rot[previous]), -1)
	_dim_others()
	_btn_play.disabled = true
	_close_panel()


func _dim_others() -> void:
	for key in _cards:
		var id := str(key)
		var chosen: bool = (id == _selected)
		var target := Color.WHITE if chosen or _selected.is_empty() else DIM
		var tw := create_tween()
		tw.tween_property(_cards[id], "modulate", target, 0.14)
		(_cards[id].get_node("Selection") as Control).visible = chosen


## rise: nhấc lên bao nhiêu pixel. angle: góc nghiêng đích.
## layer: z_index mới, -1 nghĩa là trả về thứ tự gốc trong tay bài.
func _animate_card(id: String, rise: float, angle: float, layer: int) -> void:
	var card: Control = _cards[id]
	card.z_index = layer if layer >= 0 else GameData.CHARACTER_ORDER.find(id)

	var home: Vector2 = _base_pos[id]
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "position", home - Vector2(0.0, rise), 0.18)
	tw.tween_property(card, "rotation_degrees", angle, 0.18)


# ----------------------------------------------------- bảng thông tin ---

func _fill_panel(id: String) -> void:
	# Cùng lý do với _fill_card: phải qua thong_tin_the() thì nhân vật đang
	# giấu mới hiện dấu hỏi thay vì tên, tiểu sử và tên kỹ năng thật.
	var info: Dictionary = GameData.card_info(id)
	_lbl_name.text = str(info["label"])
	_lbl_tagline.text = str(info.get("tagline", ""))
	_lbl_intro.text = str(info.get("intro", ""))
	_build_table(_grid_measure, info.get("measure", {}))
	_build_table(_grid_profile, info.get("profile", {}))
	_fill_skills(info)

	# Mỗi bí mật một dòng. Dùng dấu đầu dòng "・" (kiểu Nhật) cho khớp với
	# trang gốc, và nối bằng \n chứ không tạo mỗi dòng một Label: số lượng bí
	# mật mỗi nhân vật một khác, một Label autowrap gánh được hết.
	var secrets: Array = info.get("secrets", [])
	var lines: PackedStringArray = []
	for v in secrets:
		lines.append("・%s" % Lang.t(str(v)))
	_lbl_secrets.text = "\n".join(lines)

	# Dòng gợi ý chỉ dành cho nhân vật chưa mở khóa.
	var hint := str(info.get("hint", ""))
	_lbl_hint.visible = GameData.is_character_locked(id)
	_lbl_hint.text = hint if not hint.is_empty() else Lang.t("Gợi ý: sẽ cập nhật sau")

	# Số đo 3 vòng luôn bị che lại mỗi lần đổi nhân vật.
	var sizes: Array = info.get("sizes", ["", "", ""])
	for i in _size_buttons.size():
		var btn := _size_buttons[i]
		btn.set_meta("value", str(sizes[i]) if i < sizes.size() else "")
		btn.set_pressed_no_signal(false)
		btn.text = ""


## Dựng lại một bảng NHÃN / GIÁ TRỊ từ Dictionary trong GameData.
##
## Vì sao sinh node lúc chạy thay vì đặt sẵn các hàng trong scene: mỗi nhân
## vật có thể có số mục khác nhau, và danh sách mục còn đổi trong quá trình
## làm. Đặt sẵn thì phải chọn số hàng lớn nhất rồi ẩn bớt — hàng ẩn vẫn nằm
## đó, sửa nhãn phải mở scene sửa từng node, và thêm mục thứ sáu là phải nhớ
## sửa cả hai chỗ. Sinh lúc chạy thì scene chỉ giữ đúng cái khung, còn nội
## dung nằm gọn một chỗ duy nhất là bảng CHARACTERS.
##
## remove_child + free() chứ không queue_free(): queue_free chỉ xóa ở CUỐI
## khung hình, nên các hàng cũ vẫn còn trong cây khi hàng mới được thêm vào —
## đổi nhân vật liên tục sẽ thấy bảng dài gấp đôi trong đúng một khung hình.
func _build_table(grid: GridContainer, table: Dictionary) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	for key in table:
		grid.add_child(_table_cell(str(key), true))
		grid.add_child(_table_cell(str(table[key]), false))


## Bề ngang tối thiểu của ô GIÁ TRỊ. Đây là con số đã làm nổ bảng info.
##
## Một Label bật autowrap tính CHIỀU CAO tối thiểu của nó theo BỀ NGANG mà nó
## được cấp. Ở lượt dựng bố cục đầu tiên bề ngang đó chưa có (bằng 0), nên
## Godot coi như mỗi chữ phải xuống một dòng: dòng "Tính cả học trò của bố thì
## nhà cô có ba mươi người" thành 11 dòng cao ~240 px thay vì 2 dòng cao 44 px.
## Năm ô như thế cộng lại đẩy chiều cao tối thiểu của cả bảng lên hàng nghìn
## pixel — đo được lúc chạy là 5396 px trong khi con số đúng là 514.
##
## Đặt bề ngang tối thiểu thì Godot có cái để tính chiều cao ngay từ lượt đầu,
## không còn lượt nào bị phồng. Đây là lỗi kinh điển của autowrap trong
## container, và cách chữa luôn là cho nó một bề ngang, không phải chỉnh cao.
const VALUE_COL_WIDTH := 300.0


## Một ô trong bảng NHÃN / GIÁ TRỊ. nhan = true là cột trái (chữ nâu, rộng cố
## định để hai cột thẳng hàng), false là cột phải (chữ sáng, tự xuống dòng).
func _table_cell(text: String, highlight: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	if highlight:
		lbl.custom_minimum_size = Vector2(104.0, 0.0)
		lbl.add_theme_color_override("font_color", Color(0.827, 0.639, 0.408))
	else:
		lbl.custom_minimum_size = Vector2(VALUE_COL_WIDTH, 0.0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.969, 0.929, 0.871))
	return lbl


## Cấp độ được ghép thẳng vào chuỗi tên chứ không tách ra một Label riêng:
## một kỹ năng chưa có cấp (level = 0) thì không có gì để hiện, mà một Label
## rỗng vẫn chiếm chỗ và làm hàng chữ lệch.
func _fill_skills(info: Dictionary) -> void:
	var skills: Array = info.get("skills", [])
	for i in _skill_names.size():
		var slot: Dictionary = skills[i] if i < skills.size() else {}
		var skill_name := str(slot.get("name", ""))
		var level := int(slot.get("level", 0))

		if skill_name.is_empty():
			# Ô chưa có kỹ năng — gạch ngang cho biết ô vẫn tồn tại.
			_skill_names[i].text = "—"
		elif level > 0:
			_skill_names[i].text = "%s   Lv%d" % [Lang.t(skill_name), level]
		else:
			_skill_names[i].text = skill_name

		_skill_descs[i].text = str(slot.get("desc", ""))
		_set_skill_icon(i, str(slot.get("icon", "")))


## Nạp ảnh minh họa cho một ô kỹ năng.
##
## icon_name là TÊN FILE KHÔNG CÓ ĐUÔI — đuôi .png do hàm này tự thêm. Ghi
## "abc.png" trong CHARACTERS sẽ thành "abc.png.png" và không tìm thấy gì.
##
## ResourceLoader.exists() phải kiểm tra TRƯỚC khi load: thiếu ảnh là chuyện
## bình thường lúc đang làm dở, mà load thẳng một file không có sẽ đổ lỗi đỏ
## ra Output mỗi lần đổi nhân vật.
func _set_skill_icon(index: int, icon_name: String) -> void:
	var rect := _skill_icons[index]
	if icon_name.is_empty():
		rect.texture = null
		return
	# CÙNG thư mục với ảnh kĩ năng trên HUD trong màn chơi.
	#
	# Trước đây bảng chọn nhân vật đọc từ assets/ui/skills/ còn HUD đọc từ
	# assets/ui/ki_nang/ — hai quy ước cho đúng một thứ. Hậu quả: bỏ ảnh vào
	# một thư mục thì chỗ kia không thấy, mà không có lỗi nào chỉ ra vì sao.
	# Gộp về một thư mục thì một file phục vụ cả hai chỗ.
	var path := "res://assets/ui/ki_nang/%s.png" % icon_name
	if not ResourceLoader.exists(path):
		push_warning("Thiếu ảnh kỹ năng: %s" % path)
		rect.texture = null
		return
	rect.texture = load(path)


func _on_size_pressed(index: int) -> void:
	# Bấm vào ô đen để lộ số đo, bấm lần nữa che lại.
	var btn := _size_buttons[index]
	var value := str(btn.get_meta("value", ""))
	btn.text = (value if not value.is_empty() else "--") if btn.button_pressed else ""


## Mở bảng thông tin.
##
## CHỈ mờ dần, KHÔNG trượt lên. Bản cũ có tween chạy `position` của bảng, và
## đó là lỗi làm bảng phình to rồi lệch ra ngoài màn hình.
##
## Lý do: InfoPanel neo kín khung cha (anchor 0,0 → 1,1). Với một Control như
## thế, hình chữ nhật thật KHÔNG phải thứ mình gán vào `position` — mỗi lượt
## dựng bố cục Godot tính lại từ neo cộng offset, rồi ép ra ít nhất bằng kích
## thước tối thiểu, và vì grow đặt là BOTH nên nó nới đều SANG HAI BÊN, ghi
## ngược lại vào offset. Gán `position` sửa offset, lượt sau lại sinh offset
## mới từ hình chữ nhật đã dời — cứ thế mỗi lượt lại to thêm. Đo lúc chạy:
## bảng 3128 × 780 px, góc trái ở x = -604, trong khi cỡ tối thiểu chỉ có
## 1508 × 514 và khung cha rộng đúng 1620.
##
## Muốn giữ hiệu ứng trượt thì phải bọc thêm một Control trung gian KHÔNG neo
## rồi trượt cái đó. Không đáng: hiệu ứng mờ dần đã đủ, mà đổi lại là bỏ hẳn
## một lớp có thể hỏng.
func _open_panel() -> void:
	if _panel.visible:
		return
	_panel.visible = true
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _close_panel() -> void:
	if not _panel.visible:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.14)
	await tw.finished
	if _selected.is_empty():
		_panel.visible = false


func _play_voice(id: String) -> void:
	var path := "res://assets/sfx/select/%s.mp3" % id
	if not ResourceLoader.exists(path):
		return
	_sfx.stream = load(path)
	_sfx.play()


# ----------------------------------------------------------- điều hướng ---

func _on_play_pressed() -> void:
	if _selected.is_empty() or GameData.is_character_locked(_selected):
		return
	# GameData.vao_man() chứ KHÔNG phải duong_dan_scene().
	#
	# Hai hàm trả về gần giống nhau, nhưng vao_man() còn xét xem có phải chen
	# một đoạn cắt cảnh ra mắt nhân vật ẩn vào trước hay không. Gọi nhầm sang
	# duong_dan_scene() thì mọi đoạn ra mắt đều bị bỏ qua LẶNG LẼ — không lỗi,
	# không cảnh báo, chỉ là cắt cảnh không bao giờ hiện.
	#
	# Đó đúng là lỗi đã xảy ra: phép kiểm tra được gom về vao_man() để mọi
	# đường vào màn đi qua một chỗ, nhưng riêng chỗ gọi này thì quên đổi. Kết
	# quả là chỉ prologue chiếu được cắt cảnh (hoi_thoai.gd gọi đúng hàm), còn
	# bấm Chơi từ màn chọn nhân vật thì không bao giờ.
	var scene := GameData.enter_level(GameData.current_level)
	if scene.is_empty():
		scene = gameplay_scene
	get_tree().change_scene_to_file(scene)


func _on_back_pressed() -> void:
	var target := GameData.return_scene
	get_tree().change_scene_to_file(target if not target.is_empty() else back_scene)
