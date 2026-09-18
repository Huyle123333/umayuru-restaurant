@tool
extends Node3D

@export var generate_collisions: bool = false:
	set(value):
		if value:
			_create_all_collisions(self)
			print("✅ Đã tạo vật lý thành công cho toàn bộ Map!")

func _create_all_collisions(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			# Kiểm tra nếu chưa có Collision thì mới tạo
			var has_collision = false
			for sub_child in child.get_children():
				if sub_child is StaticBody3D:
					has_collision = true
					break
			
			if not has_collision:
				child.create_trimesh_collision()
				
		# Quét tiếp các node con bên trong (đệ quy)
		_create_all_collisions(child)
