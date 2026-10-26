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
	# (26/10/2026, user chốt) Endless: đồng hồ về ĐÚNG số giây ban đầu (2:30,
	# lưu ở clock.bar_full), kể cả khi đang còn nhiều hơn; mốc độ khó GIỮ
	# NGUYÊN. Không gọi reset_time() vì ở Endless `duration` đã phình theo giờ
	# thưởng. Đi qua add_time() với phần chênh (có thể âm): hàm đó cộng vào cả
	# duration lẫn time_left, nên "đã trôi bao lâu" — thứ chọn mốc và ghi kết
	# quả — không đổi.
	if clock != null and GameData.is_endless_mode() and float(clock.bar_full) > 0.0:
		clock.add_time(float(clock.bar_full) - float(clock.time_left))
		return
	if clock != null and clock.has_method("reset_time"):
		clock.reset_time()
