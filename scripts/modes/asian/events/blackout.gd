extends RefCounted
## SỰ KIỆN ASIAN: CÚP ĐIỆN (20 giây).
##
## Phủ một lớp tối lên màn hình, chừa một vòng sáng quanh nhân vật. Bếp và lò
## vẫn chạy (không đụng tới hệ nào), HUD vẫn đọc được (lớp tối nằm DƯỚI HUD).
##
## Vòng sáng bám theo nhân vật bằng cách chiếu vị trí 3D của nhân vật ra toạ
## độ màn hình mỗi khung hình (Camera3D.unproject_position).

const RADIUS := 230.0

var _d: Node
var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial


func start(director: Node) -> void:
	_d = director
	_layer = CanvasLayer.new()
	# Dưới đồng hồ (5) và các bảng Asian, trên thế giới 3D.
	_layer.layer = 4
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec2 center;
uniform vec2 size;
uniform float radius;
void fragment() {
	float d = distance(UV * size, center);
	COLOR = vec4(0.0, 0.0, 0.02, 0.96 * smoothstep(radius, radius * 1.5, d));
}
"""
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("radius", RADIUS)
	_rect.material = _mat
	_layer.add_child(_rect)
	director.add_child(_layer)
	tick(0.0)


func tick(_delta: float) -> void:
	if _rect == null or not is_instance_valid(_rect):
		return
	var cam := _d.get_viewport().get_camera_3d()
	var pl: Node3D = _d._player as Node3D
	_mat.set_shader_parameter("size", _rect.size)
	if cam != null and pl != null:
		_mat.set_shader_parameter("center", cam.unproject_position(pl.global_position + Vector3.UP))


func stop(_director: Node) -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
