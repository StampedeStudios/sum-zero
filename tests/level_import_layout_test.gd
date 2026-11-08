## Run with: godot --headless --path . --script tests/level_import_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var game := root.get_node("GameManager")
	var ui := (load("res://packed_scene/user_interface/LevelImport.tscn") as PackedScene).instantiate() as Control
	root.add_child(ui)
	root.size = Vector2i(360, 640)
	await create_timer(0.25).timeout
	var cases := 0
	for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
		root.size = viewport_size
		for locale in ["en", "it", "de", "es", "fr", "pl"]:
			TranslationServer.set_locale(locale)
			await _settle()
			var context := "%s / %s" % [viewport_size, locale]
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.panel.get_global_rect()), context + ": panel exceeds viewport")
			_check(ui.panel.scale == Vector2.ONE, context + ": opening must ignore global UI scale")
			_check(ui.panel.get_global_rect().get_center().is_equal_approx(Vector2(root.size) / 2), context + ": panel not centered")
			for widget in [ui.level_name, ui.code, ui.paste, ui.save_btn]:
				_check(ui.panel.get_global_rect().encloses(widget.get_global_rect()), context + ": control exceeds panel")
			_check(not ui.code.get_global_rect().intersects(ui.paste.get_global_rect()), context + ": code overlaps paste")
			_check(ui.code.get_theme_color("font_color").is_equal_approx(Color(0.25098, 0.184314, 0.105882, 1)), context + ": field palette changed")
			cases += 1
	_check(ui.save_btn.disabled, "Empty import must disable save")
	ui._on_level_name_text_changed("Sample! ignored")
	_check(ui.level_name.text == "Sample", "Name filtering must be preserved")
	var valid_code: String = root.get_node("SaveManager")._persistent_save.levels_hash[0]
	ui._on_code_text_changed(valid_code)
	_check(ui.code.text == valid_code and not ui.save_btn.disabled, "Typed code must enable Save with name")
	_check(Encoder.decode(ui.code.text) != null, "Visible typed code must remain decodable")
	# No successful Save call: this test must never write player data.
	ui._on_code_text_changed("!")
	_check(ui.code.text.is_empty() and ui.save_btn.disabled, "Invalid characters must clear code")
	ui._on_code_text_changed("invalid")
	ui._on_save_btn_pressed()
	_check(ui.save_btn.disabled and ui.code.get_theme_color("font_color").is_equal_approx(Color.DARK_RED), "Invalid payload must show error")
	await create_timer(1.1).timeout
	_check(ui.code.text.is_empty() and ui.save_btn.disabled, "Error timeout must clear code")
	ui._on_code_text_changed("invalid")
	ui._on_save_btn_pressed()
	ui._on_code_text_changed(valid_code)
	await create_timer(1.1).timeout
	_check(ui.code.text == valid_code and not ui.save_btn.disabled, "Editing after error must cancel stale clear timer")
	_check(ui.paste.pressed.is_connected(ui._on_code_pressed), "Paste action disconnected")
	_check(ui.save_btn.pressed.is_connected(ui._on_save_btn_pressed), "Save action disconnected")
	# Closing with an active error must not leave a timer callback on a freed dialog.
	ui._show_error()
	ui.close()
	await _settle()
	_check(not is_instance_valid(ui), "Close must free dialog")
	print("Level import layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)
