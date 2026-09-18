extends RefCounted
## Danh mục vật phẩm: MỘT nơi duy nhất khai báo mỗi thứ trong game trông như
## thế nào, cả trong không gian 3D lẫn trên giao diện.
##
## Vì sao gom vào một bảng thay vì gắn thẳng vào từng trạm trong map:
##
##  - Cùng một nguyên liệu xuất hiện ở nhiều chỗ: cà chua có trong thùng
##    nguyên liệu, trong bảng chọn của bàn chế tạo, trong ghi chú "trên bàn
##    đang có gì", và sau này trong bong bóng thoại của khách. Khai báo trong
##    map thì mỗi chỗ phải tự đi tìm lại đường dẫn ảnh — sai một chỗ là lệch.
##  - Nguyên liệu có nhiều TRẠNG THÁI (sống / đã sơ chế / đã nấu / cháy). Nếu
##    mỗi trạng thái là một node đặt sẵn trong map thì map phồng lên vô ích;
##    ở đây chúng chỉ là bốn dòng dữ liệu, và hệ thống nấu ăn chỉ việc đổi id.
##
## Mỗi mục gồm:
##   ten   — chữ hiện trên giao diện
##   anh   — ảnh 2D minh hoạ (bảng chọn, ghi chú, đơn hàng)
##   model — file .gltf để sinh vật thể cầm trên tay
##   anh    — id ảnh 2D, chỉ ghi khi KHÁC id vật phẩm (món dùng lại ảnh của
##            nguyên liệu). Bỏ trống thì lấy đúng id.
##   so_che — id sau khi THÁI ở thớt (rỗng = không thái được)
##   nau    — id sau khi NẤU ở bếp (rỗng = không nấu lẻ được)
##   hong   — id khi để quá lửa trên bếp (rỗng = không cháy)
##   ti_le  — hệ số phóng to/thu nhỏ model, chỉ ghi khi KHÁC 1.0
##   bay    — CÁCH XẾP CHỒNG trên mặt bàn chế tạo. Bỏ trống thì dùng số mặc
##            định, nên CHỈ khai khi món đó bày ra nhìn không ổn:
##            {"day":    chỉ cho VẬT ĐẾ — mặt trong của nó cao bao nhiêu, tức
##                       món đầu tiên nằm ở độ cao nào (mặc định 0.12),
##             "cao":    món này DÀY bao nhiêu, tức món kế tiếp nhích lên bấy
##                       nhiêu (mặc định 0.08),
##             "ti_le":  thu nhỏ riêng khi nằm trên bàn (mặc định TI_LE_CHONG),
##             "y":      lệch thêm theo trục đứng, để chữa model có tâm không
##                       nằm ở đáy (mặc định 0.0),
##             "thu_tu": VỊ TRÍ trong chồng — số nhỏ nằm DƯỚI (mặc định 50),
##             "model":  model KHÁC dùng riêng khi nằm trong chồng, ví dụ xà
##                       lách nguyên cây đổi thành một lát,
##             "model_tren": mảnh thứ hai, luôn đặt TRÊN CÙNG cả chồng — mới
##                       chỉ bánh mì dùng, để có nắp bánh}
##   bat    — món BÀY TRONG BÁT. Ghi khoá này thì KHÔNG ghi "model": bộ dựng
##            tự nạp cái bát rồi gắn phần thức ăn vào trong lòng nó.
##            {"model": tên gltf phần thức ăn,
##             "y": độ cao đặt trong lòng bát (mặc định 0.12),
##             "ti_le": thu nhỏ phần thức ăn, mặc định 1.0}
##
## Vì sao tách "so_che" và "nau" thành HAI khoá thay vì một khoá "bước kế
## tiếp": steak đi qua cả hai bước (thái rồi nấu) còn ham thì nấu thẳng. Một
## khoá duy nhất thì không phân biệt được đưa steak sống lên bếp là hợp lệ
## hay không. Hai khoá thì mỗi trạm chỉ hỏi đúng khoá của mình, và "mang
## steak chưa thái lên bếp" tự động không làm gì — không cần viết luật chặn.

const ANH := "res://assets/ui/nguyen_lieu/%s.png"
const MODEL := "res://assets/gltf/%s.gltf"

