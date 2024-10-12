class_name LevelManager extends Node2D

const BASIC_CELL = preload("res://packed_scene/scene_2d/BasicCell.tscn")
const SLIDER_AREA = preload("res://packed_scene/scene_2d/SliderArea.tscn")

var grid_cells: Array[Cell]

@onready var grid = %Grid


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	grid.position = get_viewport_rect().get_center()

	if GameManager.builder_test != null:
		GameManager.builder_test.reset_test_level.connect(_reset_level)
	if GameManager.game_ui != null:
		GameManager.game_ui.reset_level.connect(_reset_level)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()		
		GlobalConst.GameState.LEVEL_START:
			self.visible = true			
		GlobalConst.GameState.LEVEL_END:
			self.visible = true		
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = false		
		GlobalConst.GameState.BUILDER_TEST:
			self.visible = true		
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = false		
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = false		
		GlobalConst.GameState.BUILDER_RESIZE:
			self.visible = false				


func init_level(current_level: LevelData) -> void:
	_clear()
	var level_size: Vector2i
	var half_grid_size: Vector2
	var cell_scale: float

	level_size = Vector2i(current_level.width, current_level.height)
	cell_scale = GameManager.cell_size / GlobalConst.CELL_SIZE
	half_grid_size = level_size * GameManager.cell_size / 2

	# placing cells
	for coord in current_level.cells_list.keys():
		var cell_instance := BASIC_CELL.instantiate()
		var relative_pos: Vector2 
		var cell_offset: Vector2
		relative_pos = coord * GameManager.cell_size
		cell_offset = Vector2.ONE * GameManager.cell_size / 2
		grid.add_child(cell_instance)
		cell_instance.position = -half_grid_size + cell_offset + relative_pos
		cell_instance.scale = Vector2(cell_scale, cell_scale)
		cell_instance.init_cell(current_level.cells_list.get(coord))
		grid_cells.append(cell_instance)

	# placing slider areas clockwise
	for coord in current_level.slider_list.keys():
		var edge: int = coord.x
		var dist: int = coord.y * GameManager.cell_size
		var x_pos: float
		var y_pos: float
		var angle: float

		match edge:
			# TOP
			0:
				angle = 90
				x_pos = -half_grid_size.x + GameManager.cell_size / 2 + dist
				y_pos = -half_grid_size.y - GameManager.cell_size / 2
			# LEFT
			1:
				angle = 180
				x_pos = half_grid_size.x + GameManager.cell_size / 2
				y_pos = -half_grid_size.y + GameManager.cell_size / 2 + dist
			# BOTTOM
			2:
				angle = 270
				x_pos = -half_grid_size.x + GameManager.cell_size / 2 + dist
				y_pos = half_grid_size.y + GameManager.cell_size / 2
			# RIGHT
			3:
				angle = 0
				x_pos = -half_grid_size.x - GameManager.cell_size / 2
				y_pos = -half_grid_size.y + GameManager.cell_size / 2 + dist

		var sc_instance = SLIDER_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.scale = Vector2(cell_scale, cell_scale)
		sc_instance.init_slider(current_level.slider_list.get(coord))
		sc_instance.scale_change.connect(check_grid)
		GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid_cells = []


func check_grid() -> void:
	var level_complete: bool
	for cell in grid_cells:
		if cell.get_cell_value() == 0:
			level_complete = true
		else:
			level_complete = false
			break
	if level_complete:
		print("level complete")


func _reset_level() -> void:
	for child in grid.get_children():
		child.reset()	


func on_level_complete() -> void:
	print("Complete")
