extends RefCounted

const IMAGE_DIR := "res://assets/ui/huong_dan/"

const SECTIONS := [
	{
		"id": "interface",
		"name": "Giao diện",
		"blocks": [
			{"img": IMAGE_DIR + "tong_quan.png", "caption": "Toàn cảnh một màn đang chơi"},

			{"h": "Bảng đơn hàng (góc trên trái)"},
			{"p": "Mỗi vé là một khách đang ngồi bàn: món, giá, [b]số bàn[/b] và thanh kiên nhẫn. Vé gấp nhất nằm trên cùng. Bấm [b]1[/b] để ẩn/hiện bảng."},
			{"img": IMAGE_DIR + "bang_don_hang.png", "caption": "Vé đơn hàng"},

			{"h": "Đồng hồ và tiền (góc trên phải)"},
			{"p": "Thời gian còn lại, doanh thu hiện tại và mốc hạng kế tiếp. Dưới 30 giây đồng hồ chuyển đỏ."},
			{"img": IMAGE_DIR + "dong_ho.png", "caption": "Đồng hồ, doanh thu, mốc hạng"},

			{"h": "Danh sách tương tác (giữa dưới)"},
			{"p": "Các trạm đang ở trong tầm và phím để dùng. Có nhiều trạm thì bấm [b]Tab[/b] để đổi."},
			{"img": IMAGE_DIR + "danh_sach_tram.png", "caption": "Trạm trong tầm"},

			{"h": "Thanh tiến trình"},
			{"p": "Hiện trên bếp, lò nướng và thớt khi đang chạy.\n[color=#f08a33]Cam[/color]: đang làm.\n[color=#c4433a]Đỏ, vơi dần[/color]: món đã chín và sắp cháy — lấy ra trước khi thanh hết."},
			{"img": IMAGE_DIR + "tram_bep.png", "caption": "Thanh tiến trình trên trạm"},

			{"h": "Nhân vật (góc dưới trái)"},
			{"p": "Thanh thể lực và kĩ năng chủ động. Biểu tượng xám là chưa dùng được."},
			{"img": IMAGE_DIR + "ban_than.png", "caption": "Kĩ năng và thể lực"},

			{"h": "Phím"},
			{"key_label": [
				["W A S D", "Di chuyển"],
				["Shift", "Chạy nhanh (tốn thể lực)"],
				["E", "Cầm, đặt, lấy ra, giao món"],
				["F", "Ráp món ở bàn chế tạo"],
				["Tab", "Đổi mục tiêu"],
				["Space", "Kĩ năng chủ động"],
				["1", "Ẩn/hiện bảng đơn hàng"],
				["C", "Đóng bảng chọn"],
				["P", "Đổi góc nhìn (khi đã mở)"],
				["F1", "Mở/đóng hướng dẫn"],
				["ESC", "Tạm dừng"],
			]},
		],
	},

	{
		"id": "customers",
		"name": "Khách hàng",
		"blocks": [
			{"h": "Quy trình"},
			{"p": "1. Khách xếp hàng ở cửa, món gọi hiện trên đầu.\n2. Có bàn trống thì khách vào ngồi, vé hiện ở bảng đơn hàng.\n3. Mang đúng món tới đúng số bàn và bấm [b]E[/b].\n4. Khách ăn xong thì rời đi và trả bàn."},
			{"img": IMAGE_DIR + "vong_doi_khach.png", "caption": "Số trên bàn khớp với số trên vé"},

			{"h": "Kiên nhẫn"},
			{"p": "Khi xếp hàng: [b]45 giây[/b].\nKhi ngồi bàn: thanh nạp đầy lại, dài hay ngắn tuỳ món.\nHết kiên nhẫn thì khách bỏ về và bạn mất đơn đó."},

			{"h": "Đơn hoàn hảo"},
			{"p": "Giao khi thanh kiên nhẫn còn [b]trên 50%[/b] (trước vạch trắng) được thêm [b]35%[/b] giá món."},

			{"h": "Giao nhầm món"},
			{"p": "Bàn không nhận, món nằm lại trên bàn. Bấm [b]E[/b] tay không để nhấc lại."},
		],
	},

	{
		"id": "recipe",
		"name": "Công thức",
		"blocks": [
			{"p": "Thứ tự bỏ nguyên liệu không quan trọng, chỉ cần đủ và không thừa."},
			{"p": "Vé đơn hàng ghi sẵn nguyên liệu của món. Kí hiệu dưới mỗi nguyên liệu cho biết nấu ở đâu: [b]chảo[/b] (bếp), [b]nồi[/b] (nồi soup), [b]lò[/b] (lò nướng)."},

			{"h": "Ráp ở bàn chế tạo"},
			{"p": "Bấm [b]E[/b] đặt từng thứ lên bàn, bấm [b]F[/b] để ráp. Bấm [b]E[/b] tay không để chọn thứ cần lấy ra."},
			{"recipe": "table"},

			{"h": "Nguyên liệu phải qua thớt"},
			{"p": "Gần như mọi nguyên liệu đều phải thái ở thớt trước khi dùng — trừ bánh mì, đùi nướng, đế bánh và kem."},
			{"chop_list": true},

			{"h": "Nấu trên bếp"},
			{"p": "[b]Steak đã thái[/b] và [b]đùi nướng[/b] đặt thẳng lên bếp.\n[b]Soup[/b]: bỏ nồi cùng [b]3 phần rau cùng loại[/b] đã thái lên bàn chế tạo, bấm [b]F[/b], rồi đặt nồi lên bếp. Soup nấu xong mang thẳng ra bàn, không cần đĩa."},

			{"h": "Nướng trong lò"},
			{"p": "Ghép [b]pizza sống[/b] ở bàn chế tạo (đế bánh + cà chua + 1 topping), rồi đặt vào lò."},
		],
	},

	{
		"id": "kitchen",
		"name": "Chức năng bếp",
		"blocks": [
			{"h": "Lấy nguyên liệu"},
			{"p": "[b]Thùng nguyên liệu[/b], [b]chồng đĩa[/b], [b]chồng nồi[/b]: bấm [b]E[/b] để lấy, không giới hạn số lượng.\n[b]Tủ lạnh[/b], [b]máy kem[/b]: bấm [b]E[/b] mở bảng chọn, [b]W/S[/b] chọn, [b]E[/b] lấy, [b]C[/b] đóng. Game không dừng khi bảng đang mở.\nĐĩa và nồi là một phần của công thức — thiếu thì ráp không được."},

			{"h": "Thớt"},
			{"p": "Thái một thứ mất [b]2,5 giây[/b]."},

			{"h": "Bếp"},
			{"p": "Nấu một thứ mỗi lần, mất [b]8 giây[/b]. Nấu được steak, đùi nướng và nồi soup.\nSteak và đùi nướng để trên bếp quá [b]gấp đôi[/b] thời gian nấu thì cháy. Nồi soup không cháy."},

			{"h": "Lò nướng"},
			{"p": "Nướng mất [b]11 giây[/b]. Đang nướng thì không lấy ra được. Pizza để trong lò quá [b]gấp đôi[/b] thời gian nướng thì cháy."},

			{"h": "Quầy để đồ"},
			{"p": "Mỗi quầy giữ [b]một món[/b]. Bấm [b]E[/b] để đặt tạm, [b]E[/b] tay không để lấy lại."},

			{"h": "Thùng rác và Doro"},
			{"p": "Bấm [b]E[/b] để bỏ thứ đang cầm. Không vứt đồ xuống sàn được.\n[b]Doro[/b] (thú cưng ở khu khách) cũng nhận đồ bỏ đi như thùng rác."},
		],
	},

	{
		"id": "grading",
		"name": "Đánh giá",
		"blocks": [
			{"p": "Hết giờ thì màn kết thúc. Hạng tính theo [b]tổng doanh thu[/b]."},

			{"h": "Hạng"},
			{"p": "Từ thấp lên cao: [color=#5b8fb0][b]D[/b][/color] · [color=#4f9d5d][b]C[/b][/color] · [color=#e27ba0][b]B[/b][/color] · [color=#e8823f][b]A[/b][/color] · [color=#f2c230][b]S[/b][/color]."},
			{"p": "Mốc doanh thu của từng màn xem ở màn hình [b]Chọn màn[/b]; trong lúc chơi, mốc kế tiếp hiện cạnh số tiền.\nKhông đạt hạng [b]D[/b] thì chưa qua màn."},

			{"h": "Bảng tổng kết"},
			{"p": "Doanh thu và kỷ lục cũ, số đơn đã phục vụ, số đơn hoàn hảo, số khách bỏ về và tiền shop nhận được."},

			{"h": "Tiền shop"},
			{"p": "Qua màn nhận [b]10%[/b] doanh thu vào ví shop, dùng ở [b]Cửa hàng[/b] trong menu chính."},
		],
	},

	{
		"id": "modes",
		"name": "Chế độ chơi",
		"blocks": [
			{"p": "Mở ở nút [b]Chế độ[/b] trong màn chọn màn."},

			{"h": "AAA Mode"},
			{"p": "Một màn chơi châm biếm game của các hãng lớn: trạm bị khoá chờ mua DLC, nhiệm vụ dẫn đường từng bước."},

			{"h": "Endless Mode"},
			{"p": "Chơi tới khi hết giờ. Bắt đầu với [b]2:30[/b].\nĐơn giao đúng [b]+15 giây[/b], đơn hoàn hảo [b]+25 giây[/b], khách đang ngồi bỏ về [b]−10 giây[/b].\nMỗi [b]3 phút[/b] món khó hơn và khách đông hơn.\nXếp hạng theo doanh thu."},

			{"h": "Asian Mode"},
			{"p": "[b]10 phút[/b], toàn bộ thực đơn, không mở được F1 trong màn."},
			{"p": "[b]Mạng:[/b] 3 mạng. Khách bỏ về mất 1 mạng (khách VIP mất 2). Phục vụ liền [b]8 đơn[/b] không ai bỏ về thì hồi 1 mạng. Hết mạng là thua.\n[b]Tiền:[/b] vốn [b]200[/b]. Nguyên liệu tốn tiền, bếp/lò/tủ lạnh tốn phí khi chạy, mỗi đơn trừ [b]10% thuế[/b], đồ cháy phạt gấp đôi giá nguyên liệu. Hết tiền là thua.\n[b]Tiền trên bàn:[/b] khách để tiền lại trên bàn, bấm [b]E[/b] để thu trong [b]20 giây[/b]."},
			{"p": "[b]Sự kiện[/b] từ phút thứ hai, báo trước 5 giây:\n[b]Chó trộm[/b] — Doro tự đi ra cửa, bấm [b]E[/b] vào Doro để giữ lại. Doro ra tới cửa là thua.\n[b]Khách VIP[/b] — món khó, ít kiên nhẫn, trả gấp ba.\n[b]Mất điện[/b] — màn hình tối ở rìa.\n[b]Doro đói[/b] — 15 giây để cho Doro ăn một món, không kịp thì mọi khách bỏ về, mỗi người mất 1 mạng.\nNgoài ra: tăng giá gas, đầu bếp mệt, giờ cao điểm, sàn trơn, trời mưa, hết hàng, đánh giá xấu."},
			{"p": "Kĩ năng nhân vật trong Asian khác với chế độ thường — xem ở màn chọn nhân vật."},
		],
	},
]
