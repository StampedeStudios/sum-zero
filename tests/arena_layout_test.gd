## Run with: godot --headless --path . --script tests/arena_layout_test.gd
# gdlint: disable=max-line-length
extends "res://tests/test_base.gd"


func _run() -> void:
	var manager_scene := load("res://packed_scene/scene_2d/LevelManager.tscn") as PackedScene
	var arena_scene := load("res://packed_scene/user_interface/ArenaUI.tscn") as PackedScene
	var manager := manager_scene.instantiate() as Node2D
	root.add_child(manager)
	root.get_node("GameManager").level_manager = manager
	var arena := arena_scene.instantiate() as Control
	root.add_child(arena)
	var host := arena.get_node("%BoardHost") as Control
	var header := arena.get_node("%Header") as Control
	var actions := arena.get_node("%BottomRightContainer") as Control
	var loading := arena.get_node("%Loading") as Control
	var bonus := arena.get_node("%AddedTime") as Label
	var grid := manager.get_node("Grid") as Node2D
	var cases: int = 0
	for dimensions in [Vector2i(2, 2), Vector2i(5, 5), Vector2i(2, 5), Vector2i(5, 2)]:
		await manager.init_level(_make_level(dimensions))
		host.bind_level_manager(manager)
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
			root.size = viewport_size
			for timed in [true, false]:
				header.visible = timed
				for skippable in [true, false]:
					arena.get_node("%SkipBtn").visible = skippable
					await _settle()
					var context := "%s / %s / timer=%s / skip=%s" % [dimensions, viewport_size, timed, skippable]
					var extent := Vector2(dimensions + Vector2i(2, 2)) * Constants.Sizes.CELL_SIZE * grid.scale.x
					var bounds := Rect2(grid.global_position - extent / 2, extent)
					_check(host.get_global_rect().encloses(bounds), context + ": board exceeds host")
					_check(not bounds.intersects(actions.get_global_rect()), context + ": board overlaps actions")
					if timed:
						_check(not bounds.intersects(header.get_global_rect()), context + ": board overlaps timer")
					_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), context + ": board not centered")
					_check(loading.global_position.is_equal_approx(host.get_global_rect().get_center()), context + ": loading not centered")
					cases += 1

	# Exercise real initialization/binding, timer startup and repeated bonuses.
	var mode := ArenaMode.new()
	mode.timer_options = TimerOptions.new()
	arena._current_mode = mode
	arena._timer = Timer.new()
	arena.add_child(arena._timer)
	arena._time = 60
	arena._current_level = _make_level(Vector2i(3, 3))
	await arena._init_level()
	_check(not arena._timer.is_stopped(), "Timed arena must start timer")
	arena._timer.stop()
	mode.is_skippable = true
	mode.timer_options.is_countdown = true
	arena._set_arena_time(10)
	_check(not arena.get_node("%SkipBtn").visible, "Skip must hide below its time cost")
	arena._set_arena_time(60)
	_check(arena.get_node("%SkipBtn").visible, "Skip must return above its time cost")
	arena._animate_extra_time(5)
	arena._animate_extra_time(-15)
	_check(bonus.text == "-15" and bonus.visible, "Repeated bonus must replace previous animation")
	await create_timer(1.3).timeout
	_check(not bonus.visible and bonus.position.is_zero_approx(), "Bonus must hide and reset")
	arena._show_ui(false)
	_check(not header.visible, "Untimed arena must hide timer header")
	arena._start_loading()
	_check(loading.visible, "Loading indicator must show")
	arena._tween.kill()
	loading.hide()
	arena.queue_free()
	manager.queue_free()
	await process_frame
	print("Arena layout: %d cases, %d failures" % [cases, _failures])
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
	data.slider_list[Vector2i.ZERO] = SliderData.new()
	return data
