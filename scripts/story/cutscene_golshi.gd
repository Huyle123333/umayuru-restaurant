extends RefCounted
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"line": "Sáu giờ hai mươi tối. Quán còn ba mươi phút nữa mở cửa.",
	},
	{
		"line": "Rồi cửa trước bật tung.",
	},
	{"emotion": "proud", "portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "GOLSHI-SAMA TỚI ĐÂY ĐỂ TRỢ GIÚP CÁC NGƯƠI!",
	},
	{"emotion": "surprise", 
		"portrait": "kitamoi",
		"speaker": "Kitasan Black",
		"line": "...Hả?",
	},
	{"emotion": "surprise", 
		"portrait": "tuandb",
		"speaker": "Special Week",
		"line": "Ơ... mẹ trẻ vào đây bằng cách nào thế? Cửa khoá mà?",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "Con ngọ nào đây... Tôi không nhớ mình có mời em đấy.",
	},
	{"emotion": "proud", "portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "Gọi hay không thì liên quan gì? GOLSHI này thích đến thì đến.",
	},
	{
		"portrait": "oui",
		"speaker": "Oguri Cap",
		"line": "...Thôi kệ. Đằng nào cũng thiếu người.",
	},
	{"emotion": "proud", 
		"portrait": "golshi",
		"speaker": "Gold Ship",
		"line": "Vậy nhé! Bếp đâu? Để GOLSHI-SAMA thể hiện!",
	},
	{
		"portrait": "",
		"speaker": "",
		"line": "Không ai kịp ngăn lại.",
	},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Ba mươi phút trước giờ mở cửa, Gold Ship đạp cửa xông vào, tự xưng tới để \"trợ giúp\". Không ai mời, nhưng quán đang thiếu người nên Trainer đành để cô ở lại."
