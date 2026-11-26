extends RefCounted

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

	var v: Vector3 = character.velocity
	if Vector2(v.x, v.z).length() < 0.5:
		return
	_moving_bank += delta
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
	if character.has_method("set_dizzy"):
		character.set_dizzy(true)
	AmThanh.play_sfx("craft_fail")


func _release(character: Variant) -> void:
	_stun_left = 0.0
	if character != null and is_instance_valid(character) and "movement_locked" in character:
		character.movement_locked = false
	if character != null and is_instance_valid(character) and character.has_method("set_dizzy"):
		character.set_dizzy(false)
