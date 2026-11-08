## Run with: godot --headless --path . --script tests/level_menu_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var game := root.get_node("GameManager")
	var saves := root.get_node("SaveManager")
	# All custom fixtures are in-memory: never call persistence methods.
	var original_save: Resource = saves._player_save
	saves._player_save = original_save.duplicate(true)
	saves._player_save._persistent = saves._persistent_save
	var scene := load("res://packed_scene/user_interface/LevelUI.tscn") as PackedScene
	var cases := 0
	for world in [Constants.LevelGroup.MAIN, Constants.LevelGroup.CUSTOM]:
		game.reset_active_level_id()
		var ui := scene.instantiate() as Control
		ui.set_context(world)
		game.level_ui = ui
		root.add_child(ui)
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
			root.size = viewport_size
			for locale in ["en", "it", "de", "es", "fr", "pl"]:
				TranslationServer.set_locale(locale)
				await _settle()
				_check_layout(ui, "%s / %s / %s" % [world, viewport_size, locale])
				cases += 1
		_check(ui.builder_btn.visible == (world == Constants.LevelGroup.CUSTOM), "Builder visibility must match context")
		if world == Constants.LevelGroup.MAIN:
			ui._current_page = 1
			ui._check_pages()
			ui._init_pages()
			ui._layout_pages()
			_check(ui.left.disabled, "First page must disable previous")
			ui._on_right_pressed()
			await create_timer(0.25).timeout
			await _settle()
			_check(ui._current_page == 2, "Next must advance one page")
			_check(ui._levels_page[1]._levels[0].text == "10" or ui._levels_page[1]._levels[0].disabled, "Recycled current page must contain correct level")
			_check_layout(ui, "After next")
			ui._on_left_pressed()
			await create_timer(0.25).timeout
			await _settle()
			_check(ui._current_page == 1, "Previous must restore first page")
			ui._on_right_pressed()
			root.size = Vector2i(360, 640)
			await _settle()
			await create_timer(0.25).timeout
			_check(ui._current_page == 1 and not ui._has_movement, "Resize must cancel transition without advancing")
			_check_layout(ui, "Resize during transition")
			# Exercise swipe start, click suppression, and resize cancellation.
			ui._on_pages_drag()
			ui._start_drag = ui.get_global_mouse_position().x + ui._page_width / 3
			ui._process(0.0)
			_check(ui._has_drag and ui.has_consumed_input, "Swipe must suppress level activation")
			root.size = Vector2i(640, 360)
			await _settle()
			_check(not ui._has_drag and not ui.has_consumed_input, "Resizing must cancel drag cleanly")
			_check_layout(ui, "Resize during swipe")
			ui._current_page = ui._num_pages
			ui._check_pages()
			ui._init_pages()
			ui._layout_pages()
			await _settle()
			_check(ui.right.disabled, "Last page must disable next")
			_check_layout(ui, "Last campaign page")
			# Reused tiles must reset both directions between locked and empty.
			var tile: Button = ui._levels_page[1]._levels[0]
			tile.construct(0, true, 0)
			_check(tile.disabled, "Locked tile must be disabled")
			_check(tile.theme_type_variation == &"LevelTileLocked" and tile.get_theme_constant("icon_max_width") == 40, "Locked tile must use smaller themed icon")
			_check(tile.get_theme_color("icon_disabled_color").is_equal_approx(Color(0.62, 0.55, 0.45, 1)), "Locked tile must retain softer tint")
			_check(tile.get_theme_stylebox("disabled") != tile.get_theme_stylebox("normal"), "Locked tile must have a distinct unavailable background")
			tile.construct_empty()
			_check(not tile.disabled and tile.text.is_empty(), "Import tile must clear previous lock")
			tile.construct(0, false, 3)
			_check(not tile.disabled and tile.text == "1", "Unlocked tile must restore number")
			for stars in range(4):
				tile.construct(0, false, stars)
				var texture_path: String = [tile.ZERO_STARS, tile.ONE_STAR, tile.TWO_STARS, tile.THREE_STARS][stars]
				_check(tile.icon.resource_path == texture_path, "Star rating must retain its original texture")
				for color_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
					_check(tile.get_theme_color(color_name).is_equal_approx(Color.WHITE), "Star texture must retain gold colors in every enabled state")
		else:
			for count in [0, 8, 9, 10, 18]:
				var hashes: Array[String] = []
				for i in range(count):
					var hash_value: String = saves._persistent_save.levels_hash[i]
					hashes.append(hash_value)
					saves._player_save.custom_progress[hash_value] = Vector3i(1, 0, -3)
				saves._player_save.custom_levels_hash = hashes
				ui._refresh_next()
				_check(ui._num_pages == ceili(float(count + 1) / 9), "Custom pagination must reserve import slot")
				ui._current_page = ui._num_pages
				ui._check_pages()
				ui._init_pages()
				ui._layout_pages()
				await _settle()
				var tiles: Array = ui._levels_page[1]._levels
				_check(not tiles[count % 9].disabled and tiles[count % 9].text.is_empty(), "Custom import slot must be enabled after recycling locked tiles")
				_check_layout(ui, "Custom count=%s" % count)
			# Deleting from the final page must clamp and refresh the current page.
			saves._player_save.custom_levels_hash.clear()
			ui._refresh_next()
			_check(ui._current_page == 1 and ui._num_pages == 1, "Shrinking custom list must clamp page")
		ui.queue_free()
		await _settle()
	saves._player_save = original_save
	print("Level menu layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _check_layout(ui: Control, context: String) -> void:
	var ink := Color(0.25098, 0.184314, 0.105882, 1)
	_check(ui.title.get_theme_color("font_color").is_equal_approx(ink), context + ": page number must use dark text")
	for button in [ui.exit_btn, ui.left, ui.right, ui.builder_btn]:
		_check(button.get_theme_color("font_color").is_equal_approx(ink), context + ": button text must use dark ink")
		_check(button.get_theme_color("icon_normal_color").is_equal_approx(ink), context + ": navigation icon must use dark ink")
	var host: Control = ui.page_host
	var page: Control = ui._levels_page[1]
	_check(page.get_global_rect().is_equal_approx(host.get_global_rect()), context + ": current page not aligned")
	_check(host.clip_contents, context + ": page region must clip neighbors")
	var grid: Control = page.level_grid
	_check(host.get_global_rect().grow(0.1).encloses(grid.get_global_rect()), context + ": grid exceeds host")
	_check(grid.get_global_rect().get_center().distance_to(host.get_global_rect().get_center()) <= 1.0, context + ": grid not centered")
	for tile in page._levels:
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			_check(tile.get_theme_color(color_name).is_equal_approx(ink), context + ": level number must remain dark")
		_check(host.get_global_rect().grow(0.1).encloses(tile.get_global_rect()), context + ": tile exceeds host")
		_check(not tile.get_global_rect().intersects(ui.exit_btn.get_global_rect()), context + ": tile overlaps header")
		_check(not tile.get_global_rect().intersects(ui.title.get_global_rect()), context + ": tile overlaps navigation")
	for widget in [ui.exit_btn, ui.left, ui.right, ui.title, ui.builder_btn]:
		if widget.visible:
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(0.1).encloses(widget.get_global_rect()), context + ": control offscreen")
