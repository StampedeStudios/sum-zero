## Handles logic of Level Builder.
##
## Each custom level can be built with the Level Builder which offers the possibility
## to create levels of any size and any composition.
##
## Makes use of encoder to persist the created levels.
class_name LevelBuilder extends Node2D

const BUILDER_CELL := preload("res://packed_scene/scene_2d/BuilderCell.tscn")
const BUILDER_SLIDER := preload("res://packed_scene/scene_2d/BuilderSlider.tscn")
const PANEL := preload("res://assets/resources/themes/panel.tres")
const RANDOMIZER_OPTIONS = "res://assets/resources/levels/randomizer_options/builder_options.tres"
const BUILDER_RESIZE := "res://packed_scene/user_interface/BuilderResize.tscn"
const BUILDER_SAVE := "res://packed_scene/user_interface/BuilderSave.tscn"
const BUILDER_SELECTION := "res://packed_scene/user_interface/BuilderSelection.tscn"

var _randomizer: Randomizer
var _level_data: LevelData
var _cell_collection: Dictionary[Vector2i, BuilderCell]
var _slider_collection: Dictionary[Vector2i, BuilderSlider]
var _multiselection_enabled: bool
var _multiselection_start_pos: Vector2
var _multiselection_panel: Panel
var _multiselection_area: Area2D
var _multiselection_coll: CollisionShape2D
var _multiselection_cells: Array[BuilderCell]

@onready var grid: Node2D = %Grid


func _ready() -> void:
	GameManager.set_level_scale(3, 3)
	grid.position = get_viewport_rect().get_center() - Vector2(0, GameManager.CENTER_OFFSET)
	grid.scale = Vector2.ZERO
	GameManager.on_state_change.connect(_on_state_change)
	GameManager.builder_ui.reset_builder_level.connect(_reset_builder_grid)

	if !GameManager.builder_selection:
		var scene := ResourceLoader.load(BUILDER_SELECTION) as PackedScene
		var builder_selection := scene.instantiate() as BuilderSelection
		builder_selection.hide()
		get_tree().root.add_child.call_deferred(builder_selection)
		GameManager.builder_selection = builder_selection


func _on_scale_change(new_scale: Vector2) -> void:
	var tween : Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(grid, "scale", new_scale, 0.1).from_current()


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()

		Constants.GameState.MAIN_MENU:
			self.queue_free.call_deferred()

		Constants.GameState.BUILDER_IDLE:
			self.show()
			_multiselection_cells.clear()
			_on_scale_change(GameManager.level_scale)

		Constants.GameState.BUILDER_SAVE:
			var scene := ResourceLoader.load(BUILDER_SAVE) as PackedScene
			var builder_save := scene.instantiate() as BuilderSave
			builder_save.on_query_close.connect(_on_save_query_received)
			get_tree().root.add_child(builder_save)
			var level_name := _level_data.name
			var moves := str(_level_data.moves_left)
			builder_save.init_info(level_name, moves, is_valid_data())

		Constants.GameState.BUILDER_RESIZE:
			if !GameManager.builder_resize:
				var scene := ResourceLoader.load(BUILDER_RESIZE) as PackedScene
				var builder_resize := scene.instantiate() as BuilderResize
				get_tree().root.add_child.call_deferred(builder_resize)
				builder_resize.on_height_change.connect(_on_height_change)
				builder_resize.on_width_change.connect(_on_width_change)
				builder_resize.on_zoom_change.connect(_on_scale_change)
				GameManager.builder_resize = builder_resize

			var level_size: Vector2i
			level_size.x = _level_data.width
			level_size.y = _level_data.height
			GameManager.builder_resize.init_query.call_deferred(level_size)

		Constants.GameState.BUILDER_SELECTION:
			if _multiselection_cells.size() > 0:
				var size: Vector2
				var pos: Vector2
				var top_left := _multiselection_cells[0].global_position
				var bottom_right := top_left

				for cell in _multiselection_cells:
					cell.z_index = 10
					cell.toggle_connection.call_deferred(true)
					var cell_pos := cell.global_position
					if cell_pos.x < top_left.x:
						top_left.x = cell_pos.x
					elif cell_pos.x > bottom_right.x:
						bottom_right.x = cell_pos.x
					if cell_pos.y < top_left.y:
						top_left.y = cell_pos.y
					elif cell_pos.y > bottom_right.y:
						bottom_right.y = cell_pos.y

				size = (bottom_right - top_left) / GameManager.level_scale
				size += Vector2(Constants.Sizes.CELL_SIZE, Constants.Sizes.CELL_SIZE)
				pos = top_left + (bottom_right - top_left) / 2
				GameManager.builder_selection.init_selection.call_deferred(true, pos, size)
		_:
			self.visible = false


