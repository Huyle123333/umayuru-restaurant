extends RefCounted
## HIỆU ỨNG: Ambition to Surpass the Sakura — kĩ năng chủ động của Chiyono O.
##
## Đưa đồng hồ màn về đầy và cho toàn bộ khách biến mất; tiền giữ nguyên.
##
## Không cần disable(): đây là một cú bấm, không phải một trạng thái kéo dài.
## Nhịp khách tự quay về giai đoạn 1 mà không phải làm gì thêm — luật màn chọn
## giai đoạn bằng "đã trôi bao lâu", và đồng hồ vừa về đầy thì con số đó là 0.


func enable(ctx: Dictionary) -> void:
	var customers: Node = ctx.get("customers")
	if customers != null and customers.has_method("clear_all_customers"):
		customers.clear_all_customers()
	var clock: Node = ctx.get("clock")
	if clock != null and clock.has_method("reset_time"):
		clock.reset_time()
	# Nhạc cao điểm đang kêu thì trả về nhạc nền: màn vừa quay lại phút đầu
	# tiên, và bài cao điểm phải để dành cho lúc nó thật sự tới lần nữa.
	var level: Node = ctx.get("level")
	var rules: Node = level.get_node_or_null("LevelRules") if level != null else null
	if rules != null and rules.has_method("rearm_music"):
		rules.rearm_music()
