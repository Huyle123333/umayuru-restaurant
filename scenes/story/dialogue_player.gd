extends Control
## Bộ máy hội thoại 1-chạm kiểu RPG Maker. Dùng chung cho prologue và mọi
## đoạn kể chuyện về sau — kịch bản nạp từ ngoài vào nên bộ máy không biết
## và không cần biết nội dung câu chuyện là gì.
##
## ------------------------------------------------------------- BA QUY TẮC
##
## 1. MỘT CÚ BẤM LÀM HAI VIỆC KHÁC NHAU tuỳ lúc:
##      - đang chạy chữ  -> hiện ngay hết câu
##      - chữ đã hiện đủ -> sang câu tiếp
##    Đây là chuẩn của thể loại (RPG Maker, Ren'Py, phần lớn visual novel).
##    Lý do: người đọc nhanh không bị bắt chờ máy gõ chữ, còn người đọc chậm
##    vẫn giữ được hiệu ứng gõ. Nếu chỉ có một hành vi thì luôn có một nửa
##    người chơi thấy khó chịu.
##
## 2. BẤM Ở ĐÂU CŨNG ĐƯỢC, không phải nhắm vào hộp thoại. Cả màn hình là
##    vùng bấm; chỉ nút "Bỏ qua" nằm đè lên trên mới cướp cú bấm về mình
##    (Godot đưa sự kiện cho node vẽ SAU CÙNG trước, nên chỉ cần đặt nút
##    ở dưới cùng trong cây scene là xong, không phải viết thêm code).
##
## 3. BÀN PHÍM LÀM ĐƯỢC MỌI THỨ CHUỘT LÀM. Space/Enter/E để tiếp, Esc để bỏ
##    qua. Cần cho hội đồng chấm: máy chiếu hay dùng bàn phím, và cũng là
##    một gạch đầu dòng về khả năng tiếp cận (accessibility) khi thuyết trình.

## Giá trị đặc biệt của khoá "speaker": lấy tên theo id nhân vật đang hiện ảnh.
const AUTO_NAME := "@"

## Kịch bản nạp LÚC CHẠY theo đường dẫn ở @export, không preload cứng.
##
## Vì sao đổi: cùng một bộ máy này giờ chạy hai đoạn kể khác nhau — prologue
## và màn ra mắt của Gold Ship — và sau này còn thêm nữa. preload cứng thì
## mỗi đoạn kể phải một bản sao script, tức là sửa lỗi ở bộ máy phải sửa
## nhiều chỗ. Nạp lúc chạy thì MỘT script, mỗi scene chỉ khác cái đường dẫn
## điền trong Inspector.

## Bảng ảnh chân dung: id trong kịch bản -> file ảnh.
##
## Vì sao dùng BẢNG TRA chứ không ghép chuỗi "res://.../%s.png":
##  1. Tên file thật không khớp id nhân vật. Id trong GameData là "kitamoi",
##     "chiyo"; file ảnh lại là "kita_avt.png", "chiyono_avt.png". Ghép chuỗi
##     thì buộc phải đổi tên một trong hai bên — mà id đã nằm trong file save
##     của người chơi, đổi id là hỏng save cũ.
##  2. Đuôi file không đồng nhất: nhân vật là .png có nền trong, còn ông
##     trainer là .jpg. Ghép chuỗi chỉ đoán được một đuôi.
##  3. Kịch bản có thể gọi cả những nhân vật KHÔNG chơi được (trainer, golshi)
##     — họ không có mặt trong GameData.CHARACTERS nên không có id để ghép.
## Thêm nhân vật mới cho đoạn kể chuyện = thêm một dòng ở đây.
const PORTRAITS := {
	# Các nhân vật có chân dung — id trùng với GameData.CHARACTERS.
	# hachimi và chiyo giữ lại dù đã thành nhân vật ẩn: về sau mở khoá xong
	# vẫn cần ảnh để họ nói chuyện được trong các đoạn kể.
	"kitamoi": "res://assets/ui/avatars/kita_avt.png",
	"hachimi": "res://assets/ui/avatars/hachimi_avt.png",
	"chiyo": "res://assets/ui/avatars/chiyono_avt.png",
	"mambo": "res://assets/ui/avatars/mambo_avt.png",
	# Hai người thế chỗ Teio và Chiyono O trong đội hình chính.
	"oui": "res://assets/ui/avatars/oui_avt.png",
	"tuandb": "res://assets/ui/avatars/tuandb_avt.png",
	# Nhân tố G. Không cần bản bóng đen nữa: Gold Ship đã bị gỡ khỏi cốt
	# truyện chính, nên đoạn kể duy nhất cô ấy xuất hiện (golshi_intro)
	# chỉ chạy khi ĐÃ mở khoá — không còn tình huống nào phải giấu mặt.
	"golshi": "res://assets/ui/avatars/golshi_avt.png",
	# Huấn luyện viên: hai biểu cảm, dùng cái nào tuỳ tình huống.
	"trainer": "res://assets/ui/avatars/trainer_avt1.png",
	"trainer2": "res://assets/ui/avatars/trainer_avt2.png",
}

