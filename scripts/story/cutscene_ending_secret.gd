extends RefCounted
## KẾT ẨN — chỉ chiếu khi lượt chơi GẦN NHẤT của cả ba ngày đều đạt hạng S
## (GameData.secret_ending_unlocked()).
##
## Không nơi nào trong game nhắc tới kết này: không gợi ý, không nút riêng,
## không dấu hiệu trên màn chọn màn. Người chơi bấm cùng một nút "Ending" và
## chỉ phát hiện ra là có kết khác khi nội dung đổi.
##
## ⚠ LỜI THOẠI DƯỚI ĐÂY LÀ BẢN TẠM. Cốt truyện thật sẽ viết sau — sửa thẳng
## các dòng "line" trong file này.

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"
const BG_BLACK := "res://assets/ui/backgrounds/den.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"portrait": "",
		"line": "Đêm thứ ba. Vị khách cuối cùng vừa rời quán — và không một ai trong ba ngày qua ra về mà thất vọng.",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "...Tôi vừa đếm lại ba lần. Con số này không thể nào đúng được.",
	},
	{
		"portrait": "player",
		"speaker": "@",
		"line": "Sao thế ạ? Thiếu ạ?",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Thừa. Thừa gấp mấy lần một chuyến đi biển.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Chủ quán vừa gọi. Ông ấy muốn hỏi: người đứng bếp ba ngày qua có muốn ở lại không.",
	},
	{
		"portrait": ["kitamoi", "tuandb", "oui", "mambo"],
		"speaker": "",
		"line": "[font_size=46]HẢ?![/font_size]",
	},
	{
		"portrait": "player",
		"speaker": "@",
		"line": "...Đi biển trước đã. Rồi tính.",
	},
	{
		"background": BG_BLACK,
		"portrait": "",
		"speaker": "",
		"line": "UMAYURU RESTAURANT\n— Ba ngày hoàn hảo —",
	},
]
