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
##   name   — chữ hiện trên giao diện
##   icon   — id ảnh 2D, chỉ ghi khi KHÁC id vật phẩm (món dùng lại ảnh của
##            nguyên liệu). Bỏ trống thì lấy đúng id.
##   model  — file .gltf sinh ra vật thể CẦM TRÊN TAY và bày trên bàn khách
##   prep   — id sau khi THÁI ở thớt (rỗng = không thái được)
##   cook   — id sau khi NẤU ở bếp (rỗng = không nấu lẻ được)
##   burnt  — id khi để quá lửa trên bếp (rỗng = không cháy)
##   scale  — hệ số phóng to/thu nhỏ model, chỉ ghi khi KHÁC 1.0
##   layout — CÁCH XẾP CHỒNG trên mặt bàn chế tạo. Bỏ trống thì dùng số mặc
##            định, nên CHỈ khai khi món đó bày ra nhìn không ổn:
##            {"thickness": chỉ cho VẬT ĐẾ — mặt trong của nó cao bao nhiêu,
##                       tức món đầu tiên nằm ở độ cao nào (mặc định 0.12),
##             "height": món này DÀY bao nhiêu, tức món kế tiếp nhích lên bấy
##                       nhiêu (mặc định STACK_STEP),
##             "scale":  thu nhỏ riêng khi nằm trên bàn (mặc định STACK_SCALE),
##             "y":      lệch thêm theo trục đứng, để chữa model có tâm không
##                       nằm ở đáy (mặc định 0.0),
##             "order":  VỊ TRÍ trong chồng — số nhỏ nằm DƯỚI (mặc định 50),
##             "model":  model KHÁC dùng riêng khi nằm trong chồng, ví dụ xà
##                       lách nguyên cây đổi thành một lát, hay cây kem ốc quế
##                       đổi thành một bát kem,
##             "model_top": mảnh thứ hai, luôn đặt TRÊN CÙNG cả chồng — mới
##                       chỉ bánh mì dùng, để có nắp bánh}
##   on_plate — món BÀY TRONG BÁT. Ghi khoá này thì KHÔNG ghi "model": bộ dựng
##            tự nạp cái bát rồi gắn phần thức ăn vào trong lòng nó.
##            {"model": tên gltf phần thức ăn,
##             "y": độ cao đặt trong lòng bát (mặc định BOWL_INNER_HEIGHT),
##             "scale": thu nhỏ phần thức ăn, mặc định 1.0}
##   model_inner — model thay thế khi vật đựng ĐANG CÓ THỨ BÊN TRONG (nồi có
##            canh), dùng qua make_model(id, has_content = true)
##   cost / price / seconds — giá vốn, giá bán, thời gian làm; xem cost() bên dưới
##
## Vì sao tách "so_che" và "nau" thành HAI khoá thay vì một khoá "bước kế
## tiếp": steak đi qua cả hai bước (thái rồi nấu) còn ham thì nấu thẳng. Một
## khoá duy nhất thì không phân biệt được đưa steak sống lên bếp là hợp lệ
## hay không. Hai khoá thì mỗi trạm chỉ hỏi đúng khoá của mình, và "mang
## steak chưa thái lên bếp" tự động không làm gì — không cần viết luật chặn.

const ICON_FMT := "res://assets/ui/nguyen_lieu/%s.png"
const MODEL_FMT := "res://assets/gltf/%s.gltf"

