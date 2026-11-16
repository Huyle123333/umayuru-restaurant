extends RefCounted
## Kịch bản phần mở đầu — CHỈ CHỨA LỜI THOẠI, không chứa một dòng logic nào.
##
## Vì sao tách riêng khỏi bộ máy hội thoại (dialogue_player.gd):
## Cốt truyện là thứ sẽ sửa nhiều nhất và sửa lâu nhất — thêm câu, đổi chữ,
## đảo thứ tự cảnh. Nếu để lẫn với code chạy chữ và code chuyển cảnh thì mỗi
## lần sửa một dấu phẩy trong lời thoại lại phải đọc qua cả bộ máy, và rất dễ
## gõ nhầm làm hỏng scene. Tách ra thì file này chỉ là DỮ LIỆU: gõ sai cũng
## chỉ sai chữ hiện lên, không bao giờ làm game không chạy.
##
## Đây cũng là cách các engine visual novel (Ren'Py, Naninovel) làm: kịch bản
## là dữ liệu, trình diễn là chương trình. Về sau muốn đổi sang đọc từ file
## .json hay .csv để người viết truyện sửa mà không cần mở Godot thì chỉ phải
## thay đúng file này, bộ máy giữ nguyên.
##
## ---------------------------------------------------------------- CÁCH VIẾT
## Mỗi phần tử của SCENES là MỘT lần bấm chuột. Các khoá đều KHÔNG bắt buộc:
##
##   "line"  — câu thoại. Đây là khoá duy nhất gần như lúc nào cũng có.
##   "speaker"   — tên người nói hiện trên thẻ tên. Bỏ trống hoặc không ghi
##            nghĩa là lời DẪN TRUYỆN: thẻ tên tự ẩn đi.
##            Ghi "@" thì bộ máy TỰ lấy tên riêng theo id ảnh đang hiện — kể
##            cả khi đó là nhân vật người chơi (không đổi thành "Bạn" nữa).
##            Các thành viên trong team đều dùng "@" thay vì gõ cứng tên, vì
##            "player" và "other" là id ĐỘNG: chỉ tới lúc chạy mới biết là ai,
##            gõ cứng thì tên trên thẻ và mặt trong ảnh sẽ lệch nhau.
##            Câu ĐỒNG THANH thì để trống: mấy khuôn mặt cùng hiện đã nói rõ
##            ai đang nói, thẻ tên chỉ lặp lại thừa.
##   "portrait"  — id ảnh chân dung, tra trong bảng PORTRAITS của dialogue_player.gd.
##            Hiện có: kitamoi, mambo, oui, tuandb, trainer, trainer2
##            (hachimi và chiyo vẫn còn trong bảng ảnh nhưng KHÔNG dùng ở
##            prologue: hai nhân vật này đã thành nhân vật ẩn, xem
##            GameData.NHAN_VAT_AN.)
##            (và golshi — nhưng KHÔNG dùng trong prologue, xem
##            cutscene_golshi.gd.)
##            Ghi "player" thì lấy nhân vật người chơi đang chọn. (Prologue
##            giờ luôn là Kitasan — xem GameData.STORY_CHARACTER — nên kịch bản
##            này gọi thẳng "kitamoi"; "player" dùng ở các đoạn hội ý trước
##            mỗi ngày.)
##            Ghi "other" thì bốc BẤT KỲ AI TRỪ người chơi (bốc một lần rồi
##            giữ nguyên suốt đoạn kể). Dùng cho câu mà người nói không thể
##            là chính mình.
##            Ghi "" (chuỗi rỗng) thì GỠ ảnh đang hiện xuống.
##            Ghi một MẢNG id — ["kitamoi", "oui"] — thì hiện nhiều chân dung
##            cạnh nhau, dùng cho câu đồng thanh.
##            KHÔNG ghi khoá này thì giữ nguyên ảnh của câu trước.
##   "background"  — đường dẫn ảnh nền mới. Chỉ ghi ở câu MỞ ĐẦU một cảnh; bộ máy
##            sẽ tự làm hiệu ứng tối dần rồi sáng lại khi thấy khoá này.
##
## Chữ trong "line" hỗ trợ BBCode: nhấn mạnh bằng [b]...[/b], đổi màu bằng
## [color=#ffcc55]...[/color], gạch ngang bằng [s]...[/s], và phóng to một
## câu hét bằng [font_size=46]...[/font_size] (cỡ chữ thường là 26).
##
## ------------------------------------------------------------ BỐN CẢNH NỀN
## Đoạn mở đầu đi qua bốn nền, theo đúng thứ tự trong kịch bản gốc:
## màn đen (nối tiếp video intro_prologue.ogv) -> ngoại cảnh học viện Tracen
## -> phòng sinh hoạt của team -> màn đen (thẻ tên game).
##
## Ba ảnh nền để riêng thành hằng số chứ không gõ thẳng đường dẫn vào từng
## câu: cảnh phòng sinh hoạt chiếm gần ba mươi câu, đổi ảnh mà phải sửa ba
## mươi chỗ thì kiểu gì cũng sót một chỗ.
const BG_BLACK := "res://assets/ui/backgrounds/den.png"
const BG_TRACEN := "res://assets/ui/backgrounds/tracen.png"
const BG_ROOM := "res://assets/ui/backgrounds/phong_sinh_hoat.png"

