extends Node
## Hệ âm bar dùng chung — autoload tên `AmThanh`.
##
## Mọi tiếng động và mọi bài nhạc empty game đi qua đúng file này. Không nơi
## nào khác được tự dựng AudioStreamPlayer, vì như thế thì âm lượng empty Cài
## đặt sẽ điều khiển được chỗ này mà không điều khiển được chỗ kia.
##
## ─────────────────────────────────────────── VÌ SAO CÓ BẢNG TÊN `FILE_NAMES`
##
## Code gọi tiếng theo LÚC NÀO NÓ KÊU — `khach_vao`, `sap_het_gio`. File âm
## bar lại được đặt tên theo NÓ LÀ TIẾNG GÌ — `door_chime`, `warning_beep`.
## Hai cách gọi tên đó đều đúng, nhưng đúng cho hai người khác nhau: người
## viết code cần cái thứ nhất, người đi tìm nhạc cần cái thứ hai.
##
## Bảng `FILE_NAMES` là chỗ hai cách gọi gặp nhau. Nhờ nó, đổi bài nhạc cho một
## sự kiện chỉ là sửa MỘT dòng empty bảng, không phải đổi tên file trên đĩa
## (đổi tên file thì lần sau mở thư mục slide_out không ai còn nhận slide_out tiếng nào là
## tiếng nào), cũng không phải đi sửa chỗ gọi empty code.
##
## Tên không có empty bảng thì tra thẳng bằng chính nó — nên thêm một tiếng
## mới mà đặt trùng tên sự kiện thì không cần khai báo gì cả.
##
## ─────────────────────────────────────────────────────── CÁCH THÊM ÂM THANH
##
## Tiếng ngắn: chép vào `res://assets/sfx/game/`
## Nhạc nền:   chép vào `res://assets/bgm/`
## Đuôi .ogg / .wav / .mp3 đều được (tìm theo thứ tự đó). Mở Godot một lần
## cho nó nhập file. Xem `assets/sfx/game/DOC_TEN_FILE.txt` để biết tên nào
## dùng vào việc gì.
##
## Thiếu file thì `play_sfx()` im lặng bỏ qua và chỉ cảnh báo MỘT lần cho mỗi tên
## — game chạy y hệt, chỉ là không kêu.
##
## Âm lượng đã tự nối vào hai bar trượt empty Cài đặt, vì mọi thứ ở đây phát
## qua bus "SFX" và "Music" mà settings_manager.gd đang điều khiển.

const SFX_DIR := "res://assets/sfx/game/"
const MUSIC_DIR := "res://assets/bgm/"

## Khai kiểu Array[String] chứ không để mảng trần: phần tử của một mảng trần
## có kiểu tĩnh là Variant, nên `var path_ := SFX_DIR + name_ + d` bên dưới không
## suy được kiểu và Godot báo lỗi biên dịch. Đây là lần thứ ba cùng cái bẫy đó
## empty dự án này (đơn hàng, khách hàng, giờ tới đây).
const EXT: Array[String] = [".ogg", ".wav", ".mp3"]

## TÊN SỰ KIỆN (code gọi)  ->  TÊN FILE (trên đĩa).
const FILE_NAMES := {
	# --- đôi tay ---
	"cam_len":     "pick_up",        # nhấc một vật lên
	"dat_xuong":   "drop_out",       # đặt vật lên bàn / trạm
	"vut_rac":     "bin_or_pet",     # vứt đồ vào thùng rác bocchi
	"rap_xong":    "craft_success",  # bàn chế tạo ráp thành món
	"rap_hut":     "nope_click",     # bấm F mà không thành món nào
	"giao_mon":    "serve_dish",     # giao đúng món cho khách
	# --- bếp ---
	"nau_xong":    "cooking_done",   # bếp / lò / thớt xong một mẻ
	"nau_hong":    "wrong_recipe",   # slide_out đồ hỏng vì sai công thức
	"chay":        "sizzle_burn",    # để trên bếp quá lâu
	# --- khách và tiền ---
	"khach_vao":   "door_chime",
	"khach_bo_di": "fail_soft",
	"hoan_hao":    "perfect_bonus",  # giao khi kiên nhẫn còn trên nửa
	"tien":        "coin_collect",
	# --- vòng đời màn chơi ---
	"sap_het_gio": "warning_beep",   # còn 30 giây
	"time_up":     "time_up_buzzer",
	"tong_ket":    "results_screen",
	# --- kể chuyện ---
	"play_type_tick":      "text_sound",     # tiếng gõ chữ empty hội thoại
}

