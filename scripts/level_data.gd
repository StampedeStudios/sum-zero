class_name LevelData
extends Resource

@export_range(2, 5) var width: int = 3
@export_range(2, 5) var height: int = 3
## KEY: Cell coordinate (column, row) [br]VALUE: Cell data
## [br]NB: if the cells do not complete the grid, intentional holes are created
@export var cells_list: Dictionary
## KEY: Slider coordinate (edge, dist) [br]VALUE: Slider data
@export var slider_position: Dictionary
## Moves to complete including the three extra ones to get the stars
@export var moves_left: int = 1