## Tốc độ gõ chữ (ký tự mỗi giây).
##
## 45 là khoảng giữa: chậm hơn thì người đọc nhanh phát bực và bấm liên tục
## để nhảy cóc, nhanh hơn thì mất hẳn cảm giác "có người đang nói".
@export var type_speed: float = 45.0
## Thời gian tối/sáng khi đổi ảnh nền (giây, cho MỘT chiều).
@export var fade_time: float = 0.35

## Nhóm nhạc nền cho đoạn kể này, theo AmThanh.NHOM_NHAC. RỖNG = không đụng
## tới nhạc đang phát.
##
## Vì sao là tên NHÓM chứ không phải tên bài: đoạn cắt cảnh Gold Ship dùng
## chung script này nhưng chen vào GIỮA màn chơi — nó phải để yên bài nhạc
## màn đang chạy, nên ô này của nó để rỗng. Còn Prologue mở đầu game thì cần
## bài riêng. Cùng một script, hai hành vi, không có nhánh if nào.
##
## Dùng nhóm thay vì gõ thẳng "bgm2_ura": sau này muốn Prologue bốc ngẫu nhiên
## trong ba bài thì chỉ thêm tên vào nhóm "prologue" bên AmThanh.
@export var music_group: String = ""
## File kịch bản của đoạn kể này.
@export_file("*.gd") var cutscene_path: String = "res://scripts/story/cutscene_prologue.gd"

## Màn sẽ vào sau khi kể xong. ĐỂ TRỐNG nghĩa là "đi tiếp tới màn người chơi
## đang chọn dở" — đó là trường hợp của đoạn cắt cảnh chen giữa (Gold Ship
## đạp cửa), nó chỉ chèn vào giữa đường chứ không tự quyết định đi đâu.
@export var next_level: String = ""

## Đánh dấu màn nào đã hoàn thành khi kể xong. Để trống thì không đánh dấu gì.
## Prologue cần đánh dấu để Tutorial đủ điều kiện mở khoá theo luật "needs";
## đoạn cắt cảnh thì không, vì nó không phải một màn chơi.
@export var mark_completed: String = ""

## Scene sẽ chuyển tới khi kể xong, thay cho việc vào một màn chơi. Dùng cho
## màn KẾT: sau nó không còn màn nào để vào, nên phải nói rõ đi đâu (về màn
## chọn màn). Để trống thì giữ hành vi cũ — vào màn `next_level` / màn đang
## chọn dở.
@export_file("*.tscn") var next_scene: String = ""
## BIẾN THỂ của đoạn kể này, do scene đặt. Dòng kịch bản nào ghi
## "only_for_variant" khác giá trị này thì bị bỏ qua.
##
## Dùng cho màn kết: ending_normal.tscn và ending_secret.tscn trỏ CÙNG một
## file kịch bản, chỉ khác biến này. Đặt ở scene chứ không để kịch bản tự hỏi
## GameData "đang là kết nào": bộ máy hội thoại không cần biết luật mở kết ẩn,
## và muốn xem thử một biến thể thì chỉ việc mở đúng scene đó.
@export var variant: String = ""

## Cho phép bỏ qua (nút "Bỏ qua" và phím Esc). Tắt cho đoạn nào bắt buộc xem
## hết — hiện là hai đoạn của AAA Mode. Tắt thì kịch bản phải NGẮN: người chơi
## không có lối thoát, nên mỗi câu thừa là một câu họ bị ép đọc.
@export var skippable: bool = true

