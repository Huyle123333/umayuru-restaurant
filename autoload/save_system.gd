extends Node
## SaveSystem — đọc/ghi file save (Autoload #2, phải đứng SAU GameData).
## Dùng JSON cho dễ mở ra xem khi debug và dễ đưa ảnh vào báo cáo.
## File nằm ở user:// — trên Windows là %APPDATA%\Godot\app_userdata\<tên project>

const SAVE_PATH := "user://savegame.json"


func _ready() -> void:
	load_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Không mở được file save để ghi (mã lỗi %d)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(GameData.to_dict(), "\t"))
	file.close()


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(text)
	# File save có thể hỏng: tắt máy giữa chừng, sửa tay, phiên bản cũ...
	# Kiểm tra kiểu trước khi dùng để game không crash ngay lúc khởi động.
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("File save hỏng, bỏ qua và chơi từ đầu.")
		return false
	GameData.from_dict(data)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
