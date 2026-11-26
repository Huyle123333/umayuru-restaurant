class_name DizzyHeadModifier
extends SkeletonModifier3D

## Tên xương đầu. Model Uma đều tên "Head"; để export cho model khác dùng lại.
@export var head_bone := "Head"
## Biên độ nghiêng tối đa (radian). 0.14 ≈ 8° — đủ thấy là choáng, chưa đến
@export var tilt := 0.14
## Số vòng đầu đảo mỗi giây.
@export var turns_per_second := 1.1

var _bone := -1
var _time := 0.0
## 0 → 1: mức lắc hiện tại, dâng/hạ dần theo `dizzy`.
var _fade := 0.0
## Đặt true/false từ ngoài; modifier tự dâng/hạ _fade.
var dizzy := false


func _ready() -> void:
	var skeleton := get_skeleton()
	if skeleton != null:
		_bone = skeleton.find_bone(head_bone)


func _process(delta: float) -> void:
	_time += delta
	_fade = move_toward(_fade, 1.0 if dizzy else 0.0, delta * 4.0)


func _process_modification() -> void:
	if _bone < 0 or _fade <= 0.0:
		return
	var skeleton := get_skeleton()
	var angle := _time * TAU * turns_per_second
	var wobble := Basis.from_euler(Vector3(
		sin(angle) * tilt * _fade, 0.0, cos(angle) * tilt * _fade))
	var global_pose := skeleton.get_bone_global_pose(_bone)
	global_pose.basis = wobble * global_pose.basis
	var parent := skeleton.get_bone_parent(_bone)
	var parent_pose := skeleton.get_bone_global_pose(parent) if parent >= 0 else Transform3D()
	skeleton.set_bone_pose_rotation(_bone,
		(parent_pose.basis.inverse() * global_pose.basis).get_rotation_quaternion())
