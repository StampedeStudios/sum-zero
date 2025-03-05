class_name RandomizerOptions extends Resource

## Options for randomize GRID (NONE: size = 3x3)
@export var grid_opt: RandomGridOptions
## Options for randomize CELL (NONE: no holes or blocked cells)
@export var cell_opt: RandomCellOptions
## Options for randomize SLIDER (NONE: invalid level)
@export var slider_opt: RandomSliderOptions


func  _init() -> void:
	grid_opt = RandomGridOptions.new()
	cell_opt = RandomCellOptions.new()
	slider_opt = RandomSliderOptions.new()
