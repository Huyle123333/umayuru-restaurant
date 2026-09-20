extends Control
## Màn intro chiếu trước khi vào menu chính.
##
## ------------------------------------------------------- VÌ SAO PHẢI .OGV
## Godot KHÔNG phát được MP4. Engine chỉ nhúng sẵn bộ giải mã Ogg Theora
## (.ogv) vì H.264/H.265 dính bằng sáng chế — nhúng vào thì mọi game làm
## bằng Godot đều phải trả phí bản quyền. Nên file mp4 gốc phải chuyển sang
## .ogv trước khi đưa vào project. Đây là hạn chế của engine, không phải
## lựa chọn thiết kế; nói được câu này khi hội đồng hỏi "sao không dùng mp4"
## là đủ.
##
## ---------------------------------------------------------- BA NGUYÊN TẮC
## 1. LUÔN CÓ ĐƯỜNG THOÁT. Bấm phím hay chuột bất kỳ là bỏ qua — cùng quy
##    ước với hộp thoại ở dialogue_player.gd, để cả game chỉ có MỘT thói quen cho
##    người chơi học. Lúc demo trước hội đồng cũng đỡ phải ngồi chờ hết
##    video mới vào được menu.
## 2. HỎNG VIDEO KHÔNG ĐƯỢC TREO GAME. Thiếu file, sai định dạng, hay chưa
##    import — mọi trường hợp đều đi thẳng vào menu và ghi lỗi ra console.
##    Màn hình đen vĩnh viễn là lỗi tệ nhất có thể có ở scene khởi động, vì
##    người chơi không có cách nào thoát ra.
## 3. CHỈ ĐỔI SCENE ĐÚNG MỘT LẦN. Video kết thúc và người chơi bấm bỏ qua
##    có thể xảy ra gần như cùng lúc; không chốt cờ thì gọi
##    change_scene_to_file() hai lần, Godot cảnh báo và cảnh có thể nhấp nháy.

## File video. Để ở @export chứ không preload cứng: đổi intro sau này chỉ
## cần kéo file mới vào ô này trong Inspector, không phải sửa code.
@export_file("*.ogv") var video_path: String = "res://assets/video/intro.ogv"

## Menu sẽ vào sau khi chiếu xong.
@export_file("*.tscn") var next_scene: String = "res://scenes/menu/main_menu.tscn"

## Chặn bỏ qua trong khoảng đầu (giây). Chống việc người chơi đang bấm chuột
## dở từ màn trước làm mất luôn intro ngay khi nó vừa hiện ra.
@export var skip_lock_seconds: float = 0.4

@onready var _video: VideoStreamPlayer = %Video

var _switched := false
var _skip_allowed := false


func _ready() -> void:
	# Intro không có gì để tạm dừng, nhưng đặt ALWAYS cho chắc: nếu sau này
	# có ai bật pause trước khi scene này chạy xong thì video vẫn chạy tiếp
	# chứ không đứng hình vĩnh viễn.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var stream := load(video_path) as VideoStream
	if stream == null:
		push_error("Không nạp được video intro: %s — vào thẳng menu." % video_path)
		_go_next()
		return

	# TẮT NHẠC NỀN trước khi chiếu.
	#
	# Scene này dùng cho HAI chỗ: intro lúc mở game (chưa có nhạc nào chạy —
	# gọi vào đây là vô hại) và đoạn video dẫn vào Prologue (lúc đó nhạc menu
	# ĐANG chạy). Không tắt thì nhạc menu đè lên tiếng của chính đoạn phim,
	# và người xem nghe hai bản nhạc cùng lúc.
	#
	# Tắt ở ĐÂY chứ không ở scene gọi tới: bất kỳ ai chiếu video sau này cũng
	# được xử lý đúng mà không phải nhớ thêm một bước.
	if get_node_or_null("/root/AmThanh") != null:
		AmThanh.stop_music()

	_video.stream = stream
	_video.finished.connect(_go_next)
	_video.play()

	# Godot không báo lỗi ngay khi play() thất bại, nên kiểm lại ở khung hình
	# sau: đã gọi play() mà vẫn không chạy thì coi như hỏng và đi tiếp.
	await get_tree().process_frame
	if not _video.is_playing():
		push_error("Video intro không phát được (%s) — vào thẳng menu." % video_path)
		_go_next()
		return

	await get_tree().create_timer(skip_lock_seconds).timeout
	_skip_allowed = true


## _input chứ không _unhandled_input: scene này không có nút nào để bấm, nên
## bắt sự kiện sớm nhất là được, không sợ cướp mất thao tác của ai.
func _input(event: InputEvent) -> void:
	if not _skip_allowed or _switched:
		return
	# echo = phím giữ lâu tự lặp lại; chỉ tính cú bấm xuống đầu tiên.
	var is_key := event is InputEventKey and event.is_pressed() and not event.is_echo()
	var is_mouse := event is InputEventMouseButton and event.is_pressed()
	var is_pad := event is InputEventJoypadButton and event.is_pressed()
	if is_key or is_mouse or is_pad:
		get_viewport().set_input_as_handled()
		_go_next()


func _go_next() -> void:
	if _switched:
		return
	_switched = true
	if is_instance_valid(_video):
		_video.stop()
	get_tree().change_scene_to_file(next_scene)
