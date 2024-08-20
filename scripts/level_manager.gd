extends Node2D

const BASIC_TILE = preload("res://scenes/BasicTile.tscn")
const SCALABLE_AREA = preload("res://scenes/ScalableArea.tscn")

var half_grid_size: Vector2
var selected_area: ScalableArea = null
var selected_tile: Tile = null
var is_handled: bool
var grid_tiles: Array[Tile]

@onready var grid: Node2D = $Grid


func _ready() -> void:
	GameManager.level_loading.connect(init)
	GameManager.level_end.connect(on_level_complete)
	GameManager.load_level()

	get_viewport().size_changed.connect(_on_size_changed)


# Called when the node enters the scene tree for the first time.
func init(current_level: LevelData) -> void:
	_clear()

	var level_size: Vector2i 
	level_size = Vector2i(current_level.cells_values[0].size(), current_level.cells_values.size())

	half_grid_size = level_size * GlobalConst.CELL_SIZE / 2
	
	# placing tiles
	for row in range(0, level_size.y):
		var row_cells: Array = current_level.cells_values[row]
		for column in range(0, level_size.x):
			var tile_instance := BASIC_TILE.instantiate()
			var tile_x_pos := (column - float(level_size.x) / 2) * GlobalConst.CELL_SIZE
			var tile_y_pos := (row - float(level_size.y) / 2) * GlobalConst.CELL_SIZE

			tile_instance.position = Vector2(tile_x_pos, tile_y_pos)
			grid.add_child(tile_instance)
			tile_instance.init(row_cells[column])
			grid_tiles.append(tile_instance)
			tile_instance.enter.connect(_on_tile_enter)
			tile_instance.exit.connect(_on_tile_exit)
			tile_instance.click.connect(_on_click)

	# placing scalable areas clockwise
	for sc_index in current_level.handles_positions:
		var x_pos: float
		var y_pos: float
		var is_horizontal: bool
		var extend_limit: int
		var reachable_tiles: Array[Tile]
		var temp: int

		if sc_index > 0 and sc_index <= level_size.x:
			extend_limit = level_size.y
			is_horizontal = false
			x_pos = -half_grid_size.x - GlobalConst.CELL_SIZE / 2 + GlobalConst.CELL_SIZE * sc_index
			y_pos = -half_grid_size.y

			temp = sc_index - 1
			while temp < grid_tiles.size():
				reachable_tiles.append(grid_tiles[temp])
				temp += level_size.x

		elif sc_index > level_size.x and sc_index <= (level_size.x + level_size.y):
			extend_limit = -level_size.x
			is_horizontal = true
			x_pos = half_grid_size.x
			y_pos = -half_grid_size.y - GlobalConst.CELL_SIZE / 2 + GlobalConst.CELL_SIZE * (sc_index - level_size.x)

			temp = level_size.x * (sc_index - level_size.x) - 1
			for i in range(temp, temp - level_size.x, -1):
				reachable_tiles.append(grid_tiles[i])

		elif (sc_index > (level_size.x + level_size.y) and sc_index <= (level_size.x * 2 + level_size.y)):
			extend_limit = -level_size.y
			is_horizontal = false
			x_pos = (half_grid_size.x + GlobalConst.CELL_SIZE / 2 - GlobalConst.CELL_SIZE * (sc_index - level_size.x - level_size.y)			)
			y_pos = half_grid_size.y

			temp = grid_tiles.size() - (sc_index - level_size.x - level_size.y)
			while temp > 0:
				reachable_tiles.append(grid_tiles[temp])
				temp -= level_size.x

		elif sc_index > (level_size.x * 2 + level_size.y):
			extend_limit = level_size.x
			is_horizontal = true
			x_pos = -half_grid_size.x
			y_pos = (half_grid_size.y + GlobalConst.CELL_SIZE / 2 - GlobalConst.CELL_SIZE * (sc_index - level_size.x * 2 - level_size.y)			)

			temp = grid_tiles.size() - (sc_index - level_size.x * 2 - level_size.y) * level_size.x
			for i in range(temp, temp + level_size.x):
				reachable_tiles.append(grid_tiles[i])

		var sc_instance = SCALABLE_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos, y_pos)
		sc_instance.init(is_horizontal, extend_limit, reachable_tiles)
		sc_instance.click.connect(_on_click)
		sc_instance.scale_change.connect(check_grid)
		sc_instance.enter.connect(_on_handle_enter)
		sc_instance.exit.connect(_on_handle_exit)

	_on_size_changed()


func _process(_delta: float) -> void:
	if is_handled and Input.is_action_just_released("click"):
		is_handled = false
		selected_area.release_handle()
				

func _on_size_changed() -> void:
	var viewport_size = get_viewport_rect().size
	grid.position = Vector2(viewport_size.x - max(GameManager.level_size / 2, (viewport_size.x - GlobalConst.UI_MAX_WIDTH) / 2) , viewport_size.y / 2)


func _on_click() -> void:
	if selected_area:
		is_handled = true
		selected_area.is_scaling = true


func _on_tile_enter(tile: Tile, area: ScalableArea) -> void:
	if !is_handled:
		if selected_tile == null: # entro dal vuoto o da un handle
			selected_tile = tile
			if selected_area == null: # entro dal vuoto in una cella
				if area != null: # entro in una cella attiva
					selected_area = area
					selected_area.toggle_highlight(true)
			else: # entro da un handle in una cella
				if area == null: # entro in una cella non attiva
					selected_area.toggle_highlight(false)
					selected_area = null
				else: # entro in una cella attiva
					if area != selected_area:
						selected_area.toggle_highlight(false)
						selected_area = area
						selected_area.toggle_highlight(true)
		else: # entro da una cella adiacente
			selected_tile = tile
			if selected_area == null: # entro da una cella non attiva
				if area != null: # entro in una cella attiva
					selected_area = area
					selected_area.toggle_highlight(true)
			else: # entro da una cella attiva
				if area == null: # entro in una cella non attiva
					selected_area.toggle_highlight(false)
					selected_area = null
				else: # entro in una cella attiva
					if area != selected_area:
						selected_area.toggle_highlight(false)
						selected_area = area
						selected_area.toggle_highlight(true)
						

func _on_tile_exit(tile: Tile) -> void:
	if !is_handled:
		if tile == selected_tile: # esco nel vuoto o su un handle
			if selected_area != null:
				selected_area.toggle_highlight(false)
				selected_area = null
				selected_tile = null		


func _on_handle_enter(handle: ScalableArea) -> void:
	if !is_handled:
		if selected_tile == null: # entro dal vuoto o da un handle adiacente
			if selected_area == null: # entro dal vuoto
				selected_area = handle
				selected_area.toggle_highlight(true)
			else: # entro da un handle adiacente
				selected_area.toggle_highlight(false)
				selected_area = handle
				selected_area.toggle_highlight(true)
		else: # entro da una cella adiacente
			selected_tile = null
			if selected_area == null: # entro da cella non attiva
				selected_area = handle
				selected_area.toggle_highlight(true)
			else: # entro da cella attiva
				if handle != selected_area:
					selected_area.toggle_highlight(false)
					selected_area = handle
					selected_area.toggle_highlight(true)				


func _on_handle_exit(handle: ScalableArea) -> void:
	if !is_handled:
		if selected_tile == null: # esco nel vuoto o un handle adiacente
			if selected_area == handle: # esco nel vuoto
				selected_area.toggle_highlight(false)
				selected_area = null
			
							
func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()

	grid_tiles = []
	selected_area = null
	selected_tile = null
	is_handled = false

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
	
