extends CharacterBody3D

const SPEED = 5.0

# Kéo thả Node AnimationPlayer của bạn vào đây hoặc chỉnh lại đúng đường dẫn
@onready var anim_player = $kitamoi/AnimationPlayer 

func _physics_process(delta):
	# Lấy hướng di chuyển từ phím mũi tên / WASD
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Xoay mặt nhân vật theo hướng di chuyển
		look_at(global_position + direction, Vector3.UP)
		
		# Bật animation Chạy
		if anim_player.current_animation != "kitabigrun_bone":
			anim_player.play("kitabigrun_bone")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Bật animation Đứng yên (Idle)
		if anim_player.current_animation != "idle_bone":
			anim_player.play("idle_bone")

	move_and_slide()
