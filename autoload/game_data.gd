extends Node
## GameData — trí nhớ của game khi đang chạy (Autoload #1).
## Giữ: màn nào đã hoàn thành, doanh thu tốt nhất từng màn, nhân vật đang chọn.
## KHÔNG chứa logic gameplay, chỉ dữ liệu + quy tắc mở khóa.

signal progress_changed

## Phát khi đổi qua lại giữa top-down và góc nhìn thứ 3. Camera màn chơi và
## script nhân vật cùng nghe tín hiệu này, nên không ai phải giữ tham chiếu
## tới ai — thêm thứ khác cần biết góc nhìn (HUD, minimap...) chỉ việc nối vào.
signal view_mode_changed(is_third_person: bool)

## Giai đoạn buổi tối chưa làm. Khi nào làm xong thì đổi thành true,
## toàn bộ các màn "Tối" tự mở khóa theo đúng quy tắc bên dưới.
const EVENING_ENABLED := false

## Map của quán, dùng chung cho cả ba màn Sáng.
##
## Ba ngày khác nhau ở thực đơn, tốc độ khách vào và số bàn được mở — chứ
## không khác nhau ở hình dạng cái quán. Nên chỉ cần MỘT file map; đổi một
## dòng ở đây là đổi cả ba màn, thay vì phải sửa ba file .tscn giống hệt nhau.
const MAP_RESTAURANT := "res://restaurant_map_planb.tscn"

## Scene kể chuyện mở đầu. Không phải map 3D mà là một màn hội thoại 1 chạm:
## bấm chuột để chạy chữ, kể xong thì TỰ chuyển sang Tutorial. Tách thành một
## scene riêng chứ không nhét vào map, vì nó không cần vật lý, không cần nhân
## vật, không cần camera 3D — nạp một Control nhẹ hơn nạp cả cái quán rất
## nhiều, và sửa lời thoại không đụng gì tới map.
##
## Từ 9/9/2026 phần mở đầu bắt đầu bằng MỘT ĐOẠN VIDEO rồi mới tới hội thoại,
## nên hằng này trỏ vào scene video chứ không vào thẳng prologue.tscn nữa.
## Video tự chuyển sang prologue.tscn khi chiếu xong hoặc khi người chơi bấm
## bỏ qua — xem scene_tiep_theo trong intro_prologue.tscn.
##
## Nối chuỗi theo kiểu này chứ KHÔNG nhét VideoStreamPlayer vào prologue.tscn:
## dialogue_player.gd đang là một bộ máy sạch, chỉ biết chạy chữ và đổi nền. Thêm
## video vào đó là thêm một trạng thái "đang chiếu, chưa cho bấm" vào giữa
## vòng đời của nó, và mọi đoạn kể sau này đều phải gánh cái trạng thái đó dù
## không dùng. Còn intro_video.gd thì vốn đã tổng quát sẵn: đường dẫn video và
## scene kế tiếp đều là @export, nên đoạn mở đầu này KHÔNG cần thêm một dòng
## code nào — chỉ là một scene mới dùng lại đúng script cũ.
const SCENE_PROLOGUE := "res://scenes/story/intro_prologue.tscn"

## ĐOẠN RA MẮT của từng nhân vật ẩn: id nhân vật -> file scene.
##
## Không phải màn chơi nên không có mặt trong LEVELS — chúng chen vào giữa lúc
## bấm Chơi và lúc map hiện ra, mỗi đoạn đúng một lần cho mỗi file save.
##
## Vì sao là một BẢNG chứ không phải ba hằng số và ba nhánh if: ba nhân vật ẩn
## dùng chung một luật (đã mở khoá + đang chọn + chưa xem + sắp vào màn chơi
## thật). Viết luật đó ba lần là ba chỗ có thể quên sửa; đọc từ bảng thì thêm
## nhân vật ẩn thứ tư chỉ là thêm một dòng ở đây cộng một file kịch bản.
##
## Ba đoạn ĐỘC LẬP với nhau — không đoạn nào nhắc tới hai đoạn kia, vì người
## chơi mở khoá theo thứ tự bất kỳ và có thể chỉ mở đúng một người.
const INTRO_SCENES := {
	"hachimi": "res://scenes/story/teio_intro.tscn",
	"chiyo": "res://scenes/story/chiyono_intro.tscn",
	"golshi": "res://scenes/story/golshi_intro.tscn",
}

## Giai đoạn BUỔI TỐI đã có chỗ trong dữ liệu nhưng chưa có nội dung.
##
## Để là một cái cờ chứ không xoá hẳn các màn "*_toi" khỏi LEVELS: xoá đi thì
## luật mở khoá (needs) phải viết lại, file save cũ đang ghi tiến trình theo
## id cũ sẽ lệch, và lúc quay lại làm buổi tối phải dựng lại từ đầu. Bật lại
## chỉ là đổi false thành true — bố cục, luật mở khoá và bản dịch đều còn
## nguyên.
const SHOW_EVENING := false

## ─────────────────────────────── LUẬT RIÊNG CỦA TỪNG MÀN ──────────────────
##
## Tám màn dùng CHUNG một file map. Thứ phân biệt chúng nằm ở đây: thực đơn
## nào mở, khách vào nhanh cỡ nào, màn dài bao lâu, và bao nhiêu tiền thì được
## hạng nào. Đọc bởi scripts/nha_hang/luat_man.gd — xem file đó để biết ý
## nghĩa từng khoá.
##
## Đặt trong GameData chứ không trong file map: dữ liệu cân bằng là họ hàng
## với giá món và mốc xếp hạng, không phải với vị trí cái tủ lạnh. Và một
## bảng đọc được cả tám ngày cạnh nhau thì nhìn ra đường cong độ khó ngay,
## thay vì phải mở tám file lên so.

