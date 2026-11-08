## Run with: godot --headless --path . --script tests/canvas_scaling_test.gd
## Unlike logical-layout tests, keep the project's real canvas settings enabled.
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"

const REFERENCE := Vector2(480, 853)
const WINDOW_SIZES: Array[Vector2i] = [
	Vector2i(480, 853), Vector2i(960, 1706), Vector2i(1440, 2559),
	Vector2i(360, 640), Vector2i(720, 1280),
	Vector2i(360, 800), Vector2i(720, 1600), Vector2i(1080, 2400),
	Vector2i(768, 1024), Vector2i(1536, 2048),
	Vector2i(640, 360), Vector2i(1280, 720),
]

func _uses_canvas_scaling() -> bool:
	return true


func _run() -> void:
	_check(root.content_scale_size == Vector2i(REFERENCE), "Reference canvas must remain 480×853")
	_check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "Canvas items scaling must be enabled")
	_check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND, "Canvas must expand without letterboxing")

	var menu := _scene("MainMenu")
	var tutorial := _scene("TutorialUI")
	var manager := (load("res://packed_scene/scene_2d/LevelManager.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(manager)
	root.get_node("GameManager").level_manager = manager
	var game := _scene("GameUI")
	var host := game.get_node("%BoardHost") as Control
	var grid := manager.get_node("Grid") as Node2D
	await manager.init_level(_make_level())
	manager.spawn_grid(false)
	var cases: int = 0
	for physical_size: Vector2i in WINDOW_SIZES:
		root.size = physical_size
		for locale: String in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			tutorial.setup(load("res://assets/resources/tutorial/level_zero.tres"))
			await _settle()
			var context := "%s / %s" % [physical_size, locale]
			var factor := minf(physical_size.x / REFERENCE.x, physical_size.y / REFERENCE.y)
			var expected_size := Vector2(physical_size) / factor
			var logical_size := root.get_visible_rect().size
			# Godot rounds the expanded logical viewport to whole units.
			_check(logical_size.distance_to(expected_size) <= 2, context + ": incorrect logical canvas")
			var stretch := root.get_stretch_transform()
			_check(absf(stretch.x.x - factor) < 0.01 and absf(stretch.y.y - factor) < 0.01, context + ": incorrect physical scale")
			_check(absf(stretch.x.x - stretch.y.y) < 0.01, context + ": nonuniform stretch")
			_check(stretch.origin.is_zero_approx(), context + ": canvas must not be letterboxed")
			for screen: Control in [menu, tutorial, game]:
				_check(screen.size.is_equal_approx(logical_size), context + ": screen does not fill logical canvas")
				_check(screen.scale == Vector2.ONE, context + ": screen must not apply additional scaling")
			var next := tutorial.get_node("%NextBtn") as Button
			_check(is_equal_approx(next.size.y, 56), context + ": logical button height changed")
			var physical_button_height := (stretch * next.get_global_rect()).size.y
			_check(absf(physical_button_height - 56 * factor) < 1, context + ": button did not scale with resolution")
			_check(tutorial.get_node("%Hint").get_theme_font_size("normal_font_size") == 22, context + ": font must remain a logical metric")
			var board_extent := Vector2(5, 5) * Constants.Sizes.CELL_SIZE * grid.scale.x
			var board_bounds := Rect2(grid.global_position - board_extent / 2, board_extent)
			_check(host.get_global_rect().grow(0.1).encloses(board_bounds), context + ": board exceeds logical host")
			for slider: Node2D in manager.grid_sliders:
				slider.activate_slider()
				var target := slider.to_global(Vector2(128 + Constants.Sizes.CELL_SIZE * 1.5, 0))
				var physical_target := stretch * target
				var logical_target := stretch.affine_inverse() * physical_target
				_check(is_equal_approx(slider.get_drag_extension(logical_target), 1.5), context + ": slider input changed with resolution")
				slider.release_handle()
			# Feed real physical mouse coordinates through Viewport input conversion.
			menu.hide()
			game.hide()
			var click_position := stretch * next.get_global_rect().get_center()
			for pressed: bool in [true, false]:
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = pressed
				click.position = click_position
				click.global_position = click_position
				root.push_input(click, false)
			await _settle()
			_check(tutorial._current_hint == 1, context + ": physical click did not reach Next")
			menu.show()
			game.show()
			cases += 1

	for node: Node in [menu, tutorial, game, manager]:
		node.queue_free()
	await process_frame
	print("Canvas scaling: %d resolution/locale cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _scene(scene_name: String) -> Control:
	var ui := (load("res://packed_scene/user_interface/%s.tscn" % scene_name) as PackedScene).instantiate() as Control
	root.add_child(ui)
	return ui


func _make_level() -> LevelData:
	var data := LevelData.new()
	data.width = 3
	data.height = 3
	for x: int in range(3):
		for y: int in range(3):
			var cell := CellData.new()
			cell.value = 1
			data.cells_list[Vector2i(x, y)] = cell
	for edge: int in range(4):
		var slider := SliderData.new()
		slider.area_effect = Constants.Sliders.Effect.SUBTRACT
		slider.area_behavior = Constants.Sliders.Behavior.BY_STEP
		data.slider_list[Vector2i(edge, 0)] = slider
	return data
