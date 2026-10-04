extends RefCounted
## Nội dung của menu hướng dẫn (F1) — DỮ LIỆU thuần, không có logic vẽ.
##
## Cùng lối viết với cutscene_prologue.gd và cutscene_tutorial.gd: sửa nội dung
## là sửa bảng này, không đụng tới file dựng giao diện. Ba file kịch bản của
## game giờ đọc giống nhau, nên người sửa chữ chỉ phải học MỘT quy ước.
##
## MỖI MỤC là một Dictionary {id, name, blocks}. `blocks` là danh sách các khối nội
## build, mỗi khối một loại:
##
##   {"h":   "Tiêu đề nhỏ"}
##   {"p":   "Đoạn văn, có BBCode"}
##   {"key_label": [["E", "việc"], ...]}      bảng phím hai cột
##   {"img": "res://...png", "caption": ""} ảnh minh hoạ kèm chú thích
##   {"recipe": "table"|"oven"}           bảng công thức TỰ SINH từ ItemCatalog
##
## Vì sao có loại khối "recipe" thay vì gõ tay danh sách món:
##
## Công thức là thứ đổi nhiều nhất trong cả game — riêng tuần này đã thêm ba
## món và khoá/mở một nhánh cơ chế. Gõ tay vào đây thì trang hướng dẫn sẽ nói
## sai ngay lần sửa công thức đầu tiên, mà nó nói sai một cách IM LẶNG: không
## có lỗi nào báo, chỉ có người chơi làm theo rồi không ra món. Sinh thẳng từ
## ItemCatalog thì trang này không bao giờ lệch được với luật thật.
##
## ẢNH: đặt ở res://assets/ui/huong_dan/<tên>.png. Thiếu ảnh thì khối đó tự bỏ
## qua, không báo lỗi và không để lại ô trống — nên khai sẵn đường dẫn rồi bổ
## sung ảnh sau lúc nào cũng được.

const IMAGE_DIR := "res://assets/ui/huong_dan/"