const MUC := {
	# ---- nguyên liệu lấy từ thùng ----
	"bun":        {"ten": "Bánh mì",   "model": "food_ingredient_bun",
		# Ổ bánh nguyên lúc cầm trên tay; TRÊN BÀN thì tách làm hai mảnh —
		# đế nằm dưới cùng (nấc 10), nắp luôn đậy trên cùng cả chồng.
		# Số đo: đế dày 0,200; nắp dày 0,307.
		"bay": {"thu_tu": 10, "cao": 0.20,
			"model": "food_ingredient_bun_bottom",
			"model_tren": "food_ingredient_bun_top"}},
	"lettuce":    {"ten": "Xà lách",   "model": "food_ingredient_lettuce",
		# Cả cây xà lách cao 0,82 — kẹp nguyên cây vào bánh thì bánh cao gấp
		# bốn lần bình thường. Trong chồng dùng MỘT LÁT, dày 0,088.
		"bay": {"thu_tu": 20, "cao": 0.088, "y": 0.034,
			"model": "food_ingredient_lettuce_slice"}},
	"carrot":     {"ten": "Cà rốt",    "model": "food_ingredient_carrot",
		"bay": {"cao": 1.27, "y": 0.585}},
	"potato":     {"ten": "Khoai tây", "model": "food_ingredient_potato",
		"bay": {"cao": 0.78, "y": 0.394}},
	"tomato":     {"ten": "Cà chua",   "model": "food_ingredient_tomato",
		"bay": {"cao": 0.70}},
	"onion":      {"ten": "Hành tây",  "model": "food_ingredient_onion",
		"bay": {"cao": 0.86, "y": 0.011}},
	"mushroom":   {"ten": "Nấm",       "model": "food_ingredient_mushroom",
		"bay": {"cao": 0.57, "y": 0.217}},
	"dough":      {"ten": "Bột",       "model": "food_ingredient_dough",
		"so_che": "dough_pre"},
	"dough_pre":  {"ten": "Bột đã cán", "model": "food_ingredient_dough_base",
		"bay": {"day": 0.14}},

	# ---- nguyên liệu trong tủ lạnh ----
	# Ham KHÔNG qua thớt — nấu thẳng. Ảnh dùng lại ham_uncook.png (ham sống)
	# vì bộ ảnh không có file "ham.png" riêng.
	"ham":        {"ten": "Ham", "model": "food_ingredient_ham",
		"anh": "ham_uncook", "nau": "ham_cooked", "hong": "ham_cooked_fail"},
	"ham_cooked": {"ten": "Ham đã nấu",  "model": "food_ingredient_ham_cooked",
		"bay": {"cao": 0.83, "y": 0.415}},
	"ham_cooked_fail": {"ten": "Ham cháy", "model": "food_ingredient_ham_trash"},

	"steak":        {"ten": "Steak", "model": "food_ingredient_steak",
		"so_che": "steak_uncook"},
	"steak_uncook": {"ten": "Steak đã thái", "bay": {"cao": 0.20},
		"model": "food_ingredient_burger_uncooked",
		"nau": "steak_cooked", "hong": "steak_cooked_fail"},
	"steak_cooked": {"ten": "Steak đã nấu",
		# Nấc 30: giữa xà lách (20) và phô mai (40), đúng thứ tự một cái burger.
		# Model food_ingredient_burger_cooked vốn đã là miếng chả tròn dày 0,20,
		# không cần đổi model.
		"bay": {"thu_tu": 30, "cao": 0.20},
		"model": "food_ingredient_burger_cooked"},
	"steak_cooked_fail": {"ten": "Steak cháy",
		"model": "food_ingredient_burger_trash"},

	"cheese":      {"ten": "Phô mai",  "model": "food_ingredient_cheese",
		# Khối phô mai cao 0,50 → một lát dày 0,105. Gốc toạ độ của lát nằm
		# gần MẶT TRÊN (y từ −0,087 tới 0,018) nên phải nâng 0,087.
		"bay": {"thu_tu": 40, "cao": 0.105, "y": 0.087,
			"model": "food_ingredient_cheese_slice"}},
	"cookiestick": {"ten": "Bánh quế", "model": "icecream_cookiestick",
		"bay": {"cao": 0.52, "y": 0.258}},

	"peperoni":     {"ten": "Xúc xích", "model": "food_ingredient_pepperoni",
		"so_che": "peperoni_pre"},
	"peperoni_pre": {"ten": "Xúc xích đã thái", "bay": {"cao": 0.40},
		"model": "food_ingredient_pepperoni_chopped"},

	# ---- vật chứa ----
	"bowl": {"ten": "Đĩa", "model": "plate", "bay": {"day": 0.08}},
	# CÁI NỒI RỖNG — từ 14/9/2026 là một NGUYÊN LIỆU BÌNH THƯỜNG, lấy vô hạn
	# ở chồng nồi y như cái đĩa lấy ở chồng đĩa.
	#
	# Trước đó nồi là vật thể ĐỘC NHẤT của cả màn: nhấc lên, đổ nguyên liệu
	# vào, bê lên bếp, chờ, múc canh ra, nồi ở lại bếp. Sáu bước, và không
	# bước nào giống bất cứ trạm nào khác trong game — người chơi phải học
	# riêng một luật chỉ dùng cho đúng một món. Kèm theo đó là cả một chuỗi
	# ngoại lệ rải khắp code: bàn chế tạo không được nuốt nồi, thùng rác không
	# được xoá nồi, bếp phải phân biệt "đang nấu nồi" với "đang nấu món lẻ",
	# và nồi phải có hai model tuỳ theo trong ruột có gì.
	#
	# Giờ nồi đi đúng con đường của mọi nguyên liệu khác: lấy ở chồng nồi →
	# bỏ lên bàn chế tạo cùng rau củ → bấm F ra NỒI CANH SỐNG → đặt lên bếp
	# như đặt miếng thịt → nấu xong ra canh. Không còn một ngoại lệ nào.
	#
	# Không còn `model_day`: nồi không bao giờ chứa gì nữa. Thứ "nồi có đồ
	# bên trong" giờ là một vật phẩm riêng — noi_canh ngay dưới đây.
	"noi": {"ten": "Nồi", "model": "pot_A", "bay": {"day": 0.48}},
	# NỒI CANH SỐNG — thành phẩm của bàn chế tạo, nguyên liệu của cái bếp.
	#
	# `nau` trỏ sang "stew" nên cái bếp không cần biết đây là nồi: nó đọc
	# đúng khoá `nau` mà nó vẫn đọc cho ham sống và steak sống. Đó là cả lý do
	# của lần sửa này — cái nồi hết là một cơ chế riêng, nó chỉ còn là một
	# dòng dữ liệu.
	#
	# Nấu xong ra THẲNG "stew" — món hoàn chỉnh, giao được cho khách ngay,
	# KHÔNG qua bàn chế tạo và KHÔNG cần đĩa. Đây là ngoại lệ duy nhất của
	# luật "món ăn phải bày ra đĩa", và nó có lý do: nồi canh ĐÃ LÀ đồ đựng.
	# Bắt múc từ nồi sang đĩa là thêm một chuyến đi lấy đĩa và một cú bấm F
	# cho đúng một món, đổi lại không được gì — người chơi không có quyết
	# định nào để ra ở bước đó.
	#
	# Model pot_A_stew (731 đỉnh = pot_A + stew_pot): nhìn là thấy nồi đã có
	# đồ, phân biệt được với nồi rỗng từ xa.
	# KHÔNG có khoá `hong` — CANH HẦM KHÔNG CHÁY, và đây là quyết định chứ
	# không phải sót.
	#
	# Chỉ ham và steak mới có `hong`: chúng là miếng thịt áp chảo, để quá lửa
	# là khét, và người chơi nhìn model đổi màu là hiểu ngay. Canh thì ngược
	# lại — hầm lâu hơn một chút không hỏng gì cả, nên phạt ở đây là phạt một
	# thứ trái với hiểu biết thông thường của người chơi.
	#
	# Cơ chế: bep_nau._process chỉ giữ mẻ lại đếm tiếp (để rồi cháy) khi
	# `trang_thai_hong(goc)` KHÁC RỖNG; không có khoá `hong` thì nấu xong là
	# mẻ bị gỡ khỏi bảng đang-nấu ngay, không có đường nào đi tới _chay().
	# Nghĩa là nồi canh nằm trên bếp bao lâu cũng được.
	"noi_canh": {"ten": "Nồi canh (sống)", "model": "pot_A_stew",
		"nau": "stew", "bay": {"day": 0.48}},

	# ---- món hoàn chỉnh ----
	"hambuger":      {"ten": "Hamburger",       "model": "food_burger",
		"gia": 95, "giay": 20.0},
	"vegetablebuger_uncook": {"ten": "Steak rau củ (sống)",
		"model": "food_ingredient_vegetableburger_uncooked",
		"nau": "vegetablebuger_cooked"},
	"vegetablebuger_cooked": {"ten": "Steak rau củ (chín)",
		"bay": {"thu_tu": 30, "cao": 0.216},
		"model": "food_ingredient_vegetableburger_cooked"},
	"vegetablebuger": {"ten": "Hamburger rau củ", "model": "food_vegetableburger",
		"gia": 110, "giay": 22.6},
	"dinner":        {"ten": "Bữa tối",         "model": "food_dinner",
		"gia": 150, "giay": 30.6},
	# CANH RAU CỦ — món hoàn chỉnh, ra thẳng từ bếp, giao được cho khách ngay.
	#
	# Trước đây chỗ này có HAI mục cho cùng một bát canh: "stew" (canh múc ra
	# từ nồi, chưa bán được) và "mon_canh" (canh đã bày ra đĩa, bán 135). Hai
	# mục đó chỉ khác nhau vì có một bước "múc sang đĩa" ở giữa — bỏ bước đó
	# thì hai mục mô tả đúng một thứ, và giữ cả hai là mời gọi người viết code
	# sau này dùng nhầm mục.
	#
	# Giữ tên "stew" chứ không giữ "mon_canh": mọi id nguyên liệu và món trong
	# bảng này đều theo tên model của KayKit (food_stew), còn "mon_" là tiền tố
	# của ba MÓN BÀY BÁT ghép lúc chạy (mon_ham, mon_steak) — canh không thuộc
	# nhóm đó vì nó có model sẵn.
	"stew": {"ten": "Canh rau củ", "model": "food_stew", "bay": {"cao": 0.37},
		"gia": 135, "giay": 28.0},
	# Ba loại pizza thu nhỏ còn 0.7: model "plated" của KayKit đã kèm sẵn cái
	# khay bên dưới nên to hơn hẳn mọi món khác, cầm trên tay thì che mất
	# nửa nhân vật.
	"pizza_cheese":   {"ten": "Pizza phô mai",  "model": "food_pizza_cheese_plated",
		"ti_le": 0.5, "gia": 105, "giay": 23.0},
	"pizza_mushroom": {"ten": "Pizza nấm",      "model": "food_pizza_mushroom_plated",
		"ti_le": 0.5, "gia": 100, "giay": 23.0},
	"pizza_peperoni": {"ten": "Pizza xúc xích", "model": "food_pizza_pepperoni_plated",
		"ti_le": 0.5, "gia": 100, "giay": 23.0},
	"icecream_vani":       {"ten": "Kem vani",
		"model": "icecream_bowl_icecream_vanilla", "bay": {"cao": 0.36},
		"gia": 15, "giay": 4.2},
	"icecream_chocolate":  {"ten": "Kem chocolate",
		"model": "icecream_bowl_icecream_chocolate", "bay": {"cao": 0.36},
		"gia": 15, "giay": 4.2},
	"icecream_strawberry": {"ten": "Kem dâu",
		"model": "icecream_bowl_icecream_strawberry", "bay": {"cao": 0.36},
		"gia": 15, "giay": 4.2},
	# Hai món kem ghép. Khác ba loại kem lẻ ở trên (lấy thẳng từ máy rồi giao
	# luôn), hai món này phải qua bàn chế tạo — xem CONG_THUC_BAN.
	#
	# Ảnh riêng chứ không mượn ảnh kem lẻ: cả hai đều là BA viên kem trong một
	# bát, nhìn từ xa mà dùng ảnh một viên thì người chơi không phân biệt được
	# mình đang cầm món ghép hay nguyên liệu rời.
	"kem_tam_hop": {"ten": "Kem tam hợp",
		"model": "icecream_bowl_decorated_B", "bay": {"cao": 0.73},
		"gia": 40, "giay": 8.9},
	"kem_tam_hop_que": {"ten": "Kem tam hợp và bánh quế",
		"model": "icecream_bowl_decorated_A", "gia": 55, "giay": 12.2},

	# ---- món bày ra đĩa (dùng lại ảnh của nguyên liệu cuối) ----
	# Ba món dưới đây là BÁT GHÉP: bộ KayKit không có model nào sẵn "thức ăn
	# nằm trong bát", nên phải ghép cái bát với phần thức ăn lúc chạy. Ghép
	# bằng dữ liệu chứ không dựng ba file .tscn: ba dòng ở đây rẻ hơn ba file
	# phải mở ra sửa mỗi lần đổi độ cao, và món thứ tư chỉ là thêm một dòng.
	"mon_ham":  {"ten": "Ham",
		"bat": {"model": "food_ingredient_ham_cooked", "y": 0.37, "ti_le": 0.75},
		"anh": "ham_cooked", "gia": 60, "giay": 14.9},
	# Món dạy trong màn hướng dẫn. Đây là món NGẮN NHẤT đi qua đủ cả bốn trạm
	# thái → nấu → đĩa → bàn chế tạo: chuỗi "thái rồi nấu" trong game chỉ có ở
	# steak, mà trước đó steak_cooked chỉ dùng cho Hamburger 5 nguyên liệu —
	# quá dài cho bài học đầu tiên.
	#
	# Giá suy từ đúng công thức trong bảng cân bằng: 4 × 19,4 giây × 1,04
	# (một nguyên liệu phụ trội) ≈ 80. Thời gian 19,4 s = thời gian món Ham
	# (14,9 s) cộng một chuyến ghé thớt.
	"mon_steak": {"ten": "Steak",
		"bat": {"model": "food_ingredient_burger_cooked", "y": 0.12},
		"anh": "steak_cooked", "gia": 80, "giay": 19.4},
	# Steak rau củ bày bát.
	#
	# (Đổi tên 18/9/2026) Trước là "Chả rau củ". Ba mục vegetablebuger_* cùng
	# đổi theo, vì chúng là ba trạng thái của CÙNG một miếng — tên lệch nhau
	# thì người chơi đọc bảng công thức không nối được "chả" với "steak".
	#
	# Giá 105 suy từ công thức bảng cân bằng khi miếng này còn là 2 nguyên
	# liệu (steak + cà rốt). Từ 18/9 nó thành 4 nguyên liệu, nên con số này
	# ĐANG THẤP so với công sức bỏ ra — xem ghi chú ở CONG_THUC_BAN.
	"vegetablesteak": {"ten": "Steak rau củ",
		"bat": {"model": "food_ingredient_vegetableburger_cooked", "y": 0.12},
		"anh": "vegetablebuger_cooked", "gia": 105, "giay": 24.5},

	# ---- đồ hỏng ----
	"do_hong": {"ten": "Đồ hỏng", "model": "food_ingredient_ham_trash"},
}

