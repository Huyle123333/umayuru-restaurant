extends RefCounted
## Kịch bản phần mở đầu — CHỈ CHỨA LỜI THOẠI, không chứa một dòng logic nào.
##
## Vì sao tách riêng khỏi bộ máy hội thoại (hoi_thoai.gd):
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
## Mỗi phần tử của MAN là MỘT lần bấm chuột. Các khoá đều KHÔNG bắt buộc:
##
##   "loi"  — câu thoại. Đây là khoá duy nhất gần như lúc nào cũng có.
##   "ai"   — tên người nói hiện trên thẻ tên. Bỏ trống hoặc không ghi
##            nghĩa là lời DẪN TRUYỆN: thẻ tên tự ẩn đi.
##            Ghi "@" thì bộ máy TỰ lấy tên riêng theo id ảnh đang hiện — kể
##            cả khi đó là nhân vật người chơi (không đổi thành "Bạn" nữa).
##            Các thành viên trong team đều dùng "@" thay vì gõ cứng tên, vì
##            "player" và "khac" là id ĐỘNG: chỉ tới lúc chạy mới biết là ai,
##            gõ cứng thì tên trên thẻ và mặt trong ảnh sẽ lệch nhau.
##            Câu ĐỒNG THANH thì để trống: mấy khuôn mặt cùng hiện đã nói rõ
##            ai đang nói, thẻ tên chỉ lặp lại thừa.
##   "anh"  — id ảnh chân dung, tra trong bảng ANH_NHAN_VAT của hoi_thoai.gd.
##            Hiện có: kitamoi, mambo, oui, tuandb, trainer, trainer2
##            (hachimi và chiyo vẫn còn trong bảng ảnh nhưng KHÔNG dùng ở
##            prologue: hai nhân vật này đã thành nhân vật ẩn, xem
##            GameData.NHAN_VAT_AN.)
##            (và golshi — nhưng KHÔNG dùng trong prologue, xem
##            kich_ban_golshi.gd.)
##            Ghi "player" thì lấy nhân vật người chơi vừa chọn ở màn trước —
##            nhờ vậy prologue tự khớp với lựa chọn của họ mà mình không phải
##            viết bốn bản kịch bản khác nhau.
##            Ghi "khac" thì bốc BẤT KỲ AI TRỪ người chơi (bốc một lần rồi
##            giữ nguyên suốt đoạn kể). Dùng cho câu mà người nói không thể
##            là chính mình.
##            Ghi "" (chuỗi rỗng) thì GỠ ảnh đang hiện xuống.
##            Ghi một MẢNG id — ["kitamoi", "oui"] — thì hiện nhiều chân dung
##            cạnh nhau, dùng cho câu đồng thanh.
##            KHÔNG ghi khoá này thì giữ nguyên ảnh của câu trước.
##   "nen"  — đường dẫn ảnh nền mới. Chỉ ghi ở câu MỞ ĐẦU một cảnh; bộ máy
##            sẽ tự làm hiệu ứng tối dần rồi sáng lại khi thấy khoá này.
##
## Chữ trong "loi" hỗ trợ BBCode: nhấn mạnh bằng [b]...[/b], đổi màu bằng
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
const NEN_DEN := "res://assets/ui/backgrounds/den.png"
const NEN_TRACEN := "res://assets/ui/backgrounds/tracen.png"
const NEN_PHONG := "res://assets/ui/backgrounds/phong_sinh_hoat.png"

