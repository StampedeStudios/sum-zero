class_name LevelManager extends Node2D

signal on_level_complete
signal on_consume_move

const BASIC_CELL = preload("res://packed_scene/scene_2d/BasicCell.tscn")
const SLIDER_AREA = preload("res://packed_scene/scene_2d/SliderArea.tscn")

var grid_cells: Array[Cell]
var grid_sliders: Array[SliderArea]
var _has_slider_active: bool

@onready var grid: Node2D = %Grid
@onready var playable_area: Area2D = %PlayableArea
@onready var collider: CollisionShape2D = %Collider


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			self.visible = true
		_:
			self.visible = false


func init_level(current_level: LevelData) -> void:
	_clear()
	if current_level == null:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
		push_error("Invalid level!")
		return

	var level_size: Vector2i
	var half_grid_size: Vector2
	var half_cell := roundi(float(GlobalConst.CELL_SIZE) / 2)
	level_size = Vector2i(current_level.width, current_level.height)
	half_grid_size = level_size * GlobalConst.CELL_SIZE / 2

	_init_grid(level_size)

	# placing cells
	for coord: Vector2i in current_level.cells_list.keys():
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
	for coord: Vector2i in current_level.slider_list.keys():
		var edge: int = coord.x
		var dist: int = coord.y * GlobalConst.CELL_SIZE
		var x_pos: float
		var y_pos: float
		var angle: float

		match edge:
			# TOP
			0:
				angle = 90
				x_pos = -half_grid_size.x + half_cell + dist
				y_pos = -half_grid_size.y - half_cell
			# LEFT
			1:
				angle = 180
				x_pos = half_grid_size.x + half_cell
				y_pos = -half_grid_size.y + half_cell + dist
			# BOTTOM
			2:
				angle = 270
				x_pos = -half_grid_size.x + half_cell + dist
				y_pos = half_grid_size.y + half_cell
			# RIGHT
			3:
				angle = 0
				x_pos = -half_grid_size.x - half_cell
				y_pos = -half_grid_size.y + half_cell + dist

		var sc_instance := SLIDER_AREA.instantiate() as SliderArea
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.init_slider.call_deferred(current_level.slider_list.get(coord))
		sc_instance.alter_grid.connect(check_grid)
		grid_sliders.append(sc_instance)
	await get_tree().process_frame
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _clear() -> void:
	_has_slider_active = false
	for child in grid.get_children():
		child.queue_free()
	grid_cells.clear()
	grid_sliders.clear()


func check_grid(move_count: bool) -> void:
	if move_count:
		on_consume_move.emit()
	var level_complete: bool
	_has_slider_active = false
	for cell in grid_cells:
		if cell.get_cell_value() == 0:
			level_complete = true
		else:
			level_complete = false
			break
	if level_complete:
		on_level_complete.emit()


func reset_level() -> void:
	for child in grid.get_children():
		if child is SliderArea:
			child.reset()
		elif child is Cell:
			child.reset()
	GameManager.change_state(GlobalConst.GameState.LEVEL_START)


func _init_grid(level_size: Vector2i) -> void:
	GameManager.set_level_scale(level_size.x, level_size.y)
	var grid_pos := get_viewport_rect().get_center() - Vector2(0, GameManager.CENTER_OFFSET)
	var grid_size := (level_size + Vector2i.ONE) * GlobalConst.CELL_SIZE
	grid.position = grid_pos
	grid.scale = GameManager.level_scale
	playable_area.position = grid_pos
	playable_area.scale = GameManager.level_scale
	collider.shape.size = grid_size


func _on_playable_area_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !_has_slider_active:
			var min_distance: float = GameManager.cell_size / 2
			var selected_slider: SliderArea
			for slider in grid_sliders:
				var pos := slider.get_slider_position()
				var distance := pos.distance_to(_event.global_position)
				if distance < min_distance:
					min_distance = distance
					selected_slider = slider
			if selected_slider != null:
				_has_slider_active = true
				selected_slider.activate_slider()
