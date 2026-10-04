extends RefCounted
## KẾT THƯỜNG — chiếu khi bấm Ending mà CHƯA đủ điều kiện kết ẩn.
##
## Điều kiện chọn kết nằm ở GameData.ending_scene(): kết ẩn cần hạng S ở lượt
## chơi GẦN NHẤT của cả ba ngày; mọi trường hợp còn lại là kết này.
##
## ⚠ LỜI THOẠI DƯỚI ĐÂY LÀ BẢN TẠM để màn kết chạy được từ đầu tới cuối. Cốt
## truyện thật sẽ viết sau — sửa thẳng các dòng "line" trong file này, cùng
## định dạng với cutscene_prologue.gd ("portrait": "player" là người đã đứng
## bếp, "other" là một đồng đội khác).

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"
const BG_ROOM := "res://assets/ui/backgrounds/phong_sinh_hoat.png"
const BG_BLACK := "res://assets/ui/backgrounds/den.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"portrait": "",
		"line": "Đêm thứ ba. Vị khách cuối cùng vừa rời quán.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Hết ba ngày rồi. Mọi người vất vả rồi.",
	},
	{
		"portrait": "player",
		"speaker": "@",
		"line": "Vậy... quỹ đội thế nào rồi ạ?",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Đủ. Vừa đủ cho một chuyến đi biển.",
	},
	{
		"portrait": ["kitamoi", "tuandb", "oui", "mambo"],
		"speaker": "",
		"line": "[font_size=46]YEAHHH![/font_size]",
	},
	{
		"background": BG_ROOM,
		"portrait": "other",
		"speaker": "@",
		"line": "Mai xuất phát luôn nhé! Lần này nhớ đừng ăn hết quỹ trước khi tới nơi.",
	},
	{
		"portrait": "player",
		"speaker": "@",
		"line": "Ba ngày đứng bếp... hoá ra cũng vui hơn mình tưởng.",
	},
	{
		"background": BG_BLACK,
		"portrait": "",
		"speaker": "",
		"line": "UMAYURU RESTAURANT\n— Hết —",
	},
]
