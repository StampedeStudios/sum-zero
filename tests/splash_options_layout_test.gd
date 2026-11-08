## Run with: godot --headless --path . --script tests/splash_options_layout_test.gd
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
	root.get_node("SplashScreen").queue_free()
	await process_frame
	root.get_node("AudioManager")._is_sfx_on = false
	root.get_node("AudioManager")._is_music_on = false
	var save := root.get_node("SaveManager")
	var options_before: String = var_to_str(save.get_options())
	var ui := (load("res://packed_scene/user_interface/Options.tscn") as PackedScene).instantiate() as Control
	root.add_child(ui)
	_check(ui.music_btn.button_pressed == save.get_options().music_on, "Music initialization changed")
	_check(ui.sfx_btn.button_pressed == save.get_options().sfx_on, "SFX initialization changed")
	_check(ui.tutorial_btn.button_pressed == save.get_options().tutorial_on, "Tutorial initialization changed")
	_check(ui.options_btn.selected == Constants.AVAILABLE_LANGS.find(save.get_options().language), "Language initialization changed")
	_check(ui.options_btn.item_selected.is_connected(ui._on_option_button_item_selected), "Language action disconnected")
	_check(ui.exit_btn.pressed.is_connected(ui._on_exit_btn_pressed), "Back action disconnected")
	_check(ui.link_button.pressed.is_connected(ui._on_link_button_pressed), "Credits action disconnected")
	# Verify persistence connections, then isolate visual toggling from disk/audio.
	var buttons: Array = [ui.music_btn, ui.sfx_btn, ui.tutorial_btn]
	var handlers: Array = [ui._on_music_btn_toggled, ui._on_sfx_btn_toggled, ui._on_tutorial_btn_toggled]
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		_check(button.toggled.is_connected(handlers[index]), "Toggle persistence action disconnected")
		button.toggled.disconnect(handlers[index])
		button.button_pressed = true
		_check(button.icon == ui.TOGGLE_ON, "Enabled art incorrect")
		button.button_pressed = false
		_check(button.icon == ui.TOGGLE_OFF, "Disabled art incorrect")
	var splash := (load("res://packed_scene/user_interface/SplashScreen.tscn") as PackedScene).instantiate() as Control
	splash.name = "LayoutSplash"
	Engine.time_scale = 0.01
	root.add_child(splash)
	_check(splash.version_label.text == ProjectSettings.get("application/config/version"), "Version missing")
	var cases := 0
	for viewport_size in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(480, 853), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(640, 360)]:
		root.size = viewport_size
		for locale in ["en", "it", "de", "es", "fr", "pl"]:
			TranslationServer.set_locale(locale)
			await _settle()
			var context := "%s / %s" % [viewport_size, locale]
			var viewport := Rect2(Vector2.ZERO, Vector2(root.size))
			var scroll: ScrollContainer = ui.get_node("%ScrollContainer")
			_check(viewport.encloses(ui.exit_btn.get_global_rect()), context + ": Back offscreen")
			_check(viewport.encloses(scroll.get_global_rect()), context + ": scroll host offscreen")
			_check(not ui.exit_btn.get_global_rect().intersects(scroll.get_global_rect()), context + ": Back overlaps content")
			for button: Button in buttons:
				_check(button.global_position.x >= scroll.global_position.x and button.get_global_rect().end.x <= scroll.get_global_rect().end.x, context + ": toggle exceeds host width")
			for label: Label in [ui.music_label, ui.sfx_label, ui.tutorial_label]:
				_check(not label.get_global_rect().intersects(label.get_parent().get_child(1).get_global_rect()), context + ": label overlaps toggle")
			ui.options_btn.show_popup()
			await _settle()
			var popup: PopupMenu = ui.options_btn.get_popup()
			_check(popup.item_count == 6, context + ": language list changed")
			_check(popup.get_theme_font_size("font_size") == 24, context + ": popup font is not themed")
			_check(popup.size.x <= root.size.x and popup.size.y <= root.size.y, context + ": language popup exceeds window")
			popup.hide()
			scroll.scroll_vertical = 10000
			await _settle()
			_check(scroll.get_global_rect().grow(1).encloses(ui.link_button.get_global_rect()), context + ": Credits unreachable at scroll end: %s in %s" % [ui.link_button.get_global_rect(), scroll.get_global_rect()])
			scroll.scroll_vertical = 0
			_check(viewport.encloses(splash.version_label.get_global_rect()), context + ": version offscreen")
			for sprite: AnimatedSprite2D in [splash.splash_top, splash.splash_bottom]:
				var frame_size := sprite.sprite_frames.get_frame_texture("default", 0).get_size() * sprite.scale
				var bounds := Rect2(sprite.global_position - frame_size / 2, frame_size)
				_check(splash.logo_host.get_global_rect().encloses(bounds), context + ": logo outside host")
				_check(not bounds.intersects(splash.version_label.get_global_rect()), context + ": logo overlaps version")
			_check(is_equal_approx(splash.splash_top.position.x, splash.logo_host.size.x / 2), context + ": logo not centered")
			cases += 1
	_check(var_to_str(save.get_options()) == options_before, "Layout test changed player options")
	# Exercise the real animation and skip path, including start() and cleanup.
	splash.tree_exiting.connect(func() -> void:
		_check(splash.splash_top.frame == 16 and splash.splash_bottom.frame == 16, "Both logo animations must finish")
	)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	splash.get_node("ColorRect").gui_input.emit(click)
	_check(Engine.time_scale == 5, "Click must speed up splash")
	await splash.tree_exited
	_check(Engine.time_scale == 1, "Splash completion must restore time scale")
	await _settle()
	_check(root.get_node_or_null("MainMenu") != null, "Splash completion must start main menu")
	ui.queue_free()
	await _settle()
	print("Splash and Options layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _settle() -> void:
	for frame in range(8):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