## ══════════════════════════════════════════════════════════════════════════
## NGÀY 1 — ca làm đầu tiên
## ══════════════════════════════════════════════════════════════════════════
##
## THỰC ĐƠN 6 MÓN, và cả sáu đều KHÔNG cần nồi, không cần lò.
##   3 loại kem (15)  — lấy thẳng từ máy kem rồi giao. 1 bước.
##   Ham       (60)   — nấu rồi bày bát. 2 bước.
##   Steak     (80)   — thái → nấu → bày bát. Đúng món đã dạy ở màn hướng dẫn.
##   Hamburger (95)   — 5 nguyên liệu qua bàn chế tạo. Món khó nhất của ngày.
##
## Vì sao đúng sáu món này: người chơi vừa rời màn hướng dẫn, nơi họ làm đúng
## MỘT món. Sáu món trên phủ đủ ba cái thao tác nền của game — lấy sẵn, nấu,
## và ghép ở bàn chế tạo — mà không món nào bắt họ học một trạm mới. Pizza,
## kem tam hợp, chả rau củ, canh và bữa tối để dành cho Ngày 2 và Ngày 3, mỗi
## ngày mở thêm một trạm.
##
## BA CHẶNG, không phải một nhịp đều:
##   0:00–2:00  18 giây/khách  — mở cửa, vắng. Đủ thời gian đọc bảng đơn,
##                               tìm lại cái thớt, và làm hỏng một món mà
##                               không mất gì.
##   2:00–5:00  12 giây/khách  — nhịp bình thường. Bàn bắt đầu kín.
##   5:00–7:00   8 giây/khách  — cao điểm. Hàng đợi dài hơn số bàn, và người
##                               chơi phải chọn bỏ ai.
##
## TRẦN 3 BÀN + 3 Ô HÀNG ĐỢI (chốt sau buổi chơi thử đầu tiên). Trước đó chỉ
## có `toi_da = 6` là trần TỔNG, nên với sáu bàn trống thì cả sáu người được
## xếp chỗ ngay và người chơi phải phục vụ sáu đơn song song từ phút đầu —
## người mới chưa thuộc đường đi trong bếp thì đó là sáu thanh kiên nhẫn cùng
## cạn cùng lúc. Ba đơn trên bàn là số việc một người theo kịp; ba người đứng
## đợi là đủ thấy áp lực mà không thành vô vọng. Cả sáu bàn vẫn dùng được —
## chặn ở SỐ CHỖ NGỒI chứ không tắt bớt bàn, để quán không trông vắng.
##
## NHẠC: còn 3 phút 32 giây thì đổi sang Hashire Umamusume (mốc 212 giây —
## đúng độ dài đo được của file). Chọn theo giây CÒN LẠI chứ không theo giây
## đã trôi, để bài hát kết thúc đúng lúc chuông hết giờ.
## Đổi bài khác thì sửa 212.0 thành số giây của bài đó.
##
## MỐC DOANH THU — TẠM, phải playtest rồi chỉnh:
## Trung bình một đơn ≈ 64 (tính theo trọng số: 45+180+320+285 chia 13). Một
## lượt chơi khá ≈ 16 đơn, chừng 60% đạt hoàn hảo (+35%) → khoảng 1.230. Từ đó
## đặt S 1200 / A 950 / B 700 / C 450. Bốn con số này THẤP hơn hẳn mốc mặc
## định 1650/1300/950/600 vì thực đơn Ngày 1 không có món nào trên 95 tiền.
const RULES_D1 := {
	"duration": 420.0,
	"max_customers": 6,
	"max_tables": 3,
	"max_queue": 2,
	"first_wait": 4.0,
	"menu": [
		"icecream_vani", "icecream_chocolate", "icecream_strawberry",
		"mon_ham", "mon_steak", "hambuger",
	],
	"weights": {
		"icecream_vani": 1, "icecream_chocolate": 1, "icecream_strawberry": 1,
		"mon_ham": 3, "mon_steak": 4, "hambuger": 3,
	},
	"stages": [
		{"until": 120.0, "interval": 18.0},
		{"until": 300.0, "interval": 12.0},
		{"until": 420.0, "interval": 8.0},
	],
	"music_cue": 212.0,
	"rank_thresholds": {"S": 1200, "A": 950, "B": 700, "C": 450},
}

## Toàn bộ màn chơi của game.
##   label   — chữ hiện trên nút
##   needs   — phải hoàn thành màn nào thì màn này mới mở (rỗng = mở sẵn)
##   evening — thuộc giai đoạn buổi tối
##   scene   — file map của màn. RỖNG = chưa dựng map cho màn đó.
const LEVELS := {
	# ke_chuyen — màn này chỉ kể chuyện, không có bếp và không có nhân vật
	# điều khiển được. Cần phân biệt vì mấy đoạn cắt cảnh "nhân vật bước vào
	# quán" không được phép chen vào trước một màn như thế.
	"prologue": {"label": "Prologue", "needs": "", "scene": SCENE_PROLOGUE, "story_only": true},
	"tutorial": {"label": "Tutorial", "needs": "prologue", "scene": MAP_RESTAURANT},
	"d1_sang": {"label": "Sáng", "needs": "tutorial", "scene": MAP_RESTAURANT, "rules": RULES_D1},
	"d1_toi": {"label": "Tối", "needs": "d1_sang", "evening": true, "scene": ""},
	"d2_sang": {"label": "Sáng", "needs": "d1_sang", "scene": MAP_RESTAURANT},
	"d2_toi": {"label": "Tối", "needs": "d2_sang", "evening": true, "scene": ""},
	"d3_sang": {"label": "Sáng", "needs": "d2_sang", "scene": MAP_RESTAURANT},
	"d3_toi": {"label": "Tối", "needs": "d3_sang", "evening": true, "scene": ""},
}