## Tự sang câu sau bao nhiêu giây kể từ lúc câu hiện tại gõ xong. 0 = tắt
## (phải bấm mới sang câu). Bấm chuột / phím vẫn tua nhanh như thường.
##
## Dùng cho đoạn không bỏ qua được (AAA Mode, đặt 5 giây): người chơi không
## có nút Bỏ qua, nên ít nhất đoạn kể phải tự chạy khi họ buông tay — không
## bắt ai ngồi bấm qua từng câu một.
##
## Đếm từ lúc GÕ XONG chứ không từ lúc câu bắt đầu: câu dài cần nhiều thời
## gian đọc hơn, đếm từ đầu thì câu dài nhất chỉ còn vài giây để đọc.
@export var auto_advance_seconds: float = 0.0
## Còn bao nhiêu giây thì tự sang câu. Âm = không đếm.
var _auto_left := -1.0

@onready var _background: TextureRect = %Background
@onready var _tint: ColorRect = %Tint
@onready var _portrait: TextureRect = %Portrait
## Khung xếp NHIỀU chân dung cạnh nhau, dùng cho câu đồng thanh.
##
## Một node riêng chứ không biến %Portrait thành container: 39 trong 41 câu của
## prologue chỉ có MỘT người nói, và %Portrait đang được canh sẵn ở góc trái với
## kích thước cố định. Đổi %Portrait thành container thì một chân dung sẽ bị căn
## giữa lại — tức là sửa một câu đặc biệt mà làm xê dịch bốn mươi câu bình
## thường. Hai node, mỗi node một việc, không câu nào ảnh hưởng câu nào.
@onready var _group_box: HBoxContainer = %GroupPortrait

## Chân dung trong khung nhóm không được cao hơn bấy nhiêu pixel.
const MAX_GROUP_HEIGHT := 620.0
@onready var _lbl_name: Label = %LblSpeaker
@onready var _lbl_line: RichTextLabel = %LblLine
@onready var _arrow: Label = %Arrow
@onready var _btn_skip: Button = %BtnSkip

## Nội dung kịch bản đã nạp.
var _scenes: Array = []
## Id nhân vật đang hiện ảnh, đã quy đổi hết mọi id đặc biệt.
##
## Phải NHỚ chứ không đọc lại từ câu hiện tại, vì khoá "portrait" là tuỳ chọn: một
## người nói liền mấy câu thì chỉ câu đầu ghi "portrait". Không nhớ thì từ câu thứ
## hai trở đi bộ máy hết biết ai đang nói và "speaker": "@" sẽ trống.
var _shown_id: String = ""
## Ai được bốc làm "người khác". Bốc MỘT LẦN rồi nhớ suốt đoạn kể — nếu bốc
## lại mỗi câu thì hai câu liền nhau của cùng một người lại ra hai khuôn mặt.
var _other_id: String = ""
var _index: int = -1
## Đang gõ chữ hay đã gõ xong — biến quyết định cú bấm tiếp theo làm gì.
var _typing: bool = false
var _revealed: float = 0.0
## Khoá nhập trong lúc chuyển cảnh, để bấm dồn không làm nhảy mất một câu.
var _fading: bool = false


func _ready() -> void:
	if not music_group.is_empty():
		AmThanh.play_random_music(music_group)
	_load_cutscene()
	_tint.color = Color(0, 0, 0, 1)
	_portrait.modulate.a = 0.0
	_group_box.modulate.a = 0.0
	_lbl_line.visible_characters = 0
	_btn_skip.pressed.connect(_skip)
	_btn_skip.visible = skippable

	# Mũi tên ▼ nhấp nháy báo "đọc xong rồi, bấm đi". Dùng tween lặp vô hạn
	# thay vì tự đếm thời gian trong _process: ít code hơn và không tốn gì
	# khi mũi tên đang ẩn.
	var blink := create_tween().set_loops()
	blink.tween_property(_arrow, "modulate:a", 0.15, 0.55)
	blink.tween_property(_arrow, "modulate:a", 1.0, 0.55)

	# Mở màn bằng một lần sáng dần từ đen, cho đỡ giật khi vừa đổi scene.
	var fade := create_tween()
	fade.tween_property(_tint, "color:a", 0.0, fade_time)
	await fade.finished
	_next_line()


