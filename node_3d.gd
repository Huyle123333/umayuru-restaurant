@tool
extends Node3D

@export var chieu_rong: int = 10  # Số lượng ô theo chiều ngang
@export var chieu_dai: int = 10   # Số lượng ô theo chiều dọc
@export var kich_thuoc_o: float = 2.0 # Kích thước 1 ô sàn (sửa lại cho đúng độ rộng miếng gltf của bạn)

func _ready():
	var tile_goc = $TileGoc
	if not tile_goc: return
	
	for x in range(chieu_rong):
		for z in range(chieu_dai):
			if x == 0 and z == 0: continue # Bỏ qua ô gốc
			var tile_moi = tile_goc.duplicate()
			add_child(tile_moi)
			tile_moi.position = Vector3(x * kich_thuoc_o, 0, z * kich_thuoc_o)
