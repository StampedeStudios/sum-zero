## Run with: godot --headless --path . --script tests/gameplay_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var manager_scene := load("res://packed_scene/scene_2d/LevelManager.tscn") as PackedScene
	var ui_scene := load("res://packed_scene/user_interface/GameUI.tscn") as PackedScene
	var manager := manager_scene.instantiate() as Node2D
	root.add_child(manager)
	root.get_node("GameManager").level_manager = manager
	var ui := ui_scene.instantiate() as Control
	root.add_child(ui)
	var host := ui.get_node("MarginContainer/Layout/BoardHost") as Control
	var actions := ui.get_node("MarginContainer/Layout/BottomRightContainer") as Control
	var grid := manager.get_node("Grid") as Node2D
	var cases: int = 0
	for dimensions in [Vector2i(2, 2), Vector2i(5, 5), Vector2i(2, 5), Vector2i(5, 2)]:
		var data := _make_level(dimensions)
		await manager.init_level(data)
		manager.spawn_grid(false)
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
			root.size = viewport_size
			for show_skip in [true, false]:
				ui.get_node("%SkipBtn").visible = show_skip
				for frame in range(8):
					await process_frame
				var context := "%s / %s / skip=%s" % [dimensions, viewport_size, show_skip]
				var extent := Vector2(dimensions + Vector2i(2, 2)) * Constants.Sizes.CELL_SIZE * grid.scale.x
				var bounds := Rect2(grid.global_position - extent / 2, extent)
				_check(host.get_global_rect().encloses(bounds), context + ": board exceeds host")
				_check(not bounds.intersects(actions.get_global_rect()), context + ": board overlaps actions")
				_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), context + ": board not centered")
				_check(Constants.Sizes.CELL_SIZE * grid.scale.x <= 120.01, context + ": small board too large")
				for slider in manager.grid_sliders:
					slider.activate_slider()
					var local_position := Vector2(128 + Constants.Sizes.CELL_SIZE * 1.5, 0)
					var extension: float = slider.get_drag_extension(slider.to_global(local_position))
					_check(is_equal_approx(extension, 1.5), context + ": drag depends on scale or edge")
					_check(is_zero_approx(slider.get_drag_extension(slider.to_global(Vector2(-256, 0)))), context + ": backwards drag extends slider")
					slider.release_handle()
					# Exercise the same tile mutation path as manual dragging, then rewind.
					slider._update_changed_tiles(1)
					_check(slider._reachable_cells[0].get_cell_value() == 0, context + ": drag does not affect first tile")
					slider._update_changed_tiles(0)
					_check(slider._reachable_cells[0].get_cell_value() == 1, context + ": drag rewind does not restore tile")
				cases += 1

	# Shared renderer remains usable without a campaign host (arena/playtest).
	manager.set_board_rect(Rect2())
	await manager.init_level(_make_level(Vector2i(3, 3)))
	for slider in manager.grid_sliders:
		slider._data.area_behavior = Constants.Sliders.Behavior.FULL
		slider.activate_slider()
		slider._process(0.11)
		_check(slider._current_scale == 1, "Automatic slider must still advance")
		# Stop processing before the scene is freed.
		slider.release_handle()

	ui.queue_free()
	manager.queue_free()
	await process_frame
	print("Gameplay layout: %d cases, %d failures" % [cases, _failures])
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
	for edge in range(4):
		var slider := SliderData.new()
		slider.area_effect = Constants.Sliders.Effect.SUBTRACT
		slider.area_behavior = Constants.Sliders.Behavior.BY_STEP
		data.slider_list[Vector2i(edge, 0)] = slider
	return data
