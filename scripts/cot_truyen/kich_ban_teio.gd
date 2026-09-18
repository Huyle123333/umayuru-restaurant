extends RefCounted
## Màn ra mắt của Tokai Teio — đoạn cắt cảnh chen giữa "bấm Chơi" và "vào bếp".
##
## Một trong BA đoạn ra mắt của ba nhân vật ẩn (Teio, Chiyono O, Gold Ship).
## Chạy khi: đã mở khoá trong bảng CODE No.7, đang thật sự chọn Teio, chưa xem
## lần nào, và màn sắp vào là một màn chơi thật (không phải prologue).
##
## ------------------------------------------------------- Ý ĐỒ THIẾT KẾ
##
## BA ĐOẠN NÀY ĐỘC LẬP VỚI NHAU. Không đoạn nào nhắc tới hai đoạn kia, và
## không ai trong ba người xuất hiện trong đoạn của người khác.
##
## Vì sao phải cẩn thận chuyện đó: ba nhân vật ẩn được mở khoá theo thứ tự
## bất kỳ — người chơi có thể tìm ra Gold Ship trước Teio, hoặc chỉ mở đúng
## một người rồi thôi. Nếu đoạn của Teio nhắc "hôm nọ Gold Ship cũng xông
## vào" thì người chưa mở Gold Ship sẽ đọc một câu nói về người họ chưa từng
## gặp. Đội hình xuất hiện trong mỗi đoạn vì thế chỉ gồm team 0rca chính thức
## (Kitasan Black, Oguri Cap, Special Week, Huấn luyện viên) cộng đúng một
## người mới.
##
## TÍNH CÁCH TEIO: vui vẻ, năng động. Cô ấy không xin phép — cô ấy hỏi dồn,
## nói nhanh, và đã tự quyết trước khi ai kịp trả lời. Khác Gold Ship ở chỗ
## Teio thật lòng muốn giúp; Gold Ship thì chỉ muốn vui.

const NEN_QUAN := "res://assets/ui/backgrounds/quan_an.png"

const MAN: Array[Dictionary] = [
	{
		"nen": NEN_QUAN,
		"loi": "Bốn giờ chiều. Quán vừa dọn xong bàn cuối, chưa kịp ngồi.",
	},
	{
		"loi": "Chuông cửa reo. Rồi reo thêm bốn lần nữa, rất nhanh.",
	},
	{
		"anh": "hachimi",
		"ai": "Tokai Teio",
		"loi": "HÍ Ngọ! Nghe nói mọi người làm thêm ở đây đúng không? Mình cũng muốn giúp!",
	},
	{
		"anh": "kitamoi",
		"ai": "Kitasan Black",
		"loi": "Teio-san... chị đến giúp bọn em sao *cảm động rớt nước nắt*?",
	},
	{
		"anh": "hachimi",
		"ai": "Tokai Teio",
		"loi": "Biết chứ! Nên chị mới tới sớm! Thiếu người phải không? Chắc chắn thiếu người mà!",
	},
	{
		"anh": "trainer",
		"ai": "0rca's Trainer",
		"loi": "Em... định xin việc à?",
	},
	{
		"anh": "hachimi",
		"ai": "Tokai Teio",
		"loi": "Xin gì mà xin! Đây là thông báo không phải đè nghị! À mà bếp ở đâu? Tạp dề đâu? Chị buộc tóc trước nhé!",
	},
	{
		"anh": "oui",
		"ai": "Oguri Cap",
		"loi": "...Cậu ấy chạy nhanh thật.",
	},
	{
		"anh": "hachimi",
		"ai": "Tokai Teio",
		"loi": "Yên tâm đi! Tokai Teio này chưa thua ai bao giờ đâu — kể cả giờ cao điểm!",
	},
	{
		"anh": "",
		"ai": "",
		"loi": "Không ai nỡ nói với cô ấy rằng giờ cao điểm sẽ đánh cổ như tê liệt đánh fan.",
	},
]