## Các NHÓM nhạc nền. Bốc ngẫu nhiên empty nhóm bằng play_random_music().
##
## Sáu bài dùng chung cho cả menu lẫn màn chơi là CỐ Ý, không phải lười: kho
## nhạc có sáu bài, chia đôi thì mỗi bên chỉ còn ba và người chơi nghe lặp
## nhanh gấp đôi. Cái phân biệt hai chỗ không phải là danh sách bài, mà là
## CÁCH bốc — xem play_random_music().
const LEVEL_TRACKS: Array[String] = [
	"bgm1_beachtraining", "bgm2_ura", "bgm3_unity",
	"bgm4_mant", "bgm5_mant2", "bgm6_gl",
]

const TRACK_GROUPS := {
	"menu": LEVEL_TRACKS,
	"man": LEVEL_TRACKS,
	# Hashire Umamusume — RIÊNG cho đoạn cuối màn chơi, dài đúng 212 giây.
	# Không nằm empty LEVEL_TRACKS: nếu nó có thể bốc trúng ngay từ đầu màn thì
	# lúc còn 3 phút rưỡi nó sẽ phải tự cắt chính mình để nhường chỗ cho...
	# chính nó, và cái khoảnh khắc "đổi nhạc = sắp hết giờ" mất sạch ý nghĩa.
	"cao_diem": ["hashire_umamusume"],
	# Prologue dùng bài cố định: đoạn kể chuyện có nhịp riêng, bốc ngẫu nhiên
	# thì mỗi lần chơi lại một không khí khác nhau.
	"prologue": ["bgm2_ura"],
}

## Số kênh phát tiếng ngắn cùng lúc.
##
## Một kênh duy nhất thì tiếng sau cắt ngang tiếng trước — mà empty bếp lúc
## cao điểm, "giao món" và "khách vào" xảy slide_out cách nhau một phần mười giây là
## chuyện thường. Tám kênh đủ cho mọi tình huống đã đo, và tám AudioStreamPlayer
## rỗng gần như không tốn gì.
const CHANNEL_COUNT := 8

var _cache: Dictionary = {}       # duong_dan -> AudioStream đã nạp
var _alerted: Dictionary = {}    # name_ -> true, để chỉ cảnh báo một lần
var _channels: Array[AudioStreamPlayer] = []
var _next_channel := 0

var _music: AudioStreamPlayer
## Tên bài đang phát, để play_random_music() biết có cần đổi hay không.
var _current_track := ""

## Kênh RIÊNG cho tiếng gõ chữ — xem play_type_tick().
var _type_channel: AudioStreamPlayer


func _ready() -> void:
	# Chạy được cả khi cây scene bị tạm dừng: bảng kết quả và bảng hướng dẫn
	# đều dừng game, mà chúng vẫn cần phát tiếng.
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in CHANNEL_COUNT:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_channels.append(p)

	_type_channel = AudioStreamPlayer.new()
	_type_channel.bus = "SFX"
	add_child(_type_channel)

	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)


