extends RefCounted
## Màn ra mắt của Gold Ship — đoạn cắt cảnh chen giữa "bấm Chơi" và "vào bếp".
##
## Một trong BA đoạn ra mắt của ba nhân vật ẩn (Teio, Chiyono O, Gold Ship).
## Chỉ chạy khi hội đủ CẢ HAI điều kiện: đã mở khoá nhân tố G trong bảng
## CODE No.7, VÀ người chơi thật sự chọn Gold Ship. Chạy đúng MỘT lần cho mỗi
## file save.
##
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ
##
## Gold Ship KHÔNG có trong team 0rca, không có trong prologue, không có một
## dòng nào trong cốt truyện chính. Với người chơi bình thường, thẻ đó mãi
## mãi chỉ là một cái bóng đen không tên.
##
## Vì sao làm vậy thay vì cho cô ấy vào truyện rồi khoá lại: một nhân vật có
## mặt trong truyện mà không chơi được thì người chơi cảm thấy bị GIỮ LẠI
## thứ đáng ra thuộc về mình — đó là cảm giác của DLC bán tiền, không dễ chịu.
## Còn một nhân vật hoàn toàn không tồn tại trong truyện thì lúc tìm ra là
## PHÁT HIỆN, không phải mở khoá. Chính vì thế đoạn này viết theo kiểu Gold
## Ship tự ý xông vào phá vỡ câu chuyện — cô ấy không được mời, và cả bộ
## khung truyện lẫn phản ứng của team đều nói đúng điều đó.
##
## BA ĐOẠN RA MẮT ĐỘC LẬP VỚI NHAU — xem giải thích ở kich_ban_teio.gd.
##
## LỖI ĐÃ SỬA: bản đầu của đoạn này cho Tokai Teio và Sakura Chiyono O nói
## thoại, mà hai người đó CŨNG là nhân vật ẩn. Người chơi mở được Gold Ship
## nhưng chưa mở hai người kia sẽ thấy hai gương mặt lạ hoắc bình luận về
## một chuyện họ không liên quan — và tệ hơn, thấy trước hai nhân vật mà lẽ
## ra họ phải tự tìm ra. Thay bằng Oguri Cap và Special Week, hai người thuộc
## team 0rca chính thức và đã xuất hiện từ prologue.

const NEN_QUAN := "res://assets/ui/backgrounds/quan_an.png"

const MAN: Array[Dictionary] = [
	{
		"nen": NEN_QUAN,
		"loi": "Mười giờ ba mươi. Quán còn ba mươi phút nữa mở cửa.",
	},
	{
		"loi": "Rồi cửa trước bật tung.",
	},
	{
		"anh": "golshi",
		"ai": "Gold Ship",
		"loi": "BỔN ĐẠI VƯƠNG ĐÃ TỚI ĐÂY ĐỂ TRỢ GIÚP CÁC NGƯƠI",
	},
	{
		"anh": "kitamoi",
		"ai": "Kitasan Black",
		"loi": "...Hả?",
	},
	{
		"anh": "tuandb",
		"ai": "Special Week",
		"loi": "Ơ... mẹ trẻ vào đây bằng cách nào thế? Cửa khoá mà?",
	},
	{
		"anh": "trainer2",
		"ai": "0rca's Trainer",
		"loi": "Con ngọ nào đây... Tôi không nhớ mình có mời em đấy.",
	},
	{
		"anh": "golshi",
		"ai": "Gold Ship",
		"loi": "Gọi hay không thì liên quan gì? Bổn đại vương đến là đến.",
	},
	{
		"anh": "oui",
		"ai": "Oguri Cap",
		"loi": "...Thôi kệ. Đằng nào cũng thiếu người.",
	},
	{
		"anh": "golshi",
		"ai": "Gold Ship",
		"loi": "Vậy nhé! Bếp đâu? Bổn đại vương nấu cho mà xem!",
	},
	{
		"anh": "",
		"ai": "",
		"loi": "Không ai kịp ngăn lại.",
	},
]
