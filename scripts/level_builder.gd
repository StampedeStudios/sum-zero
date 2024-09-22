extends Node2D

const CELL = preload("res://scenes/BuilderCell.tscn")
const SLIDER = preload("res://scenes/BuilderSlider.tscn")
const LEVEL_INFO_QUERY = preload("res://scenes/LevelInfoQuery.tscn")

@onready var grid = $Grid


func _ready():
	var query: Query = LEVEL_INFO_QUERY.instantiate()
	get_tree().root.add_child.call_deferred(query)
	query.on_confirm.connect(_init_level)
	grid.position = get_viewport_rect().get_center()


func _init_level(width: int, height: int) -> void:

	var half_grid:= Vector2(width, height) * GameManager.cell_size / 2
	var half_cell:= Vector2.ONE * GameManager.cell_size / 2 
	var	cell_scale: Vector2
	cell_scale.x = (GameManager.cell_size / GlobalConst.CELL_SIZE)
	cell_scale.y = (GameManager.cell_size / GlobalConst.CELL_SIZE)
	
	# add cell space	
	for columun in range(0, width):
		for row in range(0, height):
			var cell_coord := Vector2i(columun, row)
			var cell_pos := cell_coord * GameManager.cell_size
			var cell := CELL.instantiate()
			cell.position = -half_grid + cell_pos + half_cell
			cell.scale = cell_scale
			grid.add_child(cell)
	
	var slider_index: int = 0
	var slider_pos: Vector2
	var edge_start_pos: Vector2
	
	# add slider space
	# TOP
	for column in range(0, width):
		slider_index += 1
		var slider:= SLIDER.instantiate()
		slider_pos.x = column * GameManager.cell_size
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y - half_cell.y
		slider.position = edge_start_pos + slider_pos	
		slider.scale = cell_scale
		slider.rotation_degrees = 90
		grid.add_child(slider)
	 # RIGHT
	for row in range(0, height):
		slider_index += 1
		var slider:= SLIDER.instantiate()
		slider_pos.x = 0
		slider_pos.y = row * GameManager.cell_size
		edge_start_pos.x = half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos	
		slider.scale = cell_scale
		slider.rotation_degrees = 180
		grid.add_child(slider)	
	# BOTTOM
	for column in range(0, width):
		slider_index += 1
		var slider:= SLIDER.instantiate()
		slider_pos.x = -column * GameManager.cell_size
		slider_pos.y = 0
		edge_start_pos.x = half_grid.x - half_cell.x
		edge_start_pos.y = half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos	
		slider.scale = cell_scale
		slider.rotation_degrees = 270
		grid.add_child(slider)	
	# LEFT
	for row in range(0, height):
		slider_index += 1
		var slider:= SLIDER.instantiate()
		slider_pos.x = 0
		slider_pos.y = -row * GameManager.cell_size
		edge_start_pos.x = -half_grid.x - half_cell.x
		edge_start_pos.y = half_grid.y - half_cell.y
		slider.position = edge_start_pos + slider_pos	
		slider.scale = cell_scale
		slider.rotation_degrees = 0
		grid.add_child(slider)
