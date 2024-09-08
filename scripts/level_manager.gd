extends Node2D

const BASIC_TILE = preload("res://scenes/BasicTile.tscn")
const SLIDER_AREA = preload("res://scenes/SliderArea.tscn")

var half_grid_size: Vector2
var grid_tiles: Array[Tile]

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
	level_size = Vector2i(current_level.cells_values[0].size(), current_level.cells_values.size())
	
	var cell_scale: float
	cell_scale = GameManager.CELL_SIZE / GlobalConst.CELL_SIZE
	
	half_grid_size = level_size * GameManager.CELL_SIZE / 2

	# placing tiles
	for row in range(0, level_size.y):
		var row_cells: Array = current_level.cells_values[row]
		for column in range(0, level_size.x):
			var tile_instance := BASIC_TILE.instantiate()
			var tile_x_pos := (
				(column - float(level_size.x) / 2) *  GameManager.CELL_SIZE
				+  GameManager.CELL_SIZE / 2
			)
			var tile_y_pos := (
				(row - float(level_size.y) / 2) *  GameManager.CELL_SIZE +  GameManager.CELL_SIZE / 2
			)

			grid.add_child(tile_instance)
			tile_instance.position = Vector2(tile_x_pos, tile_y_pos)
			tile_instance.scale = Vector2(cell_scale,cell_scale)
			tile_instance.init(row_cells[column])
			grid_tiles.append(tile_instance)

	# placing scalable areas clockwise
	for index in range(0, current_level.handles_positions.size()):
		var sc_index: int = current_level.handles_positions[index]
		var x_pos: float
		var y_pos: float
		var is_horizontal: bool
		var reachable_tiles: Array[Tile]
		var temp: int
		var angle: float

		if sc_index > 0 and sc_index <= level_size.x:
			angle = 90
			is_horizontal = false
			x_pos = -half_grid_size.x -  GameManager.CELL_SIZE / 2 +  GameManager.CELL_SIZE * sc_index
			y_pos = -half_grid_size.y

			temp = sc_index - 1
			while temp < grid_tiles.size():
				reachable_tiles.append(grid_tiles[temp])
				temp += level_size.x

		elif sc_index > level_size.x and sc_index <= (level_size.x + level_size.y):
			angle = 180
			is_horizontal = true
			x_pos = half_grid_size.x
			y_pos = (
				-half_grid_size.y
				-  GameManager.CELL_SIZE / 2
				+  GameManager.CELL_SIZE * (sc_index - level_size.x)
			)

			temp = level_size.x * (sc_index - level_size.x) - 1
			for i in range(temp, temp - level_size.x, -1):
				reachable_tiles.append(grid_tiles[i])

		elif (
			sc_index > (level_size.x + level_size.y)
			and sc_index <= (level_size.x * 2 + level_size.y)
		):
			angle = 270
			is_horizontal = false
			x_pos = (
				half_grid_size.x
				+  GameManager.CELL_SIZE / 2
				-  GameManager.CELL_SIZE * (sc_index - level_size.x - level_size.y)
			)
			y_pos = half_grid_size.y

			temp = grid_tiles.size() - (sc_index - level_size.x - level_size.y)
			while temp > 0:
				reachable_tiles.append(grid_tiles[temp])
				temp -= level_size.x

		elif sc_index > (level_size.x * 2 + level_size.y):
			angle = 0
			is_horizontal = true
			x_pos = -half_grid_size.x
			y_pos = (
				half_grid_size.y
				+  GameManager.CELL_SIZE / 2
				-  GameManager.CELL_SIZE * (sc_index - level_size.x * 2 - level_size.y)
			)

			temp = grid_tiles.size() - (sc_index - level_size.x * 2 - level_size.y) * level_size.x
			for i in range(temp, temp + level_size.x):
				reachable_tiles.append(grid_tiles[i])

		var sc_instance = SLIDER_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.rotation_degrees = angle
		sc_instance.scale = Vector2(cell_scale,cell_scale)
		sc_instance.init(
			is_horizontal, reachable_tiles, current_level.handles_increment[index]
		)
		sc_instance.scale_change.connect(check_grid)

	_on_size_changed()


func _on_size_changed() -> void:
	var viewport_size = get_viewport_rect().size
	grid.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)


func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid_tiles = []


func check_grid() -> void:
	var level_complete: bool

	for tile in grid_tiles:
		if tile.value == 0:
			level_complete = true
		else:
			level_complete = false
			break

	if level_complete:
		GameManager.level_complete()


func on_level_complete() -> void:
	print("Complete")
