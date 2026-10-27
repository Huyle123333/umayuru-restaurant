extends RefCounted
## HIỆU ỨNG: Anchors Aweigh! — kĩ năng chủ động của Gold Ship.
##
## Nhận một khoản tiền khổng lồ (khoá "reward_money" trong golshi.gd) rồi kết
## thúc màn chơi ngay.
##
## Phần thưởng trao trong tick() chứ không trong enable(): enable() chạy ngay
## lúc bấm Space, khi đoạn phim cut-in còn đang chiếu. Kết thúc màn ở đó thì
## bảng kết quả hiện ĐÈ lên đoạn phim. tick() chỉ được gọi khi phim đã xong và
## game đang chạy thật, nên chờ ở đây là đủ — không cần biết phim dài bao lâu.

var _pending := false


func enable(_ctx: Dictionary) -> void:
	_pending = true


func tick(_delta: float, ctx: Dictionary) -> void:
	if not _pending:
		return
	_pending = false
	var data: Dictionary = ctx.get("data", {})
	var customers: Node = ctx.get("customers")
	if customers != null and customers.has_method("add_money"):
		customers.add_money(int(data.get("reward_money", 0)))
	var level: Node = ctx.get("level")
	# Asian: không kết thúc màn (kết thúc = thắng ngay), mà hồi mạng. Đi qua
	# AsianMode.restore_lives() để luật "mạng dư đổi tiền" của Aura farming
	# tự áp vào.
	if not bool(data.get("end_level", true)):
		var asian: Node = level.get_node_or_null("AsianMode") if level != null else null
		if asian != null:
			asian.restore_lives(int(data.get("restore_lives", 0)))
		return
	# Báo cho GameData biết lượt này thắng bằng kĩ năng: xếp ở hạng 0, một lần
	# duy nhất, và không ghi kỷ lục.
	GameData.skill_win_pending = true
	if level != null and level.has_method("_end_level"):
		# Hạng để RỖNG: bảng kết quả tự xếp hạng theo số tiền, và chỉ khi hạng
		# không bị ép thì lượt chơi mới được ghi vào bảng xếp hạng.
		level._end_level("")
