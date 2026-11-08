## Run with: godot --headless --editor --path . --script tests/ui_editor_preview_test.gd
# gdlint: disable=max-line-length
extends SceneTree

var _failures := 0


func _initialize() -> void:
	root.content_scale_size = Vector2i.ZERO
	_run.call_deferred()


func _run() -> void:
	_check(Engine.is_editor_hint(), "Editor previews require --editor")
	var shared_theme := load("res://assets/resources/themes/ui.tres") as Theme
	var touch_script := load("res://scripts/user_interface/touch_button.gd") as Script
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
			for node: Node in ui.find_children("*", "Button", true, false):
				var button := node as Button
				var variation := button.theme_type_variation
				if button.get_script() == touch_script:
					_check(button.size.x >= 56 and button.size.y >= 56, scene_name + ": panel action must meet touch minimum")
					if button.icon != null and button.text.is_empty() and variation != &"InspectCopy":
						_check(button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, scene_name + ": icon-only panel action must center its icon")
				if variation == &"LevelTile":
					_check(button.expand_icon and button.get_theme_constant("icon_max_width") == 0, "Level preview icons must fit the tile without a small shared icon cap")
				if variation == &"LevelTileLocked":
					_check(button.get_theme_constant("icon_max_width") == 40, "Lock preview must use the smaller themed icon size")
					_check(button.get_theme_color("icon_disabled_color").is_equal_approx(Color(0.62, 0.55, 0.45, 1)), "Lock preview must use the softer tint")
				_check(not button.has_theme_font_override("font") and not button.has_theme_font_size_override("font_size"), scene_name + ": button typography must come from shared theme")
				for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
					_check(not button.has_theme_stylebox_override(state), scene_name + ": button styling must come from shared theme")
					var style_type := variation if not variation.is_empty() else StringName(button.get_class())
					while not shared_theme.has_stylebox(state, style_type) and style_type != &"Button":
						style_type = shared_theme.get_type_variation_base(style_type)
						if style_type.is_empty():
							style_type = &"Button"
					var expected := shared_theme.get_stylebox(state, style_type)
					_check(button.get_theme_stylebox(state) == expected, scene_name + ": button state must resolve shared theme: " + str(variation) + "/" + str(state))
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
			if scene_name == "LevelUI":
				var host := ui.get_node("%PageHost") as Control
				var current := ui.get_node("%Pages").get_child(1) as Control
				var grid := current.get_node("%LevelGrid") as GridContainer
				_check(current.size.is_equal_approx(host.size), "Editor page must fill host")
				_check(current.global_position.is_equal_approx(host.global_position), "Editor page must align with host")
				_check(host.get_global_rect().grow(1).encloses(grid.get_global_rect()), "Editor grid must fit host")
				_check(grid.size.x >= 168, "Editor grid must not collapse")
				_check((grid.get_child(0) as Button).text == "1", "Preview must provide numbered sample levels")
				_check((grid.get_child(4) as Button).disabled, "Preview must provide locked sample levels")
				var builder := ui.get_node("%BuilderBtn") as Button
				for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
					_check(builder.get_theme_stylebox(state) is StyleBoxEmpty, "Build a level shortcut must stay icon-only in every state")
			if scene_name == "TutorialUI":
				var content := ui.get_node("%Content") as BoxContainer
				var illustration := ui.get_node("%TextureRect") as TextureRect
				_check(content.vertical, "Tutorial editor layout must keep text above image")
				_check(illustration.size.y >= content.size.y * 0.5 and ui.get_global_rect().encloses(illustration.get_global_rect()), "Tutorial illustration must have visible editor bounds")
				_check(ui.get_node("%NextBtn").size.y <= 64, "Tutorial editor button must stay compact")
			cases += 1
		ui.queue_free()
		await process_frame
	# The theme, rather than a fixed scene override, controls touch bounds live.
	var touch := Button.new()
	touch.set_script(touch_script)
	touch.theme = shared_theme.duplicate() as Theme
	touch.theme_type_variation = &"PanelIcon"
	root.add_child(touch)
	var icon_limit := touch.get_theme_constant("icon_max_width")
	touch.theme.set_constant("touch_minimum_height", "Button", 72)
	touch.theme.set_constant("touch_minimum_width", "Button", 64)
	await process_frame
	_check(touch.get_combined_minimum_size().is_equal_approx(Vector2(64, 72)), "Theme edits must update touch minimums")
	_check(touch.get_theme_constant("icon_max_width") == icon_limit, "Touch bounds must not enlarge icons")
	touch.theme.set_constant("touch_minimum_height", "Button", 56)
	touch.theme.set_constant("touch_minimum_width", "Button", 56)
	await process_frame
	_check(touch.get_combined_minimum_size().is_equal_approx(Vector2(56, 56)), "Touch minimum must shrink again after theme edits")
	touch.queue_free()
	await process_frame
	_check(root.get_node_or_null("GameManager") == null, "Preview must not need game autoloads")
	print("UI editor previews: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
