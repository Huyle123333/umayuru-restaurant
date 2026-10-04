extends RefCounted
## Kịch bản màn hướng dẫn — DỮ LIỆU thuần, không có logic.
##
## Cùng lối viết với cutscene_prologue.gd: một mảng, mỗi phần tử một bước. Sửa
## lời thoại, đảo thứ tự hay chèn thêm một bước đều chỉ là sửa bảng này, không
## đụng tới bộ dẫn dắt. Nhờ vậy phần "dạy cái gì" và phần "làm sao biết người
## chơi đã làm được" nằm ở hai file khác nhau và không kéo nhau đổ.
##
## Mỗi bước có:
##   line     — câu trainer nói
##   wait_for — ĐIỀU KIỆN để bước này coi như xong. Bộ dẫn dắt hiểu các dạng:
##             "ask"            hiện hai nút Có/Không, chờ người chơi bấm
##             "move"      đi đủ LEARN_DISTANCE đơn vị
##             "hold:<id>"       trên tay đang cầm đúng vật phẩm đó
##             "table_has:<id>"  bàn chế tạo đang chứa vật phẩm đó
##             "chop"           thái xong một thứ ở thớt
##             "cook"            nấu xong một thứ ở bếp
##             "serve"           giao đúng món cho một bàn khách
##             "seconds:<n>"       tự sang bước sau n giây (dùng cho câu dẫn)
##   action  — việc bộ dẫn dắt làm NGAY khi bước này bắt đầu (tuỳ chọn):
##             "spawn_customer"      cho một người khách bước vào quán
##
## Vì sao điều kiện là CHUỖI chứ không phải Callable: kịch bản phải đọc được
## như một tờ giấy. Nhét lambda vào bảng thì mỗi lần muốn biết bước 5 dạy gì
## lại phải đọc code, mà cái bảng này chính là thứ đưa cho người khác xem để
## góp ý về nội dung dạy.

## Đi đủ bao nhiêu đơn vị thì coi là "đã biết đi".
const LEARN_DISTANCE := 6.0

const STEPS := [
	{
		"line": " xin chào! Lần đầu đứng bếp hả? Để tôi chỉ cho một lượt nhé — hay muốn tự mò?",
		"wait_for": "ask",
	},
	{
		"line": "Trước hết là chân. Dùng [b]W A S D[/b] để đi quanh bếp, thử một vòng xem nào.",
		"wait_for": "move",
	},
	{
		"line": "Có khách rồi kìa! Nhìn cái bong bóng trên đầu họ là biết họ gọi món gì.",
		"wait_for": "seconds:5",
		"action": "spawn_customer",
	},
	{
		"line": "Họ muốn món [b]Steak[/b]. Ra chỗ [b]Tủ lạnh[/b], bấm [b]E[/b] rồi chọn Steak.",
		"wait_for": "hold:steak",
	},
	{
		"line": "Thịt sống thì chưa ăn được. Mang tới cái [b]Thớt[/b], bấm [b]E[/b] để thái.",
		"wait_for": "chop",
	},
	{
		"line": "Giờ đặt lên [b]Bếp[/b] rồi bấm [b]E[/b]. Nhớ canh chừng — để lâu là cháy đấy.",
		"wait_for": "cook",
	},
	{
		"line": "Nhấc miếng thịt khỏi bếp, mang tới [b]Bàn chế tạo[/b] rồi bấm [b]E[/b] để đặt xuống.",
		"wait_for": "table_has:steak_cooked",
	},
	{
		"line": "Món nào cũng phải bày ra đĩa. Lấy một cái ở [b]Chồng đĩa[/b], bỏ nốt vào bàn rồi bấm [b]F[/b] để ráp. Xong thì bấm [b]E[/b] nhấc món lên.",
		"wait_for": "hold:mon_steak",
	},
	{
		"line": "Nhìn [b]số bàn[/b] trên tấm vé bên trái, mang món tới đúng bàn đó rồi bấm [b]E[/b].",
		"wait_for": "serve",
	},
	{
		"line": "Chuẩn rồi! Cứ thế mà làm. Nhớ: [b]E[/b] đặt đồ, [b]F[/b] ráp món, [b]Q[/b] vứt đi, [b]1[/b] ẩn/hiện bảng đơn. Bấm [b]F1[/b] lúc nào cũng được để xem hướng dẫn đầy đủ.",
		"wait_for": "seconds:7",
	},
	# (1/10/2026) Câu chốt + hỏi mở quán. Trước đây học xong là bị đẩy thẳng
	# sang màn chọn nhân vật — đang đứng trong bếp thì cảnh đổi cái rụp, không
	# một lời. Câu này cho trainer khép bài học và trao quyền quyết cho người
	# chơi: ai chưa tự tin thì làm lại một lượt, không phải ra menu tìm.
	{
		"line": "Xong rồi đấy! Em đã nắm được hết những gì cần cho một buổi tối. Sắp tới giờ mở cửa rồi — mở quán luôn chứ, hay muốn thử lại một lượt?",
		"wait_for": "ask_finish",
	},
]

## Chữ trên hai cái nút ở bước hỏi. Để ở đây cùng kịch bản chứ không nằm trong
## bộ dẫn dắt: đây vẫn là NỘI DUNG, và người sửa lời thoại phải sửa được nó mà
## không cần mở file code.
const BTN_YES := "Chỉ đi"
const BTN_NO := "Bỏ qua"

## Hai nút của câu hỏi cuối bài.
const BTN_OPEN := "Mở quán"
const BTN_RETRY := "Thử lại"
