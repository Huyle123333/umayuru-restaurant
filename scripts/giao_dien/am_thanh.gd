extends Node
## Hệ âm thanh dùng chung — autoload tên `AmThanh`.
##
## Mọi tiếng động và mọi bài nhạc trong game đi qua đúng file này. Không nơi
## nào khác được tự dựng AudioStreamPlayer, vì như thế thì âm lượng trong Cài
## đặt sẽ điều khiển được chỗ này mà không điều khiển được chỗ kia.
##
## ─────────────────────────────────────────── VÌ SAO CÓ BẢNG TÊN `TEN_FILE`
##
## Code gọi tiếng theo LÚC NÀO NÓ KÊU — `khach_vao`, `sap_het_gio`. File âm
## thanh lại được đặt tên theo NÓ LÀ TIẾNG GÌ — `door_chime`, `warning_beep`.
## Hai cách gọi tên đó đều đúng, nhưng đúng cho hai người khác nhau: người
## viết code cần cái thứ nhất, người đi tìm nhạc cần cái thứ hai.
##
## Bảng `TEN_FILE` là chỗ hai cách gọi gặp nhau. Nhờ nó, đổi bài nhạc cho một
## sự kiện chỉ là sửa MỘT dòng trong bảng, không phải đổi tên file trên đĩa
## (đổi tên file thì lần sau mở thư mục ra không ai còn nhận ra tiếng nào là
## tiếng nào), cũng không phải đi sửa chỗ gọi trong code.
##
## Tên không có trong bảng thì tra thẳng bằng chính nó — nên thêm một tiếng
## mới mà đặt trùng tên sự kiện thì không cần khai báo gì cả.
##
## ─────────────────────────────────────────────────────── CÁCH THÊM ÂM THANH
##
## Tiếng ngắn: chép vào `res://assets/sfx/game/`
## Nhạc nền:   chép vào `res://assets/bgm/`
## Đuôi .ogg / .wav / .mp3 đều được (tìm theo thứ tự đó). Mở Godot một lần
## cho nó nhập file. Xem `assets/sfx/game/DOC_TEN_FILE.txt` để biết tên nào
## dùng vào việc gì.
##
## Thiếu file thì `phat()` im lặng bỏ qua và chỉ cảnh báo MỘT lần cho mỗi tên
## — game chạy y hệt, chỉ là không kêu.
##
## Âm lượng đã tự nối vào hai thanh trượt trong Cài đặt, vì mọi thứ ở đây phát
## qua bus "SFX" và "Music" mà settings_manager.gd đang điều khiển.

const THU_MUC := "res://assets/sfx/game/"
const THU_MUC_NHAC := "res://assets/bgm/"

## Khai kiểu Array[String] chứ không để mảng trần: phần tử của một mảng trần
## có kiểu tĩnh là Variant, nên `var dd := THU_MUC + ten + d` bên dưới không
## suy được kiểu và Godot báo lỗi biên dịch. Đây là lần thứ ba cùng cái bẫy đó
## trong dự án này (đơn hàng, khách hàng, giờ tới đây).
const DUOI: Array[String] = [".ogg", ".wav", ".mp3"]

## TÊN SỰ KIỆN (code gọi)  ->  TÊN FILE (trên đĩa).
const TEN_FILE := {
	# --- đôi tay ---
	"cam_len":     "pick_up",        # nhấc một vật lên
	"dat_xuong":   "drop_out",       # đặt vật lên bàn / trạm
	"vut_rac":     "bin_or_pet",     # vứt đồ vào thùng rác bocchi
	"rap_xong":    "craft_success",  # bàn chế tạo ráp thành món
	"rap_hut":     "nope_click",     # bấm F mà không thành món nào
	"giao_mon":    "serve_dish",     # giao đúng món cho khách
	# --- bếp ---
	"nau_xong":    "cooking_done",   # bếp / lò / thớt xong một mẻ
	"nau_hong":    "wrong_recipe",   # ra đồ hỏng vì sai công thức
	"chay":        "sizzle_burn",    # để trên bếp quá lâu
	# --- khách và tiền ---
	"khach_vao":   "door_chime",
	"khach_bo_di": "fail_soft",
	"hoan_hao":    "perfect_bonus",  # giao khi kiên nhẫn còn trên nửa
	"tien":        "coin_collect",
	# --- vòng đời màn chơi ---
	"sap_het_gio": "warning_beep",   # còn 30 giây
	"het_gio":     "time_up_buzzer",
	"tong_ket":    "results_screen",
	# --- kể chuyện ---
	"go_chu":      "text_sound",     # tiếng gõ chữ trong hội thoại
}