## Những nguyên liệu cho được vào NỒI.
##
## Danh sách trắng chứ không phải danh sách đen: thêm nguyên liệu mới vào
## game thì mặc định nó KHÔNG bỏ nồi được, và người viết phải chủ động cho
## phép. Ngược lại thì mỗi nguyên liệu mới đều lặng lẽ trở thành hợp lệ, và
## lỗi kiểu đó chỉ lộ ra khi người chơi thử một tổ hợp không ai nghĩ tới.
## ══════════════════════════════════════════════════════════════════════════
## CÔNG TẮC HỆ NỒI — ĐÃ MỞ LẠI (10/9/2026)
## ══════════════════════════════════════════════════════════════════════════
##
## Khoá ngày 9/9 vì ba lỗi làm cái nồi biến mất khỏi màn chơi. Cả ba đã sửa:
##
##   1. BÀN CHẾ TẠO NUỐT NỒI — `_dat_len_ban()` nhận bất kì thứ gì đang cầm
##      rồi `queue_free()` nó. SỬA: thêm luật LÂU DÀI `KHONG_LEN_BAN` (xem
##      ngay dưới) — nồi chỉ đặt được lên BẾP, không đặt lên bàn nào cả.
##   2. NỒI TÀNG HÌNH — mục "noi" khai `"model": ""` nên `tao_mo_hinh()` trả
##      null. SỬA: gán model thật `pot_A`, kèm `pot_A_stew` cho lúc có đồ.
##   3. KHÔNG NHẤC RA ĐƯỢC — hệ quả của lỗi 1, hết luôn khi bàn từ chối nhận.
##
## Còn một lỗi thứ tư không ai để ý vì nó im lặng hoàn toàn: node `Noi` trong
## file map là một StaticBody3D TRẦN — không mesh, không CollisionShape3D. Nó
## vô hình VÀ không bấm vào được ngay từ đầu, vì bộ chọn mục tiêu dò va chạm
## mà nó thì không có hình va chạm nào. Sửa ở `TramTuongTac.dung_vat_cam()`.
##
## GIỮ LẠI cái công tắc này dù đã mở: nó là cách tắt cả một nhánh cơ chế trong
## một dòng khi cần thử cân bằng hay quay phim demo. Đổi thành false là thực
## đơn tự bỏ ba món nấu nồi, khách thôi gọi chúng, và cái nồi biến khỏi map —
## không phải sửa chỗ nào khác.
const NOI_MO := true