const ITEMS := {
	# ---- nguyên liệu lấy từ thùng ----
	"bun":        {"cost": 1, "name": "Bánh mì",   "model": "food_ingredient_bun",
		# Ổ bánh nguyên lúc cầm trên tay; TRÊN BÀN thì tách làm hai mảnh —
		# đế nằm dưới cùng (nấc 10), nắp luôn đậy trên cùng cả chồng.
		# Số đo: đế dày 0,200; nắp dày 0,307.
		"layout": {"order": 10, "height": 0.20,
			"model": "food_ingredient_bun_bottom",
			"model_top": "food_ingredient_bun_top"}},
	"lettuce":    {"cost": 2, "name": "Xà lách",   "model": "food_ingredient_lettuce",
		# Cả cây xà lách cao 0,82 — kẹp nguyên cây vào bánh thì bánh cao gấp
		# bốn lần bình thường. Trong chồng dùng MỘT LÁT, dày 0,088.
		"layout": {"order": 20, "height": 0.088, "y": 0.034,
			"model": "food_ingredient_lettuce_slice"}},
	"carrot":     {"cost": 4, "name": "Cà rốt",    "model": "food_ingredient_carrot",
		"layout": {"height": 1.27, "y": 0.585}},
	"potato":     {"cost": 4, "name": "Khoai tây", "model": "food_ingredient_potato",
		"layout": {"height": 0.78, "y": 0.394}},
	"tomato":     {"cost": 2, "name": "Cà chua",   "model": "food_ingredient_tomato",
		"layout": {"height": 0.70}},
	"onion":      {"cost": 4, "name": "Hành tây",  "model": "food_ingredient_onion",
		"layout": {"height": 0.86, "y": 0.011}},
	"mushroom":   {"cost": 4, "name": "Nấm",       "model": "food_ingredient_mushroom",
		"layout": {"height": 0.57, "y": 0.217}},
	"dough":      {"cost": 4, "name": "Bột",       "model": "food_ingredient_dough",
		"prep": "dough_pre"},
	# "arrange" = topping bày VÒNG QUANH mặt đế thay vì chồng lên nhau. Xem
	# _arrange_ring(). Đế rộng 1,75 (bán kính 0,87): vòng 0,42 giữ topping
	# nằm gọn trong mép bánh. Thu 0,55 (chụp thử: 0,4 thì cây nấm chỉ còn một
	# chấm trắng, không ai nhận ra là nấm).
	"dough_pre":  {"name": "Bột đã cán", "model": "food_ingredient_dough_base",
		"layout": {"thickness": 0.14, "arrange": {"radius": 0.42, "scale": 0.55}}},

	# ---- nguyên liệu trong tủ lạnh ----
	# Ham KHÔNG qua thớt — nấu thẳng. Ảnh dùng lại ham_uncook.png (ham sống)
	# vì bộ ảnh không có file "ham.png" riêng.
	"ham":        {"cost": 9, "name": "Ham", "model": "food_ingredient_ham",
		"icon": "ham_uncook", "cook": "ham_cooked", "burnt": "ham_cooked_fail"},
	"ham_cooked": {"name": "Ham đã nấu",  "model": "food_ingredient_ham_cooked",
		"layout": {"height": 0.83, "y": 0.415}},
	"ham_cooked_fail": {"name": "Ham cháy", "model": "food_ingredient_ham_trash"},

	"steak":        {"cost": 9, "name": "Steak", "model": "food_ingredient_steak",
		"prep": "steak_uncook"},
	"steak_uncook": {"name": "Steak đã thái", "layout": {"height": 0.20},
		"model": "food_ingredient_burger_uncooked",
		"cook": "steak_cooked", "burnt": "steak_cooked_fail"},
	"steak_cooked": {"name": "Steak đã nấu",
		# Nấc 30: giữa xà lách (20) và phô mai (40), đúng thứ tự một cái burger.
		# Model food_ingredient_burger_cooked vốn đã là miếng chả tròn dày 0,20,
		# không cần đổi model.
		"layout": {"order": 30, "height": 0.20},
		"model": "food_ingredient_burger_cooked"},
	"steak_cooked_fail": {"name": "Steak cháy",
		"model": "food_ingredient_burger_trash"},

	"cheese":      {"cost": 7, "name": "Phô mai",  "model": "food_ingredient_cheese",
		# Khối phô mai cao 0,50 → một lát dày 0,105. Gốc toạ độ của lát nằm
		# gần MẶT TRÊN (y từ −0,087 tới 0,018) nên phải nâng 0,087.
		"layout": {"order": 40, "height": 0.105, "y": 0.087,
			"model": "food_ingredient_cheese_slice"}},
	# Hai model, cùng cách với ba vị kem ở dưới:
	#   "model"        — BÁT bánh quế. Dùng khi cầm trên tay, và khớp với ảnh 2D
	#                    (cookiestick.png cũng là một bát bánh quế).
	#   layout.model   — MỘT que bánh. Dùng khi cắm vào bát kem tam hợp: lúc đó
	#                    cái bát đã có sẵn, chồng thêm bát nữa là bát lồng bát.
	"cookiestick": {"cost": 1, "name": "Bánh quế", "model": "icecream_bowl_cookiesticks",
		"layout": {"height": 0.52, "y": 0.258, "model": "icecream_cookiestick"}},

	"peperoni":     {"cost": 9, "name": "Xúc xích", "model": "food_ingredient_pepperoni",
		"prep": "peperoni_pre"},
	"peperoni_pre": {"name": "Xúc xích đã thái", "layout": {"height": 0.40},
		"model": "food_ingredient_pepperoni_chopped"},

	# ---- vật chứa ----
	"bowl": {"name": "Đĩa", "model": "plate", "layout": {"thickness": 0.08}},
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
	"noi": {"name": "Nồi", "model": "pot_A", "layout": {"thickness": 0.48}},
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
	# Cơ chế: cooking_system._process chỉ giữ mẻ lại đếm tiếp (để rồi cháy) khi
	# `trang_thai_hong(goc)` KHÁC RỖNG; không có khoá `hong` thì nấu xong là
	# mẻ bị gỡ khỏi bảng đang-nấu ngay, không có đường nào đi tới _chay().
	# Nghĩa là nồi canh nằm trên bếp bao lâu cũng được.
	"noi_canh": {"name": "Nồi canh (sống)", "model": "pot_A_stew",
		"cook": "stew", "layout": {"thickness": 0.48}},

	# ---- món hoàn chỉnh ----
	"hambuger":      {"name": "Hamburger",       "model": "food_burger",
		"price": 95, "seconds": 20.0},
	"vegetablebuger_uncook": {"name": "Steak rau củ (sống)",
		"model": "food_ingredient_vegetableburger_uncooked",
		"cook": "vegetablebuger_cooked", "burnt": "vegetablebuger_cooked_fail"},
	"vegetablebuger_cooked": {"name": "Steak rau củ (chín)",
		"layout": {"order": 30, "height": 0.216},
		"model": "food_ingredient_vegetableburger_cooked"},
	# (2/10/2026) Chả rau củ cũng CHÁY được, như ham và steak. Trước đây nó
	# là thứ duy nhất nấu trên bếp mà bỏ quên bao lâu cũng không sao — tức là
	# món khó nhất thực đơn lại an toàn nhất ở đúng khâu dễ hỏng nhất.
	#
	# Mượn model và ảnh của steak cháy: bộ KayKit chỉ có hai model "trash"
	# (burger và ham), không có bản cháy riêng cho chả rau củ. Cháy đen rồi
	# thì hai miếng chả trông như nhau, nên mượn không gây nhầm.
	"vegetablebuger_cooked_fail": {"name": "Steak rau củ cháy",
		"icon": "steak_cooked_fail",
		"model": "food_ingredient_burger_trash"},
	"vegetablebuger": {"name": "Hamburger rau củ", "model": "food_vegetableburger",
		"price": 210, "seconds": 22.6},
	"dinner":        {"name": "Bữa tối",         "model": "food_dinner",
		"price": 250, "seconds": 30.6},
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
	"stew": {"name": "Canh rau củ", "model": "food_stew", "layout": {"height": 0.37},
		"price": 235, "seconds": 28.0},
	# Ba loại pizza thu nhỏ còn 0.7: model "plated" của KayKit đã kèm sẵn cái
	# khay bên dưới nên to hơn hẳn mọi món khác, cầm trên tay thì che mất
	# nửa nhân vật.
	"pizza_cheese":   {"name": "Pizza phô mai",  "model": "food_pizza_cheese_plated",
		"scale": 0.5, "price": 105, "seconds": 23.0},
	"pizza_mushroom": {"name": "Pizza nấm",      "model": "food_pizza_mushroom_plated",
		"scale": 0.5, "price": 100, "seconds": 23.0},
	"pizza_peperoni": {"name": "Pizza xúc xích", "model": "food_pizza_pepperoni_plated",
		"scale": 0.5, "price": 100, "seconds": 23.0},
	# PIZZA SỐNG — ghép sẵn ở bàn chế tạo, mang vào lò nướng thẳng.
	#
	# Là con đường THỨ HAI tới cùng ba chiếc pizza, không thay con đường cũ
	# (bỏ đế vào lò rồi thả topping). Lợi của đường mới: ghép trước lúc lò còn
	# bận mẻ khác, nên hai mẻ pizza gối nhau được.
	#
	# "bake" chứ KHÔNG "cook": khoá "cook" là thứ cái BẾP đọc (put_item →
	# cook_step). Ghi "cook" thì pizza sống bỏ lên bếp cũng nấu chín được —
	# một lối tắt không ai thiết kế. Khoá riêng thì chỉ lò hỏi tới nó.
	#
	# Dùng CHÍNH model của pizza chín, phủ "raw_look" cho nhạt màu (xem
	# _apply_raw_look). Bộ KayKit không có model pizza sống, và cùng hình dáng
	# còn là một lợi thế: người chơi nhận ra ngay "đây là pizza gì", chỉ còn
	# phải hỏi "đã nướng chưa" — đúng câu mà độ nhạt trả lời.
	#
	# Không "price": chưa nướng thì không bán. Không "cost": tiền đã trừ lúc
	# lấy từng nguyên liệu. "icon" mượn ảnh pizza chín; tên có chữ "(sống)".
	"pizza_cheese_uncooked":   {"name": "Pizza phô mai (sống)", "icon": "pizza_cheese",
		"model": "food_pizza_cheese_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_cheese"},
	"pizza_mushroom_uncooked": {"name": "Pizza nấm (sống)", "icon": "pizza_mushroom",
		"model": "food_pizza_mushroom_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_mushroom"},
	"pizza_peperoni_uncooked": {"name": "Pizza xúc xích (sống)", "icon": "pizza_peperoni",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_peperoni"},
	# Ba loại kem lẻ mang HAI hình dạng, tuỳ chỗ chúng đang nằm:
	#
	#   "model"        — cây kem ốc quế. Dùng khi cầm trên tay và khi đã giao
	#                    cho khách, tức là lúc nó đóng vai MÓN BÁN hoàn chỉnh.
	#   "layout.model" — bát kem một viên. Dùng khi nằm trong chồng trên bàn
	#                    chế tạo, tức là lúc nó đóng vai NGUYÊN LIỆU của kem
	#                    tam hợp.
	#
	# Vì sao phải tách: một viên kem trong game này mang hai vai. Ảnh 2D của nó
	# (icecream_vani.png) vẽ cây ốc quế, nên trước đây cầm trên tay lại ra cái
	# bát là LỆCH với chính ảnh đơn hàng mà khách đang giơ. Nhưng ốc quế thì
	# không xếp chồng được: kem tam hợp là ba viên nằm trong MỘT cái bát, chồng
	# ba cây ốc quế lên nhau vừa xuyên qua nhau vừa vô nghĩa.
	#
	# Không cần thêm cơ chế mới: khoá "layout.model" đã có sẵn và đang được xà
	# lách (cả cây → một lát) với phô mai (cả khối → một lát) dùng đúng kiểu
	# này. Đây là mục thứ ba dùng lại nó, nên bảng dữ liệu vẫn chỉ có một cách
	# diễn đạt "vật này trông khác khi nằm trong chồng".
	#
	# "height" 0.36 giữ nguyên vì nó tả CÁI BÁT — đúng chiều cao model bát
	# (0.360), và height chỉ có nghĩa trong chồng. Cây ốc quế cao 1.036 nhưng
	# không bao giờ vào chồng nên không ảnh hưởng số này.
	"icecream_vani":       {"cost": 2, "name": "Kem vani",
		"model": "food_icecream_cone_vanilla",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_vanilla"},
		"price": 15, "seconds": 4.2},
	"icecream_chocolate":  {"cost": 2, "name": "Kem chocolate",
		"model": "food_icecream_cone_chocolate",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_chocolate"},
		"price": 15, "seconds": 4.2},
	"icecream_strawberry": {"cost": 2, "name": "Kem dâu",
		"model": "food_icecream_cone_strawberry",
		"layout": {"height": 0.36, "model": "icecream_bowl_icecream_strawberry"},
		"price": 15, "seconds": 4.2},
	# Hai món kem ghép. Khác ba loại kem lẻ ở trên (lấy thẳng từ máy rồi giao
	# luôn), hai món này phải qua bàn chế tạo — xem TABLE_RECIPES.
	#
	# Ảnh riêng chứ không mượn ảnh kem lẻ: cả hai đều là BA viên kem trong một
	# bát, nhìn từ xa mà dùng ảnh một viên thì người chơi không phân biệt được
	# mình đang cầm món ghép hay nguyên liệu rời.
	"kem_tam_hop": {"name": "Kem tam hợp",
		"model": "icecream_bowl_decorated_B", "layout": {"height": 0.73},
		"price": 40, "seconds": 8.9},
	"kem_tam_hop_que": {"name": "Kem tam hợp và bánh quế",
		"model": "icecream_bowl_decorated_A", "price": 55, "seconds": 12.2},

	# ---- món bày ra đĩa (dùng lại ảnh của nguyên liệu cuối) ----
	# Ba món dưới đây là BÁT GHÉP: bộ KayKit không có model nào sẵn "thức ăn
	# nằm trong bát", nên phải ghép cái bát với phần thức ăn lúc chạy. Ghép
	# bằng dữ liệu chứ không dựng ba file .tscn: ba dòng ở đây rẻ hơn ba file
	# phải mở ra sửa mỗi lần đổi độ cao, và món thứ tư chỉ là thêm một dòng.
	"mon_ham":  {"name": "Ham",
		"on_plate": {"model": "food_ingredient_ham_cooked", "y": 0.37, "scale": 0.75},
		"icon": "ham_cooked", "price": 60, "seconds": 14.9},
	# Món dạy trong màn hướng dẫn. Đây là món NGẮN NHẤT đi qua đủ cả bốn trạm
	# thái → nấu → đĩa → bàn chế tạo: chuỗi "thái rồi nấu" trong game chỉ có ở
	# steak, mà trước đó steak_cooked chỉ dùng cho Hamburger 5 nguyên liệu —
	# quá dài cho bài học đầu tiên.
	#
	# Giá suy từ đúng công thức trong bảng cân bằng: 4 × 19,4 giây × 1,04
	# (một nguyên liệu phụ trội) ≈ 80. Thời gian 19,4 s = thời gian món Ham
	# (14,9 s) cộng một chuyến ghé thớt.
	"mon_steak": {"name": "Steak",
		"on_plate": {"model": "food_ingredient_burger_cooked", "y": 0.12},
		"icon": "steak_cooked", "price": 80, "seconds": 19.4},
	# Steak rau củ bày bát.
	#
	# (Đổi tên 18/9/2026) Trước là "Chả rau củ". Ba mục vegetablebuger_* cùng
	# đổi theo, vì chúng là ba trạng thái của CÙNG một miếng — tên lệch nhau
	# thì người chơi đọc bảng công thức không nối được "chả" với "steak".
	#
	# Giá 105 suy từ công thức bảng cân bằng khi miếng này còn là 2 nguyên
	# liệu (steak + cà rốt). Từ 18/9 nó thành 4 nguyên liệu, nên con số này
	# ĐANG THẤP so với công sức bỏ ra — xem ghi chú ở TABLE_RECIPES.
	"vegetablesteak": {"name": "Steak rau củ",
		"on_plate": {"model": "food_ingredient_vegetableburger_cooked", "y": 0.12},
		"icon": "vegetablebuger_cooked", "price": 105, "seconds": 24.5},

	# ---- đồ hỏng ----
	"do_hong": {"name": "Đồ hỏng", "model": "food_ingredient_ham_trash"},
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
## mà nó thì không có hình va chạm nào. Sửa ở `Workstation.build_carriable()`.
##
## GIỮ LẠI cái công tắc này dù đã mở: nó là cách tắt cả một nhánh cơ chế trong
## một dòng khi cần thử cân bằng hay quay phim demo. Đổi thành false là thực
## đơn tự bỏ ba món nấu nồi, khách thôi gọi chúng, và cái nồi biến khỏi map —
## không phải sửa chỗ nào khác.
const POT_ENABLED := true

## Những id chỉ tồn tại được khi có nồi: chính cái nồi, món nấu ra từ nồi, và
## mọi món CHỨA món đó. Bữa tối nằm đây vì công thức của nó cần "stew".
const POT_LOCKED_ITEMS := ["noi", "noi_canh", "stew", "dinner"]

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
static func is_locked(id: String) -> bool:
	return not POT_ENABLED and POT_LOCKED_ITEMS.has(id)


## (Đã bỏ) CHO_VAO_NOI và TABLE_RECIPES — bảng "thứ gì đổ được vào nồi" và
## bảng "nồi chứa gì thì ra món gì".
##
## Cả hai là bảng công thức THỨ HAI của một cái bàn ghép đồ, chỉ khác chỗ
## người chơi đứng. Công thức nấu canh giờ nằm chung TABLE_RECIPES với mọi
## công thức khác, nên muốn biết làm canh thế nào thì tra đúng một bảng.


## Những thứ cho được vào LÒ NƯỚNG sau khi đã có đế bánh.
##
## Không có dough_pre trong danh sách này: đế bánh là thứ KHỞI ĐỘNG lò, không
## phải topping. Tách hai vai ra thì "bỏ đế thứ hai vào lò đang chạy" tự động
## là hành động không hợp lệ, không cần viết thêm luật nào để chặn.
const OVEN_TOPPINGS := ["cheese", "mushroom", "onion", "tomato", "peperoni_pre"]

## Đế bánh — thứ duy nhất bật được lò nướng.
const PIZZA_BASE := "dough_pre"

## Công thức lò nướng. Cùng quy ước khoá với TABLE_RECIPES: sắp xếp rồi nối
## bằng "+", nên thứ tự bỏ vào không quan trọng.
const OVEN_RECIPES := {
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
const TABLE_RECIPES := {
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
	# phím F sinh ra để dập — xem _rap_ban() trong hands.gd.
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
	# Pizza sống. CÙNG KHOÁ với OVEN_RECIPES, cố ý: một chiếc pizza làm từ
	# đúng một bộ nguyên liệu dù ráp ở đâu. Hai bảng khác nhau ở KẾT QUẢ
	# (lò ra pizza chín, bàn ra pizza sống), không khác ở công thức — nên
	# người chơi học một công thức, dùng được ở hai nơi.
	"dough_pre+peperoni_pre+tomato": "pizza_peperoni_uncooked",
	"dough_pre+mushroom+tomato": "pizza_mushroom_uncooked",
	"cheese+dough_pre+onion+tomato": "pizza_cheese_uncooked",

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


# ══════════════════════════════════════════════════════════════════════════
# PHƯƠNG ÁN B — THỰC ĐƠN THEO HỌ MÓN (thử nghiệm, 16/11/2026)
# ══════════════════════════════════════════════════════════════════════════
#
# Bật bằng `plan_b = true` (scene recipe_plan_b_test.tscn bật lúc mở). Tắt là
# game chạy y nguyên bộ công thức cũ — nên thử phương án B không đụng tới
# màn chơi nào đang có.
#
# Vì sao làm bằng một công tắc + bảng ĐÈ chứ không sửa thẳng bảng gốc: đây
# mới là thử nghiệm. Nếu chốt B thì chỉ việc gộp bảng đè vào bảng gốc rồi xoá
# công tắc; nếu bỏ B thì xoá khối này là xong, không phải gỡ từng dòng.
#
# Vì sao các hàm đọc items()/table_recipes() thay vì hằng số: hằng số trong
# GDScript không đổi được lúc chạy. Hàm thì chọn được bảng theo công tắc.
#
# Bốn quy tắc của B (giải thích trong tài liệu so sánh):
#   1. MỌI nguyên liệu đều qua thớt trước (16/11/2026; bỏ ham và Bữa tối).
#   2. Họ burger: đĩa + bánh mì + steak chín + 0/1 nguyên liệu phụ.
#   3. Họ soup: nồi + 3 phần CÙNG một loại rau đã thái.
#   4. Họ pizza: ghép ở bàn (đế + cà chua + 1 topping) rồi mới vào lò.
## (16/11/2026) BẬT MẶC ĐỊNH — user chốt áp dụng phương án B cho game gốc.
## Giữ công tắc thay vì gộp hẳn bảng B vào bảng gốc: đổi về false là quay lại
## bộ công thức cũ trong một dòng, khi cần so sánh lúc bảo vệ đồ án.
static var plan_b := true

static var _items_b: Dictionary = {}

## Mục ĐÈ lên ITEMS. Giá trị null = XOÁ mục đó khỏi thực đơn B.
const PLAN_B_ITEMS := {
	# (16/11/2026) MỌI món đều qua thớt — quy tắc chung của B, kiểu Overcooked:
	# nguyên liệu lấy ra luôn phải thái trước. Nhờ vậy dưới vé đơn hàng không
	# cần kí hiệu dao; chỉ còn chảo (bếp), nồi (soup) và lò (pizza).
	# Model "đã thái" lấy từ bộ KayKit (food_ingredient_*_chopped...).
	"steak": {"cost": 9, "name": "Steak", "model": "food_ingredient_steak",
		"prep": "steak_uncook"},
	"cheese": {"cost": 7, "name": "Phô mai", "model": "food_ingredient_cheese",
		"prep": "cheese_chopped"},
	"lettuce": {"cost": 2, "name": "Xà lách", "model": "food_ingredient_lettuce",
		"prep": "lettuce_chopped"},
	"tomato": {"cost": 2, "name": "Cà chua", "model": "food_ingredient_tomato",
		"prep": "tomato_chopped"},
	"mushroom": {"cost": 4, "name": "Nấm", "model": "food_ingredient_mushroom",
		"prep": "mushroom_chopped"},
	"carrot": {"cost": 4, "name": "Cà rốt", "model": "food_ingredient_carrot",
		"prep": "carrot_chopped"},
	"onion": {"cost": 4, "name": "Hành tây", "model": "food_ingredient_onion",
		"prep": "onion_chopped"},
	"potato": {"cost": 4, "name": "Khoai tây", "model": "food_ingredient_potato",
		"prep": "potato_chopped"},

	# Đồ hỏng chung (nấu sai, kĩ năng gieo thất bại): trước đây thiếu ảnh 2D
	# (kiểm thử 16/11/2026 bắt được) — mượn ảnh steak cháy.
	"do_hong": {"name": "Đồ hỏng", "model": "food_ingredient_ham_trash",
		"icon": "steak_cooked_fail"},
	# Đổi tên chuỗi ham theo tên món mới "Đùi nướng" (16/11/2026): thông báo
	# "Nấu xong: Ham đã nấu" lệch hẳn với tên món trên vé.
	"ham": {"cost": 9, "name": "Đùi sống", "model": "food_ingredient_ham",
		"icon": "ham_uncook", "cook": "ham_cooked", "burnt": "ham_cooked_fail"},
	"ham_cooked": {"name": "Đùi nướng chín", "model": "food_ingredient_ham_cooked",
		"layout": {"height": 0.83, "y": 0.415}},
	"ham_cooked_fail": {"name": "Đùi cháy", "model": "food_ingredient_ham_trash"},

	# ---- bản đã thái ----
	# Ảnh 2D mượn ảnh nguyên liệu gốc: trên vé người chơi chỉ cần biết "cà
	# chua"; trạng thái đã thái nhìn ở model 3D đang cầm.
	# layout: lát phô mai / xà lách dùng lại số đo của bộ cũ (chồng burger).
	"cheese_chopped": {"name": "Phô mai đã thái", "icon": "cheese",
		"model": "food_ingredient_cheese_slice",
		"layout": {"order": 40, "height": 0.105, "y": 0.087,
			"model": "food_ingredient_cheese_slice"}},
	"lettuce_chopped": {"name": "Xà lách đã thái", "icon": "lettuce",
		"model": "food_ingredient_lettuce_chopped",
		"layout": {"order": 20, "height": 0.088, "y": 0.034,
			"model": "food_ingredient_lettuce_slice"}},
	"tomato_chopped": {"name": "Cà chua đã thái", "icon": "tomato",
		"model": "food_ingredient_tomato_slices", "layout": {"height": 0.15}},
	"mushroom_chopped": {"name": "Nấm đã thái", "icon": "mushroom",
		"model": "food_ingredient_mushroom_chopped", "layout": {"height": 0.3}},
	"carrot_chopped": {"name": "Cà rốt đã thái", "icon": "carrot",
		"model": "food_ingredient_carrot_chopped", "layout": {"height": 0.3}},
	"onion_chopped": {"name": "Hành tây đã thái", "icon": "onion",
		"model": "food_ingredient_onion_chopped", "layout": {"height": 0.3}},
	"potato_chopped": {"name": "Khoai tây đã thái", "icon": "potato",
		"model": "food_ingredient_potato_chopped", "layout": {"height": 0.3}},

	# Ba nồi soup sống — cùng cơ chế noi_canh cũ (bỏ lên bếp, nấu ra thẳng soup).
	"soup_carrot_raw": {"name": "Nồi soup cà rốt (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_carrot", "layout": {"thickness": 0.48}},
	"soup_onion_raw": {"name": "Nồi soup hành tây (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_onion", "layout": {"thickness": 0.48}},
	"soup_potato_raw": {"name": "Nồi soup khoai tây (sống)", "model": "pot_A_stew",
		"icon": "noi", "cook": "soup_potato", "layout": {"thickness": 0.48}},

	# Pizza sống có ảnh riêng (đế bột chưa nướng) thay cho ảnh pizza chín.
	"pizza_cheese_uncooked": {"name": "Pizza phô mai (sống)",
		"model": "food_pizza_cheese_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_cheese", "burnt": "pizza_cheese_burnt"},
	"pizza_mushroom_uncooked": {"name": "Pizza nấm (sống)",
		"model": "food_pizza_mushroom_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_mushroom", "burnt": "pizza_mushroom_burnt"},
	"pizza_peperoni_uncooked": {"name": "Pizza xúc xích (sống)",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5,
		"raw_look": true, "bake": "pizza_peperoni", "burnt": "pizza_peperoni_burnt"},

	# PIZZA CHÁY — để pizza trong lò quá lâu sau khi chín. Không có model
	# riêng: phủ đen lên chính model pizza ("burnt_look"), nên người chơi vẫn
	# nhận ra là chiếc pizza mình vừa nướng, chỉ là đã cháy. Không giá → không
	# giao được, chỉ bỏ thùng rác.
	"pizza_cheese_burnt": {"name": "Pizza cháy", "icon": "pizza_cheese",
		"model": "food_pizza_cheese_plated", "scale": 0.5, "burnt_look": true},
	"pizza_mushroom_burnt": {"name": "Pizza cháy", "icon": "pizza_mushroom",
		"model": "food_pizza_mushroom_plated", "scale": 0.5, "burnt_look": true},
	"pizza_peperoni_burnt": {"name": "Pizza cháy", "icon": "pizza_peperoni",
		"model": "food_pizza_pepperoni_plated", "scale": 0.5, "burnt_look": true},

	# ---- món bán ----
	# Giá theo bảng cân bằng: ≈ 4 × giây × (1 + 4% × nguyên liệu phụ trội).
	# Steak thêm một chuyến ghé thớt so với bản trước → 19,4 s như bộ cũ.
	"mon_steak": {"name": "Steak",
		"on_plate": {"model": "food_ingredient_burger_cooked", "y": 0.12},
		"icon": "steak_cooked", "price": 80, "seconds": 19.4},
	# Ba burger: chưa có model riêng nên cầm trên tay dùng chung food_burger;
	# ảnh 2D thì riêng từng món.
	"burger_plain": {"name": "Burger thường", "model": "food_burger",
		"stack": ["bowl", "bun", "steak_cooked"], "scale": 1.6,
		"price": 85, "seconds": 21.0},
	"burger_cheese": {"name": "Burger phô mai", "model": "food_burger",
		"stack": ["bowl", "bun", "steak_cooked", "cheese_chopped"], "scale": 1.6,
		"price": 100, "seconds": 24.0},
	"burger_lettuce": {"name": "Burger xà lách", "model": "food_burger",
		"stack": ["bowl", "bun", "lettuce_chopped", "steak_cooked"], "scale": 1.6,
		"price": 100, "seconds": 24.0},
	# HAMBURGER ĐẦY ĐỦ — như bản gốc: cả phô mai lẫn xà lách. Id "hambuger"
	# giữ nguyên để dùng lại ảnh hambuger.png.
	"hambuger": {"name": "Hamburger", "model": "food_burger",
		"stack": ["bowl", "bun", "lettuce_chopped", "steak_cooked", "cheese_chopped"],
		"scale": 1.6, "price": 115, "seconds": 27.0},
	# HAM + BỮA TỐI — thêm lại (16/11/2026). Ham giữ công thức cũ (nấu thẳng,
	# không thái — ngoại lệ duy nhất của quy tắc "mọi thứ qua thớt", vì KayKit
	# không có model ham thái). Bữa tối đổi công thức: ham chín + soup cà rốt.
	"mon_ham": {"name": "Đùi nướng",
		"on_plate": {"model": "food_ingredient_ham_cooked", "y": 0.37, "scale": 0.75},
		"icon": "ham_cooked", "price": 60, "seconds": 14.9},
	# ĐÙI NƯỚNG CÀ RỐT (id "dinner" giữ nguyên để dùng lại ảnh dinner.png và
	# model food_dinner — chính là đùi nướng với cà rốt trên đĩa, khớp công
	# thức mới: đĩa + đùi nướng chín + cà rốt thái).
	"dinner": {"name": "Đùi nướng cà rốt", "model": "food_dinner",
		"price": 90, "seconds": 22.0},
	"soup_carrot": {"name": "Soup cà rốt", "model": "bowl", "liquid": "e8792b",
		"topping": {"model": "food_ingredient_carrot_pieces", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},
	"soup_onion": {"name": "Soup hành tây", "model": "bowl", "liquid": "c9973f",
		"topping": {"model": "food_ingredient_onion_rings", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},
	"soup_potato": {"name": "Soup khoai tây", "model": "bowl", "liquid": "efe0b0",
		"topping": {"model": "food_ingredient_potato_chopped", "scale": 0.45, "y": 0.25},
		"layout": {"height": 0.37}, "price": 120, "seconds": 27.0},

	# Món bị bỏ trong B. Ham bỏ hẳn (user chốt 16/11/2026): ham thái ra trông
	# y hệt steak thái, mà bộ KayKit không có model ham thái riêng.
	"vegetablesteak": null,
	"vegetablebuger": null, "stew": null, "noi_canh": null,
	"vegetablebuger_uncook": null,
	"vegetablebuger_cooked": null, "vegetablebuger_cooked_fail": null,
}

const PLAN_B_TABLE := {
	"bowl+steak_cooked": "mon_steak",
	"bowl+bun+steak_cooked": "burger_plain",
	"bowl+bun+cheese_chopped+steak_cooked": "burger_cheese",
	"bowl+bun+lettuce_chopped+steak_cooked": "burger_lettuce",
	# Nối tiếp: burger thường là tập con của hai burger kia — bàn tự ráp
	# burger thường trước thì vẫn thêm phô mai / xà lách vào được.
	"burger_plain+cheese_chopped": "burger_cheese",
	"burger_plain+lettuce_chopped": "burger_lettuce",
	"bowl+bun+cheese_chopped+lettuce_chopped+steak_cooked": "hambuger",
	"burger_cheese+lettuce_chopped": "hambuger",
	"burger_lettuce+cheese_chopped": "hambuger",
	"bowl+ham_cooked": "mon_ham",
	"bowl+carrot_chopped+ham_cooked": "dinner",
	# Nối tiếp: Đùi nướng là tập con của Đùi nướng cà rốt.
	"carrot_chopped+mon_ham": "dinner",
	"carrot_chopped+carrot_chopped+carrot_chopped+noi": "soup_carrot_raw",
	"noi+onion_chopped+onion_chopped+onion_chopped": "soup_onion_raw",
	"noi+potato_chopped+potato_chopped+potato_chopped": "soup_potato_raw",
	"dough_pre+mushroom_chopped+tomato_chopped": "pizza_mushroom_uncooked",
	"cheese_chopped+dough_pre+tomato_chopped": "pizza_cheese_uncooked",
	"dough_pre+peperoni_pre+tomato_chopped": "pizza_peperoni_uncooked",
	"bowl+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop",
	"bowl+cookiestick+icecream_chocolate+icecream_strawberry+icecream_vani": "kem_tam_hop_que",
	"cookiestick+kem_tam_hop": "kem_tam_hop_que",
}


static func items() -> Dictionary:
	if not plan_b:
		return ITEMS
	if _items_b.is_empty():
		_items_b = ITEMS.duplicate()
		for id in PLAN_B_ITEMS:
			if PLAN_B_ITEMS[id] == null:
				_items_b.erase(id)
			else:
				_items_b[id] = PLAN_B_ITEMS[id]
	return _items_b


static func table_recipes() -> Dictionary:
	return PLAN_B_TABLE if plan_b else TABLE_RECIPES


## B: lò KHÔNG còn công thức topping — chỉ nướng pizza sống ghép từ bàn.
static func oven_recipes() -> Dictionary:
	return {} if plan_b else OVEN_RECIPES


static func oven_toppings() -> Array:
	return [] if plan_b else OVEN_TOPPINGS


## Bỏ đế bánh trần vào lò để bật lò được không. B: không — một đường duy nhất.
static func oven_takes_base() -> bool:
	return not plan_b


## Id này có phải MỘT MÓN hoàn chỉnh không (thứ nhấc được khỏi bàn chế tạo).
##
## Suy ra từ chính bảng công thức thay vì gắn cờ vào từng mục: món hoàn chỉnh
## theo định nghĩa là thứ nằm ở vế PHẢI của một công thức. Thêm công thức mới
## là tự động có thêm một món, không phải nhớ đánh dấu ở chỗ thứ hai.
## Giá bán của một món. 0 = chưa định giá.
static func price(id: String) -> int:
	return int(items().get(id, {}).get("price", 0))


## ═════════════════════════════════════════════ GIÁ VỐN NGUYÊN LIỆU
##
## Tiền TRỪ NGAY lúc người chơi lấy một nguyên liệu ở kệ, tủ lạnh hay máy kem.
## 0 = miễn phí.
##
## ── VÌ SAO CÓ CƠ CHẾ NÀY
##
## Trước đây nguyên liệu vô hạn và miễn phí, nên chiến thuật tối ưu là lấy bừa:
## cầm sai thì vứt đi lấy lại, không mất gì ngoài vài giây. Có giá vốn thì mỗi
## lần bấm E ở cái kệ là một quyết định, và món đắt tự nhiên đáng làm hơn món
## rẻ vì phần lãi chênh nhau thật.
##
## ── CÁCH ĐẶT SỐ: 10–20% GIÁ BÁN
##
## Tổng giá vốn của một món phải nằm trong 10–20% giá bán nó. Dưới 10% thì chi
## phí không cảm nhận được, trên 20% thì một lần giao muộn (mất thưởng hoàn
## hảo) là lỗ, và người chơi học được điều sai: "đừng làm món khó".
##
## 16 con số dưới đây KHÔNG chọn tay — chúng là nghiệm của một bài toán 13 ràng
## buộc khoảng (một ràng buộc cho mỗi món bán được), giải bằng máy. Sửa MỘT số
## là có thể đẩy ba bốn món ra ngoài dải, vì nguyên liệu dùng chung nhiều món.
## Tỉ lệ thực tế của từng món:
##
##   pizza_mushroom  10,0%   mon_steak       11,2%   kem_tam_hop_que 12,7%
##   icecream_*      13,3%   mon_ham         15,0%   kem_tam_hop     15,0%
##   pizza_peperoni  15,0%   dinner          15,3%   pizza_cheese    16,2%
##   vegetablesteak  18,1%   hambuger        20,0%   vegetablebuger  20,0%
##   stew            10,4%
##
## ── ĐỘNG VẬT ĐẮT HƠN THỰC VẬT
##
##   thịt (ham, steak, xúc xích)  9    ← đắt nhất
##   sữa  (phô mai)               7
##   bột và rau củ (bột, nấm,     4
##         cà rốt, khoai, hành)
##   lá và quả (xà lách, cà chua) 2
##   bánh (bánh mì, bánh quế)     1    ← rẻ nhất
##
## MỘT NGOẠI LỆ: kem = 2, rẻ hơn cà rốt, dù kem là sản phẩm từ sữa. Không phải
## quên — bị ÉP. Kem vừa là nguyên liệu vừa là MÓN BÁN giá 15, và kem tam hợp
## giá 40 cần ba viên. Muốn kem tam hợp không vượt 20% thì 3 × giá kem ≤ 8, tức
## giá kem ≤ 2,67. Đặt kem đắt hơn là món kem tam hợp lỗ nặng.
##
## ── BÁNH MÌ CHỈ 1 ĐỒNG
##
## Cũng bị ép: vegetablebuger giá 110 cần SÁU nguyên liệu, mà steak một mình đã
## 9. Trần 20% của nó là 22, nên năm thứ còn lại chỉ được tổng 13.
##
## ── ĐỒ ĐỰNG MIỄN PHÍ
##
## Đĩa và nồi KHÔNG khai khoá này. Chúng là đồ đựng dùng lại, không bỏ vào món.
## Quan trọng hơn: 8 trong 13 món đều cần đĩa, nên giá đĩa thành thuế đồng
## loạt — nó bóp dải 10–20% của mấy món rẻ (kem tam hợp chỉ 40 đồng) mà không
## thêm quyết định nào cho người chơi.
static func cost(id: String) -> int:
	return int(items().get(id, {}).get("cost", 0))


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
const PATIENCE_FACTOR := 3.75
const PATIENCE_MIN := 52.5

## 2/10/2026: món từ BA NGUYÊN LIỆU trở lên được thêm 50% kiên nhẫn.
##
## Lý do (user chơi thử): ngay cả Kitasan với kĩ năng +30% kiên nhẫn vẫn không
## kịp các món dài. Công thức gốc chỉ nhân theo THỜI GIAN LÀM của một lượt
## trơn tru, mà món nhiều nguyên liệu thì hiếm khi trơn tru: mỗi nguyên liệu
## thêm là một chuyến đi có thể bị kẹt (bếp đang bận, thớt đang bận, cầm nhầm).
## Rủi ro đó tăng theo SỐ nguyên liệu chứ không theo số giây, nên phần bù cũng
## gắn vào số nguyên liệu.
##
## Vì sao ngưỡng là 3 chứ không tăng đều cho mọi món: kem lẻ, Ham và Steak
## (một nguyên liệu) hiện đã kịp — tăng cả chúng thì chỉ làm màn chơi dễ đi
## đồng loạt mà không chữa đúng chỗ đang đau.
##
## Hệ số này nhân SAU cái sàn: món nhiều nguyên liệu mà làm nhanh (Kem tam
## hợp, 8,9 giây) đang ăn sàn 52,5 — nhân trước rồi mới lấy sàn thì nó vẫn
## 52,5 và coi như không được tăng gì.
const MANY_INGREDIENTS := 3
const MANY_INGREDIENTS_BONUS := 1.5

static func patience(id: String) -> float:
	var t := float(items().get(id, {}).get("seconds", 0.0))
	var base := PATIENCE_MIN
	if t > 0.0:
		base = maxf(PATIENCE_MIN, PATIENCE_FACTOR * t)
	if ingredient_count(id) >= MANY_INGREDIENTS:
		base *= MANY_INGREDIENTS_BONUS
	return base


## Đồ ĐỰNG: có mặt trong công thức nhưng không phải nguyên liệu (dùng lại
## được, không mất tiền). Không tính vào số nguyên liệu của món.
const CONTAINER_ITEMS := ["bowl", "noi"]

## Số nguyên liệu THÔ người chơi phải đi lấy để làm ra món này.
##
## TÍNH từ bảng công thức chứ không gõ thêm một cột "số nguyên liệu" vào từng
## món — cùng lý do với patience(): hai nguồn số liệu rời nhau thì đổi công
## thức mà quên sửa cột kia, và không có lỗi nào báo.
##
## Cách đếm: bung món ra theo công thức; mỗi thành phần lại bung tiếp cho tới
## khi gặp thứ không do công thức nào sinh ra — đó là một nguyên liệu thô.
## Một thành phần đã qua sơ chế / nấu (steak_cooked, dough_pre, stew...) thì
## lần ngược về thứ sinh ra nó qua khoá "prep" / "cook" / "bake".
##
## Ví dụ: hambuger = bowl + bun + cheese + lettuce + steak_cooked
##        -> bowl bỏ (đồ đựng); steak_cooked <- steak_uncook <- steak
##        -> 4 nguyên liệu.
static func ingredient_count(id: String) -> int:
	return _count_raw(id, 0)


static func _count_raw(id: String, depth: int) -> int:
	if CONTAINER_ITEMS.has(id):
		return 0
	# Chặn đệ quy vô hạn nếu sau này ai khai hai công thức vòng nhau.
	if depth > 8:
		return 1
	# 1. Là kết quả của một công thức ghép -> cộng các thành phần. Bảng nào
	#    khai trước thắng; với món có hai công thức (Kem tam hợp bánh quế) thì
	#    công thức đầy đủ đứng trước dòng nối tiếp nên được chọn.
	for table in [table_recipes(), oven_recipes()]:
		for key in table:
			if String(table[key]) != id:
				continue
			var total := 0
			for part in String(key).split("+"):
				total += _count_raw(part, depth + 1)
			return total
	# 2. Là kết quả sơ chế / nấu / nướng của một thứ khác -> lần ngược về nó.
	for source in items():
		var info: Dictionary = items()[source]
		for step in ["prep", "cook", "bake"]:
			if String(info.get(step, "")) == id:
				return _count_raw(String(source), depth + 1)
	# 3. Không ai sinh ra nó -> chính nó là một nguyên liệu thô.
	return 1


## ═════════════════════════════════════════════ ĐỘ KHÓ CỦA MÓN
##
## Ba mức: "easy" / "medium" / "hard". Hệ đơn hàng dùng để quyết định ĐẦU MÀN
## khách gọi gì: mức khó chỉ bắt đầu xuất hiện khi người chơi đã vào nhịp (xem
## "tier_weights" trong các RULES_* của GameData và customer_manager._pick_dish).
##
## Chia theo SỐ BƯỚC phải làm, không theo giá:
##   easy   — lấy ra là giao, hoặc nấu một thứ rồi bày đĩa (một trạm).
##   medium — phải gom nhiều nguyên liệu về một chỗ (bàn chế tạo hoặc lò),
##            nhưng mỗi nguyên liệu chỉ qua tối đa một bước xử lý.
##   hard   — có CHUỖI lồng nhau: ghép ra một thứ trung gian, đem nấu, rồi mới
##            ghép tiếp (chả rau củ, nồi canh). Sai một bước là làm lại từ đầu.
##
## Gõ tay thành bảng chứ không suy từ số nguyên liệu: Pizza phô mai (4 nguyên
## liệu) và Steak rau củ (4 nguyên liệu) cùng con số nhưng khác hẳn độ rối —
## pizza chỉ là "bỏ hết vào lò", còn chả rau củ là thái → ghép → nướng → bày.
## Món không có trong bảng coi là "medium".
##
## (2/10/2026) GIÁ ba món khó đã cộng thêm 100 mỗi món (Hamburger rau củ 110 ->
## 210, Canh rau củ 135 -> 235, Bữa tối 150 -> 250), theo yêu cầu user. Lý do:
## cùng ngày, tỉ lệ món khó bị cắt hơn một nửa và thêm quãng nghỉ sau mỗi món
## khó, nên phần doanh thu chúng đóng góp tụt mạnh trong khi mốc hạng giữ
## nguyên. Món khó giờ HIẾM, nên mỗi lần gặp phải ĐÁNG — không thì người chơi
## thấy nó chỉ là rủi ro (dễ cháy, dễ mất khách) mà chẳng được gì hơn pizza.
const DIFFICULTY_ORDER := ["easy", "medium", "hard"]
const DISH_DIFFICULTY := {
	"icecream_vani": "easy", "icecream_chocolate": "easy", "icecream_strawberry": "easy",
	"mon_ham": "easy", "mon_steak": "easy",
	"kem_tam_hop": "medium", "kem_tam_hop_que": "medium", "hambuger": "hard",
	"pizza_mushroom": "medium", "pizza_peperoni": "medium", "pizza_cheese": "medium",
	# (2/10/2026) Steak rau củ xuống mức vừa theo yêu cầu user: nó là NỀN của
	# Hamburger rau củ, nên phải gặp trước ở mức dễ hơn rồi mới tới món dựng
	# trên nó.
	"vegetablesteak": "medium",
	"vegetablebuger": "hard", "stew": "hard",
	# (16/11/2026) Món bộ B. Đùi nướng cà rốt xuống "medium": giờ chỉ là đùi
	# nướng + cà rốt thái. Hamburger đầy đủ lên "hard" (5 thành phần). Soup
	# "hard" như canh cũ: 3 lần thái + ráp nồi + nấu.
	"dinner": "medium",
	"burger_plain": "easy", "burger_cheese": "medium", "burger_lettuce": "medium",
	"soup_carrot": "hard", "soup_onion": "hard", "soup_potato": "hard",
}

static func difficulty(id: String) -> String:
	return String(DISH_DIFFICULTY.get(id, "medium"))


## Những thứ phải GOM LẠI để làm ra món này, để vẽ công thức cho người chơi.
##
## Khác ingredient_count() ở chỗ GIỮ nguyên trạng thái đã xử lý: hamburger trả
## về "steak_cooked" chứ không lần ngược về "steak", vì ảnh miếng thịt chín
## chính là lời nhắc "phải nấu". Chỉ bung tiếp những thứ TRUNG GIAN do một
## công thức khác ghép ra (chả rau củ, nồi canh) — người chơi không lấy được
## chúng ở kệ nào cả, nên để nguyên thì công thức vô dụng.
##
## Món không có công thức (kem lẻ: lấy thẳng từ máy) trả về mảng rỗng.
##
## NGOẠI LỆ: thứ trung gian mà bản thân nó ĐÃ LÀ MỘT MÓN trong thực đơn thì
## giữ nguyên, không bung. Hamburger rau củ hiện "miếng steak rau củ" chứ không
## hiện lại cà rốt, hành, cà chua, steak — công thức của miếng chả đã nằm ở
## dòng Steak rau củ ngay phía trên, lặp lại chỉ làm dòng dài ra và che mất ý
## chính: "món này = món kia + bánh + xà lách". Bữa tối hiện "canh" cũng vì thế.
static func recipe_parts(id: String) -> Array[String]:
	var out: Array[String] = []
	_expand_parts(id, out, 0, id)
	return display_order(out)


## Thứ tự VẼ nguyên liệu trong một dòng công thức, từ trái sang phải.
##
## Khoá công thức sắp theo bảng chữ cái (để thứ tự bỏ vào không quan trọng),
## nên vẽ thẳng theo khoá thì cái nồi rơi vào giữa hàng và đế pizza đứng sau
## phô mai. Bảng này thay thứ tự chữ cái bằng thứ tự NGƯỜI CHƠI CẦN ĐỌC:
##
##   1. ĐỒ ĐỰNG (đĩa, nồi)   — quyết định bước đầu tiên là đi lấy cái gì.
##   2. PHẦN NỀN (đế bánh, bánh mì) — thứ cho biết món thuộc họ nào.
##   3. NGUYÊN LIỆU DÙNG CHUNG — cà chua, xà lách... thứ nhiều món cùng có.
##   4. THỨ RIÊNG của từng món — nấm, peperoni, miếng thịt.
##
## Vì MỌI dòng dùng chung một bảng, hai món cùng họ tự có phần đầu giống hệt
## nhau: ba pizza đều mở bằng "đế + cà chua", hai hamburger đều mở bằng "đĩa +
## bánh + xà lách". Các ô lại rộng bằng nhau nên phần giống nhau thẳng cột, và
## chỗ hai món KHÁC nhau là ô đầu tiên lệch — mắt bắt được ngay.
##
## Một bảng cố định thay vì tự đếm "nguyên liệu nào nhiều món dùng nhất": tự
## đếm thì thứ tự đổi theo thực đơn từng ngày, cùng một món mà ngày 1 và ngày
## 3 vẽ khác nhau — người chơi phải học lại. Thứ không có trong bảng thì đứng
## cuối, giữ thứ tự cũ.
const DISPLAY_ORDER := [
	"bowl", "noi",
	"dough_pre", "bun",
	"stew",
	"tomato", "lettuce", "cheese", "onion", "carrot", "potato",
	"mushroom", "peperoni_pre",
	"steak_cooked", "steak_uncook", "ham_cooked", "vegetablebuger_cooked",
	"icecream_vani", "icecream_chocolate", "icecream_strawberry", "cookiestick",
]


## Xếp lại một công thức theo DISPLAY_ORDER. Chỉ đổi thứ tự VẼ — khoá công
## thức và luật ghép không đụng tới.
static func display_order(parts: Array) -> Array[String]:
	var ranked: Array = []
	for i in parts.size():
		var id := String(parts[i])
		var rank := DISPLAY_ORDER.find(id)
		if rank < 0:
			rank = DISPLAY_ORDER.size()
		# Vị trí gốc `i` làm khoá phụ: sort_custom của Godot KHÔNG ổn định, nên
		# hai thứ cùng hạng phải tự mang theo thứ tự cũ.
		ranked.append([rank, i, id])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	var out: Array[String] = []
	for r in ranked:
		out.append(String(r[2]))
	return out


## Thứ này có phải là (lõi của) một món BÁN ĐƯỢC khác với `root` không: hoặc
## chính nó có giá (canh), hoặc bày nó ra đĩa là thành một món có giá (miếng
## chả rau củ -> Steak rau củ).
static func _is_other_dish(id: String, root: String) -> bool:
	if id == root:
		return false
	if price(id) > 0:
		return true
	var plated := String(table_recipes().get("bowl+" + id, ""))
	return not plated.is_empty() and plated != root and price(plated) > 0


static func _expand_parts(id: String, out: Array[String], depth: int, root: String) -> void:
	var is_root := id == root and depth == 0
	if depth > 8:
		out.append(id)
		return
	if not is_root and _is_other_dish(id, root):
		out.append(id)
		return
	var key := _recipe_key_for(id)
	if not key.is_empty():
		for part in key.split("+"):
			_expand_parts(part, out, depth + 1, root)
		return
	# Thứ này là kết quả NẤU của một thứ do công thức ghép ra (stew <- noi_canh,
	# vegetablebuger_cooked <- vegetablebuger_uncook) -> bung thứ đó.
	var source := _source_of(id)
	if not source.is_empty() and not _recipe_key_for(source).is_empty():
		_expand_parts(source, out, depth + 1, root)
		return
	if not is_root:
		out.append(id)


## Khoá công thức ("a+b+c") sinh ra id này, hoặc rỗng. Bảng bàn chế tạo xét
## trước lò; trong một bảng thì dòng khai trước thắng.
static func _recipe_key_for(id: String) -> String:
	for table in [table_recipes(), oven_recipes()]:
		for key in table:
			if String(table[key]) == id:
				return String(key)
	return ""


## Thứ mà sơ chế / nấu / nướng lên thì ra id này, hoặc rỗng.
static func _source_of(id: String) -> String:
	for source in items():
		var info: Dictionary = items()[source]
		for step in ["prep", "cook", "bake"]:
			if String(info.get(step, "")) == id:
				return String(source)
	return ""


## Mọi món BÁN ĐƯỢC, tức có giá. Hệ đơn hàng bốc món từ đây.
static func sellable_dishes() -> Array[String]:
	var out: Array[String] = []
	for id in items():
		if is_locked(String(id)):
			continue
		if int(items()[id].get("price", 0)) > 0:
			out.append(String(id))
	return out


static func is_dish(id: String) -> bool:
	# HOẶC có giá. Chỉ hỏi TABLE_RECIPES là thiếu, vì có những món hoàn chỉnh
	# KHÔNG ra đời ở bàn chế tạo: ba loại kem lẻ lấy thẳng từ máy, và từ
	# 14/9/2026 thêm món canh — nấu xong trên bếp là xong luôn.
	#
	# Hàm này chỉ quyết định BÀY MODEL GÌ trên mặt bàn chế tạo, nên hậu quả
	# của việc thiếu là một lỗi im lặng và nhỏ: đặt bát canh lên bàn để ghép
	# Bữa tối thì mặt bàn hiện trống trơn, người chơi tưởng mình đặt hụt.
	return table_recipes().values().has(id) or price(id) > 0


static func combine_on_table(ingredients: Array) -> String:
	var list_ := ingredients.duplicate()
	list_.sort()
	var dish := String(table_recipes().get("+".join(list_), ""))
	# Chặn ở KẾT QUẢ chứ không xoá dòng công thức: bảng công thức là tài liệu
	# thiết kế, xoá đi thì lúc mở khoá phải nhớ gõ lại từng dòng.
	if is_locked(dish):
		return ""
	return dish


static func can_go_in_oven(id: String) -> bool:
	return oven_toppings().has(id)


static func bake_in_oven(ingredients: Array) -> String:
	# Lò đang chứa đúng MỘT chiếc pizza sống ghép sẵn: nướng nó thành bản chín.
	if ingredients.size() == 1:
		var ready_ := bake_step(String(ingredients[0]))
		if not ready_.is_empty():
			return ready_
	var list_ := ingredients.duplicate()
	list_.sort()
	return String(oven_recipes().get("+".join(list_), ""))


## Kết quả khi đưa NGUYÊN MỘT vật vào lò nướng. Rỗng = không nướng thẳng được
## (đế bánh trần thì rỗng: nó bật lò theo đường cũ, chờ topping).
static func bake_step(id: String) -> String:
	return String(items().get(id, {}).get("bake", ""))


## Dựng node model 3D của một vật phẩm, hoặc null nếu không có model.
##
## Để ở danh mục chứ không ở trạm: cả đôi tay, cái thớt và cái bàn đều cần
## dựng model từ một id, mà cả ba đều không có lý do gì để biết file .gltf
## nằm ở đâu.
## Tên file gltf của cái bát dùng chung cho mọi món bày bát.
const BOWL_MODEL := "bowl"
## Độ cao mặc định đặt thức ăn trong lòng bát. Bát cao 0,30; lòng bát bắt đầu
## khoảng 0,12 — đo từ chính model `stew_bowl` (phần ruột của bát, y 0,12→0,37).
const BOWL_INNER_HEIGHT := 0.12

## `co_do` = vật này đang chứa thứ gì bên trong. Chỉ mục nào khai `model_day`
## mới quan tâm tới cờ này; số còn lại bỏ qua.
static func make_model(id: String, has_content: bool = false) -> Node3D:
	var entry: Dictionary = items().get(id, {})
	if entry.has("on_plate"):
		return _make_bowl_combo(entry["on_plate"])
	# (16/11/2026) Món dựng bằng CHỒNG NGUYÊN LIỆU — dùng đúng hàm bày chồng
	# của bàn chế tạo. Bộ KayKit chỉ có MỘT model burger (đủ cả phô mai lẫn
	# xà lách), nên ba burger của bộ B tự dựng từ chính các lớp của mình:
	# burger phô mai trên tay trông đúng là có phô mai, không xà lách.
	if entry.has("stack"):
		var parts: Array[String] = []
		for p in entry["stack"]:
			parts.append(String(p))
		var st := make_stack(parts)
		if st != null and entry.has("scale"):
			st.scale = Vector3.ONE * float(entry["scale"])
		return st

	var model_name := String(entry.get("model", ""))
	if has_content and entry.has("model_inner"):
		model_name = String(entry["model_inner"])
	var m := _load_model(model_name)
	if m != null:
		var scale_: float = float(entry.get("scale", 1.0))
		if not is_equal_approx(scale_, 1.0):
			m.scale = Vector3.ONE * scale_
		if bool(entry.get("raw_look", false)):
			_apply_raw_look(m)
		if bool(entry.get("burnt_look", false)):
			_apply_burnt_look(m)
		# "topping": model phụ đặt lên trên model chính. Dùng cho ba soup của
		# bộ B: KayKit chỉ có một bát canh, cả model dùng chung một ảnh màu nên
		# không đổi màu riêng phần nước được — rắc lên mặt bát đúng loại rau
		# (cà rốt miếng / hành khoanh / khoai nghiền) để nhìn là phân biệt.
		# "liquid": mặt nước màu phẳng trong lòng bát (bát KayKit rỗng, miệng
		# bán kính 0,475, cao 0,30). Màu tự đặt được nên ba soup khác hẳn nhau:
		# cam (cà rốt), nâu vàng (hành), kem (khoai) — khớp ảnh 2D của món.
		if entry.has("liquid"):
			var disc := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.40
			cyl.bottom_radius = 0.36
			cyl.height = 0.04
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(String(entry["liquid"]))
			mat.roughness = 0.35
			cyl.material = mat
			disc.mesh = cyl
			disc.position.y = 0.23
			m.add_child(disc)
		# "combo": đặt thêm các MÓN KHÁC (dựng bằng chính make_model) lên model
		# gốc, mỗi món một vị trí. Dùng cho Bữa tối: đĩa + ham + bát soup.
		for piece in entry.get("combo", []):
			var pm := make_model(String(piece["id"]))
			if pm != null:
				pm.scale *= float(piece.get("scale", 1.0))
				pm.position = Vector3(float(piece.get("x", 0.0)),
					float(piece.get("y", 0.0)), float(piece.get("z", 0.0)))
				m.add_child(pm)
		if entry.has("topping"):
			var tp: Dictionary = entry["topping"]
			var t := _load_model(String(tp["model"]))
			if t != null:
				t.scale = Vector3.ONE * float(tp.get("scale", 1.0))
				t.position.y = float(tp.get("y", 0.0))
				m.add_child(t)
	return m


## Màu phủ lên đồ SỐNG (hiện chỉ pizza chưa nướng). Trắng, nửa trong suốt.
const RAW_TINT := Color(1.0, 1.0, 1.0, 0.45)

## Vật liệu phủ, tạo MỘT lần rồi dùng chung cho mọi chiếc pizza sống.
static var _raw_material: StandardMaterial3D = null


## Làm NHẠT một model bằng material_overlay: một lớp trắng mờ vẽ đè lên trên.
##
## Vì sao overlay chứ không đổi màu vật liệu gốc: toàn bộ bộ KayKit dùng CHUNG
## MỘT vật liệu tên "restaurant" (một tấm ảnh bảng màu). Sửa vật liệu đó là
## đổi màu mọi đồ vật trong nhà hàng cùng lúc. Overlay gắn vào TỪNG
## MeshInstance3D của riêng model này, vật liệu gốc không bị chạm tới.
##
## Vì sao UNSHADED: lớp phủ phải trông nhạt như nhau dù đứng dưới đèn hay
## trong bóng. Có đổ bóng thì pizza trong góc tối nhìn chẳng khác pizza chín.
static func _apply_raw_look(root: Node) -> void:
	if _raw_material == null:
		_raw_material = StandardMaterial3D.new()
		_raw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_raw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_raw_material.albedo_color = RAW_TINT
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = _raw_material


## Phủ đen đồ CHÁY (pizza bộ B). Cùng kiểu với _apply_raw_look: overlay lên
## model gốc thay vì cần model riêng.
static var _burnt_material: StandardMaterial3D = null

static func _apply_burnt_look(root: Node) -> void:
	if _burnt_material == null:
		_burnt_material = StandardMaterial3D.new()
		_burnt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_burnt_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_burnt_material.albedo_color = Color(0.06, 0.04, 0.03, 0.82)
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = _burnt_material


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
const STACK_STEP := 0.08

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
const STACK_SCALE := 0.6

## Món không khai "thu_tu" thì nằm ở nấc này. Chọn 50 để còn chỗ cho cả thứ
## phải nằm dưới nó (10–40) lẫn thứ phải nằm trên (60–90).
const DEFAULT_ORDER := 50

## Vật đế mặc định cao bao nhiêu, khi nó không tự khai "day".
const DEFAULT_THICKNESS := 0.12

## Mỗi tầng xoay thêm bấy nhiêu độ quanh trục đứng.
##
## Xoay chứ không để thẳng hàng: chồng hai củ khoai giống hệt nhau lên nhau mà
## cùng góc quay thì nhìn ra MỘT củ méo, không ra hai. Dùng một góc CỐ ĐỊNH
## chứ không randf(): mặt bàn phải bày y hệt nhau mỗi lần dựng lại, nếu không
## thì mỗi lần nhấc một món ra, cả chồng còn lại nhảy sang tư thế khác.
const ROTATION_PER_LAYER := 37.0

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
const BASE_ITEMS := ["bowl", "noi", "noi_canh", "dough_pre"]


## Số liệu bày biện của một vật phẩm. Luôn trả Dictionary, rỗng là hợp lệ.
static func layout(id: String) -> Dictionary:
	return items().get(id, {}).get("layout", {})


## Dựng MỘT node gồm cả chồng đồ đang nằm trên bàn chế tạo.
##
## Trả về đúng một Node3D như tao_mo_hinh(), nên nơi gọi (Workstation) không
## phải biết trên bàn có mấy món — nó vẫn giữ đúng một tham chiếu để xoá.
##
## Một món thì đi thẳng tao_mo_hinh(): món đã ráp xong nằm một mình trên bàn
## phải trông y hệt lúc cầm trên tay, không bị nhấc lên một nấc vô cớ.
static func make_stack(list_: Array[String]) -> Node3D:
	if list_.is_empty():
		return null
	if list_.size() == 1:
		return make_model(String(list_[0]))

	var parts: Array[String] = list_.duplicate()
	var origin: Node3D = null
	var height := 0.0
	var base_id := ""

	for base in BASE_ITEMS:
		var pos := parts.find(String(base))
		if pos < 0:
			continue
		origin = make_model(String(base))
		if origin == null:
			continue
		parts.remove_at(pos)
		base_id = String(base)
		height = float(layout(base_id).get("thickness", DEFAULT_THICKNESS))
		break

	# Không có vật đế nào: chồng thẳng trên mặt bàn. Dùng một Node3D rỗng làm
	# gốc chứ không lấy món đầu tiên làm gốc — như vậy mọi món con đều tính
	# độ cao theo cùng một mốc, và món đầu không bị nhân hai lần tỉ lệ khi
	# chính nó có "ti_le".
	if origin == null:
		origin = Node3D.new()

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
	var ordered: Array = []
	for i in parts.size():
		ordered.append({
			"id": String(parts[i]),
			"tt": int(layout(String(parts[i])).get("order", DEFAULT_ORDER)),
			"i": i,
		})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tt"]) != int(b["tt"]):
			return int(a["tt"]) < int(b["tt"])
		return int(a["i"]) < int(b["i"]))

	# ---- CÁCH BÀY THỨ HAI: VÒNG QUANH thay vì chồng lên nhau ----
	#
	# Chồng tầng chỉ đúng với món THẬT SỰ là một chồng (hamburger). Pizza là
	# topping rải trên MẶT đế, kem tam hợp là ba viên nằm CẠNH nhau trong
	# bát — chồng chúng thành cột thì mặt bàn tả sai chính món người chơi
	# đang làm.
	#
	# Vật ĐẾ quyết định cách bày, không phải từng nguyên liệu: cùng một quả cà
	# chua nằm trên đế bánh thì rải quanh, nằm trong nồi canh thì chồng. Nên
	# khoá "arrange" khai ở ĐẾ (dough_pre), không khai ở cà chua.
	var ids: Array[String] = []
	for entry in ordered:
		ids.append(String(entry["id"]))

	var ring: Dictionary = {}
	if not base_id.is_empty():
		ring = layout(base_id).get("arrange", {})

	# Kem: trên đĩa CHỈ có kem / bánh quế thì đổi cái đĩa thành bát kem. Công
	# thức vẫn là "bowl + 3 kem" — chỉ đổi HÌNH, không đổi thứ phải mang tới.
	# Không bắt người chơi lấy thêm một loại bát riêng: như vậy là thêm một
	# vật phẩm, một nguồn lấy và một chỗ để quên, chỉ để đổi cái vỏ.
	if base_id == "bowl" and _all_in(ids, ICECREAM_ITEMS):
		var cup := _load_model(ICECREAM_BOWL_MODEL)
		if cup != null:
			origin.free()
			origin = cup
			ring = ICECREAM_ARRANGE
			height = 0.0

	if not ring.is_empty():
		_arrange_ring(origin, ids, ring, height)
		return origin

	var layer := 0
	# Mảnh phải nằm TRÊN CÙNG (nắp bánh mì), để dành đặt sau cùng.
	var top := ""
	var top_scale := 1.0

	for entry in ordered:
		var id := String(entry["id"])
		var b: Dictionary = layout(id)
		var m := _stack_model(id)
		if m == null:
			continue
		var scale_ := float(b.get("scale", STACK_SCALE))
		if not is_equal_approx(scale_, 1.0):
			m.scale = Vector3.ONE * scale_
		# NHÂN cả "y" với tỉ lệ, không chỉ "cao": "y" đo trên model cỡ gốc
		# (cà rốt có gốc toạ độ ở GIỮA thân nên phải nâng 0,585 mới chạm đáy).
		# Thu nhỏ rồi mà vẫn nâng 0,585 thì củ cà rốt lơ lửng trên không.
		m.position.y = height + float(b.get("y", 0.0)) * scale_
		# KHÔNG xoay những món có "thu_tu" riêng: chúng là những lát phẳng phải
		# nằm khít lên nhau, xoay đi thì cái bánh thành vẹo. Chỉ xoay đám
		# nguyên liệu nguyên củ nằm ở nấc mặc định.
		if not b.has("order"):
			m.rotate_y(deg_to_rad(ROTATION_PER_LAYER * float(layer)))
		origin.add_child(m)
		# Nhân với ti_le: thu nhỏ một món thì nó cũng MỎNG đi đúng bấy nhiêu,
		# nếu không thì chồng đồ có những khoảng hở giữa các tầng.
		height += float(b.get("height", STACK_STEP)) * scale_
		layer += 1
		if top.is_empty() and b.has("model_top"):
			top = String(b["model_top"])
			top_scale = scale_

	if not top.is_empty():
		var lid := _load_model(top)
		if lid != null:
			if not is_equal_approx(top_scale, 1.0):
				lid.scale = Vector3.ONE * top_scale
			lid.position.y = height
			origin.add_child(lid)

	return origin


## Model bát kem rỗng (rộng 0,95, cao 0,30) — thay cái đĩa khi bày kem.
const ICECREAM_BOWL_MODEL := "icecream_bowl"

## Những thứ được phép nằm trong bát kem. Có một thứ khác lẫn vào (người chơi
## bỏ nhầm cà chua) thì giữ nguyên cái đĩa và chồng như thường: bày bát kem
## chứa cà chua là nói dối về thứ đang nằm trên bàn.
const ICECREAM_ITEMS := ["icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"cookiestick"]

## Số bày kem trong bát. Viên kem (model bát-một-viên) rộng 0,45: ba viên ở
## bán kính 0,19, thu 0,8, vừa khít lòng bát 0,95 mà còn chạm nhau như kem
## thật. Bánh quế cắm ĐỨNG ở giữa ba viên, nhô cao hơn — đúng như model
## thành phẩm kem_tam_hop_que.
const ICECREAM_ARRANGE := {
	"radius": 0.19, "scale": 0.8, "y": 0.10,
	"center": ["cookiestick"], "center_y": 0.22, "center_scale": 1.1,
}

## Viên đầu tiên của vòng nằm ở góc này (độ). Không để 0: ở 0 độ viên đầu
## nằm đúng trục X, mà camera nhìn chéo từ trên xuống nên hai viên sau che
## mất nó. Lệch 90 độ đẩy viên đầu ra phía camera.
const RING_START_ANGLE := 90.0


static func _all_in(ids: Array[String], allowed: Array) -> bool:
	for id in ids:
		if not allowed.has(id):
			return false
	return not ids.is_empty()


## Bày các món THÀNH VÒNG quanh tâm đế, cách đều nhau.
##
## Khoá của `arrange`:
##   radius — bán kính vòng, đo trên model đế
##   scale  — thu nhỏ mỗi món nằm trên vòng (THAY cho STACK_SCALE)
##   y      — nâng thêm so với mặt đế
##   center — id những thứ nằm GIỮA chứ không trên vòng (bánh quế)
##   center_y / center_scale — độ cao và cỡ riêng của thứ nằm giữa
##
## Chỉ MỘT món trên vòng thì đặt nó vào tâm: một quả cà chua lệch hẳn về một
## mép đế bánh trông như đặt hụt chứ không như đang bày.
##
## Vẫn dùng _stack_model(): phô mai trên pizza vẫn là MỘT LÁT, và viên kem
## vẫn là viên kem chứ không thành cây ốc quế.
static func _arrange_ring(origin: Node3D, ids: Array[String], arr: Dictionary,
		base_height: float) -> void:
	var center: Array = arr.get("center", [])
	var around: Array[String] = []
	var middle: Array[String] = []
	for id in ids:
		if center.has(id):
			middle.append(id)
		else:
			around.append(id)

	var radius := float(arr.get("radius", 0.4))
	var scale_ := float(arr.get("scale", STACK_SCALE))
	var y0 := base_height + float(arr.get("y", 0.0))
	var n := around.size()

	for k in n:
		var id := around[k]
		var m := _stack_model(id)
		if m == null:
			continue
		var angle := TAU * float(k) / float(n) + deg_to_rad(RING_START_ANGLE)
		var r := radius if n > 1 else 0.0
		m.scale = Vector3.ONE * scale_
		# Xoay theo góc của chính nó trên vòng: mỗi món quay mặt ra ngoài như
		# topping thật, và hai món giống nhau (ba viên kem) không trông như
		# một món bị nhân bản thẳng hàng.
		m.rotation.y = -angle
		# Nhân "y" riêng của món với scale, cùng lý do như trong make_stack.
		m.position = Vector3(cos(angle) * r,
				y0 + float(layout(id).get("y", 0.0)) * scale_,
				sin(angle) * r)
		origin.add_child(m)

	var c_scale := scale_ * float(arr.get("center_scale", 1.0))
	for id in middle:
		var m := _stack_model(id)
		if m == null:
			continue
		m.scale = Vector3.ONE * c_scale
		m.position = Vector3(0.0,
				y0 + float(arr.get("center_y", 0.0)) + float(layout(id).get("y", 0.0)) * c_scale,
				0.0)
		origin.add_child(m)


## Model của một vật phẩm KHI NÓ NẰM TRONG CHỒNG.
##
## Mặc định là model thường. Khai "model" trong khoá "bay" thì dùng cái đó
## thay thế — xà lách nguyên cây (cao 0,82) đổi thành MỘT LÁT (dày 0,088) khi
## kẹp trong bánh mì.
##
## Vì sao không sửa thẳng "model" của mục: cây xà lách vẫn phải là cây xà lách
## lúc cầm trên tay và lúc nằm trong thùng nguyên liệu. Chỉ riêng lúc bị kẹp
## vào bánh nó mới là một lát. Kem lẻ dùng cùng khoá theo chiều ngược lại: ốc
## quế trên tay, bát kem khi nằm trong chồng.
## Tham số đặt tên `ten_m` chứ không `ten`: lớp này đã có hàm ten(id), trùng
## tên thì Godot cảnh báo che khuất — cùng cái bẫy đã ghi ở _nap_model().
static func _stack_model(id: String) -> Node3D:
	var model_name := String(layout(id).get("model", ""))
	if model_name.is_empty():
		return make_model(id)
	return _load_model(model_name)


## Dựng "thức ăn nằm trong bát" = model bát + model thức ăn gắn vào trong.
##
## Cái bát là node GỐC, thức ăn là con. Nhờ vậy mọi chỗ đang gọi tao_mo_hinh()
## — tay cầm, mặt thớt, mặt bàn khách — không cần biết món này gồm mấy mảnh:
## chúng vẫn nhận đúng MỘT Node3D và đặt nó như mọi vật phẩm khác.
##
## Thiếu model thức ăn thì vẫn trả về cái bát rỗng chứ không trả null: mất một
## món ăn trên bàn còn dễ nhận ra và dễ chơi tiếp hơn là mất luôn cả vật phẩm.
static func _make_bowl_combo(piece: Dictionary) -> Node3D:
	var bowl := _load_model(BOWL_MODEL)
	if bowl == null:
		return null
	var hidden_ := _load_model(String(piece.get("model", "")))
	if hidden_ != null:
		hidden_.position.y = float(piece.get("y", BOWL_INNER_HEIGHT))
		var scale_ := float(piece.get("scale", 1.0))
		if not is_equal_approx(scale_, 1.0):
			hidden_.scale = Vector3.ONE * scale_
		bowl.add_child(hidden_)
	return bowl


## Nạp một file gltf theo TÊN MODEL (không phải id vật phẩm).
##
## Tham số đặt tên `ten_model` chứ không phải `ten`: lớp này đã có hàm ten(id),
## trùng tên thì Godot cảnh báo che khuất và trong thân hàm không gọi được hàm
## đó nữa.
static func _load_model(model_name: String) -> Node3D:
	if model_name.is_empty():
		return null
	var path := MODEL_FMT % model_name
	if not ResourceLoader.exists(path):
		push_warning("Thiếu model: %s" % path)
		return null
	var edge := load(path) as PackedScene
	if edge == null:
		return null
	return edge.instantiate() as Node3D


static func has_item(id: String) -> bool:
	return items().has(id)


static func display_name(id: String) -> String:
	# Dịch ngay tại đây: mọi chỗ hiện tên món (HUD, vé, câu báo) đều đi qua hàm này.
	return Lang.t(String(items().get(id, {}).get("name", id)))


## Đường dẫn ảnh 2D. Mặc định tên file TRÙNG id — bớt một cột dữ liệu và bớt
## luôn một chỗ để gõ sai; chỉ những món dùng lại ảnh của nguyên liệu mới
## phải khai báo khoá "anh".
static func icon_path(id: String) -> String:
	return ICON_FMT % String(items().get(id, {}).get("icon", id))


static func model_path(id: String) -> String:
	var m := String(items().get(id, {}).get("model", ""))
	return MODEL_FMT % m if not m.is_empty() else ""


## Kết quả sau khi thái ở thớt. Rỗng nghĩa là thứ này không thái được.
static func prep_step(id: String) -> String:
	return String(items().get(id, {}).get("prep", ""))


## Dấu con dao nhỏ ở góc icon: "món này phải qua thớt trước".
##
## Suy thẳng từ khoá "prep" của ITEMS chứ không lập danh sách tay: thêm một
## nguyên liệu cần thái là dấu tự hiện ở mọi chỗ, không có danh sách nào để quên.
const KNIFE_BADGE := "res://assets/ui/icons/knife_badge.png"


static func needs_chop(id: String) -> bool:
	return not prep_step(id).is_empty()


## Mọi nguyên liệu cần thái, theo thứ tự khai trong ITEMS (cho trang F1).
static func chop_items() -> Array[String]:
	var out: Array[String] = []
	for id in items():
		if needs_chop(String(id)):
			out.append(String(id))
	return out


## Gắn dấu con dao vào góc dưới phải của một ô icon (TextureRect/Panel).
## Ô không cần thái thì không làm gì — nơi gọi khỏi phải tự kiểm tra.
static func add_knife_badge(icon: Control, id: String) -> void:
	if not needs_chop(id) or not ResourceLoader.exists(KNIFE_BADGE):
		return
	var b := TextureRect.new()
	b.texture = load(KNIFE_BADGE)
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Neo theo tỉ lệ góc dưới phải: ô to nhỏ thế nào dấu cũng chiếm ~45%.
	b.anchor_left = 0.55
	b.anchor_top = 0.55
	b.anchor_right = 1.0
	b.anchor_bottom = 1.0
	icon.add_child(b)


## Kết quả sau khi nấu lẻ trên bếp. Rỗng nghĩa là không nấu lẻ được.
static func cook_step(id: String) -> String:
	return String(items().get(id, {}).get("cook", ""))


## Trạng thái cháy nếu để quá lửa. Rỗng nghĩa là món này không cháy được.
static func burnt_state(id: String) -> String:
	return String(items().get(id, {}).get("burnt", ""))


# ------------------------------------------------- công thức trên vé đơn ---
#
# (16/11/2026) Vé đơn hàng in công thức ngay dưới ảnh món, kiểu Overcooked:
# một hàng ảnh nguyên liệu, dưới mỗi ảnh là kí hiệu nơi nấu nó. Không có kí
# hiệu dao vì ở bộ B nguyên liệu nào cũng qua thớt — kí hiệu chung cho mọi thứ
# thì không nói thêm điều gì.

const BADGE_FMT := "res://assets/ui/icons/%s_badge.png"

## Nguyên liệu in trên vé: các phần gốc của món, BỎ đĩa và nồi. Đĩa/nồi là đồ
## đựng, món nào cũng có — in ra chỉ chiếm chỗ (Overcooked cũng không in).
static func ticket_parts(dish: String) -> Array[String]:
	var out: Array[String] = []
	for p in recipe_parts(dish):
		if not CONTAINER_ITEMS.has(p):
			out.append(p)
	return out


## Kí hiệu nơi nấu của một nguyên liệu trong một món: "pan" | "pot" | "oven" | "".
##
## Xét theo thứ tự:
##   1. Bản thân nguyên liệu (hoặc bản đã thái của nó) nấu được trên BẾP → chảo.
##   2. Món ra từ NỒI (thứ nấu ra món có công thức chứa "noi") → nồi.
##   3. Món ra từ LÒ (khoá "bake", hoặc công thức lò) → lò.
## Suy từ chính bảng dữ liệu, không gõ tay theo từng món: thêm món mới là vé
## tự có kí hiệu đúng.
static func cook_badge(dish: String, part: String) -> String:
	# Nguyên liệu trên vé thường là bản ĐÃ NẤU (steak_cooked) vì đó là thứ
	# nằm trong công thức bàn chế tạo — nên hỏi cả chiều ngược: nó có phải
	# thành phẩm của bước "cook" nào không.
	# Nguyên liệu là MỘT MÓN nấu từ nồi (soup cà rốt trong Bữa tối) → nồi,
	# xét trước chảo vì nó cũng là thành phẩm của một bước "cook".
	if _pot_cooked(part):
		return "pot"
	var prepped := prep_step(part)
	var from := _source_of(part)
	if not cook_step(part).is_empty() \
			or (not prepped.is_empty() and not cook_step(prepped).is_empty()) \
			or (not from.is_empty() and cook_step(from) == part):
		return "pan"
	var src := _source_of(dish)
	if not src.is_empty():
		var info: Dictionary = items().get(src, {})
		if String(info.get("bake", "")) == dish:
			return "oven"
		if String(info.get("cook", "")) == dish and _recipe_key_for(src).split("+").has("noi"):
			return "pot"
	if oven_recipes().values().has(dish):
		return "oven"
	return ""


static func _pot_cooked(id: String) -> bool:
	var src := _source_of(id)
	return not src.is_empty() and cook_step(src) == id \
		and _recipe_key_for(src).split("+").has("noi")


static func badge_path(kind: String) -> String:
	return BADGE_FMT % kind
