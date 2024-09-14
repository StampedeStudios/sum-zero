extends Node2D

const BASIC_CELL = preload("res://scenes/BasicCell.tscn")
const SLIDER_AREA = preload("res://scenes/SliderArea.tscn")

var grid_cells: Array[Cell]

@onready var grid: Node2D = $Grid


func _ready() -> void:
	GameManager.level_loading.connect(init)
	GameManager.level_end.connect(on_level_complete)
	GameManager.toggle_level_visibility.connect(
		func(visibility: bool) -> void: grid.visible = visibility
	)
	GameManager.load_level()

	get_viewport().size_changed.connect(_on_size_changed)


# Called when the node enters the scene tree for the first time.
func init(current_level: LevelData) -> void:
	_clear()
	var level_size: Vector2i
	var half_grid_size: Vector2
	var cell_scale: float

	level_size = Vector2i(current_level.width, current_level.height)
	cell_scale = GameManager.cell_size / GlobalConst.CELL_SIZE
	half_grid_size = level_size * GameManager.cell_size / 2

	# placing cells
	for cell in current_level.cells_list:
		var cell_instance := BASIC_CELL.instantiate()
		var relative_pos := Vector2(cell.column, cell.row) * GameManager.cell_size
		var cell_offset := Vector2.ONE * GameManager.cell_size / 2

		grid.add_child(cell_instance)
		cell_instance.position = -half_grid_size + cell_offset + relative_pos
		cell_instance.scale = Vector2(cell_scale, cell_scale)
		cell_instance.init(cell.value, cell.is_blocked)
		grid_cells.append(cell_instance)

	# placing slider areas clockwise
	for sc_index in current_level.slider_position.keys():
		var x_pos: float
		var y_pos: float
		var angle: float

		if sc_index > 0 and sc_index <= level_size.x:
			angle = 90
			x_pos = -half_grid_size.x - GameManager.cell_size / 2 + GameManager.cell_size * sc_index
			y_pos = -half_grid_size.y - GameManager.cell_size / 2

		elif sc_index > level_size.x and sc_index <= (level_size.x + level_size.y):
			angle = 180
			x_pos = half_grid_size.x + GameManager.cell_size / 2
			y_pos = (
				-half_grid_size.y
				- GameManager.cell_size / 2
				+ GameManager.cell_size * (sc_index - level_size.x)
			)

		elif (
			sc_index > (level_size.x + level_size.y)
			and sc_index <= (level_size.x * 2 + level_size.y)
		):
			angle = 270
			x_pos = (
				half_grid_size.x
				+ GameManager.cell_size / 2
				- GameManager.cell_size * (sc_index - level_size.x - level_size.y)
			)
			y_pos = half_grid_size.y + GameManager.cell_size / 2

		elif sc_index > (level_size.x * 2 + level_size.y):
			angle = 0
			x_pos = -half_grid_size.x - GameManager.cell_size / 2
			y_pos = (
				half_grid_size.y
				+ GameManager.cell_size / 2
				- GameManager.cell_size * (sc_index - level_size.x * 2 - level_size.y)
			)

		var sc_instance = SLIDER_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.scale = Vector2(cell_scale, cell_scale)
		sc_instance.init(current_level.slider_position.get(sc_index))
		sc_instance.scale_change.connect(check_grid)

	_on_size_changed()


func _on_size_changed() -> void:
	var viewport_size = get_viewport_rect().size
	grid.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)


func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid_cells = []


func check_grid() -> void:
	var level_complete: bool

	for tile in grid_cells:
		if tile.get_cell_value() == 0:
			level_complete = true
		else:
			level_complete = false
			break

	if level_complete:
		GameManager.level_complete()


func on_level_complete() -> void:
	print("Complete")