## Những id chỉ tồn tại được khi có nồi: chính cái nồi, món nấu ra từ nồi, và
## mọi món CHỨA món đó. Bữa tối nằm đây vì công thức của nó cần "stew".
const VAT_KHOA_THEO_NOI := ["noi", "noi_canh", "stew", "dinner"]

## (Đã bỏ) Danh sách đen KHONG_LEN_BAN và hàm len_ban_duoc().
##
## Danh sách đó có đúng một phần tử — cái nồi — và lý do của nó là: mặt bàn
## nhận đồ theo kiểu "nuốt vào rồi ghép", tức node bị xoá và chỉ sinh lại
## được từ danh mục; với một vật thể ĐỘC NHẤT thì đó là xoá vĩnh viễn.
##
## Nồi vô hạn làm lý do đó biến mất: nuốt mất một cái nồi bây giờ đúng bằng
## nuốt mất một củ cà rốt — đi lấy cái khác. Giữ lại một cơ chế chặn không
## còn gì để chặn thì người đọc code sau này phải đi tìm xem nó chặn cái gì,
## và tìm ra là không có gì cả.

## Id này hiện có bị khoá không. Hệ đơn hàng, bàn chế tạo và đôi tay đều hỏi
## qua đây, nên chỉ cần một chỗ để bật/tắt.
static func bi_khoa(id: String) -> bool:
	return not NOI_MO and VAT_KHOA_THEO_NOI.has(id)


## (Đã bỏ) CHO_VAO_NOI và CONG_THUC_NOI — bảng "thứ gì đổ được vào nồi" và
## bảng "nồi chứa gì thì ra món gì".
##
## Cả hai là bảng công thức THỨ HAI của một cái bàn ghép đồ, chỉ khác chỗ
## người chơi đứng. Công thức nấu canh giờ nằm chung CONG_THUC_BAN với mọi
## công thức khác, nên muốn biết làm canh thế nào thì tra đúng một bảng.


## Những thứ cho được vào LÒ NƯỚNG sau khi đã có đế bánh.
##
## Không có dough_pre trong danh sách này: đế bánh là thứ KHỞI ĐỘNG lò, không
## phải topping. Tách hai vai ra thì "bỏ đế thứ hai vào lò đang chạy" tự động
## là hành động không hợp lệ, không cần viết thêm luật nào để chặn.
const CHO_VAO_LO := ["cheese", "mushroom", "onion", "tomato", "peperoni_pre"]

## Đế bánh — thứ duy nhất bật được lò nướng.
const DE_BANH := "dough_pre"

## Công thức lò nướng. Cùng quy ước khoá với CONG_THUC_NOI: sắp xếp rồi nối
## bằng "+", nên thứ tự bỏ vào không quan trọng.
const CONG_THUC_LO := {
	"dough_pre+peperoni_pre+tomato": "pizza_peperoni",
	"dough_pre+mushroom+tomato": "pizza_mushroom",
	"cheese+dough_pre+onion+tomato": "pizza_cheese",
}


