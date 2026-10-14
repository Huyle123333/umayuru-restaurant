class_name Lang
extends RefCounted
## Lang — lớp phụ cho bản dịch tiếng Anh.
##
## Khoá dịch là CHÍNH câu tiếng Việt gốc (bảng ở text_en.gd), không đặt tên
## khoá kiểu "DLG_ENDING_042": 700+ câu thoại mà phải đặt tên từng khoá thì
## vừa lâu vừa dễ lệch; dùng câu gốc làm khoá thì code hiện giờ không phải đổi
## dữ liệu nào, và bản tiếng Việt vẫn chạy y như cũ khi không có bản dịch.
##
## Bảng được nạp vào TranslationServer như một Translation bình thường của
## Godot. Nhờ vậy Label/Button/RichTextLabel tự dịch (auto translate) mọi chữ
## gán thẳng vào, kể cả chữ viết sẵn trong file .tscn. Lang.t() chỉ cần gọi ở
## những chỗ chữ bị GHÉP (format %d, nối chuỗi) trước khi tới Label — ghép
## xong thì chuỗi không còn khớp khoá nào nữa.

const TextEn := preload("res://scripts/locale/text_en.gd")


## Dịch một chuỗi theo ngôn ngữ đang chọn. Không có bản dịch thì trả nguyên.
## Hàm tĩnh nên gọi được cả trong static func (khác với Object.tr()).
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))


## Dựng Translation "en" từ bảng EN. SettingsManager gọi một lần lúc khởi động.
static func build_english() -> Translation:
	var translation := Translation.new()
	translation.locale = "en"
	for key in TextEn.EN:
		translation.add_message(key, TextEn.EN[key])
	return translation
