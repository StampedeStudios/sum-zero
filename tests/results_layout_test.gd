## Run with: godot --headless --path . --script tests/results_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var saves := root.get_node("SaveManager")
	var original: Resource = saves._player_save
	saves._player_save = original.duplicate(true)
	saves._player_save._persistent = saves._persistent_save
	# A high fixture record prevents the real score pipeline from writing a save.
	saves._player_save.player_rewards.blitz_score = 2147483647
	var game := root.get_node("GameManager")
	var campaign_scene := load("res://packed_scene/user_interface/LevelEnd.tscn") as PackedScene
	var arena_scene := load("res://packed_scene/user_interface/ArenaEnd.tscn") as PackedScene
	var campaign := campaign_scene.instantiate() as Control
	campaign.init_score(3, true, false)
	root.add_child(campaign)
	var summary := GameSummary.new()
	for stars in [3, 3, 2, 1, 0]:
		var level := LevelSummary.new()
		level.star_count = stars
		level.reset_used = 0
		summary.add_completed_level(level)
	var arena := arena_scene.instantiate() as Control
	arena.initialize_score(summary)
	var expected := 0
	for step: Resource in arena.steps:
		expected = step.update_score(expected, step.get_multiplier(summary))
	root.add_child(arena)
	Engine.time_scale = 20
	await create_timer(14).timeout
	Engine.time_scale = 1
	_check(arena._score == expected and arena.score.text == str(expected), "Arena score pipeline changed")
	_check(not arena.record_icon.visible, "Lower score must not show record")
	_check(arena.actions.modulate.a == 1, "Arena action reveal must complete")
	var cases := 0
	for viewport_size in [Vector2i(320, 568), Vector2i(480, 853), Vector2i(640, 360)]:
		root.size = viewport_size
		for locale in ["en", "it", "de", "es", "fr", "pl"]:
			TranslationServer.set_locale(locale)
			# Exercise widest states, including large scores and the record badge.
			arena.record_icon.show()
			arena.stats.show()
			arena._update_stats_multiplier(99999)
			arena._update_score(1234567890)
			campaign.hint.text = campaign._select_random_text(3)
			await _settle()
			var badge_bounds: Rect2 = arena.record_icon.get_global_rect()
			var margin_bounds: Rect2 = arena.get_node("Panel/MarginContainer/Layout").get_global_rect()
			_check(is_equal_approx(badge_bounds.end.x, margin_bounds.end.x) and is_equal_approx(badge_bounds.position.y, margin_bounds.position.y), "Record badge must sit at top right")
			var arena_scroll: ScrollContainer = arena.get_node("%Scroll")
			arena_scroll.scroll_vertical = 10000
			await _settle()
			_check(arena.record_icon.get_global_rect().is_equal_approx(badge_bounds), "Record badge must not scroll with summary")
			arena_scroll.scroll_vertical = 0
			for ui: Control in [campaign, arena]:
				var context := "%s / %s / %s" % [ui.name, viewport_size, locale]
				var panel: Control = ui.get_node("%Panel")
				var actions: Control = ui.get_node("%Actions")
				var scroll: ScrollContainer = ui.get_node("%Scroll")
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.get_global_rect()), context + ": panel offscreen")
				_check(panel.scale == Vector2.ONE, context + ": global UI scale leaked into panel")
				_check(panel.get_global_rect().encloses(actions.get_global_rect()), context + ": actions outside panel")
				_check(not actions.get_global_rect().intersects(scroll.get_global_rect()), context + ": summary overlaps actions")
				var last_button: Control = actions.get_child(actions.get_child_count() - 1)
				_check(is_equal_approx(last_button.get_global_rect().end.x, actions.get_global_rect().end.x), context + ": primary action must fill remaining width")
				for button: Control in actions.get_children():
					_check(actions.get_global_rect().encloses(button.get_global_rect()), context + ": button exceeds row")
				_check(scroll.get_h_scroll_bar().max_value <= scroll.size.x + 1, context + ": summary has horizontal overflow")
				cases += 1
			for star: TextureRect in [campaign.left_star, campaign.middle_star, campaign.right_star]:
				_check(star.scale.is_equal_approx(Vector2.ONE), "Awarded stars must finish at slot size")
				_check(star.pivot_offset.is_equal_approx(star.size / 2), "Star pivot must follow live resize")
			_check(campaign.middle_star.global_position.y < campaign.left_star.global_position.y, "Middle star must remain raised")
			var region := campaign.get_node("%Stars") as Control
			var left := region.get_child(0) as Control
			var middle := region.get_child(1) as Control
			var right := region.get_child(2) as Control
			var composition := left.get_global_rect().merge(middle.get_global_rect()).merge(right.get_global_rect())
			_check(region.get_global_rect().grow(0.1).encloses(composition), "Result stars must fit their reserved region")
			_check(is_equal_approx(composition.size.x, region.size.x) or is_equal_approx(composition.size.y, region.size.y), "Result stars must fill available width or height")
			_check(middle.get_global_rect().intersects(left.get_global_rect()) and middle.get_global_rect().intersects(right.get_global_rect()), "Result stars must overlap")
			_check(middle.z_index > left.z_index and middle.z_index > right.z_index, "Middle result star must draw in front")
			_check(not composition.intersects(campaign.hint.get_global_rect()) and not composition.intersects(campaign.get_node("%Actions").get_global_rect()), "Result stars must not overlap message or actions")
	# All ratings, including extra-star message and final-level Exit, retain behavior.
	for stars in range(5):
		var result := campaign_scene.instantiate() as Control
		result.init_score(stars, false, false)
		root.add_child(result)
		Engine.time_scale = 20
		await create_timer(2).timeout
		Engine.time_scale = 1
		_check(result.next_btn.text == tr("EXIT"), "Final level must show Exit")
		for index in range(3):
			var star: Control = [result.left_star, result.middle_star, result.right_star][index]
			_check(star.scale.distance_to(Vector2.ONE if stars > index else Vector2.ZERO) < 0.001, "Incorrect animated rating %d: %s" % [stars, star.scale])
		_check(not result.hint.text.is_empty(), "Rating message missing")
		result.queue_free()
		await _settle()
	_check(campaign.get_node("%ReplayBtn").pressed.is_connected(campaign._on_replay_btn_pressed), "Campaign replay disconnected")
	_check(campaign.next_btn.pressed.is_connected(campaign._on_next_btn_pressed), "Campaign next disconnected")
	_check(arena.replay_btn.pressed.is_connected(arena._on_replay_btn_pressed), "Arena replay disconnected")
	_check(arena.get_node("%ExitBtn").pressed.is_connected(arena._on_exit_btn_pressed), "Arena exit disconnected")
	var replayed := [false]
	campaign.on_replay_button.connect(func() -> void: replayed[0] = true)
	campaign.get_node("%ReplayBtn").pressed.emit()
	_check(replayed[0], "Campaign replay must emit its action")
	var advanced := [false]
	var next_result := campaign_scene.instantiate() as Control
	next_result.init_score(1, true, false)
	root.add_child(next_result)
	await create_timer(1.5).timeout
	next_result.on_next_button.connect(func() -> void: advanced[0] = true)
	next_result.next_btn.pressed.emit()
	_check(advanced[0], "Campaign next must emit its action")
	# Closing during calculation must cancel node-bound tweens safely.
	var closing := arena_scene.instantiate() as Control
	closing.initialize_score(summary)
	root.add_child(closing)
	await create_timer(0.25).timeout
	closing.queue_free()
	arena.queue_free()
	await _settle()
	saves._player_save = original
	print("Results layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)