## Công thức ở BÀN CHẾ TẠO. Cùng quy ước khoá: sắp xếp rồi nối bằng "+".
##
## Mọi công thức đều có "bowl" (cái đĩa) vì luật đã chốt: món ăn phải được
## bày ra đĩa mới giao được. Để đĩa thành một NGUYÊN LIỆU thay vì một bước
## riêng thì không cần thêm trạng thái nào cho cái bàn — quên lấy đĩa cũng
## chỉ là một công thức không khớp, giống hệt quên một nguyên liệu.
const CONG_THUC_BAN := {
	"bowl+ham_cooked": "mon_ham",
	"bowl+steak_cooked": "mon_steak",
	"bowl+vegetablebuger_cooked": "vegetablesteak",
	# STEAK RAU CỦ SỐNG: nguồn duy nhất sinh ra vegetablebuger_uncook.
	#
	# Ghép ở bàn chế tạo chứ không ở thớt vì thớt chỉ nhận MỘT đầu vào; bàn
	# chế tạo vốn đã là nơi gộp nhiều thứ. Dùng steak_uncook (đã thái) chứ
	# không phải steak_cooked — miếng chả phải được nắn từ thịt SỐNG rồi mới
	# đem nướng, nướng trước rồi trộn rau vào thì không thành một miếng.
	#
	# (18/9/2026) Thêm hành tây và cà chua: trước chỉ có cà rốt, nên "rau củ"
	# thực ra là một loại rau. Ba loại thì cái tên mới đúng nghĩa.
	"carrot+onion+steak_uncook+tomato": "vegetablebuger_uncook",
	# NỒI CANH SỐNG — công thức duy nhất trong bảng này có cái nồi làm nguyên
	# liệu. Bốn thứ rau củ đúng bằng công thức nồi cũ, chỉ thêm "noi" vào.
	#
	# Năm nguyên liệu là công thức DÀI NHẤT của bàn chế tạo, ngang Hamburger
	# rau củ (sáu). Cố ý giữ dài: canh và Bữa tối là hai món đắt nhất, mà đổi
	# cơ chế nồi sang "bỏ lên bàn rồi bấm F" đã cắt mất hẳn phần chạy đi chạy
	# lại giữa kệ và bếp — nếu rút công thức xuống nữa thì món đắt nhất game
	# lại thành món nhanh nhất.
	"carrot+lettuce+noi+onion+potato": "noi_canh",
	# (Đã bỏ 14/9/2026) "bowl+stew" và "bowl+ham_cooked+stew". Cái bếp giờ trả
	# thẳng ra canh hoàn chỉnh, nên bước bày ra đĩa không còn. Bữa tối vẫn làm
	# được, bằng dòng "ham_cooked+stew" ở cuối bảng.
	"bowl+bun+cheese+lettuce+steak_cooked": "hambuger",
	# HAMBURGER RAU CỦ — giờ dựng trên MIẾNG CHẢ đã nấu, không phải trên đống
	# nguyên liệu rời.
	#
	# (Đã bỏ 18/9/2026) "bowl+bun+carrot+lettuce+steak_cooked+tomato". Công
	# thức cũ sáu nguyên liệu rời, và nó dùng steak_cooked — tức là cùng miếng
	# thịt bò với Hamburger thường, chỉ khác ở việc rắc thêm cà rốt với cà
	# chua vào bánh. "Rau củ" ở đó là tên gọi chứ không phải cấu tạo.
	#
	# Công thức mới đi qua miếng chả rau củ thật: steak thái + cà rốt + hành
	# + cà chua → nắn thành chả sống → nướng chín → kẹp bánh. Dài hơn, nhưng
	# đó là lý do món này đắt hơn Hamburger thường.
	#
	# KHÔNG sợ lồng công thức dù "bowl+vegetablebuger_cooked" (Steak rau củ)
	# là TẬP CON của dòng này: bàn chỉ ráp khi người chơi bấm F, nên không có
	# chuyện món ngắn tự ráp trước và chặn mất món dài. Đây đúng là lớp lỗi mà
	# phím F sinh ra để dập — xem _rap_ban() trong tay_cam.gd.
	#
	# CÂN BẰNG CẦN XEM LẠI: giá vẫn là 110 của công thức cũ, trong khi món giờ
	# qua thêm một lượt ghép và một lượt nấu. Theo công thức 4 × giây × (1 +
	# 4% × phụ trội) thì nó xứng đáng khoảng 160.
	"bowl+bun+lettuce+vegetablebuger_cooked": "vegetablebuger",
	# Hai món kem ghép.
	#
	# CÓ "bowl" trong công thức dù tài liệu công thức không ghi: mọi món khác
	# đều phải bày ra đĩa, và chính hai model KayKit của hai món này cũng là
	# một cái bát. Cho kem thành ngoại lệ thì người chơi phải nhớ thêm một
	# luật riêng chỉ áp dụng cho hai món — đắt hơn nhiều so với một chuyến đi
	# lấy đĩa.
	#
	# Ba loại kem LẺ vẫn giao thẳng không cần đĩa, đúng như tài liệu: chúng
	# lấy nguyên bát từ máy làm kem chứ không đi qua bàn chế tạo.
	"bowl+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop",
	"bowl+cookiestick+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop_que",

	# ---- CÔNG THỨC NỐI TIẾP: ghép thêm vào một MÓN đã ráp xong ----
	#
	# Vì sao cần: bàn chế tạo TỰ RÁP ngay khi khớp công thức. Với những món mà
	# công thức của nó CHỨA TRỌN công thức của một món khác, người chơi bỏ
	# nguyên liệu theo thứ tự "xui" là món ngắn tự ráp trước và chặn mất món
	# dài — bàn kẹt với một tổ hợp không công thức nào khớp.
	#
	# Còn đúng một chỗ bị như vậy:
	#   bowl+3 kem            ⊂ bowl+3 kem+cookiestick   (Kem tam hợp và bánh quế)
	#
	# Bữa tối trước đây cũng nằm trong danh sách này (bowl+ham_cooked và
	# bowl+stew đều là tập con của bowl+ham_cooked+stew). Từ khi nồi canh nấu
	# xong ra thẳng canh hoàn chỉnh thì công thức Bữa tối chỉ còn HAI thứ —
	# ham_cooked + stew — và không tổ hợp nào của nó trùng công thức món
	# khác, nên nó không còn là trường hợp đặc biệt. Dòng của nó ở dưới giữ
	# lại vì đó giờ là công thức DUY NHẤT của Bữa tối, không phải một bản vá.
	#
	# Cách chữa: khai báo thêm công thức "món đã ráp + nguyên liệu còn lại".
	# Chọn cách này thay vì bắt bàn chờ tới khi chắc chắn không còn công thức
	# dài hơn, vì đó là dữ liệu chứ không phải logic: đọc bảng là thấy ngay
	# ghép được gì với gì, và thêm món mới sau này không phải đụng vào code.
	# Đổi lại thì mỗi khi thêm một món CHỨA TRỌN món khác, phải nhớ khai báo
	# kèm dòng nối tiếp.
	"cookiestick+kem_tam_hop": "kem_tam_hop_que",
	# CÔNG THỨC DUY NHẤT của Bữa tối: một nồi canh đã nấu + một miếng ham
	# chín. Không cần đĩa, vì bát canh đã là đồ đựng của chính nó.
	"ham_cooked+stew": "dinner",
}