func construct_level(level_data: LevelData = null, is_imported: bool = false) -> void:
	if level_data != null:
		_level_data = level_data

	GameManager.set_level_scale(_level_data.width, _level_data.height)
	var half_cell := Vector2.ONE * Constants.Sizes.CELL_SIZE / 2
	var half_grid := Vector2(_level_data.width, _level_data.height) * Constants.Sizes.CELL_SIZE / 2

	# Used as cell and slider collection
	var old_collection: Dictionary

	# Add cell space
	old_collection = _cell_collection.duplicate()
	for column in range(0, _level_data.width):
		for row in range(0, _level_data.height):
			var cell_coord := Vector2i(column, row)
			var cell_pos := Vector2(cell_coord) * Constants.Sizes.CELL_SIZE
			var cell: BuilderCell

			if _cell_collection.has(cell_coord):
				cell = _cell_collection.get(cell_coord)
				old_collection.erase(cell_coord)
			else:
				cell = BUILDER_CELL.instantiate()
				grid.add_child(cell)
				cell.on_cell_change.connect(_on_cell_change)
				cell.start_multiselection.connect(_start_multiselection)

				if !is_imported:
					_level_data.cells_list[cell_coord] = CellData.new()
				_cell_collection[cell_coord] = cell

			if _level_data.cells_list.has(cell_coord):
				cell.set_cell_data(_level_data.cells_list.get(cell_coord))
			else:
				cell = _cell_collection.get(cell_coord)
				cell.clear_cell()

			cell.position = -half_grid + half_cell + cell_pos

	for coord: Vector2i in old_collection.keys():
		_cell_collection.erase(coord)
		_level_data.cells_list.erase(coord)
		old_collection.get(coord).queue_free()

	# Add slider space
	old_collection = _slider_collection.duplicate()
	var half_slider := Vector2.ONE * Constants.Sizes.SLIDER_SIZE / 2
	var slider_pos: Vector2
	var edge_start_pos: Vector2
	var slider: BuilderSlider
	# TOP
	for column in range(0, _level_data.width):
		var slider_coord := Vector2i(0, column)
		if _slider_collection.has(slider_coord):
			slider = _slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			_slider_collection[slider_coord] = slider
		if _level_data.slider_list.has(slider_coord):
			slider.set_slider_data(_level_data.slider_list.get(slider_coord))
		else:
			slider.clear_slider()

		slider_pos.x = column * Constants.Sizes.CELL_SIZE
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y - half_slider.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 90

	# RIGHT
	for row in range(0, _level_data.height):
		var slider_coord := Vector2i(1, row)
		if _slider_collection.has(slider_coord):
			slider = _slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			_slider_collection[slider_coord] = slider
		if _level_data.slider_list.has(slider_coord):
			slider.set_slider_data(_level_data.slider_list.get(slider_coord))
		else:
			slider.clear_slider()

		slider_pos.x = 0
		slider_pos.y = row * Constants.Sizes.CELL_SIZE
		edge_start_pos.x = half_grid.x + half_slider.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 180

	# BOTTOM
	for column in range(0, _level_data.width):
		var slider_coord := Vector2i(2, column)
		if _slider_collection.has(slider_coord):
			slider = _slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			_slider_collection[slider_coord] = slider
		if _level_data.slider_list.has(slider_coord):
			slider.set_slider_data(_level_data.slider_list.get(slider_coord))
		else:
			slider.clear_slider()

		slider_pos.x = column * Constants.Sizes.CELL_SIZE
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = half_grid.y + half_slider.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 270

	# LEFT
	for row in range(0, _level_data.height):
		var slider_coord := Vector2i(3, row)
		if _slider_collection.has(slider_coord):
			slider = _slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			_slider_collection[slider_coord] = slider
		if _level_data.slider_list.has(slider_coord):
			slider.set_slider_data(_level_data.slider_list.get(slider_coord))
		else:
			slider.clear_slider()

		slider_pos.x = 0
		slider_pos.y = row * Constants.Sizes.CELL_SIZE
		edge_start_pos.x = -half_grid.x - half_slider.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 0

	for coord: Vector2i in old_collection.keys():
		_slider_collection.erase(coord)
		_level_data.slider_list.erase(coord)
		old_collection.get(coord).queue_free()


func _on_cell_change(ref: BuilderCell, data: CellData) -> void:
	for key: Vector2i in _cell_collection.keys():
		if ref == _cell_collection.get(key):
			if data:
				_level_data.cells_list[key] = data
			else:
				_level_data.cells_list.erase(key)


func _on_slider_change(ref: BuilderSlider, data: SliderData) -> void:
	for key: Vector2i in _slider_collection.keys():
		if ref == _slider_collection.get(key):
			if data:
				_level_data.slider_list[key] = data
			else:
				_level_data.slider_list.erase(key)


