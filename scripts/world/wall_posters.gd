extends Node3D

const WALL_FACE_X := 31.75
const CENTER_Y := 2.4
const FRAME_DEPTH := 0.06
const FRAME_BORDER := 0.08
const FRAME_COLOR := Color("5a3b26")

## path, tâm theo trục z dọc bức tường, bề NGANG (chiều cao suy theo tỉ lệ ảnh).
const POSTERS := [
	{"path": "res://assets/ui/posters/ttg_logo.png", "z": 7.0, "w": 1.8},
	{"path": "res://assets/ui/posters/ttg_banner.png", "z": 10.4, "w": 3.4},
	{"path": "res://assets/ui/posters/ttg_shop.png", "z": 14.0, "w": 2.0},
	{"path": "res://assets/ui/posters/poster_face.png", "z": 16.6, "w": 1.2},
	{"path": "res://assets/ui/posters/truc_tiep_game.png", "z": 18.8, "w": 1.2},
]


func _ready() -> void:
	for p in POSTERS:
		var tex := _load_texture(String(p["path"]))
		if tex == null:
			push_warning("Tranh treo tường: thiếu ảnh %s" % p["path"])
			continue
		_add_poster(tex, float(p["z"]), float(p["w"]))


## Ảnh đã được editor import thì nạp như mọi tài nguyên. Chưa import (mới chép
func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img != null else null


func _add_poster(tex: Texture2D, z: float, w: float) -> void:
	var h := w * float(tex.get_height()) / maxf(float(tex.get_width()), 1.0)

	var pivot := Node3D.new()
	pivot.position = Vector3(WALL_FACE_X, CENTER_Y, z)
	pivot.rotation_degrees = Vector3(0, -90, 0)
	add_child(pivot)

	# Khung gỗ: một tấm hộp mỏng to hơn ảnh một viền.
	var frame := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w + FRAME_BORDER * 2.0, h + FRAME_BORDER * 2.0, FRAME_DEPTH)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = FRAME_COLOR
	box.material = fm
	frame.mesh = box
	frame.position = Vector3(0, 0, FRAME_DEPTH * 0.5)
	pivot.add_child(frame)

	var pic := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = tex
	pm.roughness = 0.9
	quad.material = pm
	pic.mesh = quad
	pic.position = Vector3(0, 0, FRAME_DEPTH + 0.001)
	pivot.add_child(pic)
