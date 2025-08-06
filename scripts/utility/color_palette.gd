## Information about a color palette.
##
## The game is fully customizable with themes. Currently only a theme is supported and it's the default.
class_name CustomColorPalette extends Resource

## Colors of cell, each cell value is associated with a specific color.
@export var cell_color: Dictionary[int, Color] = {
	-4: Color(0, 0, 0, 1),
	-3: Color(0, 0, 0, 1),
	-2: Color(0, 0, 0, 1),
	-1: Color(0, 0, 0, 1),
	0: Color(0, 0, 0, 1),
	1: Color(0, 0, 0, 1),
	2: Color(0, 0, 0, 1),
	3: Color(0, 0, 0, 1),
	4: Color(0, 0, 0, 1)
}

## Color of cells in Builder view.
@export var builder_cell_color: Color

## Color of sliders in Builder view.
@export var builder_slider_color: Color

## Default colors of each kind of slider.
@export var slider_colors: Dictionary[String, Color] = {
	"BACKGROUND": Color(0, 0, 0, 1),
	"ADD": Color(0, 0, 0, 1),
	"SUBTRACT": Color(0, 0, 0, 1),
	"CHANGE_SIGN": Color(0, 0, 0, 1),
	"FULL": Color(0, 0, 0, 1),
	"OUTLINE": Color(0, 0, 0, 1)
}