## Các nhân vật. Khóa là id, cũng là tên file ảnh đại diện trong
## assets/ui/characters/ và tên file tiếng trong assets/sfx/select/.
##   desc        — dòng ngắn hiện dưới ảnh khi nhấc lá bài lên
##   tagline     — câu mô tả một dòng, hiện ngay dưới tên trong bảng info
##   intro       — lời tự giới thiệu của nhân vật, hiện trong khung GIỚI THIỆU
##   measure     — bảng SỐ ĐO. Là Dictionary NHÃN -> GIÁ TRỊ chứ không phải các
##                 khóa cố định: bảng info dựng từng hàng bằng vòng lặp, nên
##                 thêm một chỉ số mới (ví dụ "Sải chân") chỉ là thêm một dòng
##                 ở đây, không phải thêm node vào scene. Thứ tự hiện đúng bằng
##                 thứ tự khai báo — GDScript giữ nguyên thứ tự khóa.
##   profile     — bảng HỒ SƠ, cùng quy ước Dictionary NHÃN -> GIÁ TRỊ.
##   secrets     — mảng chuỗi, mỗi phần tử là một dòng trong khung BÍ MẬT
##   hint        — gợi ý dành cho nhân vật chưa mở khóa, điền sau
##   skills      — ĐÚNG 3 ô kỹ năng hiện bên phải bảng thông tin.
##                 Ô 1 là kỹ năng CHỦ ĐỘNG (khung vàng dày), ô 2–3 bị động.
##                 name rỗng thì ô hiện dấu “—”; level 0 thì không hiện chữ Lv.
##                 desc để trống tới khi chốt xong bộ kỹ năng.
##                 icon là TÊN FILE, KHÔNG có đuôi .png, nằm trong
##                 assets/ui/ki_nang/ — để trống thì ô chỉ hiện khung.
##                 Ghi kèm ".png" là sai: hàm nạp tự thêm đuôi, thành
##                 "<tên>.png.png" và không tìm ra file nào.
##                 Ô 1 (kỹ năng chủ động) còn được HUD trong màn chơi dùng
##                 lại — xem duong_dan_anh_ki_nang().
##   sizes       — số đo 3 vòng, bị ô đen che cho tới khi bấm vào
const CHARACTERS := {
	"kitamoi": {
		"label": "Kitasan Black",
		"player": "res://scenes/characters/player_kitamoi.tscn",
		"skills": [
			{"name": "Victory Cheer!", "level": 18, "desc": "Điều kiện: Hoàn thành 5 đơn hoàn hảo.
			Trong thời gian còn lại của màn chơi, mọi đơn giao out đều được tính là hoàn hảo bất kể thanh kiên nhẫn.", "icon": "mac_dinh"},
			{"name": "Kiên nhẫn là một đức tính", "level": 0, "desc": "Thời gian kiên nhẫn của khách hàng +30%.", "icon": "skill2"},
			{"name": "Dòng tiền mờ ám", "level": 0, "desc": "Tiền thưởng từ đơn hoàn hảo +20% (35% → 55%). Đổi lại: món ăn trên bếp hỏng sớm hơn 2 giây.", "icon": "skill3"},
		],
		"desc": "Nụ cười của cô làm sáng cả căn phòng. Một khối nắng mê lễ hội.",
		"tagline": "Nụ cười của cô làm sáng cả căn phòng. Một khối nắng mê lễ hội.",
		"intro": "Tôi là Kitasan Black! Mỗi lần chạy tôi đều cố hết sức tạo không khí lễ hội để ai cũng thấy vui!",
		"measure": {
			"Height": "162 cm",
			"Weight": "Tôi vẫn đang lớn mà!",
			"Shoe size": "Trái & phải: 23,0 cm",
		},
		"profile": {
			"Strong points": "Đấm bóp",
			"Weak points": "Nhắm mắt cho qua",
			"Ears": "Cảm âm cực chuẩn",
			"Tail": "Đuôi cũng khiêng được vật nặng",
			"Family": "Tính cả học trò của bố thì nhà cô có ba mươi người",
		},
		"secrets": [
			"Cô hay phải lòng ngay từ cái nhìn đầu tiên",
			"Đã ăn kẹo là không dừng lại được",
		],
		"hint": "",
		"sizes": ["85", "56", "88"],
	},
	"hachimi": {
		"label": "Tokai Teio",
		"player": "res://scenes/characters/player_hachimi.tscn",
		"skills": [
			{"name": "Sky-High Teio Step", "level": 36, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"desc": "Bất bại và đáng yêu! Một tay đua tưng tưng lúc nào cũng vui.",
		"tagline": "Bất bại và đáng yêu! Một tay đua tưng tưng lúc nào cũng vui.",
		"intro": "Này này! Tokai Teio đây! Nhớ để mắt tới tớ nhé — sắp có một nhà vô địch Tam Miện bất bại mới rồi đấy!",
		"measure": {
			"Height": "150 cm",
			"Weight": "Không đổi",
			"Shoe size": "Trái & phải: 22,0 cm",
		},
		"profile": {
			"Strong points": "Kết bạn",
			"Weak points": "Bác sĩ",
			"Ears": "Không bao giờ bỏ lỡ một lời khen hay giọng của Hội trưởng",
			"Tail": "Ve vẩy phấn khích mỗi khi được chú ý",
			"Family": "Cả nhà đã khóc khi cô thôi gọi 'Mama' và 'Papa'",
		},
		"secrets": [
			"Giữ kỷ lục gập người của trường",
			"Hồi bé chơi ngoài biển suốt, ai cũng gọi cô là 'Bá vương bãi biển'",
		],
		"hint": "",
		"sizes": ["77", "54", "76"],
	},
	"chiyo": {
		"label": "Sakura Chiyono O",
		"player": "res://scenes/characters/player_chiyo.tscn",
		"skills": [
			{"name": "Ambition to Surpass the Sakura", "level": 67, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"desc": "Theo đuổi giấc mơ! Một Umamusume thật thà và chăm chỉ.",
		"tagline": "Theo đuổi giấc mơ! Một Umamusume thật thà và chăm chỉ.",
		"intro": "T-tôi là Sakura Chiyono O! Giấc mơ của tôi là được đứng chung sân khấu với thần tượng. Và tôi sẽ làm giấc mơ ấy nở hoa!",
		"measure": {
			"Height": "156 cm",
			"Weight": "Giảm nhẹ",
			"Shoe size": "Cả hai chân: 22,0 cm",
		},
		"profile": {
			"Strong points": "Làm bánh kẹo Nhật, dọn dẹp",
			"Weak points": "Ô tô, máy bay... (say tàu xe)",
			"Ears": "Rung lên mỗi khi cô nghĩ ra một câu châm ngôn hay",
			"Tail": "Cô dưỡng đuôi bằng đúng loại dầu Maruzensky dùng",
			"Family": "Cả nhà hay quây quần quanh một nồi lẩu lớn",
		},
		"secrets": [
			"Xe hơi màu đỏ luôn hút mắt cô",
			"Ăn wasabi thì được, nhưng mù tạt vàng thì chịu",
		],
		"hint": "",
		"sizes": ["80", "55", "83"],
	},
	"mambo": {
		"label": "Matikanetannhauser",
		"player": "res://scenes/characters/player_mambo.tscn",
		"skills": [
			{"name": "Go, Go, Mun!", "level": 120, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"desc": "Viên ngọc thô ai cũng quý. Hôm nay là ngày của cô ấy!",
		"tagline": "Viên ngọc thô ai cũng quý. Hôm nay là ngày của cô ấy!",
		"intro": "Chào chào, Matikanetannhauser đây. Tôi phải tập thật chăm để không thua... Hả? Hôm nay không có buổi tập à?!",
		"measure": {
			"Height": "155 cm",
			"Weight": "Tăng nhẹ (dạo này hay ăn vặt)",
			"Shoe size": "Trái 24,5 cm / Phải 25,5 cm",
		},
		"profile": {
			"Strong points": "Kéo co, tư vấn chuyện tình cảm",
			"Weak points": "Nhện thật, nước ép cà chua",
			"Ears": "Nghe rõ từng âm thanh riêng lẻ giữa chỗ ồn ào",
			"Tail": "Tự cắt lấy nên lúc nào cũng lệch",
			"Family": "Cô về nhà là quán ăn của gia đình lại treo băng rôn đón",
		},
		"secrets": [
			"Đây đã là chiếc mũ thứ ba của cô",
			"Có khiếu đặt tên rất riêng",
		],
		"hint": "",
		"sizes": ["80", "55", "80"],
	},
	"oui": {
		"label": "Oguri Cap",
		"player": "res://scenes/characters/player_oui.tscn",
		"skills": [
			{"name": "Triumphant Pulse", "level": 11, "desc": "Điều kiện: Màn chơi trôi qua 4 phút
			Bật/tắt bằng phím Space. Khi bật: bộ đếm màn chơi, khách hàng và thanh kiên nhẫn dừng lại; nhân vật và khu bếp vẫn hoạt động. Ngân sách 30 giây cho cả màn, dùng hết là không kích hoạt lại được.", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"desc": "Một cô gái quê điềm tĩnh mà nhiều mơ mộng.",
		"tagline": "Một cô gái quê điềm tĩnh mà nhiều mơ mộng.",
		"intro": "Tôi là Oguri Cap. Tôi sẽ cố hết sức giành chiến thắng cho bà con quê nhà. Cảm ơn mọi người đã ủng hộ.",
		"measure": {
			"Height": "167 cm",
			"Weight": "Tăng nhẹ (ăn hơi quá tay)",
			"Shoe size": "Cả hai chân: 27,0 cm",
		},
		"profile": {
			"Strong points": "Ăn đồ ngon",
			"Weak points": "Bơi lội",
			"Ears": "Chỉ nghe tiếng cổ vũ là nhận ra người cùng quê",
			"Tail": "Dẻo tới mức chải được mọi chỗ",
			"Family": "Hay đi nghỉ suối nước nóng; biết ít nhất một suối chưa ai tìm ra",
		},
		"secrets": [
			"Cắt móng cực khéo",
			"Ước mơ hồi bé là... món hầm",
		],
		"hint": "",
		"sizes": ["82", "57", "82"],
	},
	"tuandb": {
		"label": "Special Week",
		"player": "res://scenes/characters/player_tuandb.tscn",
		"skills": [
			{"name": "Shooting Star", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"desc": "Sẵn sàng lao đi! Một cô gái trong veo chỉ hướng về giấc mơ.",
		"tagline": "Sẵn sàng lao đi! Một cô gái trong veo chỉ hướng về giấc mơ.",
		"intro": "Tôi tên là Special Week! Giấc mơ của tôi là trở thành Umamusume số một Nhật Bản! Tôi phải cố lên để hai người mẹ được tự hào!",
		"measure": {
			"Height": "158 cm",
			"Weight": "Giảm nhẹ (hồi hộp trước giờ đua)",
			"Shoe size": "Trái 23,5 cm / Phải 23,0 cm",
		},
		"profile": {
			"Strong points": "Viết cảm nhận đồ ăn cực chi tiết",
			"Weak points": "Dùng vé tàu tháng",
			"Ears": "Vểnh lên và dịch chuyển tức thời xuống bếp mỗi khi nghe tiếng nấu nướng",
			"Tail": "Động theo cảm xúc, nên chơi bài là thua",
			"Family": "Màu mắt thừa hưởng từ mẹ ruột",
		},
		"secrets": [
			"Nếm là phân biệt được từng hãng sữa",
			"Cõng rất giỏi — ai được cõng cũng ngủ gật ngay",
		],
		"hint": "",
		"sizes": ["81", "56", "81"],
	},
	# "Nhân tố G" — thẻ đang khoá. Dữ liệu ở đây là dữ liệu THẬT; phần che
	# giấu do hàm thong_tin_the() lo, xem giải thích ở đó.
	"golshi": {
		"label": "Gold Ship",
		"player": "res://scenes/characters/player_golshi.tscn",
		"skills": [
			{"name": "Anchors Aweigh!", "level": 99, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
			{"name": "", "level": 0, "desc": "", "icon": ""},
		],
		"an_khi_khoa": true,
		"desc": "Hoang dã và khó đoán, tay đua vàng không giống bất kỳ ai!",
		"tagline": "Hoang dã và khó đoán, tay đua vàng không giống bất kỳ ai!",
		"intro": "Quỳ xuống! Gold Ship đã tới! Dù là biển lửa, mặt cỏ nát bét hay tận ngoài vũ trụ, ta luôn sẵn sàng phiêu lưu! ☆",
		"measure": {
			"Height": "170 cm",
			"Weight": "Không đo được",
			"Shoe size": "Cả hai chân: 26,5 cm",
		},
		"profile": {
			"Strong points": "Làm mặt",
			"Weak points": "Ngồi yên",
			"Ears": "Bịt tai người khác rồi hỏi 'Đoán xem ai nào?'",
			"Tail": "Thi thoảng bỏ quên trong phòng",
			"Family": "Nghe đâu là bí mật quốc gia",
		},
		"secrets": [
			"Cực giỏi thi đố vui",
			"Hay nói dối vặt, nhưng chuyện quan trọng thì luôn thật thà",
		],
		"hint": "Nhân tố G chỉ xuất hiện khi được gọi tên đúng chỗ.",
		"sizes": ["88", "55", "88"],
	},
}

## Chuỗi dùng để che mọi thông tin của nhân vật chưa mở khoá.
const MASK_STRING := "????????????"

## Những nhân vật BỊ GIẤU cho tới khi mở khoá bằng bảng CODE No.7.
##
## Khoá là id -> tên file ảnh thẻ bóng đen. Gom vào một bảng thay vì viết
## `if id == "golshi"` rải rác: giấu thêm một nhân vật giờ là thêm một dòng
## ở đây, không phải đi sửa is_character_locked, anh_the và cheat_panel.
##
## Vì sao Teio và Chiyono O bị giấu: đoạn intro chỉ có ba nhân vật, nên đội
## hình chơi được phải khớp với intro — Oguri Cap và Special Week thế chỗ.
## Hai người kia không biến mất khỏi game, họ thành phần thưởng ẩn giống
## Gold Ship.
const HIDDEN_CHARACTERS := {
	"hachimi": "thidden",
	"chiyo": "chidden",
	"golshi": "ghidden",
}

## Thứ tự các nhân vật hiện trên màn hình chọn nhân vật.
const CHARACTER_ORDER := ["kitamoi", "hachimi", "chiyo", "mambo",
	"oui", "tuandb", "golshi"]


## Nhân vật này có đang khoá không.
##
## Trước đây khoá là một hằng số ghi thẳng trong CHARACTERS ("locked": true),
## nên không có cách nào mở ra lúc chạy. Giờ khoá là TRẠNG THÁI: Gold Ship
## mở được bằng cờ golshi_unlocked (bật trong bảng CODE No.7). Mọi nơi trong
## game đã gọi hàm này rồi nên chỉ cần sửa đúng một chỗ là cả màn chọn nhân
## vật, nút Chơi và hàm set_selected_character() cùng hiểu luật mới.
func is_character_locked(id: String) -> bool:
	if HIDDEN_CHARACTERS.has(id):
		return not is_character_unlocked(id)
	return bool(CHARACTERS.get(id, {}).get("locked", false))


## Nhân vật ẩn này đã được mở khoá chưa.
func is_character_unlocked(id: String) -> bool:
	return bool(unlocked_characters.get(id, false))


## Ảnh thẻ hiện trên màn chọn nhân vật.
##
## Thẻ khoá dùng ảnh bóng đen riêng (ghidden.png) thay vì phủ màu tối lên ảnh
## thật. Lý do không phủ màu: ảnh gốc vẫn nằm trong bộ nhớ và vẫn lộ dáng
## nhân vật qua viền — người chơi tinh ý là đoán ra ngay, mất hết bất ngờ.
## Đổi hẳn file thì thẻ khoá không mang một pixel nào của ảnh thật.
func card_image(id: String) -> String:
	if HIDDEN_CHARACTERS.has(id) and not is_character_unlocked(id):
		return "res://assets/ui/characters/%s.png" % HIDDEN_CHARACTERS[id]
	return "res://assets/ui/characters/%s.png" % id


## Thông tin hiện trên bảng bên phải màn chọn nhân vật.
##
## Trả về BẢN SAO đã che nếu nhân vật đang khoá và có cờ "an_khi_khoa".
## Vì sao che ở đây chứ không viết sẵn hai bộ dữ liệu (một thật, một toàn dấu
## hỏi): hai bộ dữ liệu thì đến lúc điền tên kỹ năng và tiểu sử thật, rất dễ
## sửa một bên quên bên kia, và bản khoá lại chính là bản người chơi nhìn
## thấy đầu tiên. Một nguồn dữ liệu duy nhất, phần trình bày tự quyết định
## che hay không — sai sót kiểu đó không xảy ra được.
func card_info(id: String) -> Dictionary:
	var info: Dictionary = CHARACTERS.get(id, {})
	# Che khi: đang khoá VÀ (nằm trong danh sách nhân vật ẩn HOẶC có cờ
	# an_khi_khoa). Điều kiện NHAN_VAT_AN được thêm vào để giấu thêm một
	# nhân vật chỉ tốn một dòng ở bảng đó, không phải nhớ bật thêm cờ trong
	# CHARACTERS — quên bật cờ là lộ nguyên tên thật ra bảng bên phải.
	if not is_character_locked(id):
		return info
	if not (HIDDEN_CHARACTERS.has(id) or bool(info.get("an_khi_khoa", false))):
		return info

	var masked := info.duplicate(true)
	masked["label"] = MASK_STRING
	masked["desc"] = MASK_STRING
	masked["tagline"] = MASK_STRING
	masked["intro"] = " ".join([MASK_STRING, MASK_STRING, MASK_STRING, MASK_STRING])
	# Che GIÁ TRỊ nhưng GIỮ NGUYÊN NHÃN. Nếu che luôn cả nhãn thì bảng info
	# của nhân vật ẩn co lại thành một khối "????" vô nghĩa, người chơi không
	# đoán được là còn bao nhiêu thông tin đang bị giấu — mà chính cái cảm
	# giác "có gì đó ở đây mình chưa mở được" mới là thứ giữ họ đi tìm code.
	for board_name in ["measure", "profile"]:
		var board: Dictionary = masked.get(board_name, {})
		for label in board:
			board[label] = MASK_STRING
	var secrets: Array = masked.get("secrets", [])
	for i in secrets.size():
		secrets[i] = MASK_STRING
	masked["sizes"] = ["??", "??", "??"]
	for slot in masked["skills"]:
		slot["name"] = MASK_STRING
		slot["level"] = 0
		slot["desc"] = MASK_STRING
		slot["icon"] = ""
	return masked


## Màn đã hoàn thành. Khóa là id màn (chuỗi), giá trị true.
## Dùng khóa CHUỖI vì JSON luôn đổi khóa số thành chuỗi khi lưu rồi nạp lại —
## dùng khóa số thì sau khi tắt game mở lại mọi phép so sánh đều trượt.
var completed: Dictionary = {}
## Doanh thu tốt nhất từng màn, cùng kiểu khóa.
var best_money: Dictionary = {}
## Nhân vật người chơi đã chọn ở cửa sổ chọn nhân vật.
var selected_character: String = ""
## Màn đang chơi, do màn hình chọn màn ghi vào trước khi đổi scene.
var current_level: String = ""
## Scene sẽ quay về khi bấm "Trở lại" ở màn hình chọn nhân vật.
## KHÔNG lưu vào file save — chỉ có ý nghĩa trong một lượt điều hướng.
var return_scene: String = "res://scenes/menu/main_menu.tscn"
## Cheat CODE No.7: bỏ qua mọi điều kiện mở khóa. Có lưu vào file save
## để tiện test nhiều buổi, và bị xóa cùng lúc với nút "Xóa dữ liệu".
var unlock_all: bool = false

## Cheat CODE No.7 thứ hai: cho phép đổi sang góc nhìn thứ 3 bằng phím P.
## Có lưu vào file save, giống unlock_all.
##
## Vì sao là tuỳ chọn ẩn chứ không phải nút trong Cài đặt: toàn bộ cân bằng
## của màn chơi (khoảng cách bàn, thanh kiên nhẫn, bong bóng thoại trên đầu
## khách) đều tính cho việc người chơi nhìn thấy cả sàn cùng một lúc. Ở góc
## nhìn thứ 3, các bàn sau lưng không nhìn thấy được nên màn chơi khó hơn hẳn
## mà không phải do kỹ năng. Để nó ẩn thì nó là phần thưởng cho người tìm ra
## CODE No.7 — và là cách duy nhất ngắm được mấy easter egg giấu trong map.
var third_person_unlocked: bool = false

## Đang thực sự ở góc nhìn thứ 3 hay không. KHÔNG lưu vào save: mỗi lần vào
## màn đều bắt đầu lại ở top-down, để người chơi không vô tình kẹt ở góc nhìn
## khó mà không nhớ vì sao.
var third_person_active: bool = false

## Cheat CODE No.7 thứ ba: mở khoá "nhân tố G" (Gold Ship) ở màn chọn nhân
## vật. Có lưu vào file save, giống hai cheat kia.
##
## Vì sao là một cờ RIÊNG chứ không gộp vào unlock_all: unlock_all mở khoá
## MÀN CHƠI để test nhanh, còn đây là mở khoá NHÂN VẬT — hai thứ cần bật tắt
## độc lập. Muốn thử cân bằng của Gold Ship ở đúng màn 1 thì phải mở nhân vật
## mà vẫn giữ nguyên tiến trình màn chơi thật.
## Những nhân vật ẩn đã mở khoá: id -> true. Lưu vào save.
##
## Dùng TỪ ĐIỂN chứ không phải ba cờ bool riêng: số nhân vật ẩn còn tăng, và
## mỗi cờ mới lại kéo theo một dòng trong reset(), to_dict(), from_dict() và
## một nhánh trong cheat_panel. Từ điển thì cả bốn chỗ đó viết một lần xong.
var unlocked_characters: Dictionary = {}

## Cheat CODE No.7: dùng kĩ năng chủ động mà KHÔNG cần điều kiện, không giới
## hạn số lần. Lưu vào file save.
##
## Vì sao cần một cheat riêng cho việc này: điều kiện kích hoạt của mọi kĩ năng
## chủ động đều gắn với hệ đơn hàng (hoàn thành 5 đơn hoàn hảo, 3 đơn có
## steak…) — mà hệ đó chưa tồn tại. Không có cheat thì đoạn cut-in vừa làm
## không có cách nào xem được. Về sau khi đã có điều kiện thật, cheat này vẫn
## còn ích: xem lại cut-in để kiểm tra âm thanh, độ dài, thời điểm cắt mà
## không phải chơi đủ một màn cho mỗi lần thử.
var infinite_skill: bool = false

## Đã xem màn ra mắt của Gold Ship chưa. Lưu vào save.
##
## Vì sao chỉ chiếu MỘT lần chứ không mỗi lần vào màn: đây là một câu đùa —
## đạp cửa, hô "bổn đại vương", cả team ngơ ngác. Câu đùa nào xem lần thứ ba
## cũng thành phiền, mà đây lại đứng chắn ngay trước mặt người chơi mỗi lần
## họ muốn vào bếp. Chiếu một lần thì nó giữ nguyên giá trị "phát hiện".
## Những nhân vật ĐÃ chiếu đoạn ra mắt: id -> true.
##
## Trước đây là một cờ bool riêng cho Gold Ship. Đổi sang từ điển vì giờ có ba
## nhân vật ẩn — ba biến bool là ba chỗ phải nhớ khai báo, nhớ lưu, nhớ xoá
## trong reset(). from_dict() bên dưới tự chuyển cờ cũ sang để người đang chơi
## dở không bị chiếu lại đoạn Gold Ship họ đã xem.
var intro_seen: Dictionary = {}

## Cheat CODE No.7: bật phím 0 để TUA GIỜ trong màn chơi. Lưu vào file save.
##
## Vì sao phải có: một màn dài 7 phút, mà hai thứ đáng xem nhất lại nằm ở cuối
## — bài nhạc cao điểm đổi khi còn 3:32, và bảng tổng kết. Người ngồi xem
## (giáo viên chấm, bạn bè góp ý) không có 7 phút để đợi hai thứ đó.
##
## Vì sao là cheat có công tắc chứ không phải phím bấm lúc nào cũng ăn: phím 0
## nằm ngay trên hàng số, cạnh dãy phím người chơi thật sự dùng. Để nó luôn bật
## thì một cú bấm nhầm là mất cả lượt chơi, và người chơi không hiểu vì sao
## đồng hồ vừa nhảy. Giấu sau CODE No.7 thì chỉ ai cố ý mới bật được.
var cheat_time_skip: bool = false

## ───────────────────────────── BẢNG XẾP HẠNG ──────────────────────────────
##
## Lịch sử các lượt chơi: id màn -> mảng bản ghi, đã sắp giảm dần theo tiền.
## Mỗi bản ghi: {"nv": id nhân vật, "tien": int, "hang": String}.
##
## Vì sao lưu ID nhân vật chứ không lưu sẵn tên: tên hiện ra màn hình phải đi
## qua bảng CHARACTERS (và về sau là bảng dịch). Lưu chuỗi "Kitasan Black" vào
## save thì đổi tên hiển thị một nhân vật sẽ để lại một bảng xếp hạng mang tên
## cũ vĩnh viễn, và bản tiếng Anh đọc ra tên tiếng Việt.
##
## Vì sao TÁCH khỏi best_money: best_money là MỘT con số mỗi màn, dùng cho
## luật mở khoá và dòng "kỷ lục cũ" ở bảng tổng kết. Bảng xếp hạng cần NHIỀU
## lượt và cần biết ai chơi lượt đó — nhét thêm vào best_money thì hàm
## get_best_money() đang trả int sẽ phải trả về thứ khác, kéo theo mọi nơi gọi.
var leaderboard: Dictionary = {}

## Các màn có bảng xếp hạng, đúng thứ tự tab trên giao diện.
const RANKED_LEVELS := ["d1_sang", "d2_sang", "d3_sang", "endless"]

## Nhãn tab. "endless" chưa phải một màn thật trong LEVELS — nó là chỗ đã dành
## sẵn, để lúc làm chế độ Vô tận không phải đụng lại vào giao diện này.
const RANKED_LEVEL_NAMES := {
	"d1_sang": "Màn 1",
	"d2_sang": "Màn 2",
	"d3_sang": "Màn 3",
	"endless": "Endless",
}

## Giữ bao nhiêu dòng mỗi màn. Cắt bớt chứ không giữ hết: file save là JSON
## đọc lại toàn bộ lúc khởi động, mà một bảng xếp hạng không ai đọc tới dòng
## thứ hai mươi.
const LEADERBOARD_ROWS := 10


## Ghi một lượt chơi vào bảng xếp hạng.
##
## Ghi MỌI lượt chơi xong, kể cả lượt trượt hạng (hang rỗng): bảng này trả lời
## "ai kiếm được bao nhiêu", không phải "ai qua màn". Một lượt 300 đồng vẫn là
## dữ liệu thật, và nếu lọc đi thì người mới chơi sẽ thấy một cái bảng trống
## trơn sau khi vừa chơi xong một màn.
func record_rank(level_id: String, money: int, rank: String) -> void:
	if not RANKED_LEVELS.has(level_id):
		return
	var list_: Array = leaderboard.get(level_id, [])
	list_.append({
		"character": selected_character,
		"money": money,
		"rank": rank,
	})
	# Sắp lại NGAY lúc ghi chứ không sắp lúc hiện: bảng được đọc nhiều lần
	# hơn số lần được ghi, và sắp sẵn thì mọi nơi đọc đều thấy cùng một thứ tự.
	list_.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		# Bản ghi cũ dùng khoá "tien"; đọc lùi để bảng đã lưu vẫn sắp đúng.
		return int(a.get("money", a.get("tien", 0))) \
			> int(b.get("money", b.get("tien", 0))))
	if list_.size() > LEADERBOARD_ROWS:
		list_.resize(LEADERBOARD_ROWS)
	leaderboard[level_id] = list_
	progress_changed.emit()
	SaveSystem.save_game()


## Bảng xếp hạng của một màn — mảng bản ghi đã sắp sẵn, có thể rỗng.
func level_leaderboard(level_id: String) -> Array:
	var list_: Variant = leaderboard.get(level_id, [])
	return list_ if list_ is Array else []


## Tên hiển thị của nhân vật trong một bản ghi xếp hạng.
##
## Bản ghi cũ có thể mang id rỗng (chạy thẳng map bằng F6 thì chưa qua màn
## chọn nhân vật) hoặc một id đã bị xoá khỏi CHARACTERS. Cả hai đều không được
## phép làm hỏng cái bảng, nên trả về một chỗ trống có nghĩa.
func character_name(id: String) -> String:
	if id.is_empty():
		return "—"
	return String(CHARACTERS.get(id, {}).get("label", id))


## Bật/tắt cheat tua giờ.
func set_cheat_time_skip(value: bool) -> void:
	cheat_time_skip = value
	progress_changed.emit()
	SaveSystem.save_game()



func is_completed(id: String) -> bool:
	return bool(completed.get(id, false))


## Quy tắc mở khóa: hoàn thành Sáng ngày N sẽ mở Sáng ngày N+1 VÀ Tối ngày N.
## Quy tắc đó nằm gọn trong bảng LEVELS ở trên chứ không rải rác trong code,
## nên thêm ngày mới chỉ là thêm 2 dòng vào bảng.
func is_unlocked(id: String) -> bool:
	var info: Dictionary = LEVELS.get(id, {})
	if info.is_empty():
		return false
	# Giai đoạn buổi tối chưa có nội dung, cheat cũng không mở được —
	# mở ra chỉ dẫn người chơi vào một màn trống.
	if bool(info.get("evening", false)) and not EVENING_ENABLED:
		return false
	if unlock_all:
		return true
	var needs := str(info.get("needs", ""))
	return needs.is_empty() or is_completed(needs)


## Đường dẫn file map của một màn, lấy từ bảng LEVELS.
##
## Trả về chuỗi RỖNG nếu màn đó chưa dựng map. Cố ý không tự thay bằng map
## mặc định ở đây: GameData chỉ giữ dữ liệu, còn quyết định "chưa có thì đi
## đâu" là việc của màn hình điều hướng. Trộn hai việc vào một chỗ thì sau
## này muốn đổi hành vi phải sửa đúng cái file lẽ ra không liên quan.
func scene_path(id: String) -> String:
	var info: Dictionary = LEVELS.get(id, {})
	return str(info.get("scene", ""))


## Đường dẫn scene NHÂN VẬT ĐIỀU KHIỂN ĐƯỢC của một id, lấy từ bảng CHARACTERS.
##
## Trả về chuỗi RỖNG nếu nhân vật đó chưa dựng scene (ví dụ Gold Ship). Giống
## duong_dan_scene() ở trên: GameData chỉ trả lời "có hay không", còn xử lý khi
## thiếu là việc của nơi gọi — ở đây là level_base, nó sẽ lùi về nhân vật gán
## sẵn trong Inspector thay vì để màn chơi trống trơn.
func character_scene_path(id: String) -> String:
	var info: Dictionary = CHARACTERS.get(id, {})
	return str(info.get("player", ""))


## ─────────────────────────────── XẾP HẠNG CUỐI MÀN ────────────────────────
##
## Bốn mốc doanh thu. Đạt mốc nào thì mang hạng đó; DƯỚI mốc C là CHƯA ĐẠT và
## màn không được đánh dấu hoàn thành.
##
## Vì sao đặt ở GameData chứ không ở bảng kết quả: đây là số liệu CÂN BẰNG, họ
## hàng với giá món và thời gian màn chơi, không phải chuyện giao diện. Bảng
## kết quả chỉ hỏi "được hạng gì" rồi vẽ ra.
##
## Vì sao một bảng mốc CHUNG chứ không mỗi màn một bảng: cả ba ngày hiện dùng
## chung một file map, cùng thực đơn và cùng 7 phút, nên độ khó chưa khác nhau.
## Khi nào Ngày 2 và Ngày 3 có luật riêng thì thêm khoá "moc" vào mục màn đó
## trong LEVELS — hàm dưới đã đọc sẵn, không phải sửa thêm chỗ nào.
##
## CẢNH BÁO: bốn con số này là TẠM. Chúng suy từ mô hình 7 phút trong
## Bang can bang.xlsx, nhưng thực đơn vừa mất hai món đắt nhất (Canh rau củ và
## Bữa tối, do nhóm món nồi đang khoá) nên trần doanh thu đã tụt. Phải playtest
## rồi chỉnh lại — mốc quá cao thì hạng S thành thứ không ai với tới, mốc quá
## thấp thì mọi lượt chơi đều S và cái hạng mất hết ý nghĩa.
const DEFAULT_THRESHOLDS := {"S": 1650, "A": 1300, "B": 950, "C": 600}

## Thứ tự xét, cao xuống thấp. Không lấy MOC_MAC_DINH.keys() vì thứ tự khoá
## Dictionary là thứ tự khai báo — đúng lúc này nhưng sẽ sai lặng lẽ nếu ai đó
## sắp lại bảng trên, mà lỗi đó rất khó nhìn ra.
const RANK_ORDER := ["S", "A", "B", "C"]

## Hạng thấp nhất coi là qua màn.
const MIN_RANK := "C"


## Xếp hạng một lượt chơi. Trả về "S"/"A"/"B"/"C", hoặc "" nếu chưa đạt.
func rank_for(level_id: String, money: int) -> String:
	var marks := rank_thresholds_for(level_id)
	for rank in RANK_ORDER:
		if money >= int(marks.get(rank, DEFAULT_THRESHOLDS[rank])):
			return rank
	return ""


## Mốc điểm của một màn, để bảng kết quả hiện "còn thiếu bao nhiêu nữa".
func rank_thresholds_for(level_id: String) -> Dictionary:
	return rules_for_level(level_id).get("rank_thresholds", DEFAULT_THRESHOLDS)


## Luật riêng của một màn, hoặc Dictionary rỗng nếu màn đó chưa có luật.
##
## Rỗng là hợp lệ, không phải lỗi: màn hướng dẫn có bộ dẫn dắt riêng đặt luật
## của nó, và chạy thẳng map bằng F6 thì current_level rỗng. Cả hai trường hợp
## đều muốn dùng số mặc định trong quan_ly_khach.gd.
func rules_for_level(level_id: String) -> Dictionary:
	return LEVELS.get(level_id, {}).get("rules", {})


## Tên màn hiện ở màn hình mở đầu, ví dụ "NGÀY 1".
##
## Đặt ở đây chứ không gõ trong mo_man.gd vì màn hình chọn màn CŨNG đang gộp
## "Sáng/Tối" thành "Ngày N" (xem KHOA_NGAY trong level_select.gd). Hai chỗ
## tự đặt tên riêng thì sớm muộn một chỗ nói "Ngày 1" còn chỗ kia nói "Sáng".
##
## Khi bật HIEN_MAN_TOI thì mới cần phân biệt buổi, nên lúc đó mới ghép thêm
## nhãn của màn vào sau.
const DAY_NAMES := {
	"d1_sang": "NGÀY 1", "d1_toi": "NGÀY 1",
	"d2_sang": "NGÀY 2", "d2_toi": "NGÀY 2",
	"d3_sang": "NGÀY 3", "d3_toi": "NGÀY 3",
}

func level_name(id: String) -> String:
	if id == "tutorial":
		return "HƯỚNG DẪN"
	if not DAY_NAMES.has(id):
		return String(LEVELS.get(id, {}).get("label", "")).to_upper()
	var day_label: String = DAY_NAMES[id]
	if not SHOW_EVENING:
		return day_label
	return "%s · %s" % [day_label, String(LEVELS[id].get("label", "")).to_upper()]


func get_best_money(id: String) -> int:
	return int(best_money.get(id, 0))


## Gọi khi người chơi hoàn thành một màn. Tự lưu game ngay.
func complete_level(id: String, earned: int = 0) -> void:
	completed[id] = true
	if earned > get_best_money(id):
		best_money[id] = earned
	progress_changed.emit()
	SaveSystem.save_game()


## Ghi lại nhân vật người chơi vừa chọn ở màn hình chọn nhân vật.
func set_selected_character(id: String) -> void:
	if not CHARACTERS.has(id):
		push_error("Không có nhân vật id '%s'." % id)
		return
	if is_character_locked(id):
		push_warning("Nhân vật '%s' đang khóa, không chọn được." % id)
		return
	selected_character = id
	progress_changed.emit()


## Bật/tắt cheat mở khóa toàn bộ màn chơi.
func set_unlock_all(value: bool) -> void:
	unlock_all = value
	progress_changed.emit()
	SaveSystem.save_game()


## Bật/tắt cheat dùng kĩ năng không cần điều kiện.
func set_infinite_skill(value: bool) -> void:
	infinite_skill = value
	progress_changed.emit()
	SaveSystem.save_game()


## Đường dẫn đoạn cut-in kĩ năng của một nhân vật.
##
## Tên file TRÙNG id nhân vật (kitamoi.ogv, mambo.ogv…) chứ không có bảng tra
## riêng — cùng quy ước với anh_the() và ảnh nguyên liệu. Một bảng tra là một
## thứ nữa phải nhớ cập nhật khi thêm nhân vật, và quên cập nhật thì lỗi chỉ
## lộ ra lúc chạy.
##
## Godot KHÔNG phát được .mp4 (H.264 vướng bằng sáng chế) — chỉ đọc Ogg
## Theora. Mọi file trong thư mục này đều đã chuyển sang .ogv bằng ffmpeg.
func skill_cutscene_path(id: String) -> String:
	if id.is_empty():
		return ""
	return "res://assets/video/ki_nang/%s.ogv" % id


## Đường dẫn ảnh biểu tượng kĩ năng hiện trên HUD trong màn chơi.
##
## Đọc thẳng từ ô kỹ năng THỨ NHẤT của nhân vật trong CHARACTERS — đó là kỹ
## năng CHỦ ĐỘNG, cũng chính là kỹ năng phím Space kích hoạt.
##
## Bản trước tìm file theo id nhân vật (ki_nang/<id>.png). Cách đó tạo ra hai
## nguồn sự thật cho cùng một tấm ảnh: bảng chọn nhân vật đọc trường "icon"
## trong CHARACTERS, còn HUD đoán theo tên file. Điền một chỗ thì chỗ kia
## không đổi, và không có lỗi nào chỉ ra vì sao. Giờ cả hai cùng đọc trường
## "icon" — điền một lần, hiện cả hai nơi.
func skill_icon_path(id: String) -> String:
	var list_: Array = CHARACTERS.get(id, {}).get("skills", [])
	if not list_.is_empty():
		var name_ := str((list_[0] as Dictionary).get("icon", ""))
		if not name_.is_empty():
			var path := "res://assets/ui/ki_nang/%s.png" % name_
			if ResourceLoader.exists(path):
				return path
			push_warning("Thiếu ảnh kĩ năng: %s" % path)
	return "res://assets/ui/ki_nang/mac_dinh.png"


## Bật/tắt quyền dùng góc nhìn thứ 3.
func set_third_person_unlocked(value: bool) -> void:
	third_person_unlocked = value
	# Tắt quyền thì phải kéo người chơi về top-down ngay, nếu không họ sẽ kẹt
	# ở góc nhìn thứ 3 mà phím P không còn tác dụng để thoát ra.
	if not value and third_person_active:
		set_third_person_active(false)
	progress_changed.emit()
	SaveSystem.save_game()


## Bật/tắt một nhân vật ẩn.
func set_character_unlocked(id: String, value: bool) -> void:
	if not HIDDEN_CHARACTERS.has(id):
		return
	unlocked_characters[id] = value
	# Tắt lại trong khi nhân vật đó đang được chọn thì phải bỏ chọn, nếu
	# không người chơi vào màn với một nhân vật lẽ ra chưa mở khoá.
	if not value and selected_character == id:
		selected_character = ""
	# Riêng Gold Ship: khoá lại thì quên luôn "đã xem màn ra mắt", để bật
	# lại lần sau còn xem lại được từ đầu. Không có dòng này thì thử một
	# lần là mất, muốn xem lại phải xoá cả file save.
	if not value:
		intro_seen.erase(id)
	progress_changed.emit()
	SaveSystem.save_game()


## Giữ tên cũ cho bảng CODE No.7 khỏi phải đổi.
func set_golshi_unlocked(value: bool) -> void:
	set_character_unlocked("golshi", value)


## Đổi góc nhìn. Không có quyền thì không làm gì — kiểm tra ở đây một lần
## thay vì bắt mọi nơi gọi phải tự nhớ kiểm tra.
func toggle_view_mode() -> void:
	if not third_person_unlocked:
		return
	set_third_person_active(not third_person_active)


func set_third_person_active(value: bool) -> void:
	third_person_active = value
	view_mode_changed.emit(value)


## Có cần chiếu màn ra mắt của Gold Ship trước khi vào map không.
##
## Gom ba điều kiện vào một hàm thay vì để nơi gọi tự ghép: đã mở khoá, đang
## thật sự chọn Gold Ship, và chưa xem lần nào. Nơi gọi (character_select)
## chỉ hỏi một câu, nên sau này đổi luật — ví dụ cho xem lại mỗi chương —
## thì sửa đúng ở đây.
## Màn này có phải chỉ để kể chuyện không (không có gameplay).
func is_story_level(id: String) -> bool:
	return bool(LEVELS.get(id, {}).get("story_only", false))


## Scene cần nạp để VÀO màn `id` — tự chen đoạn cắt cảnh nếu tới lượt.
##
## Đây là ĐIỂM HỘI TỤ của mọi đường vào màn chơi. Trước đây phép kiểm tra
## nằm trong character_select._on_play_pressed(), và đó là lỗi: prologue tự
## chuyển sang tutorial bằng change_scene_to_file của riêng nó, không đi qua
## màn chọn nhân vật, nên đường đó không có ai kiểm tra cả. Hệ quả là chọn
## Gold Ship rồi bấm Chơi thì cô ấy đạp cửa xông vào quán TRƯỚC cả đoạn cả
## team nghe tin về cái quán. Gom vào một hàm thì mọi đường vào màn đều đi
## qua đúng một chỗ.
##
## Hàm này CÓ tác dụng phụ (đánh dấu đã xem, ghi save) chứ không phải hàm
## hỏi suông — đặt tên là "vao_man" chứ không phải "duong_dan_scene" để chỗ
## gọi thấy rõ điều đó. Nhờ việc đánh dấu ngay tại đây mà chính scene cắt
## cảnh gọi lại hàm này cũng không bị lặp vô hạn.
func enter_level(id: String) -> String:
	var target := scene_path(id)
	if target.is_empty():
		return ""

	# Bốn điều kiện chen đoạn ra mắt, xét cho ĐÚNG nhân vật đang được chọn:
	#   1. nhân vật đó có đoạn ra mắt
	#   2. đã mở khoá (không thì đoạn này chưa tồn tại với người chơi)
	#   3. chưa xem lần nào trong file save này
	#   4. màn sắp vào là màn chơi THẬT, không phải một màn kể chuyện —
	#      nếu không thì "nhân vật bước vào quán" chen được vào trước cả đoạn
	#      cả team nghe tin về cái quán.
	var who := String(selected_character)
	if INTRO_SCENES.has(who) \
			and is_character_unlocked(who) \
			and not bool(intro_seen.get(who, false)) \
			and not is_story_level(id):
		intro_seen[who] = true
		SaveSystem.save_game()
		return String(INTRO_SCENES[who])

	return target


## Xóa sạch tiến trình, quay về trạng thái mới cài.
func reset() -> void:
	completed.clear()
	best_money.clear()
	current_level = ""
	selected_character = ""
	unlock_all = false
	third_person_unlocked = false
	third_person_active = false
	infinite_skill = false
	unlocked_characters.clear()
	intro_seen.clear()
	leaderboard.clear()
	cheat_time_skip = false
	progress_changed.emit()


func to_dict() -> Dictionary:
	return {
		"completed": completed,
		"best_money": best_money,
		"selected_character": selected_character,
		"unlock_all": unlock_all,
		"third_person_unlocked": third_person_unlocked,
		"infinite_skill": infinite_skill,
		"unlocked_characters": unlocked_characters,
		"intro_seen": intro_seen,
		"leaderboard": leaderboard,
		"cheat_time_skip": cheat_time_skip,
	}


## Đọc khoá TIẾNG ANH trước, nếu không có thì đọc khoá TIẾNG VIỆT cũ.
##
## File save nằm ở user:// trên máy người chơi, không nằm trong repo — đổi tên
## khoá mà không đọc lùi thì mọi tiến độ đã có biến mất im lặng: game vẫn chạy,
## chỉ là màn nào cũng khoá lại và nhân vật đã mở thì đóng. Lần ghi tiếp theo
## tự động ghi bằng khoá mới, nên nhánh cũ này chỉ chạy đúng một lần cho mỗi
## file save. Cùng cách đã dùng cho `golshi_unlocked` bên dưới.
func from_dict(data: Dictionary) -> void:
	var c: Variant = data.get("completed", {})
	completed = c if c is Dictionary else {}
	var b: Variant = data.get("best_money", {})
	best_money = b if b is Dictionary else {}
	selected_character = str(data.get("selected_character", ""))
	unlock_all = bool(data.get("unlock_all", false))
	third_person_unlocked = bool(data.get("third_person_unlocked", false))
	infinite_skill = bool(data.get("infinite_skill", data.get("ki_nang_vo_han", false)))
	var unlocked_raw: Variant = data.get("unlocked_characters", data.get("nhan_vat_mo", {}))
	unlocked_characters = unlocked_raw if unlocked_raw is Dictionary else {}
	# Save cũ chỉ có một cờ bool cho Gold Ship — chuyển sang dạng từ điển để
	# người đang chơi dở không mất phần thưởng đã mở.
	if bool(data.get("golshi_unlocked", false)):
		unlocked_characters["golshi"] = true
	var seen_raw: Variant = data.get("intro_seen", data.get("da_gioi_thieu", {}))
	intro_seen = seen_raw if seen_raw is Dictionary else {}
	var board_raw: Variant = data.get("leaderboard", data.get("bang_xep_hang", {}))
	leaderboard = board_raw if board_raw is Dictionary else {}
	cheat_time_skip = bool(data.get("cheat_time_skip", data.get("cheat_tua_gio", false)))
	# Save cũ chỉ có một cờ bool cho Gold Ship — chuyển sang từ điển để người
	# đang chơi dở không bị chiếu lại đoạn họ đã xem.
	if bool(data.get("golshi_da_gioi_thieu", false)):
		intro_seen["golshi"] = true
	# Save cũ có thể còn ghi id "locked_1" (tên cũ của thẻ này). Bỏ đi để
	# không vào màn với một id không còn tồn tại trong CHARACTERS.
	if selected_character == "locked_1":
		selected_character = ""
	progress_changed.emit()
