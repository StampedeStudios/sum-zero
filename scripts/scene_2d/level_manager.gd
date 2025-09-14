## Handles level life cycle.
##
## Initialize the levels and handles level-related events.
class_name LevelManager extends Node2D

## Signal emitted when, after a slider is released, the grid results in only cells having zero as value.
signal on_level_complete
## Signal emitted each time a move effectively changes the state of the grid and needs to be counted as a valid move.
signal on_consume_move

const BASIC_CELL = preload("res://packed_scene/scene_2d/BasicCell.tscn")
const SLIDER_AREA = preload("res://packed_scene/scene_2d/SliderArea.tscn")

var grid_cells: Dictionary[Vector2i, Cell]
var grid_sliders: Array[SliderArea]
var _has_slider_active: bool
var _current_level: LevelData

@onready var grid: Node2D = %Grid
@onready var playable_area: Area2D = %PlayableArea
@onready var collider: CollisionShape2D = %Collider


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func init_level(current_level: LevelData) -> void:
	_clear()

	if current_level == null:
		GameManager.change_state(Constants.GameState.MAIN_MENU)
		push_error("Invalid initial level found")
		return

	_current_level = current_level
	var level_size: Vector2i
	var half_grid_size: Vector2
	var half_cell := roundi(float(Constants.Sizes.CELL_SIZE) / 2)
	level_size = Vector2i(current_level.width, current_level.height)
	half_grid_size = level_size * Constants.Sizes.CELL_SIZE / 2

	_init_grid(level_size)

	await get_tree().process_frame

	# Filling the level grid.
	for coord: Vector2i in current_level.cells_list.keys():
		var cell_instance := BASIC_CELL.instantiate()
		var relative_pos: Vector2
		var cell_offset: Vector2

		relative_pos = coord * Constants.Sizes.CELL_SIZE
		cell_offset = Vector2.ONE * Constants.Sizes.CELL_SIZE / 2
		grid.add_child(cell_instance)
		cell_instance.position = -half_grid_size + cell_offset + relative_pos
		cell_instance.init_cell(current_level.cells_list.get(coord))
		grid_cells[coord] = cell_instance

	await get_tree().process_frame

	# Placing sliders following a clockwise rotation.
	for coord: Vector2i in current_level.slider_list.keys():
		var edge: int = coord.x
		var dist: int = coord.y * Constants.Sizes.CELL_SIZE
		var x_pos: float
		var y_pos: float
		var angle: float

		match edge:
			0: # TOP
				angle = 90
				x_pos = -half_grid_size.x + half_cell + dist
				y_pos = -half_grid_size.y - half_cell

			1: # LEFT
				angle = 180
				x_pos = half_grid_size.x + half_cell
				y_pos = -half_grid_size.y + half_cell + dist

			2: # BOTTOM
				angle = 270
				x_pos = -half_grid_size.x + half_cell + dist
				y_pos = half_grid_size.y + half_cell

			3: # RIGHT
				angle = 0
				x_pos = -half_grid_size.x - half_cell
				y_pos = -half_grid_size.y + half_cell + dist

		var sc_instance := SLIDER_AREA.instantiate() as SliderArea
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.init_slider(current_level.slider_list.get(coord), _get_slider_extension(coord))
		sc_instance.alter_grid.connect(_check_grid)
		grid_sliders.append(sc_instance)

	await get_tree().process_frame


## Adds all tiles and sliders to the scene.
##
## If `animate` is true, objects are spawned in a circle starting from a random position.
## This creates a varied entry animation that feels different each time.
##
## @param animate If true, applies an entry animation to each spawned object.
func spawn_grid(animate: bool = true) -> void:
	self.show()

	if not animate:
		for cell: Cell in grid_cells.values():
			cell.show_cell(false)
		for slider in grid_sliders:
			slider.show_slider(false)
		return

	var grid_size: Vector2
	var level_size := Vector2i(_current_level.width, _current_level.height)
	grid_size = (level_size + Vector2i.ONE) * Constants.Sizes.CELL_SIZE * GameManager.level_scale.x

	var start_point: Vector2
	start_point.x = randf_range(-grid_size.x / 2, grid_size.x / 2)
	start_point.y = randf_range(-grid_size.y / 2, grid_size.y / 2)

	var start: Vector2 = grid.global_position + start_point
	var end: float = _get_max_radius(grid_size, start_point)
	var time: float = _get_time_relative_to_radius(end, grid_size)

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.tween_method(_on_radius_update.bind(start), 0.0, end, time).finished
	GameManager.change_state(Constants.GameState.PLAY_LEVEL)


