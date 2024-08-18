extends Node2D

const LEVEL_FOLDER_PATH := "res://assets/resources/"
const BASIC_TILE = preload("res://scenes/BasicTile.tscn")
const TILE_SIZE: int = 128
const GRID_OFFSET: float = 128.0

var level_data: Array[LevelData]
var grid_size: Vector2

@onready var grid: Node2D = $Grid


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_levels()

	var current_level: LevelData = level_data[0]  # TODO: Fix data
	var level_size: Vector2i = Vector2i(
		current_level.cells_values.size(), current_level.cells_values[0].size()
	)

	grid_size = level_size * TILE_SIZE / 2

	for x in range(0, level_size.x):
		var row_cells: Array = current_level.cells_values[x]
		for y in range(0, level_size.y):
			var tile_instance := BASIC_TILE.instantiate()
			var tile_x_pos := (x - float(level_size.x) / 2) * TILE_SIZE
			var tile_y_pos := (y - float(level_size.y) / 2) * TILE_SIZE

			tile_instance.position = Vector2(tile_x_pos, tile_y_pos)
			grid.add_child(tile_instance)

			tile_instance.init(row_cells[y])

	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()


func _on_size_changed() -> void:
	var viewport_size = get_viewport_rect().size
	grid.position = Vector2(viewport_size.x - grid_size.x - GRID_OFFSET, viewport_size.y / 2)


func _load_levels() -> void:
	var level_folder: DirAccess = DirAccess.open(LEVEL_FOLDER_PATH)
	for file in level_folder.get_files():
		level_data.append(load(LEVEL_FOLDER_PATH + file))
