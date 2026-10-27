extends RefCounted
## AAA MODE — đoạn kết "đóng máy" (kịch bản v4, 21/10/2026). Chiếu sau bảng
## đánh giá khi bấm "Về chọn màn". Không bỏ qua được, nên chỉ sáu câu.
##
## Câu cuối là thông báo của "nhà phát triển" trên nền đen — trước đây là một
## màn chữ riêng trong review_panel.gd, giờ gộp vào đây để cả đoạn kết đi
## chung một nhịp gõ chữ.

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"
const BG_BLACK := "res://assets/ui/backgrounds/den.png"

const SCENES: Array[Dictionary] = [
	{"background": BG_RESTAURANT, "portrait": "", "speaker": "Trợ lý đạo diễn",
		"line": "Cắt! Đóng máy!"},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Em có cảm giác mình chẳng làm gì cả. Bước nào cũng có người chỉ sẵn."},
	{"portrait": "trainer", "speaker": "0rca's Trainer",
		"line": "Đó chính là trải nghiệm điện ảnh."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Thế câu chuyện hôm nay kết thúc thế nào ạ?"},
	{"portrait": "trainer2", "speaker": "0rca's Trainer",
		"line": "[i]\"Còn tiếp — trong Season Pass.\"[/i]"},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Thằng cha nào nghĩ ra cái kịch bản này vậy."},
	{"background": BG_BLACK, "portrait": "",
		"line": "0rca dev cảm thấy quá khúm núm nên sau khi nghĩ ra mode này đã quyết định không làm nữa."},
]
