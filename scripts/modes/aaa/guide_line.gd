extends Node3D
## AAA MODE — VẠCH TRẮNG NHẤP NHÁY dưới sàn + NHÃN trên trạm cần tới.
##
## Vạch nối THẲNG từ chân nhân vật tới trạm đích, dựng lại mỗi khung bằng
## ImmediateMesh (vài chục tam giác — rẻ). Vì sao đường thẳng chứ không đi
## theo navmesh: navmesh của quán được nướng cho KHÁCH, và khu bếp là một hòn
## đảo bị chắn riêng (xem customer_manager), nên hỏi đường từ bếp ra bàn khách
## sẽ không có lời đáp. Bếp lại nhỏ, đường thẳng đã đủ chỉ hướng.
##
## Nét đứt chứ không liền: nét đứt đọc ra ngay là "đường chỉ dẫn", còn một dải
## trắng liền dễ bị nhìn nhầm thành vạch sơn của sàn nhà.

const DASH := 0.35
const GAP := 0.2
const WIDTH := 0.09
const LIFT := 0.04
## Số lần nhấp nháy mỗi giây.
const BLINK := 1.2

var _from: Node3D
var _target: Node3D
var _key := "E"
var _time := 0.0
var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()
var _line: MeshInstance3D
var _tag: Label3D
var _arrow: Label3D
var _arrow_target: Node3D


func _ready() -> void:
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(1, 1, 1, 0.8)
	_line = MeshInstance3D.new()
	_line.mesh = _mesh
	_line.material_override = _mat
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)

	_tag = _make_label(Color(1, 1, 1), 56)
	add_child(_tag)
	_arrow = _make_label(Color(1, 1, 1), 160)
	_arrow.text = "▼"
	add_child(_arrow)


func follow(player: Node3D) -> void:
	_from = player


## Đổi trạm đích. `arrow_target` là bàn của khách đang được nhắm — mũi tên
## luôn treo trên bàn đó, kể cả khi bước hiện tại là đi lấy nguyên liệu.
func point_to(target: Node3D, key: String, arrow_target: Node3D) -> void:
	_target = target
	_key = key
	_arrow_target = arrow_target


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * TAU * BLINK)
	_mat.albedo_color.a = 0.25 + 0.65 * pulse
	_mesh.clear_surfaces()

	var has_target := _from != null and is_instance_valid(_target)
	_tag.visible = has_target
	if has_target:
		var dest := _aim(_target)
		_draw_dashes(_from.global_position, dest)
		_tag.global_position = dest + Vector3.UP * 1.25
		_tag.text = Lang.t("TƯƠNG TÁC Ở ĐÂY [%s]") % _key if not _key.is_empty() else Lang.t("CHỜ Ở ĐÂY")

	_arrow.visible = is_instance_valid(_arrow_target)
	if _arrow.visible:
		_arrow.global_position = _aim(_arrow_target) + Vector3.UP * (2.0 + 0.15 * sin(_time * 4.0))


func _aim(n: Node3D) -> Vector3:
	return n.aim_position() if n.has_method("aim_position") else n.global_position


func _draw_dashes(a: Vector3, b: Vector3) -> void:
	var y := a.y + LIFT
	var start := Vector3(a.x, y, a.z)
	var end := Vector3(b.x, y, b.z)
	var length := start.distance_to(end)
	if length < 0.5:
		return
	var dir := (end - start) / length
	var side := dir.cross(Vector3.UP).normalized() * WIDTH * 0.5
	# Các nét đứt TRÔI về phía đích theo thời gian, như dấu chỉ đường GPS —
	# nhìn là biết chiều đi, không cần mũi tên trên vạch.
	var offset := fmod(_time * 1.5, DASH + GAP)
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := offset - (DASH + GAP)
	while s < length - 0.4:
		var s0 := maxf(s, 0.0)
		var s1 := minf(s + DASH, length - 0.4)
		if s1 > s0:
			var p0 := start + dir * s0
			var p1 := start + dir * s1
			for v in [p0 - side, p0 + side, p1 + side, p0 - side, p1 + side, p1 - side]:
				_mesh.surface_add_vertex(to_local(v))
		s += DASH + GAP
	_mesh.surface_end()


func _make_label(color: Color, size: int) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = color
	l.outline_modulate = Color(0.1, 0.1, 0.1)
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.visible = false
	return l
