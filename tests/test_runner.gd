extends Node
## Bộ chạy kiểm thử tự động. Chạy scene tests/test_runner.tscn (F6 trong
## editor, hoặc: godot --headless res://tests/test_runner.tscn).
## Kết quả in ra Output và ghi vào user://test_report.txt, rồi tự thoát
## với mã 0 (tất cả đạt) hoặc 1 (có ca trượt) khi chạy --headless (dùng cho CI).

const TEST_DIR := "res://tests/unit/"

var _lines: PackedStringArray = []


func _ready() -> void:
	# Đợi một khung hình để mọi autoload (GameData, SaveSystem…) dựng xong.
	await get_tree().process_frame
	var passed := 0
	var failed := 0
	var asserts := 0
	var started := Time.get_ticks_msec()
	_log("===== UMAYURU RESTAURANT · AUTOMATED TESTS =====")
	for file in _test_files():
		var suite: Node = load(TEST_DIR + file).new()
		add_child(suite)
		_log("\n▶ %s" % file)
		for m in suite.get_method_list():
			var name_ := String(m["name"])
			if not name_.begins_with("test_"):
				continue
			var errors: Array[String] = suite.run_case(name_)
			if errors.is_empty():
				passed += 1
				_log("  ✓ %s" % name_)
			else:
				failed += 1
				_log("  ✗ %s" % name_)
				for e in errors:
					_log("      - %s" % e)
		asserts += int(suite._asserts)
		suite.queue_free()
	_log("\n===== RESULT: %d passed, %d failed, %d assertions, %d ms =====" % [
		passed, failed, asserts, Time.get_ticks_msec() - started])
	_write_report()
	await _show_board(passed, failed, asserts)
	# Chạy không giao diện (dòng lệnh/CI) thì tự thoát với mã lỗi; chạy trong
	# editor thì giữ cửa sổ mở để còn đọc Output.
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0 if failed == 0 else 1)


## Mọi file test_*.gd trong thư mục unit, xếp theo tên cho thứ tự cố định.
func _test_files() -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(f)
	out.sort()
	return out


func _log(text: String) -> void:
	print(text)
	_lines.append(text)


## Ghi báo cáo vào user:// và, khi chạy từ mã nguồn (chưa xuất bản), vào cả
## thư mục tests/ cho dễ mở và đính kèm báo cáo.
func _write_report() -> void:
	var paths := ["user://test_report.txt"]
	if not OS.has_feature("template"):
		paths.append("res://tests/test_report.txt")
	for path in paths:
		var f := FileAccess.open(path, FileAccess.WRITE)
		print("Report %s → %s" % [ProjectSettings.globalize_path(path), "OK" if f != null else error_string(FileAccess.get_open_error())])
		if f != null:
			f.store_string("\n".join(_lines))
			f.close()


# ------------------------------------------------------------ bảng kết quả ---

## Vẽ kết quả lên màn hình rồi chụp lại thành ảnh, để đính kèm báo cáo.
func _show_board(passed: int, failed: int, asserts: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("1e1a17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 60.0
	text.offset_top = 40.0
	text.offset_right = -60.0
	text.offset_bottom = -40.0
	text.add_theme_font_size_override("normal_font_size", 19)
	text.add_theme_font_size_override("bold_font_size", 26)
	layer.add_child(text)
	var color_ok := "8fe388" if failed == 0 else "de6459"
	var bb := "[b][color=ffd76a]UMAYURU RESTAURANT · AUTOMATED TESTS[/color][/b]   [color=9c8b7a]%s · Godot %s[/color]\n\n" % [
		Time.get_datetime_string_from_system(false, true), Engine.get_version_info()["string"]]
	# Chia hai cột để 42 ca vừa một màn hình.
	var body: PackedStringArray = []
	for line in _lines:
		if line.strip_edges().begins_with("=====") or line.strip_edges().is_empty():
			continue
		if line.begins_with("\n▶") or line.begins_with("▶"):
			body.append("[color=ffd76a][b]%s[/b][/color]" % line.strip_edges())
		elif line.strip_edges().begins_with("✓"):
			body.append("[color=8fe388]%s[/color]" % line)
		else:
			body.append("[color=de6459]%s[/color]" % line)
	var half := int(ceil(body.size() / 2.0))
	bb += "[table=2][cell]%s[/cell][cell]%s[/cell][/table]" % [
		"\n".join(body.slice(0, half)), "\n".join(body.slice(half))]
	bb += "\n\n[b][color=%s]RESULT: %d passed · %d failed · %d assertions[/color][/b]" % [
		color_ok, passed, failed, asserts]
	text.text = bb
	# Đợi hai khung hình để chữ được vẽ xong rồi mới chụp.
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	for path in ["user://test_report.png", "res://tests/test_report.png"]:
		var err := img.save_png(path)
		print("Screenshot %s → %s (%s)" % [path, ProjectSettings.globalize_path(path), error_string(err)])
