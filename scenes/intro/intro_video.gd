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
##    ước với hộp thoại ở hoi_thoai.gd, để cả game chỉ có MỘT thói quen cho
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
@export_file("*.ogv") var duong_dan_video: String = "res://assets/video/intro.ogv"

## Menu sẽ vào sau khi chiếu xong.
@export_file("*.tscn") var scene_tiep_theo: String = "res://scenes/menu/main_menu.tscn"

## Chặn bỏ qua trong khoảng đầu (giây). Chống việc người chơi đang bấm chuột
## dở từ màn trước làm mất luôn intro ngay khi nó vừa hiện ra.
@export var khoa_bo_qua_giay: float = 0.4

@onready var _video: VideoStreamPlayer = %Video

var _da_chuyen := false
var _cho_phep_bo_qua := false


func _ready() -> void:
	# Intro không có gì để tạm dừng, nhưng đặt ALWAYS cho chắc: nếu sau này
	# có ai bật pause trước khi scene này chạy xong thì video vẫn chạy tiếp
	# chứ không đứng hình vĩnh viễn.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Tắt nhạc menu. Video có tiếng của riêng nó (phát qua bus "Music"), để
	# nhạc menu chạy tiếp thì hai thứ chồng lên nhau — mà nhạc menu là autoload
	# nên nó KHÔNG tự tắt khi đổi scene; đúng cái tính chất giúp nhạc liền mạch
	# giữa các màn hình menu lại thành phiền ở đây.
	AmThanh.dung_nhac()

	var stream := load(duong_dan_video) as VideoStream
	if stream == null:
		push_error("Không nạp được video intro: %s — vào thẳng menu." % duong_dan_video)
		_di_tiep()
		return

	_video.stream = stream
	_video.finished.connect(_di_tiep)
	_video.play()

	# Godot không báo lỗi ngay khi play() thất bại, nên kiểm lại ở khung hình
	# sau: đã gọi play() mà vẫn không chạy thì coi như hỏng và đi tiếp.
	await get_tree().process_frame
	if not _video.is_playing():
		push_error("Video intro không phát được (%s) — vào thẳng menu." % duong_dan_video)
		_di_tiep()
		return

	await get_tree().create_timer(khoa_bo_qua_giay).timeout
	_cho_phep_bo_qua = true


## _input chứ không _unhandled_input: scene này không có nút nào để bấm, nên
## bắt sự kiện sớm nhất là được, không sợ cướp mất thao tác của ai.
func _input(event: InputEvent) -> void:
	if not _cho_phep_bo_qua or _da_chuyen:
		return
	# echo = phím giữ lâu tự lặp lại; chỉ tính cú bấm xuống đầu tiên.
	var la_phim := event is InputEventKey and event.is_pressed() and not event.is_echo()
	var la_chuot := event is InputEventMouseButton and event.is_pressed()
	var la_tay_cam := event is InputEventJoypadButton and event.is_pressed()
	if la_phim or la_chuot or la_tay_cam:
		get_viewport().set_input_as_handled()
		_di_tiep()


func _di_tiep() -> void:
	if _da_chuyen:
		return
	_da_chuyen = true
	if is_instance_valid(_video):
		_video.stop()
	get_tree().change_scene_to_file(scene_tiep_theo)