## Id này có phải MỘT MÓN hoàn chỉnh không (thứ nhấc được khỏi bàn chế tạo).
##
## Suy ra từ chính bảng công thức thay vì gắn cờ vào từng mục: món hoàn chỉnh
## theo định nghĩa là thứ nằm ở vế PHẢI của một công thức. Thêm công thức mới
## là tự động có thêm một món, không phải nhớ đánh dấu ở chỗ thứ hai.
## Giá bán của một món. 0 = chưa định giá.
static func gia(id: String) -> int:
	return int(MUC.get(id, {}).get("gia", 0))


## Thời gian kiên nhẫn của khách gọi món này, tính bằng giây.
##
## TÍNH từ thời gian làm chứ không gõ sẵn một cột thứ hai: công thức trong
## bảng cân bằng là kiên nhẫn = 2,5 × thời gian làm, sàn 35 giây. Hai cột số
## rời nhau thì sửa cột này quên cột kia, và cái quên đó không báo lỗi — chỉ
## làm một món bỗng dưng dễ hoặc khó bất thường.
##
## Vì sao hệ số 2,5: "đơn hoàn hảo" tính khi giao lúc kiên nhẫn còn TRÊN 50%,
## nên người chơi phải xong trong khoảng 1,25 lần thời gian tối ưu.
##
## 11/9/2026: NÂNG CẢ HAI SỐ THÊM 50% (2,5 -> 3,75 và 35 -> 52,5) theo yêu cầu
## user sau buổi chơi thử — thanh kiên nhẫn còn ngắn quá.
##
## Phải nâng CẢ CÁI SÀN chứ không chỉ hệ số: món ngắn nhất (kem, 4,2 giây làm)
## ra 2,5 × 4,2 = 10,5 giây, tức nó luôn bị cái sàn 35 kéo lên. Chỉ nâng hệ số
## thì mọi món ngắn giữ nguyên 35 giây và "thêm 50% cho TẤT CẢ các món" không
## đúng với đúng những món đang dễ bị mất khách nhất.
const HE_SO_KIEN_NHAN := 3.75
const KIEN_NHAN_TOI_THIEU := 52.5

static func kien_nhan(id: String) -> float:
	var t := float(MUC.get(id, {}).get("giay", 0.0))
	if t <= 0.0:
		return KIEN_NHAN_TOI_THIEU
	return maxf(KIEN_NHAN_TOI_THIEU, HE_SO_KIEN_NHAN * t)


## Mọi món BÁN ĐƯỢC, tức có giá. Hệ đơn hàng bốc món từ đây.
static func danh_sach_mon_ban() -> Array[String]:
	var ra: Array[String] = []
	for id in MUC:
		if bi_khoa(String(id)):
			continue
		if int(MUC[id].get("gia", 0)) > 0:
			ra.append(String(id))
	return ra


static func la_mon(id: String) -> bool:
	# HOẶC có giá. Chỉ hỏi CONG_THUC_BAN là thiếu, vì có những món hoàn chỉnh
	# KHÔNG ra đời ở bàn chế tạo: ba loại kem lẻ lấy thẳng từ máy, và từ
	# 14/9/2026 thêm món canh — nấu xong trên bếp là xong luôn.
	#
	# Hàm này chỉ quyết định BÀY MODEL GÌ trên mặt bàn chế tạo, nên hậu quả
	# của việc thiếu là một lỗi im lặng và nhỏ: đặt bát canh lên bàn để ghép
	# Bữa tối thì mặt bàn hiện trống trơn, người chơi tưởng mình đặt hụt.
	return CONG_THUC_BAN.values().has(id) or gia(id) > 0


static func ghep_ban(nguyen_lieu: Array) -> String:
	var ds := nguyen_lieu.duplicate()
	ds.sort()
	var mon := String(CONG_THUC_BAN.get("+".join(ds), ""))
	# Chặn ở KẾT QUẢ chứ không xoá dòng công thức: bảng công thức là tài liệu
	# thiết kế, xoá đi thì lúc mở khoá phải nhớ gõ lại từng dòng.
	if bi_khoa(mon):
		return ""
	return mon


static func cho_vao_lo(id: String) -> bool:
	return CHO_VAO_LO.has(id)


static func nuong_lo(nguyen_lieu: Array) -> String:
	var ds := nguyen_lieu.duplicate()
	ds.sort()
	return String(CONG_THUC_LO.get("+".join(ds), ""))


## Dựng node model 3D của một vật phẩm, hoặc null nếu không có model.
##
## Để ở danh mục chứ không ở trạm: cả đôi tay, cái thớt và cái bàn đều cần
## dựng model từ một id, mà cả ba đều không có lý do gì để biết file .gltf
## nằm ở đâu.
## Tên file gltf của cái bát dùng chung cho mọi món bày bát.
const MODEL_BAT := "bowl"
## Độ cao mặc định đặt thức ăn trong lòng bát. Bát cao 0,30; lòng bát bắt đầu
## khoảng 0,12 — đo từ chính model `stew_bowl` (phần ruột của bát, y 0,12→0,37).
const CAO_TRONG_BAT := 0.12

## `co_do` = vật này đang chứa thứ gì bên trong. Chỉ mục nào khai `model_day`
## mới quan tâm tới cờ này; số còn lại bỏ qua.
static func tao_mo_hinh(id: String, co_do: bool = false) -> Node3D:
	var muc: Dictionary = MUC.get(id, {})
	if muc.has("bat"):
		return _tao_bat_ghep(muc["bat"])

	var ten_m := String(muc.get("model", ""))
	if co_do and muc.has("model_day"):
		ten_m = String(muc["model_day"])
	var m := _nap_model(ten_m)
	if m != null:
		var ti: float = float(muc.get("ti_le", 1.0))
		if not is_equal_approx(ti, 1.0):
			m.scale = Vector3.ONE * ti
	return m


# ══════════════════════════════════════ XẾP CHỒNG TRÊN BÀN CHẾ TẠO
#
# Trước đây mặt bàn chỉ bày ĐÚNG cái đĩa, và chỉ khi trên bàn có đĩa. Bỏ năm
# nguyên liệu lên vẫn thấy một cái đĩa rỗng y như lúc mới đặt — người chơi
# không có cách nào biết mình đã bỏ gì ngoài việc tự nhớ.
#
# Lý do của luật cũ vẫn đúng: bày hết mà cái nào cũng nằm ở y = cao_dat thì
# năm model lồng vào nhau thành một khối không đọc được. Cách chữa không phải
# là giấu bớt, mà là cho mỗi món một ĐỘ CAO riêng.