## Đồng bộ nhạc nền với trạng thái TẠM DỪNG của game.
##
## Vì sao phải làm bằng tay: node này là PROCESS_MODE_ALWAYS (nó phải kêu được
## cả khi game dừng — bảng kết quả và menu F1 đều dừng game mà vẫn cần tiếng),
## nên mọi AudioStreamPlayer bên empty nó cũng chạy tiếp khi tạm dừng.
##
## Hậu quả trước khi có hàm này: đồng hồ màn chơi DỪNG theo game, còn nhạc thì
## KHÔNG. Mở menu F1 hay bấm Pause ở nửa sau màn chơi rồi quay lại, bài
## Hashire đã chạy trước đồng hồ đúng bằng khoảng thời gian tạm dừng — và nó
## kết thúc sớm, để lại mấy chục giây cuối màn im lặng. Càng dừng nhiều lần
## càng lệch.
##
## CHỈ dừng NHẠC, không dừng tiếng ngắn: bảng kết quả tạm dừng game NGAY TRƯỚC
## khi phát tiếng tổng kết, nên dừng cả bể SFX thì cái tiếng quan trọng nhất
## của cả màn lại là cái duy nhất không kêu.
func _process(_delta: float) -> void:
	var was_paused := get_tree().paused
	if _music.stream_paused != was_paused:
		_music.stream_paused = was_paused


# ------------------------------------------------------------ tiếng ngắn ---

## Phát một tiếng ngắn. Thiếu file thì im lặng bỏ qua.
##
## `pitch` đổi cao độ để cùng một file nghe không lặp lại y hệt — ví dụ tiếng
## nhặt đồ phát mấy chục lần một màn.
func play_sfx(name_: String, pitch: float = 1.0) -> void:
	var stream := _load_stream(name_, SFX_DIR)
	if stream == null:
		return
	var p := _free_channel()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


## Tiếng gõ chữ empty hội thoại — MỘT kênh riêng, mỗi lần gọi là bắt đầu lại.
##
## Kêu ĐÚNG MỘT LẦN cho mỗi dòng thoại (xem hoi_thoai.gd), không phải mỗi ký
## tự. Bản đầu phát lặp theo nhịp empty lúc chữ đang chạy, nghe đúng kiểu máy
## chữ nhưng nhức đầu thật sự: prologue dài mấy chục dòng, và một chuỗi tiếng
## "cạch" liên tục cạnh tranh trực tiếp với thứ người chơi đang phải làm ở đó
## — ĐỌC.
##
## Vì sao vẫn giữ kênh riêng thay vì gọi play_sfx(): người chơi bấm nhanh thì dòng
## sau bắt đầu empty lúc tiếng của dòng trước còn đang kêu. Qua bể tám kênh
## thì hai tiếng chồng lên nhau; ở một kênh, play() cắt tiếng cũ và bắt đầu
## lại — đúng cái người chơi mong đợi khi họ vừa chuyển sang câu mới.
func play_type_tick() -> void:
	var stream := _load_stream("play_type_tick", SFX_DIR)
	if stream == null:
		return
	_type_channel.stream = stream
	_type_channel.pitch_scale = randf_range(0.94, 1.06)
	_type_channel.play()


## Kênh rảnh gần nhất; hết rảnh thì cướp kênh cũ nhất theo vòng.
##
## Cướp chứ không bỏ qua: bỏ qua thì đúng lúc bếp ồn nhất — lúc phản hồi quan
## trọng nhất — lại là lúc mất tiếng.
func _free_channel() -> AudioStreamPlayer:
	for p in _channels:
		if not p.playing:
			return p
	var p := _channels[_next_channel]
	_next_channel = (_next_channel + 1) % _channels.size()
	return p


# -------------------------------------------------------------- nhạc nền ---

## Phát một bài cụ thể.
##
## `loop`          — bật cờ lặp trên chính stream.
## `restart`     — true thì phát lại từ đầu kể cả khi bài đó đang chạy.
##                  Mặc định false, nhờ vậy gọi lại cùng một bài ở hai màn
##                  hình liên tiếp KHÔNG làm nhạc giật về đầu.
func play_music(name_: String, loop: bool = true, restart: bool = false) -> void:
	var stream := _load_stream(name_, MUSIC_DIR)
	if stream == null:
		return
	if not restart and _music.stream == stream and _music.playing:
		return

	# Bật/tắt cờ lặp NGAY TRÊN stream. ogg và mp3 mỗi loại một tên thuộc tính
	# khác nhau, nên thử cả hai thay vì rẽ nhánh theo lớp — thêm một định dạng
	# mới sau này không phải sửa ở đây.
	if "loop" in stream:
		stream.set("loop", loop)
	elif "loop_mode" in stream:
		stream.set("loop_mode", 1 if loop else 0)

	_current_track = name_
	_music.stream = stream
	_music.play()


