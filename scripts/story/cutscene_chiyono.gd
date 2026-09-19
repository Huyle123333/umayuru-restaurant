extends RefCounted
## Màn ra mắt của Sakura Chiyono O — đoạn cắt cảnh chen giữa "bấm Chơi" và
## "vào bếp".
##
## Một trong BA đoạn ra mắt của ba nhân vật ẩn (Teio, Chiyono O, Gold Ship).
## Chạy khi: đã mở khoá trong bảng CODE No.7, đang thật sự chọn Chiyono, chưa
## xem lần nào, và màn sắp vào là một màn chơi thật (không phải prologue).
##
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ
##
## BA ĐOẠN NÀY ĐỘC LẬP VỚI NHAU — xem giải thích đầy đủ ở kich_ban_teio.gd.
## Tóm tắt: ba người được mở khoá theo thứ tự bất kỳ, nên không đoạn nào được
## phép nhắc tới hai đoạn kia.
##
## TÍNH CÁCH CHIYONO: ngoan ngoãn, tốt bụng. Ba nhân vật ẩn cùng một tình
## huống (tới quán, tự giới thiệu, xin vào làm) nhưng phải KHÁC NHAU ở cách
## họ bước qua cái cửa — nếu không thì làm ba đoạn cũng như làm một.
##
##   Gold Ship  đạp cửa, không hỏi ai.
##   Teio       hỏi dồn, tự trả lời hộ luôn.
##   Chiyono O  đứng ngoài đợi tới lượt, và xin phép trước từng bước một.
##
## Đoạn của Chiyono vì thế phải NGẮN và LẶNG hơn hai đoạn kia. Cô ấy nói ít,
## nhưng đã chuẩn bị kỹ hơn cả hai người cộng lại — và chi tiết đó (cái hộp
## bánh) làm việc thay cho một đoạn thoại dài.

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const SCENES: Array[Dictionary] = [
	{
		"background": BG_RESTAURANT,
		"line": "Bảy giờ sáng. Quán chưa sáng đèn.",
	},
	{
		"line": "Có một cô bé đứng ngoài cửa. Đã đứng đó một lúc, ngập ngừng định vào nhưng lại thôi.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "Kitasan Black",
		"line": "Ơ Chiyo-san? Tại sao chị chỉ đứng nhìn!",
	},
	{
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "A... x-xin lỗi! Trong đó đang bận nên chị nghĩ mình nên đợi.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Có việc gì không em?",
	},
	{
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "Em... nghe nói quán đang tìm người. Em cũng biết một chút nấu nướng. Không giỏi lắm, nhưng làm được.",
	},
	{
		"line": "Cô đưa ra một cái hộp giấy buộc dây cẩn thận. Bên trong là bánh — vừa mới ra lò sáng nay.",
	},
	{
		"portrait": "tuandb",
		"speaker": "Special Week",
		"line": "...Ngon quá! Cái này ngon thật này!",
	},
	{
		"portrait": "chiyo",
		"speaker": "Sakura Chiyono O",
		"line": "T-thật ạ? Vậy... vậy em làm thêm được không? Em hứa sẽ cố hết sức!",
	},
	{
		"portrait": "",
		"speaker": "",
		"line": "Không ai kịp nói rằng cô đã được nhận từ miếng bánh thứ nhất.",
	},
]
