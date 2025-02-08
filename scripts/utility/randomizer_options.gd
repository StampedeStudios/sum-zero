class_name RandomizerOptions extends Resource

@export_group("CELLS")


@export_group("SLIDERS")
## Sliders occupation rule 
@export var OCCUPATION_RULES := {
	"STANDARD": 70,
	"LOWER": 10,
	"UPPER": 20
}
## Standard occupancy by number of possible places
@export var OCCUPATION_STD := {
	4: Vector2i(2, 3),
	6: Vector2i(3, 4),
	8: Vector2i(3, 5),
	10: Vector2i(4, 6),
	12: Vector2i(4, 8),
	14: Vector2i(5, 8),
	16: Vector2i(6, 9),
	18: Vector2i(7, 11),
	20: Vector2i(8, 14)
}
## Lower subtract probability
@export var OCCUPATION_LOWER := 30
## Upper addiction probability
@export var OCCUPATION_UPPER := 60
## Sliders extension rule
@export var EXTENSION_RULES := {
	"MAX": 60,
	"NONE": 10,
	"RANDOM": 30
}
## Slider full probability
@export var FULL_ODD := 15
## Slider block full probability
@export var BLOCK_FULL_ODD := 50
## Sliders type rules
@export var TYPE_RULES := {
	"ADD": 45,
	"SUBTRACT": 45,
	"CHANGE_SIGN": 3,
	"BLOCK": 7
}
