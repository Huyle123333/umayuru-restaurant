extends Control
## Menu chính của UMAYURU RESTAURANT.
## Chỉ làm hai việc: nối các nút với hành động, và tạo hiệu ứng rê chuột.
## Nội dung của từng bảng (Credits, Cài đặt...) nằm trong scene riêng của nó.

const HOVER_SCALE := 1.06
## Nút CODE No.7 để mờ khi không rê chuột vào, cho khỏi hút mắt.
const CODE_IDLE_ALPHA := 0.55

@export_file("*.tscn") var level_select_scene: String = "res://scenes/menu/level_select.tscn"
@export_file("*.tscn") var character_select_scene: String = "res://scenes/menu/character_select.tscn"

@onready var _btn_new: Button = %BtnNew
@onready var _btn_levels: Button = %BtnLevels
@onready var _btn_options: Button = %BtnOptions
@onready var _btn_quit: Button = %BtnQuit

@onready var _btn_code: TextureButton = %BtnCode

@onready var _credits: Control = %CreditsPanel
@onready var _cheat: Control = %CheatPanel
@onready var _options: Control = %OptionsPanel
@onready var _settings: Control = %SettingsPanel


func _ready() -> void:
	# Nhạc menu: bốc ngẫu nhiên MỘT lần cho cả cụm menu.
	#
	# giu_lien_mach = true nghĩa là nếu bài đang phát đã thuộc nhóm "menu" thì
	# không đổi gì cả. Người chơi bấm Menu chính → Chọn màn → Chọn nhân vật →
	# quay lại, cả bốn màn hình dùng chung một bài đang chạy dở. Bốc lại ở mỗi
	# màn hình thì chỉ cần bấm qua lại vài lần là nhạc giật liên tục.
	AmThanh.play_random_music("menu", true)

	_btn_new.pressed.connect(_on_new_pressed)
	_btn_levels.pressed.connect(_on_levels_pressed)
	_btn_options.pressed.connect(_on_options_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

	# Ba mục trong bảng Tuỳ chọn báo NGƯỢC lên đây bằng tín hiệu. Bảng đó
	# không biết Cài đặt hay Credits nằm ở node nào — xem options_panel.gd.
	_options.chon_huong_dan.connect(_on_guide_pressed)
	_options.chon_cai_dat.connect(_on_settings_pressed)
	_options.chon_credits.connect(_on_credits_pressed)

	for btn in [_btn_new, _btn_levels, _btn_options, _btn_quit]:
		_setup_hover(btn)

	# Nút CODE No.7 ở góc dưới phải — công cụ cho người phát triển.
	_btn_code.pressed.connect(_on_code_pressed)
	_btn_code.mouse_entered.connect(_fade_code.bind(1.0))
	_btn_code.mouse_exited.connect(_fade_code.bind(CODE_IDLE_ALPHA))
	_btn_code.modulate.a = CODE_IDLE_ALPHA

	# Bản xuất ra web không thoát được, ẩn nút đi cho gọn.
	if OS.has_feature("web"):
		_btn_quit.hide()

	# Focus sẵn nút đầu tiên để chơi được bằng bàn phím / tay cầm.
	_btn_new.grab_focus()


# ------------------------------------------------------- hiệu ứng rê chuột ---

func _setup_hover(btn: Button) -> void:
	# Phải chờ container sắp xếp xong mới biết kích thước thật của nút,
	# nên vừa gọi ngay vừa nối vào tín hiệu resized.
	btn.resized.connect(_center_pivot.bind(btn))
	_center_pivot(btn)

	btn.mouse_entered.connect(_scale_to.bind(btn, HOVER_SCALE))
	btn.mouse_exited.connect(_scale_to.bind(btn, 1.0))
	btn.focus_entered.connect(_scale_to.bind(btn, HOVER_SCALE))
	btn.focus_exited.connect(_scale_to.bind(btn, 1.0))


func _center_pivot(btn: Button) -> void:
	# Không có dòng này thì nút phóng to từ góc trên trái, nhìn như bị lệch.
	btn.pivot_offset = btn.size / 2.0


func _scale_to(btn: Button, target: float) -> void:
	# Dùng scale chứ không dùng position: nút nằm trong VBoxContainer,
	# mà container tự đặt lại position của node con mỗi lần sắp xếp.
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(target, target), 0.12)


# ------------------------------------------------------------ hành động nút ---

func _on_new_pressed() -> void:
	GameData.current_level = "prologue"
	# Nhớ đường về, để nút "Trở lại" ở màn chọn nhân vật quay lại đúng đây.
	GameData.return_scene = scene_file_path
	get_tree().change_scene_to_file(character_select_scene)


func _on_levels_pressed() -> void:
	get_tree().change_scene_to_file(level_select_scene)


## Mở menu hướng dẫn (cũng chính là thứ phím F1 mở trong màn chơi).
##
## Gọi thẳng autoload `HuongDan` chứ không dựng một bảng riêng cho menu chính:
## nội dung hướng dẫn phải giống hệt nhau ở hai chỗ, mà hai bản sao thì sớm
## muộn cũng lệch — sửa một câu trong bảng công thức rồi quên bản kia.
##
## Autoload nên nó sống sẵn từ lúc game khởi động, kể cả khi chưa vào màn nào.
## `mo()` tự nhớ trạng thái tạm dừng cũ rồi khôi phục lúc đóng, nên gọi từ menu
## chính (vốn không tạm dừng) cũng không để lại game bị treo.
func _on_guide_pressed() -> void:
	_options.close()
	HuongDan.open()


## Mở bảng Tuỳ chọn.
func _on_options_pressed() -> void:
	_options.open(_btn_options)


## Ba hàm dưới đây được gọi TỪ BẢNG TUỲ CHỌN, không phải từ nút trên menu nữa.
##
## Mỗi hàm đóng bảng Tuỳ chọn trước khi mở bảng con, và trao focus về thẳng nút
## "Tuỳ chọn" trên menu chính.
##
## Vì sao đóng chứ không để hai bảng chồng lên nhau: cả hai đều là lớp phủ kín
## màn hình có nền tối và đều tự bắt phím ESC. Chồng lên nhau thì nền tối cộng
## dồn thành gần như đen đặc, và một cú ESC có thể đóng cả hai cùng lúc —
## thứ tự nhận phím giữa hai node anh em phụ thuộc vào vị trí trong cây scene,
## tức là một hành vi đúng hôm nay và sai sau lần kéo thả node tiếp theo.
func _on_settings_pressed() -> void:
	_options.close()
	_settings.open(_btn_options)


func _fade_code(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_btn_code, "modulate:a", alpha, 0.15)


func _on_code_pressed() -> void:
	_cheat.open(_btn_code)


func _on_credits_pressed() -> void:
	_options.close()
	_credits.open(_btn_options)


func _on_quit_pressed() -> void:
	get_tree().quit()
