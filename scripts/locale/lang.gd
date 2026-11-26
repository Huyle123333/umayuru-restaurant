class_name Lang
extends RefCounted

const TextEn := preload("res://scripts/locale/text_en.gd")


## Dịch một chuỗi theo ngôn ngữ đang chọn. Không có bản dịch thì trả nguyên.
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))


## Dựng Translation "en" từ bảng EN. SettingsManager gọi một lần lúc khởi động.
static func build_english() -> Translation:
	var translation := Translation.new()
	translation.locale = "en"
	for key in TextEn.EN:
		translation.add_message(key, TextEn.EN[key])
	return translation
