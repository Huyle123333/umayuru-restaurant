extends RefCounted
## ------------------------------------------------------- CÁCH VIẾT


const BG_RESTAURANT := "res://assets/ui/backgrounds/quan_an.png"
const BG_BLACK := "res://assets/ui/backgrounds/den.png"

const SCENES: Array[Dictionary] = [
	# --------------------------------------------------------------- mở cảnh
	{
		"background": BG_RESTAURANT,
		"portrait": "",
		"line": "Nhà hàng — ba mươi phút trước giờ mở cửa.",
		"line_by_level": {
			"d1_sang": "Ngày thứ nhất — ba mươi phút trước giờ mở cửa.",
			"d2_sang": "Ngày thứ hai — ba mươi phút trước giờ mở cửa.",
			"d3_sang": "Ngày cuối cùng — ba mươi phút trước giờ mở cửa.",
		},
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Trước khi mở cửa, chốt một việc: hôm nay ai đứng bếp?",
		"line_by_level": {
			"d3_sang": "Ngày cuối rồi. Quỹ đội có lên được hay không là ở hôm nay. Ai đứng bếp?",
		},
	},
	{
		"portrait": "other",
		"speaker": "@",
		"line": "Ai cũng được ạ. Miễn là món ra đúng giờ.",
	},

	# -------------------------------------------- người đứng bếp nhận việc
	{
		"portrait": "player",
		"speaker": "@",
		"line": "Để em.",
		"line_by_player": {
			"kitamoi": "Đây rồi, đây rồi! Không khí của lễ hội đang bao trùm căn bếp!",
			"hachimi": "Để Teio-sama! Nấu ăn cũng là một cuộc đua thôi — mà mị thì bất bại đấy nhé!",
			"chiyo": "E-Em xin nhận ạ! Em biết đảo cánh rán gà, dọn dẹp cũng gọn gàng. Nhất định không để mọi người thất vọng!",
			"mambo": "Em đứng bếp cho. Hôm nay em nhất định không thua đâu... mà cũng chẳng biết thua ai nữa.",
			"oui": "Em đứng bếp. ...Nếm thử thì được, đúng không?",
			"tuandb": "Em! Mọi giác quan của em đang hướng về phía bếp từ nãy rồi ạ! Nhưng để chắc ăn thì cứ nếm thử trước, hì hì!",
			"golshi": "Gold Ship nhận bếp! Thực đơn hôm nay là món bí mật của vũ trụ — đùa thôi, ta nấu đúng thực đơn. Lần này thì không đùa...hoặc không.",
		},
	},

	{
		"only_for_player": ["kitamoi"],
		"portrait": "player",
		"speaker": "@",
		"line": "Mã nương của lễ hội xin phép được phục vụ!",
	},

	# ------------------------------------------------- trainer đáp lại
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Được, bếp giao cho em.",
		"line_by_player": {
			"kitamoi": "Được. Nhưng lồng đèn để sau giờ đóng cửa hẵng treo nhé.",
			"hachimi": "Được. Bất bại thì càng tốt — khách không đợi người thua đâu.",
			"chiyo": "Được. Cứ bình tĩnh, làm từng món một là kịp.",
			"mambo": "Được. Đối thủ hôm nay là đồng hồ, không phải ai khác.",
			"golshi": "...Tôi sẽ tin câu cuối cùng của em.",
		},
	},
	{
		"only_for_player": ["oui", "tuandb"],
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "Nhớ giùm tôi: đồ nấu ra là để bán.",
		"line_by_player": {
			"oui": "Nhớ giùm tôi: đồ nấu ra là để bán. Nếm thì được, ăn hết thì không. Tôi đang nhìn đấy.",
			"tuandb": "Nhớ giùm tôi: đồ nấu ra là để bán. Nếm thì được, nhưng nếm xong nhớ chừa lại cho khách một ít.",
		},
	},

	# ---------------------------------------------------------- vào ca
	{
		"portrait": "other",
		"speaker": "@",
		"line": "Ngoài sảnh để bọn tớ lo. Cố lên nhé!",
	},
	{
		"portrait": "player",
		"speaker": "@",
		"line": "Được rồi. Mở cửa thôi!",
		"line_by_player": {
			"kitamoi": "Vậy thì — lễ hội mở màn!",
			"chiyo": "\"Có công mài sắt, có ngày nên kim\"! ...Tai mình đang rung đấy ạ.",
			"golshi": "Quỳ xuống, hỡi chảo! Gold Ship tới rồi!",
		},
	},
	{
		"background": BG_BLACK,
		"portrait": "",
		"speaker": "",
		"line": "Quán mở cửa.",
	},
]

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Ba mươi phút trước giờ mở cửa, cả team chốt người đứng bếp hôm nay. Những người còn lại lo ngoài sảnh. Quán mở cửa."