## Món kế tiếp nhích lên bao nhiêu, khi nó không tự khai "cao".
const CAO_NAC := 0.08

## Thu nhỏ bấy nhiêu khi nằm trong chồng trên bàn, nếu món đó không tự khai
## "ti_le". ĐÂY LÀ NÚM VẶN CHÍNH của cả cơ chế — sửa một số này là cả chồng
## cao lên hay thấp xuống.
##
## Vì sao phải thu nhỏ: model nguyên liệu SỐNG của bộ KayKit to gần bằng cái
## đĩa — cà rốt dài 1,27, xà lách 1,10 × 0,82, trong khi đĩa chỉ rộng 0,95 và
## cao 0,10. Xếp nguyên cỡ thì công thức nồi canh (5 thứ) thành một tháp cao
## 4,21, tức GẤP 2,5 LẦN nhân vật, và nó đâm xuyên máy hút mùi trên bếp.
##
## Vì sao 0,6: 0,35 thử ra quá bé — nguyên liệu thành những đốm màu nằm lọt
## thỏm giữa cái đĩa. Ở 0,6 chồng cao nhất (nồi canh) còn khoảng 1,3, vẫn thấp
## hơn nhân vật (1,7), mà củ cà rốt dài 0,76 thì nhìn ra ngay là củ cà rốt.
##
## VẬT ĐẾ KHÔNG bị thu: cái đĩa phải giữ đúng cỡ đĩa thì đồ mới nhìn như đang
## nằm TRONG nó.
const TI_LE_CHONG := 0.6

## Món không khai "thu_tu" thì nằm ở nấc này. Chọn 50 để còn chỗ cho cả thứ
## phải nằm dưới nó (10–40) lẫn thứ phải nằm trên (60–90).
const THU_TU_MAC_DINH := 50

## Vật đế mặc định cao bao nhiêu, khi nó không tự khai "day".
const DAY_MAC_DINH := 0.12

## Mỗi tầng xoay thêm bấy nhiêu độ quanh trục đứng.
##
## Xoay chứ không để thẳng hàng: chồng hai củ khoai giống hệt nhau lên nhau mà
## cùng góc quay thì nhìn ra MỘT củ méo, không ra hai. Dùng một góc CỐ ĐỊNH
## chứ không randf(): mặt bàn phải bày y hệt nhau mỗi lần dựng lại, nếu không
## thì mỗi lần nhấc một món ra, cả chồng còn lại nhảy sang tư thế khác.
const XOAY_MOI_TANG := 37.0

## Thứ có thể làm ĐẾ cho những thứ khác chồng lên, xếp theo ĐỘ ƯU TIÊN.
##
## Đĩa trước nồi trước đế bánh: trên bàn có cả đĩa lẫn nồi thì cái đĩa mới là
## thứ người chơi đang bày món vào. Đế bánh pizza nằm trong danh sách dù lò
## nướng mới là nơi ráp pizza — người chơi vẫn đặt được đế bánh lên bàn, và
## lúc đó topping nằm TRÊN đế mới đúng nghĩa.
##
## Là một DANH SÁCH chứ không phải một khoá trong MUC: thứ tự ưu tiên là quan
## hệ GIỮA các món với nhau, không phải thuộc tính của từng món — viết vào MUC
## thì phải gán số thứ tự cho mỗi cái và đọc bốn dòng rời rạc mới ra thứ tự.
const VAT_DE := ["bowl", "noi", "noi_canh", "dough_pre"]


## Số liệu bày biện của một vật phẩm. Luôn trả Dictionary, rỗng là hợp lệ.
static func bay(id: String) -> Dictionary:
	return MUC.get(id, {}).get("bay", {})


## Dựng MỘT node gồm cả chồng đồ đang nằm trên bàn chế tạo.
##
## Trả về đúng một Node3D như tao_mo_hinh(), nên nơi gọi (TramTuongTac) không
## phải biết trên bàn có mấy món — nó vẫn giữ đúng một tham chiếu để xoá.
##
## Một món thì đi thẳng tao_mo_hinh(): món đã ráp xong nằm một mình trên bàn
## phải trông y hệt lúc cầm trên tay, không bị nhấc lên một nấc vô cớ.
static func tao_chong(ds: Array[String]) -> Node3D:
	if ds.is_empty():
		return null
	if ds.size() == 1:
		return tao_mo_hinh(String(ds[0]))

	var con: Array[String] = ds.duplicate()
	var goc: Node3D = null
	var cao := 0.0

	for de in VAT_DE:
		var vt := con.find(String(de))
		if vt < 0:
			continue
		goc = tao_mo_hinh(String(de))
		if goc == null:
			continue
		con.remove_at(vt)
		cao = float(bay(String(de)).get("day", DAY_MAC_DINH))
		break

	# Không có vật đế nào: chồng thẳng trên mặt bàn. Dùng một Node3D rỗng làm
	# gốc chứ không lấy món đầu tiên làm gốc — như vậy mọi món con đều tính
	# độ cao theo cùng một mốc, và món đầu không bị nhân hai lần tỉ lệ khi
	# chính nó có "ti_le".
	if goc == null:
		goc = Node3D.new()

	# SẮP XẾP THEO "thu_tu" chứ không theo thứ tự người chơi bỏ lên bàn.
	#
	# Vì sao: cái hamburger phải luôn là đế bánh → xà lách → thịt → phô mai →
	# nắp bánh. Xếp theo thứ tự bỏ vào thì người chơi nhặt phô mai trước sẽ
	# thấy miếng phô mai nằm dưới đáy, và cùng một công thức cho ra mười hình
	# thù khác nhau — mặt bàn thôi không còn là thứ nhìn vào là nhận ra món.
	#
	# Cùng "thu_tu" thì giữ nguyên thứ tự bỏ vào (so thêm chỉ số i): sort_custom
	# của Godot KHÔNG bảo đảm ổn định, nên thiếu vế này thì hai món cùng nấc có
	# thể đổi chỗ cho nhau mỗi lần dựng lại chồng.
	var xep: Array = []
	for i in con.size():
		xep.append({
			"id": String(con[i]),
			"tt": int(bay(String(con[i])).get("thu_tu", THU_TU_MAC_DINH)),
			"i": i,
		})
	xep.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tt"]) != int(b["tt"]):
			return int(a["tt"]) < int(b["tt"])
		return int(a["i"]) < int(b["i"]))

	var tang := 0
	# Mảnh phải nằm TRÊN CÙNG (nắp bánh mì), để dành đặt sau cùng.
	var tren := ""
	var ti_tren := 1.0

	for muc in xep:
		var id := String(muc["id"])
		var b: Dictionary = bay(id)
		var m := _mo_hinh_chong(id)
		if m == null:
			continue
		var ti := float(b.get("ti_le", TI_LE_CHONG))
		if not is_equal_approx(ti, 1.0):
			m.scale = Vector3.ONE * ti
		# NHÂN cả "y" với tỉ lệ, không chỉ "cao": "y" đo trên model cỡ gốc
		# (cà rốt có gốc toạ độ ở GIỮA thân nên phải nâng 0,585 mới chạm đáy).
		# Thu nhỏ rồi mà vẫn nâng 0,585 thì củ cà rốt lơ lửng trên không.
		m.position.y = cao + float(b.get("y", 0.0)) * ti
		# KHÔNG xoay những món có "thu_tu" riêng: chúng là những lát phẳng phải
		# nằm khít lên nhau, xoay đi thì cái bánh thành vẹo. Chỉ xoay đám
		# nguyên liệu nguyên củ nằm ở nấc mặc định.
		if not b.has("thu_tu"):
			m.rotate_y(deg_to_rad(XOAY_MOI_TANG * float(tang)))
		goc.add_child(m)
		# Nhân với ti_le: thu nhỏ một món thì nó cũng MỎNG đi đúng bấy nhiêu,
		# nếu không thì chồng đồ có những khoảng hở giữa các tầng.
		cao += float(b.get("cao", CAO_NAC)) * ti
		tang += 1
		if tren.is_empty() and b.has("model_tren"):
			tren = String(b["model_tren"])
			ti_tren = ti

	if not tren.is_empty():
		var nap := _nap_model(tren)
		if nap != null:
			if not is_equal_approx(ti_tren, 1.0):
				nap.scale = Vector3.ONE * ti_tren
			nap.position.y = cao
			goc.add_child(nap)

	return goc


