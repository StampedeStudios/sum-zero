class_name LevelData 
extends Resource

@export_range(2,5) var width: int = 2
@export_range(2,5) var height: int = 2
## List of cells data 
## [br]NB: if the cells in the list do not complete the grid, intentional holes are created
@export var cells_list: Array[CellData]
## KEY: Slider position clockwise starting from top left [br]VALUE: Slider data 
@export var slider_position: Dictionary
## Moves to complete including the three extra ones to get the stars
@export var moves_left: int = 1