func reset_level() -> void:
	for cell: Cell in grid_cells.values():
		cell.reset()
	for slider in grid_sliders:
		slider.reset()
	GameManager.change_state(Constants.GameState.PLAY_LEVEL)


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_START:
			self.visible = true
		Constants.GameState.PLAY_LEVEL:
			self.visible = true
		_:
			self.visible = false


## This method checks the whole grid and emits a 'level_complete' signal if it results completed.
## A level is considered complete whenever all existing cells have a value equal to zero.
##
## @param is_effective_move If a move alter the state of the grid is considered effective and needs
## to be counted as a user move.
func _check_grid(is_effective_move: bool) -> void:
	if is_effective_move:
		on_consume_move.emit()
	_has_slider_active = false

	var level_complete: bool = true
	for cell: Cell in grid_cells.values():
		if cell.get_cell_value() != 0:
			level_complete = false
			break

	if level_complete:
		on_level_complete.emit()


func _get_max_radius(size: Vector2, start: Vector2) -> float:
	var far_vertex: Vector2
	far_vertex.x = size.x if start.x <= 0 else -size.x
	far_vertex.y = size.y if start.y <= 0 else -size.y
	return start.distance_to(far_vertex / 2)


func _get_time_relative_to_radius(radius: float, size: Vector2) -> float:
	const STD_TIME: float = 0.5
	var min_radius := Vector2.ZERO.distance_to(size / 2)
	return radius / min_radius * STD_TIME


func _on_radius_update(progress: float, start_point: Vector2) -> void:
	queue_redraw()
	for cell: Cell in grid_cells.values():
		if cell.global_position.distance_to(start_point) < progress:
			cell.show_cell()
	for slider in grid_sliders:
		if slider.global_position.distance_to(start_point) < progress:
			slider.show_slider()


func _get_grid_positions(width: int, height: int) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for w: int in range(width):
		for h: int in range(height):
			result.append(Vector2i(w, h))
	result.shuffle()
	return result


func _clear() -> void:
	_has_slider_active = false
	for child in grid.get_children():
		child.queue_free()
	grid_cells.clear()
	grid_sliders.clear()


## Initialize the grid by applying its scale based on UI size and updating its position.
##
## @param level_scale 2-dimensional int indicating the amount of cells on each side of the grid.
func _init_grid(level_size: Vector2i) -> void:
	GameManager.set_level_scale(level_size.x, level_size.y)
	var grid_pos := get_viewport_rect().get_center() - Vector2(0, GameManager.CENTER_OFFSET)
	var grid_size := (level_size + Vector2i.ONE) * Constants.Sizes.CELL_SIZE

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


func _get_slider_extension(slider_coord: Vector2i) -> Array[Cell]:
	var result: Array[Cell]
	var direction: Vector2i
	var max_extension: int
	var origin: Vector2i

	match slider_coord.x:
		0:
			direction = Vector2i.DOWN
			max_extension = _current_level.height
			origin = Vector2i(slider_coord.y, 0)
		1:
			direction = Vector2i.LEFT
			max_extension = _current_level.width
			origin = Vector2i(_current_level.width - 1, slider_coord.y)
		2:
			direction = Vector2i.UP
			max_extension = _current_level.height
			origin = Vector2i(slider_coord.y, _current_level.height - 1)
		3:
			direction = Vector2i.RIGHT
			max_extension = _current_level.width
			origin = Vector2i(0, slider_coord.y)

	result.append(grid_cells.get(origin))

	for i in range(1, max_extension):
		var coord := origin + direction * i
		if !grid_cells.has(coord):
			break

		var cell := grid_cells.get(coord) as Cell
		if cell.is_cell_blocked():
			break

		result.append(cell)

	return result