func _on_save_query_received(level_name: String, level_moves: int) -> void:
	_level_data.moves_left = level_moves
	_level_data.name = level_name
	SaveManager.save_custom_level(_level_data)
	_reset_builder_grid.call_deferred()


func _start_multiselection() -> void:
	_multiselection_start_pos = get_global_mouse_position()
	_multiselection_panel = Panel.new()
	_multiselection_panel.add_theme_stylebox_override("Panel", PANEL)
	_multiselection_panel.global_position = _multiselection_start_pos
	get_tree().root.add_child(_multiselection_panel)

	_multiselection_area = Area2D.new()
	_multiselection_area.area_entered.connect(on_multiselection_enter)
	_multiselection_area.area_exited.connect(on_multiselection_exit)
	_multiselection_area.global_position = _multiselection_start_pos
	_multiselection_area.set_collision_layer_value(1, false)
	_multiselection_area.set_collision_layer_value(3, true)
	_multiselection_area.set_collision_mask_value(1, false)
	_multiselection_area.set_collision_mask_value(3, true)

	get_tree().root.add_child(_multiselection_area)
	_multiselection_coll = CollisionShape2D.new()
	_multiselection_coll.shape = RectangleShape2D.new()
	_multiselection_area.add_child(_multiselection_coll)
	_multiselection_enabled = true


func _end_multiselection() -> void:
	_multiselection_enabled = false
	_multiselection_area.area_entered.disconnect(on_multiselection_enter)
	_multiselection_area.area_exited.disconnect(on_multiselection_exit)
	_multiselection_area.queue_free()
	_multiselection_panel.queue_free()

	GameManager.change_state(Constants.GameState.BUILDER_SELECTION)


func _process(_delta: float) -> void:
	if _multiselection_enabled:
		if !Input.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_end_multiselection()
			return
		var mouse_pos := get_global_mouse_position()
		var size := mouse_pos - _multiselection_start_pos
		_multiselection_panel.size = abs(size)
		_multiselection_panel.global_position.x = minf(mouse_pos.x, _multiselection_start_pos.x)
		_multiselection_panel.global_position.y = minf(mouse_pos.y, _multiselection_start_pos.y)
		_multiselection_area.global_position = _multiselection_start_pos + size / 2
		_multiselection_coll.shape.size = abs(size)


func on_multiselection_enter(area: Area2D) -> void:
	var cell: BuilderCell
	cell = area.get_parent()
	_multiselection_cells.append(cell)


func on_multiselection_exit(area: Area2D) -> void:
	var cell: BuilderCell
	cell = area.get_parent()
	_multiselection_cells.erase(cell)


func _reset_builder_grid() -> void:
	var height := _level_data.height
	var width := _level_data.width
	_level_data = LevelData.new()
	_level_data.height = height
	_level_data.width = width
	for x in range(_level_data.width):
		for y in range(_level_data.height):
			var coord := Vector2i(x, y)
			_level_data.cells_list[coord] = CellData.new()
	await get_tree().process_frame
	construct_level()


func _on_width_change(new_width: int) -> void:
	_level_data.width = new_width
	construct_level()


func _on_height_change(new_height: int) -> void:
	_level_data.height = new_height
	construct_level()


func move_grid(offset: Vector2) -> void:
	var new_pos: Vector2
	if offset == Vector2.ZERO:
		new_pos = get_viewport_rect().get_center() - Vector2(0, GameManager.CENTER_OFFSET)
	else:
		new_pos = grid.position + offset
	await create_tween().tween_property(grid, "position", new_pos, 0.05).from_current().finished


func get_level_data() -> LevelData:
	return _level_data


func is_valid_data() -> bool:
	return _level_data.is_valid_data()


## Randomizer is is a set of features that simplify the process of level creation by
## giving three basic functionalities:
##
## - Generate random holes on the given grid;
## - Generate random blocked cells on the given grid;
## - Generate a complete level covering all non-hole and non-blocked cells.
##
## @return `true` if correctly initialized. `false` otherwise.
func initialize_randomizer() -> bool:
	var options := ResourceLoader.load(RANDOMIZER_OPTIONS) as RandomizerOptions
	if options:
		_randomizer = Randomizer.new(options)
		add_child(_randomizer)
		return true
	return false


func generate_level(element: Constants.GenerationElement) -> void:
	match element:
		Constants.GenerationElement.HOLE:
			await _randomizer.create_holes(_level_data)
		Constants.GenerationElement.BLOCK:
			await _randomizer.create_block(_level_data)
		Constants.GenerationElement.SLIDER:
			await _randomizer.create_sliders(_level_data)

	construct_level.call_deferred(_level_data, true)
	_on_state_change.call_deferred(Constants.GameState.BUILDER_IDLE)