## Nạp kịch bản. Hỏng file thì bỏ qua cả đoạn kể chứ KHÔNG treo game ở màn
## hình đen — người chơi vẫn vào được màn chơi, và console nói rõ file nào sai.
func _load_cutscene() -> void:
	var path := _cutscene_for_locale(cutscene_path)
	var cutscene := load(path) as GDScript
	if cutscene == null:
		push_error("Không nạp được kịch bản: %s" % path)
		return
	var v: Variant = cutscene.get("SCENES")
	if v is Array:
		_scenes = v
	else:
		push_error("Kịch bản %s thiếu hằng SCENES." % path)


## Chọn file kịch bản theo ngôn ngữ đang bật, theo quy ước tên file:
##     cutscene_prologue.gd     -> tiếng Việt (bản gốc, không hậu tố)
##     kich_ban_prologue_en.gd  -> tiếng Anh
##
## Vì sao hội thoại KHÔNG đi qua translations.csv như phần giao diện:
##  1. CSV là bảng một dòng một ô. Hội thoại là văn xuôi dài, có dấu phẩy,
##     dấu ngoặc kép, xuống dòng — nhét vào CSV thì vừa phải escape lắt nhắt
##     vừa không đọc nổi để mà biên tập lại lời thoại.
##  2. Kịch bản không chỉ có chữ: mỗi câu còn mang khoá "speaker"/"portrait"/"background".
##     Dịch xong vẫn phải giữ nguyên cấu trúc đó, nên giữ nguyên định dạng
##     mảng dữ liệu là cách rẻ nhất.
##  3. Người dịch làm việc trên FILE RIÊNG, không đụng vào bản tiếng Việt —
##     dịch sai cũng không làm hỏng bản gốc.
##
## Chưa có bản dịch thì rơi về bản gốc chứ không để màn hình trống: thiếu
## bản dịch là chuyện bình thường trong lúc làm dở, không phải lỗi chí mạng.
func _cutscene_for_locale(path: String) -> String:
	var lang := TranslationServer.get_locale().substr(0, 2)
	if lang == SettingsManager.DEFAULT_LANGUAGE:
		return path
	var translated := path.get_basename() + "_" + lang + ".gd"
	if ResourceLoader.exists(translated):
		return translated
	push_warning("Chưa có bản dịch '%s' — dùng tạm kịch bản gốc." % translated)
	return path


func _process(delta: float) -> void:
	if not _typing:
		if _auto_left > 0.0 and not _fading:
			_auto_left -= delta
			if _auto_left <= 0.0:
				_auto_left = -1.0
				_next_line()
		return
	_revealed += type_speed * delta
	_lbl_line.visible_characters = int(_revealed)
	if _lbl_line.visible_characters >= _lbl_line.get_total_character_count():
		_finish_typing()


# ----------------------------------------------------------------- nhập ---

## Chuột trái = một cú "chạm". TÊN HÀM PHẢI ĐÚNG LÀ `_gui_input`.
##
## Đây là HÀM ẢO của Control — engine tự gọi nó theo đúng cái tên này. Đổi tên
## thì không có lỗi, không có cảnh báo: engine chỉ đơn giản không tìm thấy hàm
## nào để gọi, và chuột im lặng mất tác dụng trong khi bàn phím vẫn chạy.
##
## Danh sách hàm ảo tuyệt đối không được đổi tên: _ready, _process,
## _physics_process, _input, _unhandled_input, _unhandled_key_input,
## _gui_input, _draw, _notification, _enter_tree, _exit_tree, _init.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_skip()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()


## Điểm vào duy nhất của mọi cú "chạm", dù từ chuột hay bàn phím.
## Gom về một hàm để hai đường nhập không bao giờ lệch hành vi nhau.
func _tap() -> void:
	if _fading:
		return
	if _typing:
		_finish_typing()
	else:
		_next_line()


func _finish_typing() -> void:
	_typing = false
	if auto_advance_seconds > 0.0:
		_auto_left = auto_advance_seconds
	_lbl_line.visible_characters = -1  # -1 = hiện tất cả
	_arrow.show()


