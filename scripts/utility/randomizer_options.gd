class_name RandomizerOptions extends Resource

@export_group("SLIDERS")
## Sliders occupation rule 
@export var OCCUPATION_RULES := {
	"STANDARD": 70,
	"LOWER": 15,
	"UPPER": 15
}
## Standard occupancy by number of possible places
@export var OCCUPATION_STD := {
	4: Vector2i(2, 3),
	6: Vector2i(3, 4),
	8: Vector2i(3, 5),
	10: Vector2i(4, 6),
	12: Vector2i(4, 8),
	14: Vector2i(4, 7),
	16: Vector2i(5, 8),
	18: Vector2i(5, 9),
	20: Vector2i(6, 11)
}
## Sliders extension rule
@export var EXTENSION_RULES := {
	"FULL": 55,
	"NONE": 15,
	"RANDOM": 30
}
## Sliders type rules
@export var TYPE_RULES := {
	"ADD": 45,
	"SUBTRACT": 45,
	"CHANGE_SIGN": 5,
	"BLOCK": 5
}
## Slider full probability
@export var FULL_ODD := 15
## Slider block full probability
@export var BLOCK_FULL_ODD := 50
