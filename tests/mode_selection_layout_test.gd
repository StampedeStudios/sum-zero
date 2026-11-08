## Run with: godot --headless --path . --script tests/mode_selection_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var ui := (load("res://packed_scene/user_interface/PlayModeSelection.tscn") as PackedScene).instantiate() as Control
	root.add_child(ui)
	ui.setup()
	await _settle()
	ui.setup()
	await _settle()
	_check(ui.hbox_container.get_child_count() == ui.arena_modes.size(), "Repeated setup must not duplicate cards")
	var cases := 0
	for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
		root.size = viewport_size
		for locale in ["en", "it", "de", "es", "fr", "pl"]:
			TranslationServer.set_locale(locale)
			ui.setup()
			await _settle()
			for index in range(ui.arena_modes.size()):
				ui._select_mode(index, false)
				await _settle()
				var context := "%s / %s / mode=%d" % [viewport_size, locale, index]
				var card: Control = ui.hbox_container.get_child(index)
				_check(is_equal_approx(card.size.x, ui.scroll_container.size.x), context + ": card width does not match host")
				_check(card.global_position.distance_to(ui.scroll_container.global_position) <= 1, context + ": card not snapped to host")
				_check(ui.play_btn.disabled == card.is_locked(), context + ": Play does not match lock")
				_check(ui.left_btn.disabled == (index == 0), context + ": previous state incorrect")
				_check(ui.right_btn.disabled == (index == ui.arena_modes.size() - 1), context + ": next state incorrect")
				for widget in [ui.panel, ui.play_btn, ui.left_btn, ui.right_btn, ui.scroll_container]:
					_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(widget.get_global_rect()), context + ": control offscreen")
				_check(not ui.play_btn.get_global_rect().intersects(ui.scroll_container.get_global_rect()), context + ": Play overlaps cards")
				_check(is_equal_approx(ui.play_btn.size.x, ui.play_btn.get_parent().size.x), context + ": Play must fill action row")
				if card.overlay_texture.visible:
					_check(card.message.size.y > 0, context + ": overlay message has no space")
				cases += 1
	# Force a locked arena independently of local progression, then test bypass.
	var mode: Resource = ui.arena_modes[2]
	var original_mode: Resource = mode
	mode = mode.duplicate()
	mode.unlock_count = root.get_node("SaveManager").get_star_count() + 100
	ui.arena_modes[2] = mode
	ui.unlock_arena_modes_in_editor = false
	ui.setup()
	await _settle()
	ui._select_mode(2, false)
	await _settle()
	_check(ui.play_btn.disabled, "Locked arena must disable Play")
	var locked_card: Control = ui.hbox_container.get_child(2)
	_check(locked_card.overlay_texture.visible and not locked_card.message.text.is_empty(), "Locked card must show explanation")
	_check(locked_card.message.size.y > 0, "Locked explanation must have layout space")
	_check(locked_card.message.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Locked explanation must be horizontally centered")
	_check(locked_card.message.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "Locked explanation must be vertically centered")
	ui.unlock_arena_modes_in_editor = true
	ui.setup()
	await _settle()
	ui._select_mode(2, false)
	_check(ui.play_btn.disabled == (not OS.has_feature("editor")), "Editor bypass must retain feature guard")
	var saves := root.get_node("SaveManager")
	var stars_before: int = saves.get_star_count()
	var card := ui.hbox_container.get_child(2) as Control
	card.setup(mode, false)
	_check(card.is_locked(), "Disabling bypass must restore lock")
	var story := StoryMode.new()
	story.unlock_mode = PlayMode.UnlockMode.STAR
	story.unlock_count = stars_before + 100
	card.setup(story, true)
	_check(card.is_locked(), "Bypass must not unlock campaign modes")
	_check(saves.get_star_count() == stars_before, "Bypass must not change saved stars")
	card.setup(mode, true)
	ui.arena_modes[2] = original_mode
	# Rapid navigation replaces the previous tween, and resizing preserves selection.
	ui._select_mode(0, false)
	ui._on_right_btn_pressed()
	ui._on_right_btn_pressed()
	root.size = Vector2i(360, 640)
	await _settle()
	_check(ui._current_mode_index == 2, "Resize must retain selected mode")
	ui.scroll_container.scroll_horizontal = roundi(ui.scroll_container.size.x)
	ui._on_h_container_scroll_ended()
	await create_timer(0.35).timeout
	_check(ui._current_mode_index == 1, "Scroll-end must select nearest card")
	ui.queue_free()
	await _settle()
	print("Mode selection layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)
