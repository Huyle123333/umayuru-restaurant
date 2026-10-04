@tool
extends Node3D

@export var width_tiles: int = 10  # Số lượng ô theo chiều ngang
@export var depth_tiles: int = 10   # Số lượng ô theo chiều dọc
@export var cell_size: float = 2.0 # Kích thước 1 ô sàn (sửa lại cho đúng độ rộng miếng gltf của bạn)

func _ready():
	var base_tile = $TileGoc
	if not base_tile: return
	
	for x in range(width_tiles):
		for z in range(depth_tiles):
			if x == 0 and z == 0: continue # Bỏ qua ô gốc
			var new_tile = base_tile.duplicate()
			add_child(new_tile)
			new_tile.position = Vector3(x * cell_size, 0, z * cell_size)
