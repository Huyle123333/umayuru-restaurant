extends TextureRect
## Phát sprite sheet như một ảnh GIF động, ngay trong hệ thống UI Control.
## Gắn script này vào một TextureRect có texture là AtlasTexture trỏ tới sprite sheet.

@export var hframes: int = 7          ## số cột trong sprite sheet
@export var vframes: int = 6          ## số hàng trong sprite sheet
@export var frame_count: int = 42     ## tổng số frame thật (có thể nhỏ hơn hframes * vframes)
@export var fps: float = 15.0
@export var playing: bool = true
@export var autostart_frame: int = 0

var _frame: int = 0
var _accum: float = 0.0
var _atlas: AtlasTexture

func _ready() -> void:
	# Tách riêng AtlasTexture cho từng instance, tránh các bản sao dùng chung một region.
	_atlas = texture as AtlasTexture
	if _atlas != null:
		_atlas = _atlas.duplicate()
		texture = _atlas
	_frame = autostart_frame
	_apply_frame()

func _process(delta: float) -> void:
	if not playing or fps <= 0.0 or frame_count <= 0:
		return
	_accum += delta
	var step := 1.0 / fps
	while _accum >= step:
		_accum -= step
		_frame = (_frame + 1) % frame_count
		_apply_frame()

func _apply_frame() -> void:
	if _atlas == null or _atlas.atlas == null:
		return
	var fw := float(_atlas.atlas.get_width()) / float(maxi(hframes, 1))
	var fh := float(_atlas.atlas.get_height()) / float(maxi(vframes, 1))
	var col := _frame % maxi(hframes, 1)
	var row := _frame / maxi(hframes, 1)
	_atlas.region = Rect2(col * fw, row * fh, fw, fh)

func play() -> void:
	playing = true

func stop() -> void:
	playing = false

func set_frame(i: int) -> void:
	_frame = clampi(i, 0, maxi(frame_count - 1, 0))
	_apply_frame()