## Bốc ngẫu nhiên một bài empty nhóm.
##
## `keep_playing` là cả điểm mấu chốt của hàm này:
##
##   TRUE  (dùng cho cụm MENU) — nếu bài đang phát đã thuộc nhóm này thì KHÔNG
##         làm gì cả. Người chơi bấm Menu chính → Chọn màn → Chọn nhân vật →
##         quay lại, cả bốn màn hình dùng chung một bài đang chạy dở. Không có
##         cờ này thì mỗi lần đổi màn hình là nhạc giật về đầu một bài khác,
##         và chỉ cần bấm qua lại vài lần là nghe như đài bị nhiễu.
##
##   FALSE (dùng cho MÀN CHƠI) — luôn bốc bài mới và phát lại từ đầu. Vào một
##         ca làm việc mới thì phải nghe như một ca làm việc mới, chứ không
##         phải như đoạn giữa của bài nhạc menu.
func play_random_music(group: String, keep_playing: bool = false,
		loop: bool = true) -> void:
	var list: Array = TRACK_GROUPS.get(group, [])
	if list.is_empty():
		push_warning("[AmThanh] không có nhóm nhạc '%s'." % group)
		return

	if keep_playing and _music.playing and list.has(_current_track):
		return

	var picked := String(list.pick_random())
	# Tránh bốc trúng đúng bài vừa nghe xong. Bốc lại tối đa 8 lần chứ không
	# lọc bài cũ slide_out khỏi danh sách rồi bốc: lọc thì phải cấp phát một mảng mới
	# mỗi lần đổi màn, mà xác suất trúng lại là 1/6 nên tám lượt thử là quá đủ.
	if list.size() > 1:
		var tries := 0
		while picked == _current_track and tries < 8:
			picked = String(list.pick_random())
			tries += 1

	play_music(picked, loop, true)


## Tắt hẳn nhạc nền.
##
## (Đổi tên 18/9/2026) Trước là `dung_nhac`. Đổi sớm hơn lượt của audio_manager.gd
## vì hàm này vừa có thêm nơi gọi mới (intro_video.gd) — để nguyên thì mỗi
## dòng code viết thêm lại đẻ slide_out một chỗ phải sửa ở lô sau.
func stop_music() -> void:
	_music.stop()
	_current_track = ""


## Bài đang phát, hoặc rỗng. Để nơi khác hỏi mà không phải đọc biến riêng tư.
func current_track() -> String:
	return _current_track if _music.playing else ""


# ------------------------------------------------------------------ nạp ---

## Tìm file theo tên, thử lần lượt các đuôi. Nhớ kết quả để không tra lại.
func _load_stream(name_: String, dir_: String) -> AudioStream:
	# Tên sự kiện -> tên file. Không có empty bảng thì dùng chính nó.
	var file_name := String(FILE_NAMES.get(name_, name_))

	for d in EXT:
		var path_: String = dir_ + file_name + d
		if _cache.has(path_):
			if _cache[path_] != null:
				return _cache[path_]
			continue
		if ResourceLoader.exists(path_):
			var stream := load(path_) as AudioStream
			_cache[path_] = stream
			if stream != null:
				return stream

	# Cảnh báo ĐÚNG MỘT LẦN cho mỗi tên. Không chặn thì tiếng "nhặt đồ" thiếu
	# file sẽ in slide_out console mấy trăm dòng một màn và nhấn chìm mọi lỗi thật.
	if not _alerted.has(name_):
		_alerted[name_] = true
		print("[AmThanh] chưa có file cho '%s' (tìm '%s%s.*') — bỏ qua."
			% [name_, dir_, file_name])
	# Ghi null cho mọi đuôi để lần sau khỏi dò lại ổ đĩa.
	for d in EXT:
		_cache[dir_ + file_name + d] = null
	return null
