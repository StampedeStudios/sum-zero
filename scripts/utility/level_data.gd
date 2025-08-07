## Holds all the data required to define a puzzle level.
##
## This resource includes grid dimensions, cell definitions, sliders, move count, and a level name.
## It's used as a data container for encoding, decoding, saving, and loading levels.
##
## Cells and sliders are stored in dictionaries indexed by their coordinates:
## - `cells_list`: key = (column, row)
## - `slider_list`: key = (edge, distance from top/left)
##
## Notes:
## - Grid size is defined by `width` and `height`, from 2x2 to 5x5.
## - Missing coordinates in `cells_list` are treated as empty or intentionally blocked.
##
## Used by: `Encoder`, game logic, and editor tools.
class_name LevelData extends Resource

## Name of the level (e.g., "Level 1", "Tutorial", etc.)
@export var name: String = ""

## Grid width (min: 2, max: 5)
@export_range(2, 5) var width: int = 3

## Grid height (min: 2, max: 5)
@export_range(2, 5) var height: int = 3

## Dictionary mapping cell coordinates to CellData.
## Key: Vector2i(column, row)
## Value: CellData (includes value and blocked state)
##
## If some positions are missing, they are treated as empty cells.
@export var cells_list: Dictionary[Vector2i, CellData]

## Dictionary mapping slider coordinates to SliderData.
## Key: Vector2i(edge, distance)
## Value: SliderData (effect and behavior)
##
## Sliders are applied clockwise: 0 = top, 1 = right, 2 = bottom, 3 = left
@export var slider_list: Dictionary[Vector2i, SliderData]

## Number of moves required to complete the level with 3 stars
@export var moves_left: int = 0

func is_valid_data() -> bool:
	if cells_list.is_empty():
		return false
	if slider_list.is_empty():
		return false
	return true
