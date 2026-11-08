## Run with: godot --headless --path . --script tests/builder_playtest_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var manager_scene := load("res://packed_scene/scene_2d/LevelManager.tscn") as PackedScene
	var ui_scene := load("res://packed_scene/user_interface/BuilderTest.tscn") as PackedScene
	var manager := manager_scene.instantiate() as Node2D
	root.add_child(manager)
	var game := root.get_node("GameManager")
	game.level_manager = manager
	var ui := ui_scene.instantiate() as Control
	root.add_child(ui)
	var host := ui.get_node("%BoardHost") as Control
	var moves := ui.get_node("%MovesCount") as Label
	var actions := ui.get_node("%BottomContainer") as Control
	var grid := manager.get_node("Grid") as Node2D
	var cases: int = 0
	for dimensions in [Vector2i(2, 2), Vector2i(5, 5), Vector2i(2, 5), Vector2i(5, 2)]:
		var data := _make_level(dimensions)
		await manager.init_level(data)
		game.change_state(Constants.GameState.LEVEL_START)
		_check(ui.visible and manager.visible, "Playtest must show when started")
		_check(manager.on_consume_move.get_connections().size() == 1, "Repeated playtest must not duplicate move connections")
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var context := "%s / %s" % [dimensions, viewport_size]
			var extent := Vector2(dimensions + Vector2i(2, 2)) * Constants.Sizes.CELL_SIZE * grid.scale.x
			var bounds := Rect2(grid.global_position - extent / 2, extent)
			_check(host.get_global_rect().encloses(bounds), context + ": board exceeds host")
			_check(not bounds.intersects(actions.get_global_rect()), context + ": board overlaps actions")
			_check(not bounds.intersects(moves.get_global_rect()), context + ": board overlaps counter")
			_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), context + ": board not centered")
			cases += 1

		var slider: Node2D = manager.grid_sliders[0]
		slider.activate_slider()
		slider._update_changed_tiles(1)
		slider.release_handle()
		_check(moves.text == "1", "Effective slider move must increment counter")
		ui._on_reset_btn_pressed()
		_check(moves.text == "0", "Reset must clear move count")
		_check(manager.grid_cells[Vector2i.ZERO].get_cell_value() == 1, "Reset must restore cells")
		ui._on_exit_btn_pressed()
		_check(not ui.visible and not manager.visible, "Returning to builder must hide playtest")
		_check(moves.text == "0", "Returning to builder must clear move count")
		_check(data.cells_list[Vector2i.ZERO].value == 1, "Playtest must preserve source level")

	game.change_state(Constants.GameState.LEVEL_PICK)
	await process_frame
	await process_frame
	_check(not is_instance_valid(ui) and not is_instance_valid(manager), "Leaving builder must free playtest scenes")
	print("Builder playtest layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _make_level(dimensions: Vector2i) -> LevelData:
	var data := LevelData.new()
	data.width = dimensions.x
	data.height = dimensions.y
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			var cell := CellData.new()
			cell.value = 1
			data.cells_list[Vector2i(x, y)] = cell
	var slider := SliderData.new()
	slider.area_effect = Constants.Sliders.Effect.SUBTRACT
	slider.area_behavior = Constants.Sliders.Behavior.BY_STEP
	data.slider_list[Vector2i.ZERO] = slider
	return data
