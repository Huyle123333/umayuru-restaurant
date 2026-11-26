extends RefCounted
## ---------------------------------------------------------------- CÁCH VIẾT
## ------------------------------------------------------------ BỐN CẢNH NỀN
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
	{"emotion": "happy", 
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
		"line": "Em định về Hokkaido thăm mẹ vài hôm ạ.",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "Không biết nữa, chị chưa có dự định gì.",
	},
	{
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Hay là... chúng ta đi biển đi!",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "Biển. Được đấy.",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "chị tán thành.",
	},
	{"emotion": "shy", 
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
	{"emotion": "happy", 
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
	{"emotion": "sad", 
		"portrait": "oui",
		"speaker": "@",
		"line": "Xin lỗi! Em có lỡ ăn một ít.",
	},
	{"emotion": "sad", 
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
		"portrait": ["oui", "tuandb"],
		"speaker": "",
		"line": "[font_size=38]Xin lỗi, xin lỗi, xin lỗi × 3,14.[/font_size]",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Tôi không trách các em. Nhưng đúng là quỹ đang bằng không.",
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
		"line": "Tiền bối của tôi giờ mở một nhà hàng. Bác ấy vừa trẹo lưng, phải nằm nghỉ ba ngày — đúng dịp đầu hè đông khách nhất. Đóng cửa thì mất khách quen, nên bác nhờ team mình trông quán hộ.",
	},
	{
		"portrait": "trainer",
		"speaker": "0rca's Trainer",
		"line": "Bác bảo giữ được khách cho bác là đủ, doanh thu ba ngày đó coi như tiền công của chúng ta.",
	},
	{
		"portrait": "mambo",
		"speaker": "@",
		"line": "Ba ngày... Vậy là chúng ta có thể giải quyết được vấn đề kinh phí rồi.",
	},
	{"emotion": "surprise", 
		"portrait": "kitamoi",
		"speaker": "@",
		"line": "Nhà hàng thật á?! Có bếp to không ạ? Có treo lồng đèn không ạ?! Em muốn đi xem ngay bây giờ!",
	},
	{
		"portrait": "oui",
		"speaker": "@",
		"line": "...Ba ngày. Em làm được.",
	},
	{"emotion": "happy", "portrait": "tuandb",
		"speaker": "@",
		"line": "Ở nhà em hay nấu cùng mẹ. Bếp nhà hàng chắc cũng không khác mấy đâu ạ!",
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
		"line": "Nhưng nhớ giùm tôi: đồ trong bếp là để bán. Oguri, Special Week — tôi để ý hai em đấy.",
	},
	{
		"portrait": ["oui", "tuandb"],
		"speaker": "",
		"line": "...Vâng ạ.",
	},
	{"emotion": "happy", 
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

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Học viện Tracen sắp nghỉ hè, team 0rca rủ nhau đi biển. Nhưng Trainer báo quỹ của team đã cạn vì tiền ăn tháng này vượt dự tính khoảng 11 lần (thủ phạm: Oguri và Special Week). Đúng lúc đó, tiền bối của Trainer bị trẹo lưng và nhờ cả team trông nhà hàng giúp ba ngày, doanh thu ba ngày đó thuộc về team. Cả nhóm nhận lời và tới làm quen với căn bếp."
