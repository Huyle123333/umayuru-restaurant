extends RefCounted
## AAA MODE — đoạn mở đầu "phim trường" (kịch bản v4, 21/10/2026).
##
## KHÔNG BỎ QUA ĐƯỢC (aaa_intro.tscn đặt skippable = false), nên cố ý ngắn:
## khoảng một phút, mỗi câu một ý. Bản dài hơn nằm trong các file docx
## kich_ban_aaa_mode_v1–v3, không đưa vào game.
##
## Chữ in nghiêng [i]…[/i] là câu Kitasan đang ĐỌC từ xấp kịch bản, để người
## chơi phân biệt với lời cô tự nói.
##
## Xưng hô: Trainer "tôi"/"em"; Kita "em", gọi "Machi-tan"; Spe xưng "mình";
## ê kíp gọi Oguri là "Oguri".

const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"

const AD := "Trợ lý đạo diễn"
const PUB := "Đại diện nhà phát hành"
const SPEAKER := "Loa"

const SCENES: Array[Dictionary] = [
	{"background": BG_RESTAURANT, "portrait": "",
		"line": "Kitasan đẩy cửa quán. Bên trong là cả một phim trường: đèn quay, máy quay, người đeo thẻ STAFF đi lại tất bật. Giữa quán là chiếc ghế đạo diễn in chữ \"0rca dev\"."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Chào buổi sáng ạ! Hôm nay em mở quán sớm—"},
	{"portrait": "", "speaker": AD,
		"line": "Diễn viên chính tới rồi! Vào vị trí!"},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Diễn viên chính?! Em chỉ tới nấu cơm thôi mà!"},
	{"portrait": "trainer", "speaker": "0rca's Trainer",
		"line": "Quán mình được một hãng lớn mua bản quyền, giờ là siêu phẩm AAA. Kịch bản đây."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "[i]\"Định mệnh của nhà hàng… nằm trong đôi tay này!\"[/i]"},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Em phải nói câu này thật à?"},
	{"portrait": "trainer2", "speaker": "0rca's Trainer",
		"line": "Một hội đồng mười hai người viết đấy. Không ai nhận là mình viết."},
	{"portrait": "tuandb", "speaker": "Special Week",
		"line": "Xin lỗi, sao kịch bản của mình trắng tinh vậy…"},
	{"portrait": "", "speaker": AD,
		"line": "À, vai của em với vai của Oguri thuộc gói Deluxe Edition."},
	{"portrait": "oui", "speaker": "Oguri Cap",
		"line": "…Thế còn được ăn không?"},
	{"portrait": "", "speaker": PUB,
		"line": "Ăn là một tính năng trả phí."},
	{"portrait": "oui", "speaker": "Oguri Cap",
		"line": "Vậy em xin chuyển sang tổ hậu cần. Ở đó có cơm hộp."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Còn Machi-tan đâu ạ?"},
	{"portrait": "trainer", "speaker": "0rca's Trainer",
		"line": "Hết cát xê. Đang xách nước bổ cam cho đoàn."},
	{"portrait": "", "speaker": PUB,
		"line": "Nhớ nhé, loot box đợi qua hạn hoàn tiền rồi mới thêm vào. Để người chơi không refund được."},
	{"portrait": "trainer2", "speaker": "0rca's Trainer",
		"line": "…Chơi mất dạy thật."},
	{"portrait": "", "speaker": AD,
		"line": "Máy… chạy! Diễn!"},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Wasshoi!"},
	{"portrait": "", "speaker": SPEAKER,
		"line": "Câu đó khó bản địa hoá. Thay bằng câu đã duyệt: \"Let's cook!\""},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Let's cook."},
]
