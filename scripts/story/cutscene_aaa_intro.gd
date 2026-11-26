extends RefCounted

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
	{"emotion": "nervous", "portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Em phải nói câu này thật à?"},
	{"portrait": "", "line": "Tổ biên kịch không ai dám nhìn vào mắt cô."},
	{"emotion": "surprise", "portrait": "tuandb", "speaker": "Special Week",
		"line": "Xin lỗi, sao kịch bản của mình trắng tinh vậy…"},
	{"portrait": "", "speaker": AD,
		"line": "À, vai của em với vai của Oguri thuộc gói Deluxe Edition."},
	{"portrait": "oui", "speaker": "Oguri Cap",
		"line": "…Thế bản thường thì em làm gì."},
	{"portrait": "", "speaker": PUB,
		"line": "Đứng nền. Có mặt trong trailer là được."},
	{"portrait": "oui", "speaker": "Oguri Cap",
		"line": "…Vậy diễn xong vai thì em có được lãnh cơm hộp không."},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Còn Machi-tan đâu ạ?"},
	{"portrait": "trainer", "speaker": "0rca's Trainer",
		"line": "Hết cát xê. Đang xách nước bổ cam cho đoàn."},
	{"portrait": "", "line": "Từ sau cánh gà, Machi-tan ôm thùng đạo cụ, lén vẫy vẫy tay về phía mọi người."},
	{"portrait": "", "speaker": PUB,
		"line": "Nhớ nhé, loot box đợi qua hạn hoàn tiền rồi mới thêm vào. Để người chơi không refund được."},
	{"portrait": "trainer2", "speaker": "0rca's Trainer",
		"line": "…Chơi mất dạy thật."},
	{"portrait": "", "speaker": AD,
		"line": "Máy… chạy! Diễn!"},
	{"emotion": "happy", "portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "Wasshoi!"},
	{"portrait": "", "speaker": SPEAKER,
		"line": "Câu đó khó bản địa hoá. Thay bằng câu đã duyệt: \"Let's cook!\""},
	{"portrait": "kitamoi", "speaker": "Kitasan Black",
		"line": "…Let's cook."},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Quán bỗng thành phim trường của một \"siêu phẩm AAA\". Kitasan bị đẩy vào vai chính, vai của Oguri nằm trong gói Deluxe Edition, còn Machi-tan hết cát xê nên đi xách nước. Đoàn làm phim bắt đầu quay: Let's cook."
