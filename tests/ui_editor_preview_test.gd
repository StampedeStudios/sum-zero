## Run with: godot --headless --editor --path . --script tests/ui_editor_preview_test.gd
extends SceneTree

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(Engine.is_editor_hint(), "Editor previews require --editor")
	var cases := 0
	for scene_name in ["MainMenu", "LevelUI", "LevelsPage", "LevelInspect", "CustomLevelInspect", "LevelImport", "PlayModeSelection", "PlayModeUI", "Options", "SplashScreen", "GameUI", "ArenaUI", "BuilderUI", "BuilderTest", "BuilderSave", "BuilderResize", "BuilderSelection", "LevelEnd", "ArenaEnd", "TutorialUI", "CreditsScreen"]:
		var ui := (load("res://packed_scene/user_interface/%s.tscn" % scene_name) as PackedScene).instantiate() as Control
		root.add_child(ui)
		for extent in [Vector2i(480, 853), Vector2i(640, 360)]:
			root.size = extent
			for frame in range(12):
				await process_frame
			_check(is_instance_valid(ui), scene_name + ": preview ran runtime cleanup")
			var panel := ui.get_node_or_null("%Panel") as Control
			if scene_name in ["LevelInspect", "CustomLevelInspect", "LevelImport", "PlayModeSelection", "BuilderSave", "LevelEnd", "ArenaEnd"]:
				_check(panel.size.x > 200 and panel.size.y > 200, scene_name + ": dialog collapsed")
				_check(panel.get_global_rect().get_center().is_equal_approx(ui.size / 2), scene_name + ": dialog not centered")
			_check(ui.get_node_or_null("EditorReference") == null, scene_name + ": mock reference must not exist")
			if scene_name in ["GameUI", "ArenaUI", "BuilderUI", "BuilderTest"]:
				var host := ui.get_node("%BoardHost") as Control
				_check(host.size.x > 100 and host.size.y > 100, scene_name + ": board region must remain identifiable")
			if scene_name == "BuilderSelection":
				for button_name in ["Backward", "Forward", "Special", "Remove"]:
					var button := ui.get_node("Control/" + button_name) as Button
					_check(ui.get_global_rect().encloses(button.get_global_rect()), "Selection control must have visible scene defaults")
			if scene_name == "SplashScreen":
				_check(ui.get_node("%SplashTop").frame == 16 and ui.get_node("%SplashBottom").frame == 16, "Splash must show completed logo")
				_check(ui.get_node("%SplashTop").scale.x > 0, "Splash logo must have size")
			if scene_name == "Options":
				_check(ui.get_node("%MusicBtn").icon != null, "Options toggle art missing")
			cases += 1
		ui.queue_free()
		await process_frame
	_check(root.get_node_or_null("GameManager") == null, "Preview must not need game autoloads")
	print("UI editor previews: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
