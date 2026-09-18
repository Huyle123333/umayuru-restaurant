extends RefCounted
## Kịch bản màn hướng dẫn — DỮ LIỆU thuần, không có logic.
##
## Cùng lối viết với kich_ban_prologue.gd: một mảng, mỗi phần tử một bước. Sửa
## lời thoại, đảo thứ tự hay chèn thêm một bước đều chỉ là sửa bảng này, không
## đụng tới bộ dẫn dắt. Nhờ vậy phần "dạy cái gì" và phần "làm sao biết người
## chơi đã làm được" nằm ở hai file khác nhau và không kéo nhau đổ.
##
## Mỗi bước có:
##   loi   — câu trainer nói
##   cho   — ĐIỀU KIỆN để bước này coi như xong. Bộ dẫn dắt hiểu các dạng:
##             "hoi"            hiện hai nút Có/Không, chờ người chơi bấm
##             "di_chuyen"      đi đủ QUANG_DUONG_HOC đơn vị
##             "cam:<id>"       trên tay đang cầm đúng vật phẩm đó
##             "ban_chua:<id>"  bàn chế tạo đang chứa vật phẩm đó
##             "thai"           thái xong một thứ ở thớt
##             "nau"            nấu xong một thứ ở bếp
##             "giao"           giao đúng món cho một bàn khách
##             "giay:<n>"       tự sang bước sau n giây (dùng cho câu dẫn)
##   viec  — việc bộ dẫn dắt làm NGAY khi bước này bắt đầu (tuỳ chọn):
##             "goi_khach"      cho một người khách bước vào quán
##
## Vì sao điều kiện là CHUỖI chứ không phải Callable: kịch bản phải đọc được
## như một tờ giấy. Nhét lambda vào bảng thì mỗi lần muốn biết bước 5 dạy gì
## lại phải đọc code, mà cái bảng này chính là thứ đưa cho người khác xem để
## góp ý về nội dung dạy.

## Đi đủ bao nhiêu đơn vị thì coi là "đã biết đi".
const QUANG_DUONG_HOC := 6.0

const BUOC := [
	{
		"loi": "Chào cậu! Lần đầu đứng bếp hả? Để tôi chỉ cho một lượt nhé — hay cậu muốn tự mò?",
		"cho": "hoi",
	},
	{
		"loi": "Trước hết là chân. Dùng [b]W A S D[/b] để đi quanh bếp, thử một vòng xem nào.",
		"cho": "di_chuyen",
	},
	{
		"loi": "Có khách rồi kìa! Nhìn cái bong bóng trên đầu họ là biết họ gọi món gì.",
		"cho": "giay:5",
		"viec": "goi_khach",
	},
	{
		"loi": "Họ muốn món [b]Steak[/b]. Ra chỗ [b]Tủ lạnh[/b], bấm [b]E[/b] rồi chọn Steak.",
		"cho": "cam:steak",
	},
	{
		"loi": "Thịt sống thì chưa ăn được. Mang tới cái [b]Thớt[/b], bấm [b]E[/b] để thái.",
		"cho": "thai",
	},
	{
		"loi": "Giờ đặt lên [b]Bếp[/b] rồi bấm [b]E[/b]. Nhớ canh chừng — để lâu là cháy đấy.",
		"cho": "nau",
	},
	{
		"loi": "Nhấc miếng thịt khỏi bếp, mang tới [b]Bàn chế tạo[/b] rồi bấm [b]E[/b] để đặt xuống.",
		"cho": "ban_chua:steak_cooked",
	},
	{
		"loi": "Món nào cũng phải bày ra đĩa. Lấy một cái ở [b]Chồng đĩa[/b], bỏ nốt vào bàn rồi bấm [b]F[/b] để ráp. Xong thì bấm [b]E[/b] nhấc món lên.",
		"cho": "cam:mon_steak",
	},
	{
		"loi": "Nhìn [b]số bàn[/b] trên tấm vé bên trái, mang món tới đúng bàn đó rồi bấm [b]E[/b].",
		"cho": "giao",
	},
	{
		"loi": "Chuẩn rồi! Cứ thế mà làm. Nhớ: [b]E[/b] đặt đồ, [b]F[/b] ráp món, [b]Q[/b] vứt đi, [b]1[/b] ẩn/hiện bảng đơn. Bấm [b]F1[/b] lúc nào cũng được để xem hướng dẫn đầy đủ.",
		"cho": "giay:7",
	},
]

## Chữ trên hai cái nút ở bước hỏi. Để ở đây cùng kịch bản chứ không nằm trong
## bộ dẫn dắt: đây vẫn là NỘI DUNG, và người sửa lời thoại phải sửa được nó mà
## không cần mở file code.
const NUT_CO := "Chỉ đi"
const NUT_KHONG := "Bỏ qua"