const SCENES: Array[Dictionary] = [
	# ------------------------------------------------ màn đen, nối tiếp video
	{
		"background": BG_BLACK,
		"line": "...Nhưng câu chuyện lần này sẽ không phải là về những cuộc đua của họ.",
	},
	{
		"line": "Mà là...",
	},

	# ------------------------------------------------------ ngoại cảnh Tracen
	{
		"background": BG_TRACEN,
		"line": "Học viện Tracen. Còn một tuần nữa là tới kỳ nghỉ hè.",
	},

	# ----------------------------------------------------- phòng sinh hoạt
	{
		"background": BG_ROOM,
		"line": "Team 0rca — phòng sinh hoạt.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "HAAAAAAAH! Kỳ nghỉ sắp tới rồi, mọi người có dự định gì không?",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "Ăn.",
	},
	{
		"portrait": "tuandb",
		"speaker": "@",
		"line": "Ăn.",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "Không biết nữa, chị chưa có dự định gì.",
	},
	{
		"portrait": "kitamoi",
		# [s]...[/s] = gạch ngang chữ. Cố ý, KHÔNG phải lỗi gõ: "cứ mãi nơi
		# đây" là một câu hát, gạch đi rồi viết tiếp là kiểu đùa trích lời bài
		# hát rồi tự bỏ ngang. Sửa thành câu xuôi là mất hẳn câu đùa.
		"speaker": "@",
		"line": "Hay là... [s]cứ mãi nơi đây[/s] chúng ta đi biển đi!",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "Biển... hải sản... tiệc BBQ... Được đấy.",
	},
	{
		"portrait": "mambo",
		# Câu ngắn, cụt — kiểu nói của Mambo (user sửa 12/11/2026).
		"speaker": "@",
		"line": "chị tán thành.",
	},
	{
		"portrait": "tuandb",
		"speaker": "@",
		"line": "Ưmmmm... Lần trước chị gửi cho mẹ ảnh chị mặc đồ bơi. Từ hôm đó mẹ chị bắt đầu gửi cho chị ít cà rốt hơn.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Chúng ta còn nhiều hoạt động ngoài biển mà! [i](Training lv5 go brrrrrrr)[/i]",
	},
	{
		"portrait": "tuandb",
		"speaker": "@",
		"line": "Mọi người đã vậy thì chị cũng bỏ phiếu tán thành.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Yeahhh! Biến kỳ nghỉ này thành một mùa hè rực cháy nào!",
	},

	# ----------------------------------------------------------- tin dữ
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Xin lỗi vì làm gián đoạn niềm vui của các em, nhưng hiện tại chúng ta đang có một vấn đề nhỏ... hoặc hơi to.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Team chúng ta hết kinh phí rồi.",
	},
	{
		# Câu ĐỒNG THANH: khoá "portrait" nhận cả một MẢNG id, bộ máy xếp bốn chân
		# dung cạnh nhau. Bốn khuôn mặt đã nói rõ ai đang la, nên bỏ luôn thẻ
		# tên ("speaker": "") thay vì gõ "Cả team" — chữ nhỏ ở thẻ tên chỉ lặp lại
		# thứ mà bức ảnh nói to hơn nhiều.
		"portrait": ["kitamoi", "tuandb", "oui", "mambo"],
		"speaker": "",
		"line": "[font_size=46]HẢ?![/font_size]",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Chi phí ăn uống tháng này nhiều hơn dự tính... tầm 11 lần.",
	},
	{
		"portrait": "",
		"line": "Dù không ai nói gì, mọi ánh mắt đều đổ dồn về hai con ngọ bel ú nu ngồi cuối bàn.",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "Xin lỗi! Em có lỡ ăn một ít.",
	},
	{
		"portrait": "tuandb",
		"speaker": "@",
		"line": "Em... em cũng vậy.",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "\"Một ít\" của hai em là 564 phần hamburger cà rốt size max dành cho mã nương.",
	},
	{
		# Cũng là câu đồng thanh, hai người.
		"portrait": ["oui", "tuandb"],
		"speaker": "",
		"line": "[font_size=38]Xin lỗi × 3,14.[/font_size]",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Không ai bắt đền ai cả. Nhưng đúng là quỹ đang bằng không.",
	},

	# ------------------------------------------------------- cuộc điện thoại
	{
		"portrait": "",
		"line": "Cả phòng chìm vào im lặng.",
	},
	{
		"portrait": "",
		"line": "[i]Your phone ringing... your phone ringing...[/i]",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Xin phép các em, tôi có điện thoại.",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "...Dạ cháu đây... vâng... vâng... dạ... thật ạ... Bác cứ để cháu... vâng... dạ chào bác, cho cháu gửi lời hỏi thăm đến mọi người nhé.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Chúng ta có một tin tốt.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "...Một người quen của tôi có một nhà hàng. Ông ấy bận việc ba ngày, cần người trông hộ.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Đổi lại, toàn bộ doanh thu ba ngày đó là của chúng ta.",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "Ba ngày... Vậy là chúng ta có thể giải quyết được vấn đề kinh phí rồi.",
	},
	# (1/10/2026) BỎ đoạn "ai nấu?" → cả team quay sang người chơi → "Mình
	# á?". Prologue và tutorial giờ luôn chơi bằng Kitasan, nên chuyện ai đứng
	# bếp không còn được quyết ở đây — nó chuyển sang đoạn hội ý trước MỖI
	# NGÀY (cutscene_kitchen_meeting.gd), ngay sau khi người chơi chọn nhân vật.
	# Ở đây cả team chỉ muốn tới xem cái quán trước đã.
	#
	# Lời thoại dựa trên hồ sơ GameTora: Kitasan mê không khí lễ hội và hay
	# quyết định theo cảm hứng; Oguri Cap chỉ thích "ăn đồ ngon"; Special Week
	# nghe tiếng nấu nướng là tai tự quay về phía bếp.
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Nhà hàng thật á?! Có bếp to không ạ? Có treo lồng đèn không ạ?! Em muốn đi xem ngay bây giờ!",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "...Nhà hàng thì có đồ ăn.",
	},
	{
		"portrait": "tuandb",
		"speaker": "@",
		"line": "Tai em đã nghe thấy tiếng chảo xèo xèo rồi đấy ạ! Mình đi luôn đi!",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "Đi xem trước cũng hay. Phải kiểm tra thật kĩ thời tiết, địa hình... à, đây đâu phải cuộc đua nhỉ.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Được. Tối nay quán chưa mở cửa, cả team qua đó làm quen với căn bếp trước.",
	},
	{
		"portrait": "trainer2",
		"speaker": "0rca's Trainer",
		"line": "Nhưng nhớ giùm tôi: đồ trong bếp là để bán. Oguri, Special Week — tôi đang nhìn hai em đấy.",
	},
	{
		"portrait": ["oui", "tuandb"],
		"speaker": "",
		"line": "...Vâng ạ.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Vậy thì xuất phát thôi! Mùa hè rực cháy bắt đầu từ căn bếp!",
	},

	# --------------------------------------------------------- khép màn đen
	{
		"background": BG_BLACK,
		"portrait": "",
		"speaker": "",
		"line": "Ngày thứ nhất — quán mở cửa lúc bảy giờ kém mười tối.\nCòn ba mươi phút để làm quen với căn bếp.",
	},
]
