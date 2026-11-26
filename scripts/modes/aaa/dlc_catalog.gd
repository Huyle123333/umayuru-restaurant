extends RefCounted

## Thứ tự hiện trên dải quảng cáo.
const ORDER := ["starter", "characters", "cooking", "music", "skill"]

const PACKS := {
	"starter": {
		"title": "Starter Pack",
		"image": "res://assets/ui/dlc/starter.png",
		"price": 9.99,
		"desc": "Bao gồm Characters Pack và Skill Pack. Mua lẻ 22,98$ — mua gói chỉ 9,99$, tiết kiệm hơn 50%! Món hời lớn nhất cửa hàng.",
	},
	"characters": {
		"title": "Characters Pack",
		"image": "res://assets/ui/dlc/characters.png",
		"price": 14.99,
		"desc": "Mở khoá Special Week, Oguri Cap và toàn bộ dàn nhân vật. Lời thoại riêng bán sau.",
	},
	"cooking": {
		"title": "Cooking Pack",
		"image": "res://assets/ui/dlc/cooking.png",
		"price": 9.99,
		"desc": "Thêm bếp thứ hai, lò nướng, máy kem và đầy đủ công thức. Oguri đã thử và thấy vẫn chưa đủ.",
	},
	"music": {
		"title": "Music Pack",
		"image": "res://assets/ui/dlc/music.png",
		"price": 7.99,
		"desc": "Bản thu Kitasan hát live trong lúc đứng bếp. Đã gồm tiếng xèo xèo của chảo.",
	},
	"skill": {
		"title": "Skill Pack",
		"image": "res://assets/ui/dlc/skill.png",
		"price": 7.99,
		"desc": "Mở khoá kĩ năng của mọi nhân vật. Dù chuyện gì xảy ra, cà rốt vẫn giòn.",
	},
}

## Mức giảm khởi điểm và mức tăng thêm sau mỗi lần từ chối (phần trăm).
const BASE_DISCOUNT := 10
const STEP_DISCOUNT := 12
## Không bao giờ chạm 100%: "−99%" buồn cười hơn "miễn phí", và vẫn là đồ phải trả tiền.
const MAX_DISCOUNT := 99

static var refusals := 0


static func discount() -> int:
	return mini(BASE_DISCOUNT + refusals * STEP_DISCOUNT, MAX_DISCOUNT)


## Gọi khi vào màn chơi AAA (aaa_mode.setup). Gán = 1 chứ không cộng dồn:
static func advance_sale() -> void:
	refusals = 1


static func sale_price(id: String) -> float:
	var price := float(PACKS[id]["price"])
	return snappedf(price * (100 - discount()) / 100.0, 0.01)


## "9,99$ → 2,99$ (−70%)" — dùng dấu phẩy thập phân kiểu Việt; bản tiếng Anh
static func price_text(id: String, bbcode: bool, sale_size: int = 18) -> String:
	var old := _money(float(PACKS[id]["price"]))
	var now := _money(sale_price(id))
	if bbcode:
		return "[s]%s[/s]  [color=#d22a1f][font_size=%d]%s[/font_size][/color]" % [old, sale_size, now]
	return "%s → %s" % [old, now]


static func _money(v: float) -> String:
	var s := "%.2f" % v
	if TranslationServer.get_locale().begins_with("en"):
		return "$" + s
	return s.replace(".", ",") + "$"
