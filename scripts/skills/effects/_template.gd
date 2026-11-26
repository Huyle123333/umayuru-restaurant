extends RefCounted
## ────────────────────────────────────── KHI NÀO CẦN MỘT FILE TRONG ĐÂY
## ─────────────────────────────────────────────────────── CÁCH DÙNG


## Bật hiệu ứng. Gọi NGAY LÚC người chơi bấm Space, không đợi cut-in chiếu
func enable(ctx: Dictionary) -> void:
	var customers: Node = ctx.get("customers")
	if customers == null:
		return
	pass


## Tắt hiệu ứng. CHỈ cần viết cho kĩ năng bật/tắt được — hiện mới có
func disable(_ctx: Dictionary) -> void:
	pass
