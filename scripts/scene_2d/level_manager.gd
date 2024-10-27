class_name LevelManager extends Node2D

const BASIC_CELL = preload("res://packed_scene/scene_2d/BasicCell.tscn")
const SLIDER_AREA = preload("res://packed_scene/scene_2d/SliderArea.tscn")
const LEVEL_END = preload("res://packed_scene/user_interface/LevelEnd.tscn")

var grid_cells: Array[Cell]
var _is_test_mode: bool

@onready var grid = %Grid


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	grid.position = get_viewport_rect().get_center()
	grid.scale = GameManager.level_scale


func set_manager_mode(is_test_mode: bool) -> void:
	_is_test_mode = is_test_mode
	if _is_test_mode:
		GameManager.builder_test.reset_test_level.connect(_reset_level)
	else:
		GameManager.game_ui.reset_level.connect(_reset_level)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			self.visible = true
		_:
			self.visible = false


func init_level(current_level: LevelData) -> void:
	_clear()
	if current_level == null:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
		push_error("Livello non valido!")
		return

	var level_size: Vector2i
	var half_grid_size: Vector2

	level_size = Vector2i(current_level.width, current_level.height)
	half_grid_size = level_size * GlobalConst.CELL_SIZE / 2

	# placing cells
	for coord in current_level.cells_list.keys():
		var cell_instance := BASIC_CELL.instantiate()
		var relative_pos: Vector2
		var cell_offset: Vector2
		relative_pos = coord * GlobalConst.CELL_SIZE
		cell_offset = Vector2.ONE * GlobalConst.CELL_SIZE / 2
		grid.add_child(cell_instance)
		cell_instance.position = -half_grid_size + cell_offset + relative_pos
		cell_instance.init_cell(current_level.cells_list.get(coord))
		grid_cells.append(cell_instance)

	# placing slider areas clockwise
	for coord in current_level.slider_list.keys():
		var edge: int = coord.x
		var dist: int = coord.y * GlobalConst.CELL_SIZE
		var x_pos: float
		var y_pos: float
		var angle: float

		match edge:
			# TOP
			0:
				angle = 90
				x_pos = -half_grid_size.x + GlobalConst.CELL_SIZE / 2 + dist
				y_pos = -half_grid_size.y - GlobalConst.CELL_SIZE / 2
			# LEFT
			1:
				angle = 180
				x_pos = half_grid_size.x + GlobalConst.CELL_SIZE / 2
				y_pos = -half_grid_size.y + GlobalConst.CELL_SIZE / 2 + dist
			# BOTTOM
			2:
				angle = 270
				x_pos = -half_grid_size.x + GlobalConst.CELL_SIZE / 2 + dist
				y_pos = half_grid_size.y + GlobalConst.CELL_SIZE / 2
			# RIGHT
			3:
				angle = 0
				x_pos = -half_grid_size.x - GlobalConst.CELL_SIZE / 2
				y_pos = -half_grid_size.y + GlobalConst.CELL_SIZE / 2 + dist

		var sc_instance = SLIDER_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.init_slider(current_level.slider_list.get(coord))
		sc_instance.scale_change.connect(check_grid)
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid_cells.clear()


func check_grid() -> void:
	var level_complete: bool
	for cell in grid_cells:
		if cell.get_cell_value() == 0:
			level_complete = true
		else:
			level_complete = false
			break
	if level_complete and !_is_test_mode:
		if GameManager.level_end == null:
			var level_end := LEVEL_END.instantiate()
			get_tree().root.add_child.call_deferred(level_end)
			level_end.restart_level.connect(_reset_level)
			GameManager.level_end = level_end
		GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_END)


func _reset_level() -> void:
	for child in grid.get_children():
		child.reset()
	GameManager.change_state(GlobalConst.GameState.LEVEL_START)