# ----------------------------------------------------------- diễn kịch ---

## Chọn câu thoại của một dòng kịch bản. Thứ tự ưu tiên:
##   1. "line_by_player" — Dictionary {id nhân vật: câu}. Lấy câu của nhân vật
##      người chơi đang chọn.
##   2. "line_by_level"  — Dictionary {id màn: câu}. Lấy câu của màn sắp vào.
##   3. "line"           — câu mặc định, cũng là câu dự phòng khi hai bảng
##      trên không có mục cho nhân vật / màn hiện tại.
##
## Vì sao thêm hai khoá vào DỮ LIỆU thay vì viết bảy file kịch bản: đoạn hội ý
## trước mỗi ngày chỉ khác nhau ở câu nhận việc của người đứng bếp. Bảy file
## thì sửa một câu chung (lời trainer) là sửa bảy chỗ. Một file với câu riêng
## nằm ngay cạnh câu chung thì người viết thấy được cả bảy giọng cùng lúc.
func _pick_line(entry: Dictionary) -> String:
	var by_player: Dictionary = entry.get("line_by_player", {})
	var who := String(GameData.selected_character)
	if by_player.has(who):
		return String(by_player[who])
	var by_level: Dictionary = entry.get("line_by_level", {})
	var lvl := String(GameData.current_level)
	if by_level.has(lvl):
		return String(by_level[lvl])
	return String(entry.get("line", ""))

## Dòng này có bị BỎ QUA không. Ba loại điều kiện, dòng phải đạt CẢ BA:
##   "only_for_player"      — người chơi phải là một trong các id ghi trong mảng.
##   "only_for_variant"     — biến thể của scene (@export variant) phải trùng.
##   "only_for_hidden_cast" — tập nhân vật ẩn đã ra mắt phải khớp CHÍNH XÁC
##                            mảng này (cùng số người, cùng những người đó).
##
## Gom vào một hàm trả về bool thay vì ba khối if rải trong _next_line(): thêm
## loại điều kiện thứ tư chỉ là thêm một khối ở đây, và _next_line() vẫn chỉ
## có đúng một chỗ quyết định "chiếu hay bỏ".
func _should_skip(entry: Dictionary) -> bool:
	var only: Array = entry.get("only_for_player", [])
	if not only.is_empty() and not only.has(String(GameData.selected_character)):
		return true

	var only_variant := String(entry.get("only_for_variant", ""))
	if not only_variant.is_empty() and only_variant != variant:
		return true

	if entry.has("only_for_hidden_cast"):
		var wanted: Array = entry["only_for_hidden_cast"]
		var present := GameData.hidden_cast_seen()
		# So khớp TẬP HỢP: cùng cỡ và mọi phần tử đều có mặt. Không so hai
		# mảng bằng == vì khi đó thứ tự viết trong kịch bản cũng phải đúng.
		if wanted.size() != present.size():
			return true
		for id in wanted:
			if not present.has(String(id)):
				return true
	return false


func _next_line() -> void:
	# Bấm tay sang câu thì huỷ bộ đếm tự động của câu cũ.
	_auto_left = -1.0
	_index += 1
	if _index >= _scenes.size():
		_finish()
		return

	var entry: Dictionary = _scenes[_index]

	# Dòng có điều kiện mà không đạt thì bỏ qua, sang luôn dòng kế — không
	# tốn một lần bấm vào một câu trống.
	if _should_skip(entry):
		_next_line()
		return

	# "music": "off" cho nhạc nền im từ dòng này, "on" cho phát tiếp. Xét
	# TRƯỚC khi đổi nền: nhạc tắt cùng lúc màn hình bắt đầu tối, chứ không phải
	# tối xong rồi mới tắt — tắt trễ thì nghe như lỗi.
	if entry.has("music"):
		AmThanh.set_music_hushed(String(entry["music"]) == "off")

	if entry.has("background"):
		await _change_background(String(entry["background"]))

	if entry.has("portrait"):
		_change_portrait(entry["portrait"])

	var speaker := String(entry.get("speaker", ""))
	if speaker == AUTO_NAME:
		speaker = _display_name(_shown_id)
	# Dịch tên và câu thoại TRƯỚC khi gõ chữ: visible_characters đếm theo
	# chuỗi đã dịch, dịch sau thì hiệu ứng gõ chữ đếm sai độ dài.
	speaker = Lang.t(speaker)
	_lbl_name.text = speaker
	# Lời dẫn truyện không có người nói -> ẩn hẳn thẻ tên thay vì để một ô
	# trống. Ô trống làm hộp thoại nhảy lên nhảy xuống mỗi câu, rất khó chịu.
	_lbl_name.visible = not speaker.is_empty()

	_lbl_line.text = Lang.t(_pick_line(entry))
	_lbl_line.visible_characters = 0
	_revealed = 0.0
	_typing = true

	# (2/10/2026) ĐÃ BỎ tiếng "tick" phát ở đầu mỗi câu thoại, theo yêu cầu
	# user: hội thoại giờ chỉ có nhạc nền. Hàm AmThanh.play_type_tick() vẫn
	# còn bên audio_manager, muốn bật lại thì gọi nó ở đây khi `speaker`
	# không rỗng.
	_arrow.hide()


