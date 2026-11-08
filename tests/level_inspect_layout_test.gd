## Run with: godot --headless --path . --script tests/level_inspect_layout_test.gd
extends SceneTree

var _failures := 0


func _initialize() -> void:
	root.child_entered_tree.connect(func(child: Node) -> void:
		if child.name == "SplashScreen":
			child.set_script(null)
	)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var splash := root.get_node_or_null("SplashScreen")
	if splash:
		splash.queue_free()
	await process_frame
	root.get_node("AudioManager")._is_sfx_on = false
	var saves := root.get_node("SaveManager")
	var original: Resource = saves._player_save
	saves._player_save = original.duplicate(true)
	saves._player_save._persistent = saves._persistent_save
	var hashes: Array[String] = [saves._persistent_save.levels_hash[0]]
	saves._player_save.custom_levels_hash = hashes
	var game := root.get_node("GameManager")
	var old_scale: Vector2 = game.ui_scale
	game.ui_scale = Vector2(2, 2)
	var cases := 0
	for custom in [false, true]:
		var path := "res://packed_scene/user_interface/CustomLevelInspect.tscn" if custom else "res://packed_scene/user_interface/LevelInspect.tscn"
		var ui := (load(path) as PackedScene).instantiate() as Control
		root.add_child(ui)
		var progress := LevelProgress.new()
		progress.name = "LongCustomLevelNameThatMustWrap"
		progress.is_unlocked = true
		progress.is_completed = true
		progress.move_left = 0
		ui.init_inspector(0, progress)
		await create_timer(0.25).timeout
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(640, 360)]:
			root.size = viewport_size
			for locale in ["en", "it", "de", "es", "fr", "pl"]:
				TranslationServer.set_locale(locale)
				await _settle()
				var context := "custom=%s / %s / %s" % [custom, viewport_size, locale]
				var panel: Control = ui.panel
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.get_global_rect()), context + ": panel offscreen")
				_check(panel.scale == Vector2.ONE, context + ": animation must ignore global UI scale")
				_check(panel.get_global_rect().get_center().is_equal_approx(Vector2(root.size) / 2), context + ": panel not centered")
				for widget in [ui.label, ui.build_btn, ui.play_btn, ui.get_node("%Stars")]:
					_check(panel.get_global_rect().encloses(widget.get_global_rect()), context + ": content exceeds panel")
				_check(ui.label.get_theme_color("font_color").is_equal_approx(Color(0.25098, 0.184314, 0.105882, 1)), context + ": title palette changed")
				_check(not ui.label.get_global_rect().intersects(ui.get_node("%Stars").get_global_rect()), context + ": title overlaps stars")
				if custom:
					for widget in [ui.copy_btn, ui.delete_btn]:
						_check(panel.get_global_rect().encloses(widget.get_global_rect()), context + ": custom control offscreen")
				cases += 1
		_check(ui.build_btn.pressed.is_connected(ui._on_build_btn_pressed), "Edit action disconnected")
		_check(ui.play_btn.pressed.is_connected(ui._on_play_btn_pressed), "Play action disconnected")
		for stars in range(5):
			progress.move_left = stars - 3
			ui.init_inspector(0, progress)
			_check(ui.left_star.visible == (stars >= 1), "Left star rating incorrect")
			_check(ui.middle_star.visible == (stars >= 2), "Middle star rating incorrect")
			_check(ui.right_star.visible == (stars >= 3), "Right star rating incorrect")
		progress.is_completed = false
		progress.is_unlocked = false
		ui.init_inspector(0, progress)
		_check(not ui.left_star.visible and not ui.middle_star.visible and not ui.right_star.visible, "Incomplete level must clear all earned stars")
		if not custom:
			_check(ui.build_btn.disabled and ui.play_btn.disabled, "Campaign access rules must remain intact")
		else:
			_check(ui.copy_btn.text.strip_edges() == ui._level_code, "Copy must display the encoded level")
			_check(ui.copy_btn.pressed.is_connected(ui._on_copy_btn_pressed), "Copy action disconnected")
			var deleted := [false]
			ui.level_deleted.connect(func() -> void: deleted[0] = true)
			ui._on_delete_btn_pressed()
			_check(deleted[0], "Delete must emit the existing signal")
		if not custom:
			ui.close()
		await _settle()
		_check(not is_instance_valid(ui), "Closing must free inspector")
	# Resize during the opening animation; do not use a cached panel center.
	var opening := (load("res://packed_scene/user_interface/LevelInspect.tscn") as PackedScene).instantiate() as Control
	root.add_child(opening)
	root.size = Vector2i(360, 640)
	await create_timer(0.25).timeout
	await _settle()
	_check(opening.panel.get_global_rect().get_center().is_equal_approx(Vector2(root.size) / 2), "Opening animation must follow resize")
	opening.close()
	await _settle()
	game.ui_scale = old_scale
	saves._player_save = original
	print("Level inspect layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _settle() -> void:
	for frame in range(10):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
