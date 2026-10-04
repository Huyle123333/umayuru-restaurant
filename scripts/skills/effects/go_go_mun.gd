extends RefCounted
## HIỆU ỨNG: Go, Go, Mun! — kĩ năng chủ động của Matikanetannhauser (Mambo).
##
## Hai nửa, một may một rủi, đúng tính cách nhân vật:
##   • MAY: đơn pizza hoàn hảo được gieo thưởng (36% × 3, 18% × 2).
##   • RỦI: trong lúc DI CHUYỂN, mỗi giây có 3% bị choáng đứng yên 2 giây.
##
## Các con số nằm ở mambo.gd (khoá "perfect_roll", "stun_chance_per_second",
## "stun_seconds"); file này chỉ thi hành.
##
## Vì sao là file riêng: nửa "rủi" diễn ra theo THỜI GIAN (phải đếm giây di
## chuyển, phải đếm ngược lúc choáng) nên cần hàm tick() — thứ một hiệu ứng
## "vặn một con số" không có.

## Giây di chuyển đã dồn lại, chưa đủ một giây để gieo.
var _moving_bank := 0.0
## Còn bao nhiêu giây choáng. 0 = không choáng.
var _stun_left := 0.0


func enable(ctx: Dictionary) -> void:
	var customers: Node = ctx.get("customers")
	var data: Dictionary = ctx.get("data", {})
	if customers != null:
		customers.perfect_roll = data.get("perfect_roll", {})


func disable(ctx: Dictionary) -> void:
	var customers: Node = ctx.get("customers")
	if customers != null and is_instance_valid(customers):
		customers.perfect_roll = {}
	_release(ctx.get("character"))


func tick(delta: float, ctx: Dictionary) -> void:
	var character: Node = ctx.get("character")
	if character == null or not is_instance_valid(character):
		return
	var data: Dictionary = ctx.get("data", {})

	if _stun_left > 0.0:
		_stun_left -= delta
		if _stun_left <= 0.0:
			_release(character)
		return

	# "Đang di chuyển" đo bằng vận tốc ngang THẬT của nhân vật chứ không bằng
	# phím đang giữ: đứng tì vào tường mà giữ W thì không đi được bước nào,
	# không có lý gì bị gieo choáng.
	var v: Vector3 = character.velocity
	if Vector2(v.x, v.z).length() < 0.5:
		return
	_moving_bank += delta
	# Gieo theo từng GIÂY TRÒN di chuyển, không gieo mỗi khung hình: gieo mỗi
	# khung thì xác suất thật phụ thuộc FPS của máy người chơi.
	while _moving_bank >= 1.0:
		_moving_bank -= 1.0
		if randf() < float(data.get("stun_chance_per_second", 0.0)):
			_stun(character, float(data.get("stun_seconds", 2.0)))
			return


func _stun(character: Node, seconds: float) -> void:
	_stun_left = seconds
	_moving_bank = 0.0
	if "movement_locked" in character:
		character.movement_locked = true
	AmThanh.play_sfx("craft_fail")


func _release(character: Variant) -> void:
	_stun_left = 0.0
	if character != null and is_instance_valid(character) and "movement_locked" in character:
		character.movement_locked = false