## Tên hiện trên thẻ tên ứng với một id nhân vật.
##
## LUÔN trả về tên riêng, kể cả với nhân vật người chơi đang điều khiển.
##
## Bản trước đổi tên người chơi thành "Bạn" để tránh cảnh một nhân vật vừa
## xưng "Bạn" vừa mang tên riêng trong cùng một đoạn. Nhưng cách đó đánh đổi
## quá đắt: người chơi không còn thấy nhân vật mình chọn CÓ TÊN trong cốt
## truyện, và mọi câu thoại phải viết sao cho vừa hợp ngôi thứ nhất vừa hợp
## ngôi thứ ba. Các game nhập vai có nhân vật chọn được (Fire Emblem,
## Persona, Octopath) đều gọi thẳng tên riêng và xử lý mạch lạc bằng cách
## VIẾT KỊCH BẢN cho khéo — không ai gọi nhân vật chính là "Bạn".
##
## Đổi lại, kịch bản phải giữ một luật: câu nào mà người nói không thể là
## chính người chơi (khen chính mình, chỉ trích chính mình) thì dùng
## "portrait": "other" để bốc người khác. Luật đó nằm ở tầng dữ liệu, đúng chỗ của
## nó — bộ máy không phải đoán ngôi xưng hộ người viết truyện nữa.
func _display_name(id: String) -> String:
	if id.is_empty():
		return ""
	return String(GameData.CHARACTERS.get(id, {}).get("label", id))


func _change_background(path: String) -> void:
	_fading = true
	var tex := load(path) as Texture2D
	# Tối dần -> đổi ảnh -> sáng lại. Đổi thẳng thì hình nhảy phựt một cái,
	# nhìn như lỗi chứ không như chuyển cảnh.
	var tween := create_tween()
	tween.tween_property(_tint, "color:a", 1.0, fade_time)
	await tween.finished
	if tex != null:
		_background.texture = tex
	var tween2 := create_tween()
	tween2.tween_property(_tint, "color:a", 0.0, fade_time)
	await tween2.finished
	_fading = false


## Quy đổi các id đặc biệt trong kịch bản thành id nhân vật thật.
##
## "player" — nhân vật người chơi đã chọn. Nhờ quy ước này mà kịch bản viết
##            MỘT lần dùng được cho cả bốn nhân vật, không phải chép ra bốn
##            bản chỉ khác mỗi cái ảnh.
## "other"   — BẤT KỲ AI TRỪ người chơi. Cần cho những câu mà nội dung không
##            cho phép người nói là chính mình: câu khen "cậu nấu ngon nhất
##            team" mà người chơi chọn Kitasan thì thành Kitasan tự khen
##            mình. Đây là loại lỗi không bao giờ lộ ra khi thử một lượt —
##            phải chơi đúng nhân vật đó mới thấy — nên để kịch bản tự tránh
##            bằng cách viết cứng tên là không đủ an toàn.
func _resolve_id(id: String) -> String:
	if id == "player":
		return GameData.selected_character
	if id == "other":
		return _other_speaker()
	return id


