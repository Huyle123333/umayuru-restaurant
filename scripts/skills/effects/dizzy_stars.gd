class_name DizzyStars
extends Node3D

@export var star_count := 4
## Bán kính vòng sao (mét, trước khi nhân scale model).
@export var radius := 0.32
## Vòng sao cao hơn gốc xương đầu bao nhiêu. Gốc xương Head nằm ở CẰM, đầu
@export var height := 0.4
@export var turns_per_second := 0.8

var _skeleton: Skeleton3D
var _bone := -1
var _stars: Array[Label3D] = []
var _time := 0.0


## Gọi một lần sau khi add_child.
func setup(skeleton: Skeleton3D, head_bone: String) -> void:
	_skeleton = skeleton
	_bone = skeleton.find_bone(head_bone)
	for i in star_count:
		var star := Label3D.new()
		star.text = "★"
		star.font_size = 64
		star.pixel_size = 0.004
		star.modulate = Color(1.0, 0.86, 0.2)
		star.outline_modulate = Color(0.45, 0.25, 0.0)
		star.outline_size = 10
		star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		star.no_depth_test = true
		star.render_priority = 10
		add_child(star)
		_stars.append(star)
	hide()


func _process(delta: float) -> void:
	if not visible or _skeleton == null or _bone < 0:
		return
	_time += delta
	var head := _skeleton.global_transform * _skeleton.get_bone_global_pose(_bone)
	var s := _skeleton.global_transform.basis.get_scale().y
	global_position = head.origin + Vector3.UP * height * s
	for i in _stars.size():
		var a := _time * TAU * turns_per_second + TAU * i / _stars.size()
		_stars[i].position = Vector3(cos(a) * radius * s, sin(a * 2.0) * 0.04 * s, sin(a) * radius * s)