const SECTIONS := [
	# ══════════════════════════════════════════════════════════ GIAO DIỆN ══
	{
		"id": "interface",
		"name": "Giao diện",
		"blocks": [
			{"p": "Màn hình chia làm bốn góc, mỗi góc trả lời một câu hỏi khác nhau. Biết góc nào trả lời câu gì thì không phải quét cả màn hình."},

			{"h": "Bên trái — Bảng đơn hàng"},
			{"p": "Mỗi tấm vé là một khách [b]đang ngồi bàn[/b]: ảnh món, tên món, giá, [b]số bàn[/b] và bar kiên nhẫn. Vé xếp theo kiên nhẫn còn lại nên [b]vé trên cùng luôn là việc gấp nhất[/b].\n\nBấm [b]1[/b] để đẩy bảng vào cho rộng tầm nhìn. Lúc đóng vẫn còn một cái nhãn nhỏ ở mép trái cho biết đang có mấy đơn, và viền nhãn mang màu của đơn gấp nhất."},
			{"img": IMAGE_DIR + "bang_don_hang.png", "caption": "Bảng đơn hàng và cái nhãn khi đóng"},

			{"h": "Góc trên phải — Đồng hồ và ví"},
			{"p": "Thời gian còn lại của màn, và tổng tiền đã kiếm. Dưới 30 giây thì đồng hồ chuyển đỏ. Trong màn hướng dẫn đồng hồ hiện [b]--:--[/b] vì màn đó không tính giờ."},

			{"h": "Đáy giữa — Danh sách trạm trong tầm"},
			{"p": "Những thứ bạn [b]bấm được ngay lúc này[/b], kèm phím tương ứng. Đứng giữa nhiều trạm thì bấm [b]Tab[/b] để đổi mục tiêu, hoặc nhắm thẳng bằng tâm ngắm ở góc nhìn thứ ba."},

			{"h": "Thanh tiến trình — nổi trên từng trạm"},
			{"p": "Mỗi trạm đang chạy có [b]bar riêng[/b] nổi ngay trên nó: hai cái bếp, lò nướng và thớt. Nhìn bar là biết luôn nó của trạm nào, không phải đọc chữ.\n\nĐi xa thì bar [b]không biến mất[/b] mà bị kẹp lại ở mép màn hình — bar nằm ở mép trái nghĩa là cái trạm đó đang ở bên trái bạn.\n\n[color=#f08a33]Cam, đầy dần[/color] — đang nấu.\n[color=#c4433a]Đỏ, vơi dần[/color] — món đã chín và đang chờ trên bếp, vơi hết là [b]cháy[/b]. Nhấp nháy nghĩa là sắp cháy tới nơi."},

			{"h": "Góc dưới trái — Bản thân bạn"},
			{"p": "Thanh thể lực, thứ đang cầm trên tay, và biểu tượng kĩ năng chủ động. Biểu tượng xám nghĩa là chưa đủ điều kiện dùng."},

			{"h": "Phím"},
			{"key_label": [
				["W A S D", "Đi lại (phím mũi tên cũng được)"],
				["Shift", "Chạy nhanh — tiêu thể lực"],
				["E", "Tương tác: cầm, đặt, lấy ra, giao món"],
				["F", "Ráp món ở bàn chế tạo"],
				["Q", "Vứt thứ đang cầm xuống đất"],
				["Tab", "Đổi mục tiêu khi đứng giữa nhiều trạm"],
				["Space", "Kĩ năng chủ động"],
				["1", "Ẩn/hiện bảng đơn hàng"],
				["C", "Đóng bảng chọn nguyên liệu"],
				["P", "Đổi góc nhìn"],
				["F1", "Mở/đóng bảng hướng dẫn này"],
				["ESC", "Tạm dừng"],
			]},
		],
	},

	# ═════════════════════════════════════════════════════════ KHÁCH HÀNG ══
	{
		"id": "customers",
		"name": "Khách hàng",
		"blocks": [
			{"h": "Một người khách đi qua bốn chặng"},
			{"p": "[b]1. Xếp hàng.[/b] Khách vào cửa và đứng vào hàng đợi. Món họ muốn hiện ngay trong bong bóng trên đầu, kể cả khi chưa có bàn nào trống — nhìn cái hàng là biết công việc sắp tới.\n\n[b]2. Ngồi bàn.[/b] Có bàn trống thì người đầu hàng đi vào ngồi. Lúc này tấm vé của họ hiện ra ở bảng bên trái, kèm số bàn.\n\n[b]3. Ăn.[/b] Giao đúng món là xong đơn — tiền đã được chốt ngay lúc đó. Họ ngồi ăn thêm vài giây, và trong lúc đó cái bàn vẫn bị chiếm.\n\n[b]4. Về.[/b] Số tiền bay lên ở chỗ cái bàn, rồi khách đi ra cửa và trả lại bàn."},
			{"img": IMAGE_DIR + "vong_doi_khach.png", "caption": "Bong bóng đơn trên đầu khách xếp hàng"},

			{"h": "Hai bar kiên nhẫn, hai chỗ khác nhau"},
			{"p": "[b]Lúc xếp hàng[/b] — bar nằm trong bong bóng trên đầu khách, [b]45 giây[/b] cho mọi món. Cố định chứ không theo món, vì lúc này khách chưa được phục vụ gì cả nên thời gian chờ dài ngắn theo món là thứ bạn không đoán được.\n\n[b]Lúc ngồi bàn[/b] — bar nằm trên tấm vé, và [b]dài ngắn theo món[/b]: món càng lâu làm thì khách càng kiên nhẫn. Ngồi được vào bàn là bar [b]nạp đầy lại[/b], không mang theo phần đã chờ ở cửa."},

			{"h": "Đơn hoàn hảo"},
			{"p": "Giao khi kiên nhẫn còn [b]trên một nửa[/b] thì được thưởng thêm [b]35%[/b] giá món. Vạch trắng ở giữa bar chính là cái mốc đó — nhắm vào vạch trắng, đừng nhắm vào lúc bar sắp cạn."},

			{"h": "Ba bậc màu"},
			{"p": "[color=#4f9d5d]Xanh[/color] còn trên 50% (vẫn kịp hoàn hảo) · [color=#d9a520]Vàng[/color] 20–50% · [color=#c4433a]Đỏ[/color] dưới 20%. Đổi màu theo bậc chứ không chuyển dần, để đọc được bằng khoé mắt lúc đang bận chỗ khác."},

			{"h": "Khi khách bỏ đi"},
			{"p": "Hết kiên nhẫn thì khách cáu, dậm chân rồi bỏ ra cửa. Bạn [b]không bị trừ tiền[/b] — mất doanh thu của đơn đó đã là hình phạt rồi. Nhưng bàn vẫn bị chiếm tới khi họ ra khỏi quán."},

			{"h": "Giao nhầm món"},
			{"p": "Bàn [b]không nhận[/b], và món nằm lại trên mặt bàn. Bấm [b]E[/b] tay không để nhấc lại rồi mang đi đúng bàn. Không mất gì ngoài thời gian — nhưng trong một màn bảy phút thì thời gian là thứ đắt nhất."},
		],
	},

	# ══════════════════════════════════════════════════════════ CÔNG THỨC ══
	{
		"id": "recipe",
		"name": "Công thức",
		"blocks": [
			{"p": "Thứ tự bỏ nguyên liệu [b]không quan trọng[/b] — chỉ cần đủ và không thừa. Thừa một thứ là công thức không khớp, nên nhìn bảng bên cạnh bàn để biết mình đã bỏ gì."},

			{"h": "Ráp ở bàn chế tạo"},
			{"p": "Bấm [b]E[/b] để đặt từng thứ xuống bàn, rồi bấm [b]F[/b] để ráp. Ráp hụt thì có câu báo liệt kê những gì đang có trên bàn. Bấm [b]E[/b] tay không để nhấc lại thứ vừa bỏ vào."},
			{"recipe": "table"},

			{"h": "Nấu trên bếp"},
			{"p": "Vài thứ ráp xong ở bàn vẫn chưa ăn được — [b]nồi canh[/b] và [b]steak rau củ[/b] là đồ SỐNG. Bỏ chúng lên bếp, chờ bar tiến trình đầy, rồi bấm [b]E[/b] tay không để lấy ra.\n\nRiêng [b]nồi canh[/b] nấu xong thành [b]món canh hoàn chỉnh[/b] — mang thẳng ra bàn khách, không cần đĩa, vì cái nồi đã là đồ đựng rồi."},

			{"h": "Nướng trong lò"},
			{"p": "Đế bánh khởi động lò; topping bỏ thêm khi lò đang chạy."},
			{"recipe": "oven"},
		],
	},

	# ═══════════════════════════════════════════════════════ CHỨC NĂNG BẾP ══
	{
		"id": "kitchen",
		"name": "Chức năng bếp",
		"blocks": [
			{"h": "Lấy nguyên liệu"},
			{"p": "[b]Thùng rau[/b] — bấm [b]E[/b] lấy một thứ. Kho vô hạn, không phải tiết kiệm.\n\n[b]Tủ lạnh[/b] và [b]Máy kem[/b] — mở bảng chọn, [b]W/S[/b] đổi, [b]E[/b] chọn, [b]C[/b] đóng. Bảng [b]không dừng game[/b], khách vẫn đang chờ.\n\n[b]Chồng đĩa[/b] và [b]chồng nồi[/b] — bấm [b]E[/b] lấy một cái. Cũng vô hạn. Đĩa và nồi là hai thứ đồ đựng, và cả hai đều là [b]nguyên liệu[/b] trong công thức chứ không phải một bước riêng — quên lấy đĩa chỉ là công thức không khớp, giống hệt quên một củ cà rốt."},

			{"h": "Thớt"},
			{"p": "Thái một thứ, [b]2,5 giây[/b]. Ngắn vì thái là thao tác bắt buộc, không có quyết định nào bên trong — đứng chờ lâu chỉ là thời gian chết."},

			{"h": "Bếp"},
			{"p": "Nấu [b]8 giây[/b]. Con số đó không phải chọn bừa: một chuyến đi lấy nguyên liệu mất khoảng 4,6 giây, nên 8 giây đủ cho [b]một[/b] chuyến nhưng không đủ hai. Bạn phải chọn giữa bỏ đủ rồi mới bật, hay bật sớm rồi chạy đua.\n\nBếp nhận [b]một thứ mỗi lần[/b], đúng như cái thớt: bỏ vào, chờ, lấy ra. Nấu được ham, steak, steak rau củ và nồi canh."},

			{"h": "Cháy"},
			{"p": "[b]Ham[/b] và [b]steak[/b] nấu xong vẫn nằm trên bếp và [b]vẫn đếm tiếp[/b]. Quá [b]gấp đôi[/b] thời gian nấu thì cháy thành đồ bỏ. Bạn có thêm đúng một khoảng bằng thời gian nấu nữa để quay lại lấy — đủ rộng để không bị phạt oan khi đang bận, đủ hẹp để \"cứ để đấy rồi tính\" là một canh bạc thật.\n\n[b]Nồi canh không cháy[/b] — canh hầm lâu thêm chút thì không hỏng, nên cứ để đấy bao lâu cũng được."},

			{"h": "Lò nướng"},
			{"p": "Nướng [b]11 giây[/b], dài hơn bếp vì pizza cần ba bốn thứ, tức hai chuyến. Bỏ [b]đế bánh[/b] vào để bật lò, rồi bỏ thêm topping trong lúc lò đang chạy. Đang chạy thì không lấy ra được."},

			{"h": "Nồi"},
			{"p": "Cái nồi là một [b]nguyên liệu bình thường[/b], lấy vô hạn ở chồng nồi y như lấy đĩa ở chồng đĩa. Nó không có luật riêng nào cả.\n\nBa bước làm canh: lấy nồi rỗng → bỏ lên [b]bàn chế tạo[/b] cùng bốn thứ rau củ rồi bấm [b]F[/b] → đặt [b]nồi canh[/b] lên bếp. Nấu xong ra món canh, mang thẳng ra bàn khách."},

			{"h": "Máng bỏ đồ và Doro"},
			{"p": "Bấm [b]E[/b] để vứt thứ đang cầm. [b]Không có ngoại lệ nào[/b] — mọi thứ đều vứt được, kể cả cái nồi, vì mọi thứ đều lấy lại được.\n\n[b]Doro[/b] — con thú cưng đi lang thang ngoài khu khách — cũng ăn đồ y hệt cái máng. Tiện hơn khi bạn đang đứng xa bếp. Bấm [b]E[/b] lúc tay không thì chỉ là vuốt ticket nó."},

			{"h": "Bàn chế tạo"},
			{"p": "[b]E[/b] đặt xuống · [b]F[/b] ráp · [b]E[/b] tay không nhấc lại thứ cuối cùng. Bảng bên cạnh bàn liệt kê những gì đang có."},
		],
	},

	# ═══════════════════════════════════════════════════════════ ĐÁNH GIÁ ══
	{
		"id": "grading",
		"name": "Đánh giá",
		"blocks": [
			{"p": "Hết giờ là màn kết thúc và bảng tổng kết hiện ra. Xếp hạng tính theo [b]tổng doanh thu[/b] của lượt chơi đó."},

			{"h": "Năm hạng"},
			# Chỉ ghi TÊN năm hạng, không in con số: mỗi màn có bộ mốc riêng
			# (Ngày 1 khác Ngày 3), in số ở đây thì hoặc sai với màn đang chơi,
			# hoặc thành một bảng dài không ai đọc. Con số của từng màn hiện ở
			# bảng yêu cầu lúc chọn màn và ngay trên HUD trong lúc chơi.
			{"p": "Từ thấp lên cao: [color=#5b8fb0][b]D[/b][/color] · [color=#4f9d5d][b]C[/b][/color] · [color=#e27ba0][b]B[/b][/color] · [color=#e8823f][b]A[/b][/color] · [color=#f2c230][b]S[/b][/color]."},
			{"p": "Mỗi màn có mốc doanh thu riêng cho từng hạng. Bấm vào màn ở màn hình [b]Chọn màn[/b] để xem mốc của màn đó; trong lúc chơi, mốc kế tiếp hiện ngay bên phải số tiền."},
			{"p": "Không đạt nổi mốc [b]D[/b] thì màn coi như [b]chưa qua[/b]: màn tiếp theo vẫn khoá, và bảng sẽ nói rõ bạn còn thiếu bao nhiêu."},

			{"h": "Bảng tổng kết nói gì"},
			{"p": "[b]Doanh thu[/b] của lượt này, kèm kỷ lục cũ của chính màn đó.\n[b]Đơn đã phục vụ[/b] — tổng số đơn giao đúng.\n[b]Trong đó hoàn hảo[/b] — số đơn giao lúc kiên nhẫn còn trên nửa. Đây là chỗ nhìn ra mình có đang chơi vội đúng cách không.\n[b]Khách bỏ đi[/b] — con số cần giảm ở lượt sau."},

			{"h": "Muốn lên hạng thì làm gì"},
			{"p": "Ba đòn bẩy, theo thứ tự dễ trước:\n\n[b]1. Bớt khách bỏ đi.[/b] Một khách bỏ đi là mất trọn giá món cộng cả thời gian đã bỏ ra làm nó.\n[b]2. Nhắm vạch trắng.[/b] Thêm 35% mỗi đơn cộng dồn nhanh hơn vẻ ngoài.\n[b]3. Làm gối đầu.[/b] Bếp và lò chạy nền trong lúc bạn đi chỗ khác — đứng nhìn bar tiến trình là đang lãng phí thứ đắt nhất."},
		],
	},
]