## Các NHÓM nhạc nền. Bốc ngẫu nhiên trong nhóm bằng nhac_ngau_nhien().
##
## Sáu bài dùng chung cho cả menu lẫn màn chơi là CỐ Ý, không phải lười: kho
## nhạc có sáu bài, chia đôi thì mỗi bên chỉ còn ba và người chơi nghe lặp
## nhanh gấp đôi. Cái phân biệt hai chỗ không phải là danh sách bài, mà là
## CÁCH bốc — xem nhac_ngau_nhien().
const NHOM_MAN: Array[String] = [
	"bgm1_beachtraining", "bgm2_ura", "bgm3_unity",
	"bgm4_mant", "bgm5_mant2", "bgm6_gl",
]

const NHOM_NHAC := {
	"menu": NHOM_MAN,
	"man": NHOM_MAN,
	# Hashire Umamusume — RIÊNG cho đoạn cuối màn chơi, dài đúng 212 giây.
	# Không nằm trong NHOM_MAN: nếu nó có thể bốc trúng ngay từ đầu màn thì
	# lúc còn 3 phút rưỡi nó sẽ phải tự cắt chính mình để nhường chỗ cho...
	# chính nó, và cái khoảnh khắc "đổi nhạc = sắp hết giờ" mất sạch ý nghĩa.
	"cao_diem": ["hashire_umamusume"],
	# Prologue dùng bài cố định: đoạn kể chuyện có nhịp riêng, bốc ngẫu nhiên
	# thì mỗi lần chơi lại một không khí khác nhau.
	"prologue": ["bgm2_ura"],
}

## Số kênh phát tiếng ngắn cùng lúc.
##
## Một kênh duy nhất thì tiếng sau cắt ngang tiếng trước — mà trong bếp lúc
## cao điểm, "giao món" và "khách vào" xảy ra cách nhau một phần mười giây là
## chuyện thường. Tám kênh đủ cho mọi tình huống đã đo, và tám AudioStreamPlayer
## rỗng gần như không tốn gì.
const SO_KENH := 8

var _kho: Dictionary = {}       # duong_dan -> AudioStream đã nạp
var _da_bao: Dictionary = {}    # ten -> true, để chỉ cảnh báo một lần
var _kenh: Array[AudioStreamPlayer] = []
var _ke_tiep := 0

var _nhac: AudioStreamPlayer
## Tên bài đang phát, để nhac_ngau_nhien() biết có cần đổi hay không.
var _bai_dang := ""

## Kênh RIÊNG cho tiếng gõ chữ — xem go_chu().
var _kenh_go: AudioStreamPlayer


func _ready() -> void:
	# Chạy được cả khi cây scene bị tạm dừng: bảng kết quả và bảng hướng dẫn
	# đều dừng game, mà chúng vẫn cần phát tiếng.
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in SO_KENH:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_kenh.append(p)

	_kenh_go = AudioStreamPlayer.new()
	_kenh_go.bus = "SFX"
	add_child(_kenh_go)

	_nhac = AudioStreamPlayer.new()
	_nhac.bus = "Music"
	add_child(_nhac)


