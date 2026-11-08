## Run with: godot --headless --path . --script tests/builder_editor_layout_test.gd
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
	var splash := root.get_node_or_null("SplashScreen")
	if splash:
		splash.queue_free()
	await process_frame
	root.get_node("AudioManager")._is_sfx_on = false
	var game := root.get_node("GameManager")
	var ui := (load("res://packed_scene/user_interface/BuilderUI.tscn") as PackedScene).instantiate() as Control
	game.builder_ui = ui
	root.add_child(ui)
	var builder := (load("res://packed_scene/scene_2d/LevelBuilder.tscn") as PackedScene).instantiate() as Node2D
	game.level_builder = builder
	root.add_child(builder)
	await _settle()
	var host := ui.get_node("%BoardHost") as Control
	var grid := builder.get_node("Grid") as Node2D
	var cases := 0
	for dimensions in [Vector2i(2, 2), Vector2i(5, 5), Vector2i(2, 5), Vector2i(5, 2)]:
		var data := _make_level(dimensions)
		builder.construct_level(data, true)
		game.change_state(Constants.GameState.BUILDER_IDLE)
		for viewport_size in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(640, 360)]:
			root.size = viewport_size
			for locale in ["en", "it", "de", "es", "fr", "pl"]:
				TranslationServer.set_locale(locale)
				await _settle()
				var context := "%s / %s / %s" % [dimensions, viewport_size, locale]
				_check(host.get_global_rect().grow(0.1).encloses(_bounds(grid, dimensions)), context + ": board exceeds host")
				_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), context + ": not centered")
				for button in ui.find_children("*", "Button", true, false):
					_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()), context + ": toolbar offscreen")
				cases += 1

		# Cell selection uses current board coordinates and survives a live resize.
		var cell: Node2D = builder._cell_collection[Vector2i.ZERO]
		builder._multiselection_cells.append(cell)
		builder._multiselection_cells.append(builder._cell_collection[Vector2i.ONE])
		game.change_state(Constants.GameState.BUILDER_SELECTION)
		await _settle()
		var selection: Control = game.builder_selection
		_check(selection.visible, "Cell selection must open")
		selection.forward_action.emit()
		_check(data.cells_list[Vector2i.ZERO].value == 2, "Selection must edit source data")
		_check(data.cells_list[Vector2i.ONE].value == 2, "Multiselection must edit every selected cell")
		root.size = Vector2i(360, 640)
		await _settle()
		for button in selection.get_node("%Control").get_children():
			_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(0.1).encloses(button.get_global_rect()), "Selection action offscreen")
		_check(selection.panel.size.is_equal_approx(Vector2(root.size)), "Selection backdrop must resize")
		game.change_state(Constants.GameState.BUILDER_IDLE)
		await _settle()

		# Select every edge, then restore the board from the temporary pan.
		for edge in range(4):
			var slider: Node2D = builder._slider_collection[Vector2i(edge, 0)]
			game.on_state_change.connect(slider._on_state_change)
			game.change_state(Constants.GameState.BUILDER_SELECTION)
			await create_timer(0.1).timeout
			await _settle()
			_check(selection.visible, "Slider selection must open")
			for button in selection.get_node("%Control").get_children():
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(0.1).encloses(button.get_global_rect()), "Slider action offscreen")
			selection.forward_action.emit()
			_check(data.slider_list.has(Vector2i(edge, 0)), "Slider action must update data")
			game.change_state(Constants.GameState.BUILDER_IDLE)
			await create_timer(0.1).timeout
			await _settle()
			_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), "Pan must reset")

		game.change_state(Constants.GameState.BUILDER_RESIZE)
		await _settle()
		for viewport_size in [Vector2i(360, 640), Vector2i(640, 360)]:
			root.size = viewport_size
			await _settle()
			var preview: Control = game.builder_resize.control
			_check(preview.get_global_rect().grow(0.1).encloses(_bounds(grid, dimensions)), "Preview exceeds resize region")
			_check(grid.global_position.is_equal_approx(preview.get_global_rect().get_center()), "Resize preview not centered")
		game.builder_resize._update_width(3)
		game.builder_resize._update_height(4)
		await _settle()
		_check(data.width == 3 and data.height == 4, "Dimension controls must update data")
		game.change_state(Constants.GameState.BUILDER_IDLE)
		await _settle()
		_check(host.get_global_rect().grow(0.1).encloses(_bounds(grid, Vector2i(3, 4))), "Return from resize must restore fit")
		# Opening/cancelling the save dialog must not write or mutate the level.
		game.change_state(Constants.GameState.BUILDER_SAVE)
		await create_timer(0.25).timeout
		var save_ui := root.get_node("SaveQuery") as Control
		for viewport_size in [Vector2i(360, 640), Vector2i(640, 360)]:
			root.size = viewport_size
			await _settle()
			for widget in [save_ui.panel, save_ui.level_name, save_ui.moves, save_ui.save_btn]:
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).grow(0.1).encloses(widget.get_global_rect()), "Save dialog widget offscreen")
		save_ui.close()
		await _settle()

	# Exercise the real playtest lifecycle, then ensure the editor reclaims its host.
	await ui._on_play_btn_pressed()
	await _settle()
	_check(not builder.visible, "Playtest must hide editor")
	game.builder_test._on_exit_btn_pressed()
	await _settle()
	_check(builder.visible and ui.visible, "Returning from playtest must show editor")
	_check(grid.global_position.is_equal_approx(host.get_global_rect().get_center()), "Returning from playtest must restore editor center")
	game.change_state(Constants.GameState.LEVEL_PICK)
	await _settle()
	print("Builder editor layout: %d cases, %d failures" % [cases, _failures])
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
	return data


func _bounds(grid: Node2D, dimensions: Vector2i) -> Rect2:
	var extent := Vector2(dimensions + Vector2i(2, 2)) * Constants.Sizes.CELL_SIZE * grid.scale.x
	return Rect2(grid.global_position - extent / 2, extent)


func _settle() -> void:
	for frame in range(10):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
