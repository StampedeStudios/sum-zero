extends Node2D

const CELL = preload("res://scenes/BuilderCell.tscn")
const SLIDER = preload("res://assets/scenes/minus.png")
const LEVEL_INFO_QUERY = preload("res://scenes/LevelInfoQuery.tscn")

@onready var grid = $Grid


func _ready():
	var query: Query = LEVEL_INFO_QUERY.instantiate()
	get_tree().root.add_child.call_deferred(query)
	query.on_confirm.connect(_init_level)
	grid.position = get_viewport_rect().get_center()


func _init_level(width: int, height: int) -> void:

	var half_grid = Vector2(width, height) * GameManager.cell_size / 2
	var half_cell = Vector2.ONE * GameManager.cell_size / 2 
	var	cell_scale = GameManager.cell_size / GlobalConst.CELL_SIZE
		
	for columun in range(0, width):
		for row in range(0, height):
			var cell_coord := Vector2i(columun, row)
			var cell_pos := cell_coord * GameManager.cell_size
			
			var cell := CELL.instantiate()
			cell.position = -half_grid + cell_pos + half_cell
			cell.scale = Vector2(cell_scale, cell_scale)
						
			grid.add_child(cell)
