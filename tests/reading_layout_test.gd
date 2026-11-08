## Run with: godot --headless --path . --script tests/reading_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var tutorial_scene := load("res://packed_scene/user_interface/TutorialUI.tscn") as PackedScene
	var tutorial := tutorial_scene.instantiate() as Control
	var credits := (load("res://packed_scene/user_interface/CreditsScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(tutorial)
	root.add_child(credits)
	credits.get_node("ScrollDelay").stop()
	var cases := 0
	for extent in [Vector2i(320, 568), Vector2i(480, 853), Vector2i(640, 360)]:
		root.size = extent
		for locale in ["en", "it", "de", "es", "fr", "pl"]:
			TranslationServer.set_locale(locale)
			for name in ["level_zero", "plus", "invert", "block", "automatic_slider", "endless", "blitz", "puzzle"]:
				var data: Resource = load("res://assets/resources/tutorial/%s.tres" % name)
				tutorial.setup(data)
				for index in range(maxi(1, data.hints.size())):
					await _settle()
					var context := "%s / %s / %s / %d" % [extent, locale, name, index]
					var viewport := Rect2(Vector2.ZERO, Vector2(root.size))
					var content: BoxContainer = tutorial.get_node("%Content")
					_check(content.vertical, context + ": text must stay above illustration")
					for control: Control in [tutorial.play_btn, tutorial.label, content, tutorial.hint, tutorial.sprite, tutorial.hint_options]:
						if control.visible:
							_check(viewport.encloses(control.get_global_rect()), context + ": control offscreen")
					_check(not content.get_global_rect().intersects(tutorial.play_btn.get_global_rect()), context + ": content overlaps Next")
					_check(tutorial.play_btn.size.y <= 64, context + ": Next must not expand vertically")
					if tutorial.sprite.visible:
						_check(not tutorial.hint.get_global_rect().intersects(tutorial.sprite.get_global_rect()), context + ": text overlaps illustration")
						_check(tutorial.sprite.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, context + ": image must fit without cropping")
						_check(tutorial.sprite.size.y >= content.size.y * (0.55 if content.vertical else 0.95), context + ": illustration region too small")
						_check(tutorial.sprite.size.x >= content.size.x * (0.95 if content.vertical else 0.45), context + ": illustration region too narrow")
					if extent == Vector2i(480, 853):
						_check(not tutorial.hint.get_v_scroll_bar().visible, context + ": ordinary portrait tip should not scroll")
					_check(tutorial.hint_options.visible == data.is_skippable, context + ": hide preference visibility changed")
					if not data.images.is_empty():
						_check(tutorial.sprite.texture == data.images[mini(index, data.images.size() - 1)], context + ": illustration sequence changed")
					if index < data.hints.size() - 1:
						tutorial._on_next_btn_pressed()
					cases += 1
			await _settle()
			var back: Button = credits.get_node("%Back")
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(credits.text.get_global_rect()), "Credits text offscreen")
			_check(not back.get_global_rect().intersects(credits.text.get_global_rect()), "Credits Back overlaps text")
			credits._scroll_to_progress(1)
			var bar: VScrollBar = credits.text.get_v_scroll_bar()
			_check(is_equal_approx(bar.value, maxf(0, bar.max_value - bar.page)), "Credits end unreachable after reflow")
	# Repeated setup, no-image/empty hints, long text and final action without saves.
	var fixture := TutorialData.new()
	fixture.hints = ["Long hint. ".repeat(100), "Last hint"]
	fixture.images = [load("res://assets/ui/tutorial/tutorial_zero_1.png") as Texture2D]
	root.size = Vector2i(320, 568)
	tutorial.setup(fixture)
	await _settle()
	_check(tutorial.hint.get_v_scroll_bar().visible, "Long illustrated hint must scroll text only")
	_check(tutorial.sprite.size.y > 200, "Long text must not squeeze away the illustration")
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(tutorial.sprite.get_global_rect()), "Long hint illustration must remain fully onscreen")
	tutorial.show_hints.toggled.emit(true)
	fixture.images.clear()
	tutorial.setup(fixture)
	await _settle()
	_check(not tutorial.sprite.visible, "No image must release image space")
	_check(tutorial.label.visible and tutorial._current_hint == 0, "Repeated setup must restore first tip")
	_check(not tutorial._hide_next_time and not tutorial.show_hints.button_pressed, "Repeated setup must reset opt-out")
	_check(tutorial.hint.get_v_scroll_bar().max_value > tutorial.hint.size.y, "Long hint must remain scrollable")
	tutorial._on_next_btn_pressed()
	_check(tutorial.play_btn.text == tr("PLAY"), "Last hint must offer Play")
	var closed := [false]
	tutorial.on_tutorial_closed.connect(func() -> void: closed[0] = true)
	tutorial.play_btn.pressed.emit()
	_check(closed[0], "Final action must close tutorial")
	var empty := tutorial_scene.instantiate() as Control
	root.add_child(empty)
	empty.setup(TutorialData.new())
	_check(empty.hint.text.is_empty() and not empty.label.visible and not empty.sprite.visible, "Empty tutorial must clear scene defaults")
	empty.queue_free()
	_check(credits.text.get_theme_color("default_color").r > 0.9, "Credits must retain readable light text over dark backdrop")
	credits.start_credits_scroll()
	credits._scroll_tween.custom_step(30)
	_check(credits.text.get_v_scroll_bar().value > 0, "Credits must auto-scroll")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	credits._on_text_gui_input(wheel)
	_check(not credits._scroll_tween.is_running(), "Manual scroll must stop automatic scrolling")
	_check(credits.get_node("%Back").pressed.is_connected(credits._close), "Credits Back disconnected")
	credits.get_node("%Back").pressed.emit()
	await _settle()
	_check(not is_instance_valid(credits), "Credits Back must dismiss screen")
	print("Tutorial and Credits layout: %d tip cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)
