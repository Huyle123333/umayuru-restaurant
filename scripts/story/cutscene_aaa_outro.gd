extends RefCounted

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"
const BG_BLACK := "res://assets/ui/backgrounds/den.png"

const SCENES: Array[Dictionary] = [
	{"background": BG_RESTAURANT, "portrait": "", "speaker": "Trợ lý đạo diễn",
		"line": "Cắt! Đóng máy!"},
	{"emotion": "sad", "portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Em có cảm giác mình chẳng làm gì cả. Bước nào cũng có người chỉ sẵn."},
	{"portrait": "trainer", "speaker": "0rca's Trainer",
		"line": "Phải làm thế bên IGN mới chấm điểm cao được."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Thế câu chuyện hôm nay kết thúc thế nào ạ?"},
	{"portrait": "trainer2", "speaker": "0rca's Trainer",
		"line": "[i]\"Còn tiếp — trong Season Pass.\"[/i]"},
	{"emotion": "angry", "portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Thằng cha nào nghĩ ra cái kịch bản này vậy."},
	{"background": BG_BLACK, "portrait": "",
		"line": "0rca dev cảm thấy quá khúm núm nên sau khi nghĩ ra mode này đã quyết định không làm nữa."},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Đóng máy. Kitasan thấy mình chẳng làm gì vì bước nào cũng có người chỉ sẵn, còn cái kết thì do tổ biên kịch tự quyết."