const MAN: Array[Dictionary] = [
	# ------------------------------------------------ màn đen, nối tiếp video
	{
		"nen": NEN_DEN,
		"loi": "...Nhưng câu chuyện lần này sẽ không phải là về những cuộc đua của họ.",
	},
	{
		"loi": "Mà là...",
	},

	# ------------------------------------------------------ ngoại cảnh Tracen
	{
		"nen": NEN_TRACEN,
		"loi": "Học viện Tracen. Còn một tuần nữa là tới kỳ nghỉ hè.",
	},

	# ----------------------------------------------------- phòng sinh hoạt
	{
		"nen": NEN_PHONG,
		"loi": "Team 0rca — phòng sinh hoạt.",
	},
	{
		"anh": "kitamoi",
		"ai": "@",
		"loi": "HAAAAAAAH! Kỳ nghỉ sắp tới rồi, mọi người có dự định gì không?",
	},
	{
		"anh": "oui",
		"ai": "@",
		"loi": "Ăn.",
	},
	{
		"anh": "tuandb",
		"ai": "@",
		"loi": "Ăn.",
	},
	{
		"anh": "mambo",
		"ai": "@",
		"loi": "Không biết nữa, chị chưa có dự định gì.",
	},
	{
		"anh": "kitamoi",
		# [s]...[/s] = gạch ngang chữ. Cố ý, KHÔNG phải lỗi gõ: "cứ mãi nơi
		# đây" là một câu hát, gạch đi rồi viết tiếp là kiểu đùa trích lời bài
		# hát rồi tự bỏ ngang. Sửa thành câu xuôi là mất hẳn câu đùa.
		"ai": "@",
		"loi": "Hay là... [s]cứ mãi nơi đây[/s] chúng ta đi biển đi!",
	},
	{
		"anh": "oui",
		"ai": "@",
		"loi": "Biển... hải sản... tiệc BBQ... Được đấy.",
	},
	{
		"anh": "mambo",
		# Viết trống không, KHÔNG dấu — cố ý, đây là kiểu nói của Mambo.
		"ai": "@",
		"loi": "toi dong tinh.",
	},
	{
		"anh": "tuandb",
		"ai": "@",
		"loi": "Ưmmmm... Lần trước chị gửi cho mẹ ảnh chị mặc đồ bơi. Từ hôm đó mẹ chị bắt đầu gửi cho chị ít cà rốt hơn.",
	},
	{
		"anh": "kitamoi",
		"ai": "@",
		"loi": "Chúng ta còn nhiều hoạt động ngoài biển mà! [i](Training lv5 go brrrrrrr)[/i]",
	},
	{
		"anh": "tuandb",
		"ai": "@",
		"loi": "Mọi người đã vậy thì chị cũng bỏ phiếu tán thành.",
	},
	{
		"anh": "kitamoi",
		"ai": "@",
		"loi": "Yeahhh! Biến kỳ nghỉ này thành một mùa hè rực cháy nào!",
	},

	# ----------------------------------------------------------- tin dữ
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Xin lỗi vì làm gián đoạn niềm vui của các em, nhưng hiện tại chúng ta đang có một vấn đề nhỏ... hoặc hơi to.",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Team chúng ta hết kinh phí rồi.",
	},
	{
		# Câu ĐỒNG THANH: khoá "anh" nhận cả một MẢNG id, bộ máy xếp bốn chân
		# dung cạnh nhau. Bốn khuôn mặt đã nói rõ ai đang la, nên bỏ luôn thẻ
		# tên ("ai": "") thay vì gõ "Cả team" — chữ nhỏ ở thẻ tên chỉ lặp lại
		# thứ mà bức ảnh nói to hơn nhiều.
		"anh": ["kitamoi", "tuandb", "oui", "mambo"],
		"ai": "",
		"loi": "[font_size=46]HẢ?![/font_size]",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Chi phí ăn uống tháng này nhiều hơn dự tính... tầm [b]11 lần[/b].",
	},
	{
		"anh": "",
		"loi": "Dù không ai nói gì, mọi ánh mắt đều đổ dồn về hai con ngọ bel ú nu ngồi cuối bàn.",
	},
	{
		"anh": "oui",
		"ai": "@",
		"loi": "Xin lỗi! Em có lỡ ăn một ít.",
	},
	{
		"anh": "tuandb",
		"ai": "@",
		"loi": "Em... em cũng vậy.",
	},
	{
		"anh": "trainer2",
		"ai": "0rca's Trainer",
		"loi": "\"Một ít\" của hai em là [b]564[/b] phần hamburger cà rốt size max dành cho mã nương.",
	},
	{
		# Cũng là câu đồng thanh, hai người.
		"anh": ["oui", "tuandb"],
		"ai": "",
		"loi": "[font_size=38]Xin lỗi × 3,14.[/font_size]",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Không ai bắt đền ai cả. Nhưng đúng là quỹ đang bằng không.",
	},

	# ------------------------------------------------------- cuộc điện thoại
	{
		"anh": "",
		"loi": "Cả phòng chìm vào im lặng.",
	},
	{
		"anh": "",
		"loi": "[i]Your phone ringing... your phone ringing...[/i]",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Xin phép các em, tôi có điện thoại.",
	},
	{
		"anh": "trainer2",
		"ai": "0rca's Trainer",
		"loi": "...Dạ cháu đây... vâng... vâng... dạ... thật ạ... Bác cứ để cháu... vâng... dạ chào bác, cho cháu gửi lời hỏi thăm đến mọi người nhé.",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Chúng ta có một tin tốt.",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "...Một người quen của tôi có một nhà hàng. Ông ấy bận việc ba ngày, cần người trông hộ.",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Đổi lại, [b]toàn bộ doanh thu ba ngày đó là của chúng ta[/b].",
	},
	{
		"anh": "mambo",
		"ai": "@",
		"loi": "Ba ngày... Vậy là chúng ta có thể giải quyết được vấn đề kinh phí rồi.",
	},
	{
		# Kịch bản giấy giao câu này cho Kitasan, nhưng ở đây phải là "khac".
		# Lý do: câu này dẫn thẳng tới cảnh cả team quay sang nhìn NGƯỜI CHƠI.
		# Người chơi có thể đang chọn chính Kitasan — lúc đó thành tự hỏi "ai
		# nấu?" rồi tự chỉ vào mình. "khac" bốc một người cố định cho cả đoạn,
		# nên đây cũng chính là người khen ở câu dưới, đọc liền mạch.
		"anh": "khac",
		"ai": "@",
		"loi": "Ba ngày thì được. Nhưng ai nấu?",
	},
	{
		"anh": "trainer2",
		"ai": "0rca's Trainer",
		"loi": "Ai đứng bếp cũng được. Nhưng nhớ giùm tôi: đồ nấu ra là để bán.",
	},
	{
		"anh": "",
		"loi": "Cả team quay sang nhìn một người.",
	},
	{
		"anh": "player",
		"ai": "@",
		"loi": "...Mình á?",
	},
	{
		# "khac" = bất kỳ ai TRỪ người chơi. Không được để người chơi tự khen
		# mình nấu ngon nhất team.
		"anh": "khac",
		"ai": "@",
		"loi": "Cậu nấu ngon nhất team mà! Quyết định vậy nhé!",
	},
	{
		"anh": "player",
		"ai": "@",
		"loi": "Thôi được. Ba ngày. Vì chuyến đi.",
	},

	# --------------------------------------------------------- khép màn đen
	{
		"nen": NEN_DEN,
		"anh": "",
		"ai": "",
		"loi": "Ngày thứ nhất — quán mở cửa lúc bảy giờ kém mười tối.\nCòn ba mươi phút để làm quen với căn bếp.",
	},
]
