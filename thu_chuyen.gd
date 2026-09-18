extends Node
func _ready() -> void:
	print("[THU] selected_character = '", GameData.selected_character, "'")
	print("[THU] duong_dan_scene('tutorial') = '", GameData.duong_dan_scene("tutorial"), "'")
	GameData.complete_level("prologue")
	GameData.current_level = "tutorial"
	var d := GameData.duong_dan_scene("tutorial")
	print("[THU] sap doi scene sang: ", d, " ton tai=", ResourceLoader.exists(d))
	var kq := get_tree().change_scene_to_file(d)
	print("[THU] change_scene_to_file tra ve: ", kq)
	await get_tree().create_timer(1.0).timeout
	var cs := get_tree().current_scene
	print("[THU] current_scene = ", cs)
	if cs != null:
		print("[THU] camera dang bat = ", get_viewport().get_camera_3d())