## Model của một vật phẩm KHI NÓ NẰM TRONG CHỒNG.
##
## Mặc định là model thường. Khai "model" trong khoá "bay" thì dùng cái đó
## thay thế — xà lách nguyên cây (cao 0,82) đổi thành MỘT LÁT (dày 0,088) khi
## kẹp trong bánh mì.
##
## Vì sao không sửa thẳng "model" của mục: cây xà lách vẫn phải là cây xà lách
## lúc cầm trên tay và lúc nằm trong thùng nguyên liệu. Chỉ riêng lúc bị kẹp
## vào bánh nó mới là một lát.
## Tham số đặt tên `ten_m` chứ không `ten`: lớp này đã có hàm ten(id), trùng
## tên thì Godot cảnh báo che khuất — cùng cái bẫy đã ghi ở _nap_model().
static func _mo_hinh_chong(id: String) -> Node3D:
	var ten_m := String(bay(id).get("model", ""))
	if ten_m.is_empty():
		return tao_mo_hinh(id)
	return _nap_model(ten_m)


## Dựng "thức ăn nằm trong bát" = model bát + model thức ăn gắn vào trong.
##
## Cái bát là node GỐC, thức ăn là con. Nhờ vậy mọi chỗ đang gọi tao_mo_hinh()
## — tay cầm, mặt thớt, mặt bàn khách — không cần biết món này gồm mấy mảnh:
## chúng vẫn nhận đúng MỘT Node3D và đặt nó như mọi vật phẩm khác.
##
## Thiếu model thức ăn thì vẫn trả về cái bát rỗng chứ không trả null: mất một
## món ăn trên bàn còn dễ nhận ra và dễ chơi tiếp hơn là mất luôn cả vật phẩm.
static func _tao_bat_ghep(cai: Dictionary) -> Node3D:
	var bat := _nap_model(MODEL_BAT)
	if bat == null:
		return null
	var an := _nap_model(String(cai.get("model", "")))
	if an != null:
		an.position.y = float(cai.get("y", CAO_TRONG_BAT))
		var ti := float(cai.get("ti_le", 1.0))
		if not is_equal_approx(ti, 1.0):
			an.scale = Vector3.ONE * ti
		bat.add_child(an)
	return bat


## Nạp một file gltf theo TÊN MODEL (không phải id vật phẩm).
##
## Tham số đặt tên `ten_model` chứ không phải `ten`: lớp này đã có hàm ten(id),
## trùng tên thì Godot cảnh báo che khuất và trong thân hàm không gọi được hàm
## đó nữa.
static func _nap_model(ten_model: String) -> Node3D:
	if ten_model.is_empty():
		return null
	var duong_dan := MODEL % ten_model
	if not ResourceLoader.exists(duong_dan):
		push_warning("Thiếu model: %s" % duong_dan)
		return null
	var canh := load(duong_dan) as PackedScene
	if canh == null:
		return null
	return canh.instantiate() as Node3D


static func co(id: String) -> bool:
	return MUC.has(id)


static func ten(id: String) -> String:
	return String(MUC.get(id, {}).get("ten", id))


## Đường dẫn ảnh 2D. Mặc định tên file TRÙNG id — bớt một cột dữ liệu và bớt
## luôn một chỗ để gõ sai; chỉ những món dùng lại ảnh của nguyên liệu mới
## phải khai báo khoá "anh".
static func duong_dan_anh(id: String) -> String:
	return ANH % String(MUC.get(id, {}).get("anh", id))


static func duong_dan_model(id: String) -> String:
	var m := String(MUC.get(id, {}).get("model", ""))
	return MODEL % m if not m.is_empty() else ""


## Kết quả sau khi thái ở thớt. Rỗng nghĩa là thứ này không thái được.
static func so_che(id: String) -> String:
	return String(MUC.get(id, {}).get("so_che", ""))


## Kết quả sau khi nấu lẻ trên bếp. Rỗng nghĩa là không nấu lẻ được.
static func nau_don(id: String) -> String:
	return String(MUC.get(id, {}).get("nau", ""))


## Trạng thái cháy nếu để quá lửa. Rỗng nghĩa là món này không cháy được.
static func trang_thai_hong(id: String) -> String:
	return String(MUC.get(id, {}).get("hong", ""))