## Đồng bộ nhạc nền với trạng thái TẠM DỪNG của game.
##
## Vì sao phải làm bằng tay: node này là PROCESS_MODE_ALWAYS (nó phải kêu được
## cả khi game dừng — bảng kết quả và menu F1 đều dừng game mà vẫn cần tiếng),
## nên mọi AudioStreamPlayer bên trong nó cũng chạy tiếp khi tạm dừng.
##
## Hậu quả trước khi có hàm này: đồng hồ màn chơi DỪNG theo game, còn nhạc thì
## KHÔNG. Mở menu F1 hay bấm Pause ở nửa sau màn chơi rồi quay lại, bài
## Hashire đã chạy trước đồng hồ đúng bằng khoảng thời gian tạm dừng — và nó
## kết thúc sớm, để lại mấy chục giây cuối màn im lặng. Càng dừng nhiều lần
## càng lệch.
##
## CHỈ dừng NHẠC, không dừng tiếng ngắn: bảng kết quả tạm dừng game NGAY TRƯỚC
## khi phát tiếng tổng kết, nên dừng cả bể SFX thì cái tiếng quan trọng nhất
## của cả màn lại là cái duy nhất không kêu.
func _process(_delta: float) -> void:
	var dung := get_tree().paused
	if _nhac.stream_paused != dung:
		_nhac.stream_paused = dung


# ------------------------------------------------------------ tiếng ngắn ---

## Phát một tiếng ngắn. Thiếu file thì im lặng bỏ qua.
##
## `cao_do` đổi cao độ để cùng một file nghe không lặp lại y hệt — ví dụ tiếng
## nhặt đồ phát mấy chục lần một màn.
func phat(ten: String, cao_do: float = 1.0) -> void:
	var st := _nap(ten, THU_MUC)
	if st == null:
		return
	var p := _kenh_ranh()
	p.stream = st
	p.pitch_scale = cao_do
	p.play()


## Tiếng gõ chữ trong hội thoại — MỘT kênh riêng, mỗi lần gọi là bắt đầu lại.
##
## Kêu ĐÚNG MỘT LẦN cho mỗi dòng thoại (xem hoi_thoai.gd), không phải mỗi ký
## tự. Bản đầu phát lặp theo nhịp trong lúc chữ đang chạy, nghe đúng kiểu máy
## chữ nhưng nhức đầu thật sự: prologue dài mấy chục dòng, và một chuỗi tiếng
## "cạch" liên tục cạnh tranh trực tiếp với thứ người chơi đang phải làm ở đó
## — ĐỌC.
##
## Vì sao vẫn giữ kênh riêng thay vì gọi phat(): người chơi bấm nhanh thì dòng
## sau bắt đầu trong lúc tiếng của dòng trước còn đang kêu. Qua bể tám kênh
## thì hai tiếng chồng lên nhau; ở một kênh, play() cắt tiếng cũ và bắt đầu
## lại — đúng cái người chơi mong đợi khi họ vừa chuyển sang câu mới.
func go_chu() -> void:
	var st := _nap("go_chu", THU_MUC)
	if st == null:
		return
	_kenh_go.stream = st
	_kenh_go.pitch_scale = randf_range(0.94, 1.06)
	_kenh_go.play()


## Kênh rảnh gần nhất; hết rảnh thì cướp kênh cũ nhất theo vòng.
##
## Cướp chứ không bỏ qua: bỏ qua thì đúng lúc bếp ồn nhất — lúc phản hồi quan
## trọng nhất — lại là lúc mất tiếng.
func _kenh_ranh() -> AudioStreamPlayer:
	for p in _kenh:
		if not p.playing:
			return p
	var p := _kenh[_ke_tiep]
	_ke_tiep = (_ke_tiep + 1) % _kenh.size()
	return p


# -------------------------------------------------------------- nhạc nền ---

## Phát một bài cụ thể.
##
## `lap`          — bật cờ lặp trên chính stream.
## `choi_lai`     — true thì phát lại từ đầu kể cả khi bài đó đang chạy.
##                  Mặc định false, nhờ vậy gọi lại cùng một bài ở hai màn
##                  hình liên tiếp KHÔNG làm nhạc giật về đầu.
func nhac(ten: String, lap: bool = true, choi_lai: bool = false) -> void:
	var st := _nap(ten, THU_MUC_NHAC)
	if st == null:
		return
	if not choi_lai and _nhac.stream == st and _nhac.playing:
		return

	# Bật/tắt cờ lặp NGAY TRÊN stream. ogg và mp3 mỗi loại một tên thuộc tính
	# khác nhau, nên thử cả hai thay vì rẽ nhánh theo lớp — thêm một định dạng
	# mới sau này không phải sửa ở đây.
	if "loop" in st:
		st.set("loop", lap)
	elif "loop_mode" in st:
		st.set("loop_mode", 1 if lap else 0)

	_bai_dang = ten
	_nhac.stream = st
	_nhac.play()


