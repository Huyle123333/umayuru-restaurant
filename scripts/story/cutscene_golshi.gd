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

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"line": "Sáu giờ hai mươi tối. Quán còn ba mươi phút nữa mở cửa.",
	},
	{
		"line": "Rồi cửa trước bật tung.",
	},
	{
		"portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "BỔN ĐẠI VƯƠNG ĐÃ TỚI ĐÂY ĐỂ TRỢ GIÚP CÁC NGƯƠI",
	},
	{
		"portrait": "kitamoi",
		"speaker": "Kitasan Black",
		"line": "...Hả?",
	},
	{
		"portrait": "tuandb",
		"speaker": "Special Week",
		"line": "Ơ... mẹ trẻ vào đây bằng cách nào thế? Cửa khoá mà?",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "Con ngọ nào đây... Tôi không nhớ mình có mời em đấy.",
	},
	{
		"portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "Gọi hay không thì liên quan gì? Bổn đại vương đến là đến.",
	},
	{
		"portrait": "oui",
		"speaker": "Oguri Cap",
		"line": "...Thôi kệ. Đằng nào cũng thiếu người.",
	},
	{
		"portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "Vậy nhé! Bếp đâu? Bổn đại vương nấu cho mà xem!",
	},
	{
		"portrait": "",
		"speaker": "",
		"line": "Không ai kịp ngăn lại.",
	},
]
