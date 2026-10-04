extends RefCounted
## Đoạn HỘI Ý trước mỗi ngày: trainer và cả team chốt ai đứng bếp hôm nay.
##
## Chiếu sau màn chọn nhân vật, trước khi vào map — với MỌI màn chơi thật,
## trừ prologue và tutorial (hai màn đó luôn là Kitasan, xem
## GameData.STORY_CHARACTER). Cách chen vào: GameData.enter_level().
##
## Nhân vật ẩn chọn LẦN ĐẦU thì không thấy đoạn này — đoạn ra mắt riêng của họ
## (cutscene_golshi / teio / chiyono) chiếu thay. Từ lần thứ hai trở đi họ
## dùng chung đoạn này như mọi người.
##
## ------------------------------------------------------- CÁCH VIẾT
## Cùng định dạng với cutscene_prologue.gd, thêm hai khoá (bộ máy hiểu ở
## dialogue_player._pick_line()):
##   "line_by_player" — câu RIÊNG theo nhân vật người chơi chọn. Nhân vật
##                      không có mục thì dùng "line".
##   "line_by_level"  — câu riêng theo màn (Ngày 1 / 2 / 3).
##   "only_for_player" — mảng id; dòng này CHỈ hiện khi người chơi là một
##                      trong các nhân vật đó, còn lại bộ máy bỏ qua hẳn.
##
## Mọi câu nói của người đứng bếp dùng "portrait": "player" + "speaker": "@",
## nên mặt và tên luôn khớp với nhân vật vừa chọn. Câu của đồng đội dùng
## "other" — bốc một người KHÁC người chơi, giữ nguyên suốt đoạn.


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
		# Câu thứ hai CHỈ của Kitasan — tách riêng một lần bấm để câu "xin
		# phép phục vụ" có nhịp của riêng nó, như một lời chào sân khấu.
		# Nhân vật khác bỏ qua hẳn dòng này (khoá only_for_player).
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
		# CHỈ cho hai người hay "ăn một ít" (Oguri, Special Week): trainer nhắc
		# lại chuyện 564 phần hamburger ở prologue. Nhân vật khác bỏ qua hẳn
		# dòng này — nhắc người không ăn vụng thì câu đùa mất nghĩa.
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