## Bốc ngẫu nhiên một bài trong nhóm.
##
## `giu_lien_mach` là cả điểm mấu chốt của hàm này:
##
##   TRUE  (dùng cho cụm MENU) — nếu bài đang phát đã thuộc nhóm này thì KHÔNG
##         làm gì cả. Người chơi bấm Menu chính → Chọn màn → Chọn nhân vật →
##         quay lại, cả bốn màn hình dùng chung một bài đang chạy dở. Không có
##         cờ này thì mỗi lần đổi màn hình là nhạc giật về đầu một bài khác,
##         và chỉ cần bấm qua lại vài lần là nghe như đài bị nhiễu.
##
##   FALSE (dùng cho MÀN CHƠI) — luôn bốc bài mới và phát lại từ đầu. Vào một
##         ca làm việc mới thì phải nghe như một ca làm việc mới, chứ không
##         phải như đoạn giữa của bài nhạc menu.
func nhac_ngau_nhien(nhom: String, giu_lien_mach: bool = false,
		lap: bool = true) -> void:
	var ds: Array = NHOM_NHAC.get(nhom, [])
	if ds.is_empty():
		push_warning("[AmThanh] không có nhóm nhạc '%s'." % nhom)
		return

	if giu_lien_mach and _nhac.playing and ds.has(_bai_dang):
		return

	var chon := String(ds.pick_random())
	# Tránh bốc trúng đúng bài vừa nghe xong. Bốc lại tối đa 8 lần chứ không
	# lọc bài cũ ra khỏi danh sách rồi bốc: lọc thì phải cấp phát một mảng mới
	# mỗi lần đổi màn, mà xác suất trúng lại là 1/6 nên tám lượt thử là quá đủ.
	if ds.size() > 1:
		var lan := 0
		while chon == _bai_dang and lan < 8:
			chon = String(ds.pick_random())
			lan += 1

	nhac(chon, lap, true)


func dung_nhac() -> void:
	_nhac.stop()
	_bai_dang = ""


## Bài đang phát, hoặc rỗng. Để nơi khác hỏi mà không phải đọc biến riêng tư.
func bai_dang_phat() -> String:
	return _bai_dang if _nhac.playing else ""


# ------------------------------------------------------------------ nạp ---

## Tìm file theo tên, thử lần lượt các đuôi. Nhớ kết quả để không tra lại.
func _nap(ten: String, thu_muc: String) -> AudioStream:
	# Tên sự kiện -> tên file. Không có trong bảng thì dùng chính nó.
	var ten_f := String(TEN_FILE.get(ten, ten))

	for d in DUOI:
		var dd: String = thu_muc + ten_f + d
		if _kho.has(dd):
			if _kho[dd] != null:
				return _kho[dd]
			continue
		if ResourceLoader.exists(dd):
			var st := load(dd) as AudioStream
			_kho[dd] = st
			if st != null:
				return st

	# Cảnh báo ĐÚNG MỘT LẦN cho mỗi tên. Không chặn thì tiếng "nhặt đồ" thiếu
	# file sẽ in ra console mấy trăm dòng một màn và nhấn chìm mọi lỗi thật.
	if not _da_bao.has(ten):
		_da_bao[ten] = true
		print("[AmThanh] chưa có file cho '%s' (tìm '%s%s.*') — bỏ qua."
			% [ten, thu_muc, ten_f])
	# Ghi null cho mọi đuôi để lần sau khỏi dò lại ổ đĩa.
	for d in DUOI:
		_kho[thu_muc + ten_f + d] = null
	return null