## Bốc một nhân vật chơi được, khác người chơi, và có sẵn ảnh chân dung.
func _other_speaker() -> String:
	if not _other_id.is_empty():
		return _other_id
	var candidates: Array[String] = []
	for k in GameData.CHARACTER_ORDER:
		var id := str(k)
		if id == GameData.selected_character:
			continue
		# Bỏ qua nhân vật đang khoá: Gold Ship không có mặt trong cốt truyện
		# chính, để cô ấy chen vào một câu thoại bình thường là hỏng cả ý đồ
		# giấu nhân vật.
		if GameData.is_character_locked(id):
			continue
		if not PORTRAITS.has(id):
			continue
		candidates.append(id)
	if candidates.is_empty():
		# Không còn ai khác — chỉ xảy ra nếu sau này chỉ còn một nhân vật
		# chơi được. Thà hiện chính người chơi còn hơn mất cả câu thoại.
		push_warning("Không tìm được nhân vật nào khác người chơi.")
		return GameData.selected_character
	_other_id = candidates.pick_random()
	return _other_id


## Đổi chân dung đang hiện.
##
## Nhận MỘT id (chuỗi) như cũ, hoặc MỘT MẢNG id cho câu đồng thanh. Cho phép
## cả hai kiểu chứ không bắt kịch bản lúc nào cũng viết mảng: gần như mọi câu
## chỉ có một người nói, ["kitamoi"] dài dòng hơn "kitamoi" mà chẳng rõ hơn.
func _change_portrait(value: Variant) -> void:
	var list: Array = value if value is Array else [value]
	# Giải id TRƯỚC rồi mới lọc: "player" và "other" chỉ tới lúc chạy mới biết
	# là ai, mà "other" còn có thể trùng với một id đã ghi thẳng trong mảng.
	var actual: Array[String] = []
	for x in list:
		var id := _resolve_id(String(x))
		if id.is_empty() or actual.has(id):
			continue
		if not PORTRAITS.has(id):
			# Gõ sai id thì chỉ bỏ qua ảnh đó chứ KHÔNG dừng đoạn kể. Kịch bản
			# là dữ liệu do người viết truyện gõ tay, sai một id không đáng để
			# cả game đứng lại — nhưng vẫn phải kêu lên console để còn biết mà
			# sửa.
			push_warning("Kịch bản gọi id nhân vật không có trong PORTRAITS: '%s'" % id)
			continue
		var path := String(PORTRAITS[id])
		if not ResourceLoader.exists(path):
			push_warning("Thiếu file ảnh: %s" % path)
			continue
		actual.append(id)

	# Câu đồng thanh không có MỘT người nói, nên "speaker": "@" phải ra chuỗi rỗng
	# (thẻ tên tự ẩn) thay vì chọn bừa một trong mấy người đang hiện mặt.
	_shown_id = actual[0] if actual.size() == 1 else ""

	if actual.is_empty():
		_hide_portrait()
		return

	if actual.size() == 1:
		_reveal_gradually(_group_box, false)
		_portrait.texture = load(String(PORTRAITS[actual[0]]))
		_reveal_gradually(_portrait, true)
		return

	_reveal_gradually(_portrait, false)
	_build_group(actual)
	_reveal_gradually(_group_box, true)


## Dựng lại dãy chân dung của câu đồng thanh.
##
## remove_child + free() chứ không queue_free(): queue_free chỉ xoá ở CUỐI
## khung hình, nên ảnh của câu trước vẫn còn trong hàng khi ảnh mới được thêm
## vào — hai câu đồng thanh liền nhau sẽ thấy tám khuôn mặt trong một khung.
func _build_group(list: Array[String]) -> void:
	for child in _group_box.get_children():
		_group_box.remove_child(child)
		child.free()
	_align_group_bottom(list.size())
	for id in list:
		var cell := TextureRect.new()
		cell.texture = load(String(PORTRAITS[id]))
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_group_box.add_child(cell)


