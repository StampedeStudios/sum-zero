extends Node2D

const LEVEL_FOLDER_PATH := "res://assets/resources/"
const BASIC_TILE = preload("res://scenes/BasicTile.tscn")
const SCALABLE_AREA = preload("res://scenes/ScalableArea.tscn")
const CELL_SIZE: float = 128
const GRID_OFFSET: float = 128.0

var level_data: Array[LevelData]
var half_grid_size: Vector2
var handled_area: ScalableArea = null
var grid_tiles: Array[Tile]

@onready var grid: Node2D = $Grid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_levels()

	var current_level: LevelData = level_data[0]  # TODO: Fix data
	var level_size: Vector2i = Vector2i(
		current_level.cells_values.size(), current_level.cells_values[0].size()
	)

	half_grid_size = level_size * CELL_SIZE / 2
	
	# placing tiles
	for row in range(0, level_size.y):
		var row_cells: Array = current_level.cells_values[row]
		for column in range(0, level_size.x):
			var tile_instance := BASIC_TILE.instantiate()
			var tile_x_pos := (column - float(level_size.x) / 2) * CELL_SIZE
			var tile_y_pos := (row - float(level_size.y) / 2) * CELL_SIZE

			tile_instance.position = Vector2(tile_x_pos, tile_y_pos)
			grid.add_child(tile_instance)
			tile_instance.init(row_cells[column])
			grid_tiles.append(tile_instance)

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
			x_pos = -half_grid_size.x  - CELL_SIZE / 2 + CELL_SIZE * sc_index
			y_pos = -half_grid_size.y
			
			temp = sc_index - 1
			while temp < grid_tiles.size():
				reachable_tiles.append(grid_tiles[temp]) 
				temp += level_size.x
						
		elif sc_index > level_size.x and sc_index <= (level_size.x + level_size.y):
			extend_limit = -level_size.x
			is_horizontal = true
			x_pos = half_grid_size.x
			y_pos = -half_grid_size.y - CELL_SIZE / 2 + CELL_SIZE * (sc_index - level_size.x)
			
			temp = level_size.x * (sc_index - level_size.x) -1
			for i in range(temp, temp-level_size.x,-1):
				reachable_tiles.append(grid_tiles[i])
		
		elif sc_index > (level_size.x + level_size.y) and sc_index <= (level_size.x * 2 + level_size.y):
			extend_limit = -level_size.y
			is_horizontal = false
			x_pos = half_grid_size.x  + CELL_SIZE / 2 - CELL_SIZE * (sc_index -level_size.x - level_size.y) 
			y_pos = half_grid_size.y 
			
			temp = grid_tiles.size() - (sc_index - level_size.x - level_size.y)
			while temp > 0:
				reachable_tiles.append(grid_tiles[temp]) 
				temp -= level_size.x			
				
		elif sc_index > (level_size.x * 2 + level_size.y):
			extend_limit = level_size.x
			is_horizontal = true
			x_pos = -half_grid_size.x
			y_pos = half_grid_size.y + CELL_SIZE / 2 - CELL_SIZE * (sc_index - level_size.x * 2 - level_size.y)
			
			temp = grid_tiles.size() - (sc_index - level_size.x * 2 - level_size.y) * level_size.x
			for i in range(temp, temp + level_size.x):
				reachable_tiles.append(grid_tiles[i])
			
		var sc_instance = SCALABLE_AREA.instantiate()
		grid.add_child(sc_instance)
		sc_instance.position = Vector2(x_pos,y_pos)
		sc_instance.init(is_horizontal,extend_limit, reachable_tiles)
		sc_instance.clicked.connect(_on_scalable_area_clicked)
					
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()


func _on_size_changed() -> void:
	var viewport_size = get_viewport_rect().size
	grid.position = Vector2(viewport_size.x - half_grid_size.x - GRID_OFFSET, viewport_size.y / 2)


func _load_levels() -> void:
	var level_folder: DirAccess = DirAccess.open(LEVEL_FOLDER_PATH)
	for file in level_folder.get_files():
		level_data.append(load(LEVEL_FOLDER_PATH + file))


func _on_scalable_area_clicked(ref:ScalableArea) -> void:
	if handled_area: 
		if handled_area == ref:
			handled_area.is_scaling = false
			handled_area = null
	else:
		handled_area = ref
		handled_area.is_scaling = true		
	
