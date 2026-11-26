extends RefCounted
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"line": "Bảy giờ sáng. Quán chưa sáng đèn.",
	},
	{
		"line": "Có một cô bé đứng ngoài cửa, ngập ngừng định vào nhưng lại thôi.",
	},
	{"emotion": "surprise", "portrait": "kitamoi",
		"speaker": "Kitasan Black",
		"line": "Ơ Chiyo-san? Sao chị chỉ đứng nhìn vậy!",
	},
	{"emotion": "nervous", 
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "A... x-xin lỗi! Trong đó đang bận nên chị nghĩ mình nên đợi.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Có việc gì không em?",
	},
	{"emotion": "shy", 
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "Em... nghe nói quán đang tìm người. Em cũng biết một chút nấu nướng. Không giỏi lắm, nhưng làm được.",
	},
	{
		"line": "Cô đưa ra một cái hộp giấy buộc dây cẩn thận. Bên trong là bánh — vừa mới ra lò sáng nay.",
	},
	{"emotion": "surprise", "portrait": "tuandb",
		"speaker": "Special Week",
		"line": "...Vỏ giòn, nhân không ngọt gắt. Mẹ em cũng không làm được thế này đâu!",
	},
	{"emotion": "nervous", 
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "T-thật ạ? Vậy... vậy em làm thêm được không? Em hứa sẽ cố hết sức!",
	},
	{
		"portrait": "",
		"speaker": "",
		"line": "Trước khi Trainer kịp trả lời, Kitasan đã đưa cho cô một chiếc tạp dề.",
	},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Sáng sớm, Sakura Chiyono O rụt rè đứng ngoài cửa quán. Cô mang tới một hộp bánh tự làm và xin được phụ bếp. Bánh ngon tới mức Kitasan đưa ngay cho cô một chiếc tạp dề."