## Kéo MÉP TRÊN của khung nhóm lên đúng bằng bề ngang một ảnh.
##
## Chân dung là ảnh VUÔNG (512×512) và vẽ bằng KEEP_ASPECT_CENTERED, nên nó
## chỉ cao đúng bằng bề ngang ô chứa nó. Khung cao hơn thế thì phần dư chia
## đều trên–dưới, và cái nửa dư phía DƯỚI đẩy ảnh lên lơ lửng giữa không khí,
## để lộ nguyên đường cắt ngang ngực. Ảnh đơn không bị vì khung của nó vừa
## khít sẵn.
##
## Tính chứ không gõ cứng một con số: bề ngang mỗi ảnh phụ thuộc SỐ ẢNH (bốn
## người thì mỗi ảnh 445 px, hai người thì 910 px), nên một con số cố định chỉ
## đúng cho đúng một trường hợp.
##
## Mép DƯỚI thì giữ nguyên ở -210, cùng mốc với ảnh đơn: đáy ảnh nằm thấp hơn
## nóc hộp thoại vài chục pixel nên đường cắt bị hộp che đi.
func _align_group_bottom(count: int) -> void:
	if count <= 0:
		return
	var gap := float(_group_box.get_theme_constant("separation"))
	# Khung neo trái 0 / phải 1, nên bề ngang = rộng màn hình trừ hai lề.
	var width := get_viewport_rect().size.x + _group_box.offset_right - _group_box.offset_left
	var new_width := (width - gap * (count - 1)) / float(count)
	# Chặn trên để hai người không thành hai bức chân dung cao quá đầu.
	_group_box.offset_top = _group_box.offset_bottom - minf(new_width, MAX_GROUP_HEIGHT)


func _hide_portrait() -> void:
	_reveal_gradually(_portrait, false)
	_reveal_gradually(_group_box, false)


## Mờ dần vào/ra.
##
## Ẩn bằng ALPHA chứ không tắt visible. Bản đầu có tắt: `await` cho tween mờ
## hết rồi mới `visible = false`. Nhưng như thế là gài sẵn một lỗi — cái lệnh
## tắt đó chạy TRỄ 0,2 giây so với lúc gọi, nên nếu trong quãng đó có câu mới
## bật cùng node lên thì lệnh tắt cũ vẫn nổ và làm biến mất bức ảnh vừa hiện.
## Loại lỗi chỉ lộ ra khi bấm nhanh, tức là gần như không bao giờ lộ lúc mình
## tự thử.
##
## Bỏ hẳn phần tắt thì không còn trạng thái nào để lệch: node cứ nằm đó với
## alpha 0. Không tốn gì cả — nó neo tuyệt đối chứ không nằm trong container
## nên chẳng chiếm chỗ của ai, và mouse_filter đã đặt IGNORE nên không chắn
## cú bấm nào.
func _reveal_gradually(btn: CanvasItem, show_it: bool) -> void:
	btn.visible = true
	var tween := create_tween()
	tween.tween_property(btn, "modulate:a", 1.0 if show_it else 0.0, 0.25 if show_it else 0.2)


# --------------------------------------------------------------- kết thúc ---

func _skip() -> void:
	if _fading or not skippable:
		return
	_finish()


## Lưới an toàn thứ hai cho nhạc: scene bị đổi bằng đường KHÔNG qua _finish()
## (ví dụ thoát ra menu giữa chừng) thì vẫn trả nhạc lại.
func _exit_tree() -> void:
	AmThanh.set_music_hushed(false)


func _finish() -> void:
	_fading = true
	_typing = false
	# Trả nhạc lại dù đoạn kể kết thúc ở đâu. Nút Bỏ qua cũng đi qua đây: bấm
	# bỏ qua giữa cảnh im lặng mà không có dòng này thì nhạc im luôn tới hết
	# phiên chơi, vì dòng "music": "on" trong kịch bản không bao giờ được chạy.
	AmThanh.set_music_hushed(false)
	var tween := create_tween()
	tween.tween_property(_tint, "color:a", 1.0, fade_time)
	await tween.finished

	# Đánh dấu đã xem xong thì màn kế mới đủ điều kiện mở khoá theo đúng luật
	# "needs" trong GameData.LEVELS — không phá lệ, không đi cửa sau.
	if not mark_completed.is_empty():
		GameData.complete_level(mark_completed)
	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)
		return
	if not next_level.is_empty():
		GameData.current_level = next_level

	var path := GameData.enter_level(GameData.current_level)
	if path.is_empty():
		push_error("Màn '%s' chưa khai báo scene trong GameData.LEVELS." % GameData.current_level)
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		return
	get_tree().change_scene_to_file(path)
