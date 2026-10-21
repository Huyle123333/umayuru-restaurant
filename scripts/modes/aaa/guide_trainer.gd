extends Node
## AAA MODE — TRAINER HƯỚNG DẪN LIÊN TỤC.
##
## Đứng yên hơn IDLE_SECONDS, hoặc quá STUCK_SECONDS mà không tiến thêm bước
## nào, thì hộp thoại trainer trượt vào với một lời nhắc. Lời nhắc LEO THANG
## theo số lần: lần đầu còn tử tế, lần thứ năm thì gạ mua DLC "làm hộ".
##
## Trainer chỉ HƯỚNG DẪN THAO TÁC (đi đâu, bấm gì) — không nói về màu sắc hay
## dấu hiệu trên màn hình. Mọi lời nhắc đều điền đúng tên trạm, hướng và
## khoảng cách thật: vừa đúng vừa thừa, đó là chỗ buồn cười.
##
## Dùng lại guide_panel.gd của màn hướng dẫn thay vì dựng hộp thoại mới: cùng
## một trainer, cùng một cái hộp — người chơi nhận ra ngay "lại là ông ấy".

signal offer_requested

const GuidePanel := preload("res://scripts/ui/guide_panel.gd")

const IDLE_SECONDS := 3.0
const STUCK_SECONDS := 6.0
const SHOW_SECONDS := 4.0

var nag_count := 0

var _panel: CanvasLayer
var _player: CharacterBody3D
var _idle := 0.0
var _stuck := 0.0
var _visible_left := 0.0
var _asking := false
var _last_text := ""
## Thông tin bước hiện tại do aaa_mode.gd đẩy vào.
var _step := ""
var _station := ""
var _key := ""
var _dir := ""
var _dist := 0.0
var _num := 1
var _total := 1


func setup(player: CharacterBody3D) -> void:
	_player = player
	_panel = GuidePanel.new()
	_panel.name = "AaaTrainer"
	get_parent().add_child.call_deferred(_panel)
	_panel.start_choice.connect(_on_choice)


func update_step(step: String, station: String, key: String, dir: String, dist: float,
		num: int, total: int) -> void:
	_num = maxi(num, 1)
	_total = maxi(total, 1)
	if step != _last_text:
		_last_text = step
		_stuck = 0.0
	_step = step
	_station = station
	_key = key
	_dir = dir
	_dist = dist


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if _visible_left > 0.0:
		_visible_left -= delta
		if _visible_left <= 0.0 and not _asking:
			_panel.close()
		return
	# Chưa có bước nào gắn với một trạm (đang chờ khách) thì chưa có gì để nhắc.
	if _player == null or _station.is_empty():
		return
	var v := _player.velocity
	if Vector2(v.x, v.z).length() < 0.3:
		_idle += delta
	else:
		_idle = 0.0
	_stuck += delta
	if _idle >= IDLE_SECONDS or _stuck >= STUCK_SECONDS:
		_idle = 0.0
		_stuck = 0.0
		_nag()


func _nag() -> void:
	nag_count += 1
	var line := _line_for(nag_count)
	if nag_count == 5:
		_asking = true
		_panel.ask(Lang.t("...Hay để tôi làm hộ?"), Lang.t("Có"), Lang.t("Không"))
	else:
		_panel.set_step(line, _num, _total)
	_panel.open()
	_visible_left = SHOW_SECONDS


func _line_for(n: int) -> String:
	var pick := n if n <= 4 else randi_range(1, 4)
	var line := ""
	match pick:
		1: line = Lang.t("Bước tiếp theo: %s. Nó ở %s.") % [_step, _dir]
		2: line = (Lang.t("Đi tới %s rồi bấm %s nhé.") % [_station, _key]) if not _key.is_empty() \
				else Lang.t("Đứng ở %s và chờ một chút nhé.") % _station
		3: line = Lang.t("%s cách bạn %d mét. Bạn chỉ cần đi về %s.") % [_station, int(roundf(_dist)), _dir]
		_: line = Lang.t("Mẹo: muốn tới %s thì phải đi tới chỗ %s.") % [_station, _station]
	if n > 5:
		line += " " + Lang.t("Tôi tin ở bạn!")
	return line


func _on_choice(yes: bool) -> void:
	_asking = false
	_panel.close()
	if yes:
		offer_requested.emit()
