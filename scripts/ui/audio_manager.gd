extends Node
## ─────────────────────────────────────────── VÌ SAO CÓ BẢNG TÊN `FILE_NAMES`
## ─────────────────────────────────────────────────────── CÁCH THÊM ÂM THANH

const SFX_DIR := "res://assets/sfx/game/"
const MUSIC_DIR := "res://assets/bgm/"

## Khai kiểu Array[String] chứ không để mảng trần: phần tử của một mảng trần
const EXT: Array[String] = [".ogg", ".wav", ".mp3"]

## TÊN SỰ KIỆN (code gọi)  ->  TÊN FILE (trên đĩa).
const FILE_NAMES := {
	# --- đôi tay ---
	"pick_up":       "pick_up",
	"put_down":      "drop_out",
	"trash":         "bin_or_pet",
	"doro":          "doro_voice",
	"craft_ok":      "craft_success",
	"craft_fail":    "nope_click",
	"serve":         "serve_dish",
	# --- bếp ---
	"cook_done":     "cooking_done",
	"cook_fail":     "wrong_recipe",
	"burn":          "sizzle_burn",
	# --- khách và tiền ---
	"customer_in":   "door_chime",
	"customer_out":  "fail_soft",
	"perfect":       "perfect_bonus",
	"coin":          "coin_collect",
	# --- vòng đời màn chơi ---
	"time_warning":  "warning_beep",
	"time_up":       "time_up_buzzer",
	"results":       "results_screen",
	# --- vượt mốc hạng giữa màn (HUD) — mỗi hạng một câu reo riêng ---
	"rank_d":        "rank_d",
	"rank_c":        "rank_c",
	"rank_b":        "rank_b",
	"rank_a":        "rank_a",
	"rank_s":        "rank_s",
	# --- kể chuyện ---
	"type_tick":     "text_sound",
}

## Các NHÓM nhạc nền. Bốc ngẫu nhiên trong nhóm bằng play_random_music().
const LEVEL_TRACKS: Array[String] = [
	"bgm1_beachtraining", "bgm2_ura", "bgm3_unity",
	"bgm4_mant", "bgm5_mant2", "bgm6_gl", "bgm7_umasamba",
]

## Nhạc TRONG MÀN CHƠI = sáu bài trên + Hashire Umamusume (21/10/2026).
const GAMEPLAY_TRACKS: Array[String] = [
	"bgm1_beachtraining", "bgm2_ura", "bgm3_unity",
	"bgm4_mant", "bgm5_mant2", "bgm6_gl",
	"hashire_umamusume", "bgm7_umasamba",
]

const TRACK_GROUPS := {
	"menu": LEVEL_TRACKS,
	"level": GAMEPLAY_TRACKS,
	"prologue": ["bgm2_ura"],
	"ending": ["bgm1_beachtraining"],
}

## Số kênh phát tiếng ngắn cùng lúc.
const CHANNEL_COUNT := 8

var _cache: Dictionary = {}
var _alerted: Dictionary = {}
var _channels: Array[AudioStreamPlayer] = []
var _next_channel := 0

var _music: AudioStreamPlayer
## Tên bài đang phát, để play_random_music() biết có cần đổi hay không.
var _current_track := ""

## Kênh RIÊNG cho tiếng gõ chữ — xem play_type_tick().
var _type_channel: AudioStreamPlayer


func _ready() -> void:
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
func _process(_delta: float) -> void:
	var was_paused := get_tree().paused or _hushed
	if _music.stream_paused != was_paused:
		_music.stream_paused = was_paused


# ------------------------------------------------------------ tiếng ngắn ---

## Phát một tiếng ngắn. Thiếu file thì im lặng bỏ qua.
func play_sfx(name_: String, pitch: float = 1.0) -> void:
	var stream := _load_stream(name_, SFX_DIR)
	if stream == null:
		return
	var p := _free_channel()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


## Tiếng gõ chữ trong hội thoại — MỘT kênh riêng, mỗi lần gọi là bắt đầu lại.
func play_type_tick() -> void:
	var stream := _load_stream("type_tick", SFX_DIR)
	if stream == null:
		return
	_type_channel.stream = stream
	_type_channel.pitch_scale = randf_range(0.94, 1.06)
	_type_channel.play()


## Kênh rảnh gần nhất; hết rảnh thì cướp kênh cũ nhất theo vòng.
func _free_channel() -> AudioStreamPlayer:
	for p in _channels:
		if not p.playing:
			return p
	var p := _channels[_next_channel]
	_next_channel = (_next_channel + 1) % _channels.size()
	return p


# -------------------------------------------------------------- nhạc nền ---

## Phát một bài cụ thể.
func play_music(name_: String, loop: bool = true, restart: bool = false) -> void:
	var stream := _load_stream(name_, MUSIC_DIR)
	if stream == null:
		return
	if not restart and _music.stream == stream and _music.playing:
		return

	if "loop" in stream:
		stream.set("loop", loop)
	elif "loop_mode" in stream:
		stream.set("loop_mode", 1 if loop else 0)

	_current_track = name_
	_music.stream = stream
	_music.play()


## Bốc ngẫu nhiên một bài trong nhóm.
func play_random_music(group: String, keep_playing: bool = false,
		loop: bool = true) -> void:
	var list: Array = TRACK_GROUPS.get(group, [])
	if list.is_empty():
		push_warning("[AmThanh] không có nhóm nhạc '%s'." % group)
		return

	if keep_playing and _music.playing and list.has(_current_track):
		return

	var picked := String(list.pick_random())
	if list.size() > 1:
		var tries := 0
		while picked == _current_track and tries < 8:
			picked = String(list.pick_random())
			tries += 1

	play_music(picked, loop, true)


## Cho nhạc nền IM tạm thời (true) rồi phát tiếp (false).
var _hushed := false

func set_music_hushed(value: bool) -> void:
	_hushed = value


## Tắt hẳn nhạc nền.
func stop_all_sfx() -> void:
	for p in _channels:
		p.stop()
	_type_channel.stop()


func stop_music() -> void:
	_music.stop()
	_current_track = ""


## Bài đang phát, hoặc rỗng. Để nơi khác hỏi mà không phải đọc biến riêng tư.
func current_track() -> String:
	return _current_track if _music.playing else ""


# ------------------------------------------------------------------ nạp ---

## Tìm file theo tên, thử lần lượt các đuôi. Nhớ kết quả để không tra lại.
func _load_stream(name_: String, dir_: String) -> AudioStream:
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

	if not _alerted.has(name_):
		_alerted[name_] = true
		print("[AmThanh] chưa có file cho '%s' (tìm '%s%s.*') — bỏ qua."
			% [name_, dir_, file_name])
	for d in EXT:
		_cache[dir_ + file_name + d] = null
	return null
