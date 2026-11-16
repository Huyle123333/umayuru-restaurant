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
##             "serve_count:<n>"   giao đúng món cho đủ n đơn (phần tự làm thử)
##   action  — việc bộ dẫn dắt làm NGAY khi bước này bắt đầu (tuỳ chọn):
##             "spawn_customer"      cho một người khách bước vào quán
##             "practice"            phần TỰ LÀM THỬ: PRACTICE_GUESTS khách gọi món
##                                   ngẫu nhiên (thực đơn Ngày 1), không tính
##                                   tiền, không cạn kiên nhẫn
##   allow   — (tuỳ chọn) các loại trạm được bấm ở bước này; trạm khác bị chặn
##             kèm lời nhắc. Bước 0–2 khoá hẳn tương tác (xem tutorial_director).
##             Luôn GỘP CẢ trạm của bước trước: bước vừa xong có thể còn để đồ
##             trên trạm đó (thịt thái xong nằm trên thớt, bước đã sang "nấu"),
##             chặn trạm cũ là người chơi không lấy đồ của chính mình ra được.
##   allow_item — (tuỳ chọn) món duy nhất được lấy ở tủ lạnh ở bước này.
##
## Vì sao điều kiện là CHUỖI chứ không phải Callable: kịch bản phải đọc được
## như một tờ giấy. Nhét lambda vào bảng thì mỗi lần muốn biết bước 5 dạy gì
## lại phải đọc code, mà cái bảng này chính là thứ đưa cho người khác xem để
## góp ý về nội dung dạy.

## Đi đủ bao nhiêu đơn vị thì coi là "đã biết đi".
const LEARN_DISTANCE := 6.0

## Phần tự làm thử (16/11/2026): số khách, và khoảng cách giữa hai lượt khách
## vào. Vào lệch nhau chứ không cùng lúc: ba vé hiện cùng lúc ngay sau bài học
## đầu tiên là quá tải; cách nhau vài giây thì người mới làm xong món này vừa
## kịp ngó sang vé tiếp.
const PRACTICE_GUESTS := 3
const PRACTICE_GAP := 6.0

const STEPS := [
	{
		"line": "Chào mừng tới bếp. Bạn có muốn xem hướng dẫn cơ bản trước khi bắt đầu không?",
		"wait_for": "ask",
	},
	{
		"line": "Di chuyển bằng [b]W A S D[/b]. Đi một vòng quanh bếp để làm quen.",
		"wait_for": "move",
	},
	{
		"line": "Khách đã vào. Món khách gọi hiện trên bong bóng phía trên đầu và trên vé đơn hàng.",
		"wait_for": "seconds:5",
		"action": "spawn_customer",
	},
	{
		"line": "Khách gọi [b]Steak[/b]. Đến [b]Tủ lạnh[/b], bấm [b]E[/b] và chọn Steak.",
		"wait_for": "hold:steak",
		"allow": ["fridge"],
		"allow_item": "steak",
	},
	{
		"line": "Mang thịt tới [b]Thớt[/b] và bấm [b]E[/b] để thái.",
		"wait_for": "chop",
		"allow": ["cutting_board"],
	},
	{
		"line": "Đặt thịt đã thái lên [b]Bếp[/b] và bấm [b]E[/b]. Để quá lâu thịt sẽ cháy.",
		"wait_for": "cook",
		"allow": ["cutting_board", "stove", "bin"],
	},
	{
		"line": "Lấy thịt chín khỏi bếp, mang tới [b]Bàn chế tạo[/b] và bấm [b]E[/b] để đặt xuống.",
		"wait_for": "table_has:steak_cooked",
		"allow": ["cutting_board", "stove", "crafting_table", "bin"],
	},
	{
		"line": "Mọi món phải có đĩa. Lấy đĩa ở [b]Chồng đĩa[/b], đặt lên bàn, bấm [b]F[/b] để ráp, rồi bấm [b]E[/b] để lấy món.",
		"wait_for": "hold:mon_steak",
		"allow": ["plate_stack", "crafting_table", "bin"],
	},
	{
		"line": "Xem [b]số bàn[/b] trên vé đơn hàng, mang món tới đúng bàn đó và bấm [b]E[/b].",
		"wait_for": "serve",
		"allow": ["guest_table", "crafting_table"],
	},
	# (16/11/2026) TỰ LÀM THỬ — sau bài Steak, ba khách gọi món ngẫu nhiên
	# để người chơi tự đọc vé và làm, không có ai cầm tay. Không tính tiền và
	# thanh kiên nhẫn không cạn: đây vẫn là chỗ tập, sai thì làm lại.
	{
		"line": "Phần thực hành: [b]3 khách[/b] sẽ gọi món ngẫu nhiên. Làm theo [b]công thức trên vé đơn hàng[/b].",
		"wait_for": "serve_count:3",
		"action": "practice",
	},
	{
		"line": "Hoàn thành. Tóm tắt: [b]E[/b] đặt và lấy đồ, [b]F[/b] ráp món, thùng rác để bỏ đồ, [b]1[/b] ẩn/hiện vé đơn hàng. Bấm [b]F1[/b] để xem hướng dẫn đầy đủ.",
		"wait_for": "seconds:7",
	},
	# (1/10/2026) Câu chốt + hỏi mở quán. Trước đây học xong là bị đẩy thẳng
	# sang màn chọn nhân vật — đang đứng trong bếp thì cảnh đổi cái rụp, không
	# một lời. Câu này cho trainer khép bài học và trao quyền quyết cho người
	# chơi: ai chưa tự tin thì làm lại một lượt, không phải ra menu tìm.
	{
		"line": "Bạn đã nắm các thao tác cơ bản. Mở quán ngay, hay thực hiện lại hướng dẫn?",
		"wait_for": "ask_finish",
	},
]

## Chữ trên hai cái nút ở bước hỏi. Để ở đây cùng kịch bản chứ không nằm trong
## bộ dẫn dắt: đây vẫn là NỘI DUNG, và người sửa lời thoại phải sửa được nó mà
## không cần mở file code.
const BTN_YES := "Xem hướng dẫn"
const BTN_NO := "Bỏ qua"

## Hai nút của câu hỏi cuối bài.
const BTN_OPEN := "Mở quán"
const BTN_RETRY := "Thử lại"
