extends RefCounted
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"line": "Sáu giờ chiều. Quán vừa kê xong bàn cuối, chưa kịp ngồi.",
	},
	{
		"line": "Chuông cửa reo. Rồi reo thêm bốn lần nữa, rất nhanh.",
	},
	{"emotion": "happy", 
		"portrait": "hachimi",
		"speaker": "Tokai Teio",
		"line": "Hí Ngọ! Nghe nói mọi người làm thêm ở đây đúng không? Mị cũng muốn giúp!",
	},
	{"emotion": "sad", "portrait": "kitamoi",
		"speaker": "Kitasan Black",
		"line": "Teio-san... chị đến giúp bọn em sao *cảm động rớt nước mắt*?",
	},
	{
		"portrait": "hachimi",
		"speaker": "Tokai Teio",
		"line": "Biết chứ! Nên chị mới tới sớm! Thiếu người phải không? Chắc chắn thiếu người mà!",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Em... định xin việc à?",
	},
	{
		"portrait": "hachimi",
		"speaker": "Tokai Teio",
		"line": "Xin gì mà xin! Đây là thông báo không phải đề nghị! À mà bếp ở đâu? Tạp dề đâu? Mị buộc tóc trước nhé!",
	},
	{
		"portrait": "oui",
		"speaker": "Oguri Cap",
		"line": "...Cậu ấy chạy nhanh thật.",
	},
	{"emotion": "happy", "portrait": "hachimi",
		"speaker": "Tokai Teio",
		"line": "Yên tâm đi! Giờ cao điểm thì cứ để Tokai Teio này lo!",
	},
	{
		"portrait": "",
		"speaker": "",
		"line": "Không ai nỡ nói rằng giờ cao điểm sẽ cho cô ấy thở oxi như fan tê liệt.",
	},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Trước giờ mở cửa, Tokai Teio bất ngờ xuất hiện và tuyên bố sẽ phụ quán, không cần ai đồng ý. Cô lao thẳng vào bếp, hứa sẽ lo hết giờ cao điểm."
