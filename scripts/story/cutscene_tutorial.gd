extends RefCounted

## Đi đủ bao nhiêu đơn vị thì coi là "đã biết đi".
const LEARN_DISTANCE := 6.0

## Phần tự làm thử (16/11/2026): số khách, và khoảng cách giữa hai lượt khách
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
	{
		"line": "Phần thực hành: [b]3 khách[/b] sẽ gọi món ngẫu nhiên. Làm theo [b]công thức trên vé đơn hàng[/b].",
		"wait_for": "serve_count:3",
		"action": "practice",
	},
	{
		"line": "Hoàn thành. Tóm tắt: [b]E[/b] đặt và lấy đồ, [b]F[/b] ráp món, thùng rác để bỏ đồ, [b]1[/b] ẩn/hiện vé đơn hàng. Bấm [b]F1[/b] để xem hướng dẫn đầy đủ.",
		"wait_for": "seconds:7",
	},
	{
		"line": "Bạn đã nắm các thao tác cơ bản. Mở quán ngay, hay thực hiện lại hướng dẫn?",
		"wait_for": "ask_finish",
	},
]

## Chữ trên hai cái nút ở bước hỏi. Để ở đây cùng kịch bản chứ không nằm trong
const BTN_YES := "Xem hướng dẫn"
const BTN_NO := "Bỏ qua"

## Hai nút của câu hỏi cuối bài.
const BTN_OPEN := "Mở quán"
const BTN_RETRY := "Thử lại"

## Tóm tắt hiện khi người chơi bấm "Bỏ qua".
const SUMMARY := "Hướng dẫn các thao tác cơ bản: di chuyển bằng WASD, lấy và đặt đồ bằng E, thái và nấu nguyên liệu, ráp món trên đĩa bằng F, rồi mang món tới đúng số bàn trên vé đơn hàng."
