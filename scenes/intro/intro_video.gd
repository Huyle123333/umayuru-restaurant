extends Control
## ------------------------------------------------------- VÌ SAO PHẢI .OGV
## ---------------------------------------------------------- BA NGUYÊN TẮC

@export_file("*.ogv") var video_path: String = "res://assets/video/intro.ogv"

@export_file("*.tscn") var next_scene: String = "res://scenes/menu/main_menu.tscn"

## Chặn bỏ qua trong khoảng đầu (giây). Chống việc người chơi đang bấm chuột
@export var skip_lock_seconds: float = 0.4

@onready var _video: VideoStreamPlayer = %Video

var _switched := false
var _skip_allowed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var stream := load(video_path) as VideoStream
	if stream == null:
		push_error("Không nạp được video intro: %s — vào thẳng menu." % video_path)
		_go_next()
		return

	if get_node_or_null("/root/AmThanh") != null:
		AmThanh.stop_music()

	_video.stream = stream
	_video.finished.connect(_go_next)
	_video.play()

	await get_tree().process_frame
	if not _video.is_playing():
		push_error("Video intro không phát được (%s) — vào thẳng menu." % video_path)
		_go_next()
		return

	await get_tree().create_timer(skip_lock_seconds).timeout
	_skip_allowed = true


## _input chứ không _unhandled_input: scene này không có nút nào để bấm, nên
func _input(event: InputEvent) -> void:
	if not _skip_allowed or _switched:
		return
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
