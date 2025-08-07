class_name RandomSliderOptions extends Resource

## Sliders occupation rule
@export var occupation_rules: Dictionary[String, int] = {"STANDARD": 70, "LOWER": 10, "UPPER": 20}
## Lower subtract probability
@export_range(0, 100, .1) var lower_odd: int = 30
## Upper addiction probability
@export_range(0, 100, .1) var upper_odd: int = 60
## Standard occupancy by number of possible places
@export var std_occupation: Dictionary[int, Vector2i] = {
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
## Sliders extension rule
@export var extension_rules: Dictionary[String, int] = {"NONE": 10, "MAX": 60, "RANDOM": 30}
## Slider behavior-full probability for max extended
@export_range(0, 100, .1) var full_odd: int = 15
## Slider behavior-full probability when stopped by another block
@export_range(0, 100, .1) var full_odd_on_stop: int = 30
## Slider block behavior-full probability
@export_range(0, 100, .1) var block_full_odd: int = 50
## Slider block behavior-full probability when stopped by another block
@export_range(0, 100, .1) var block_full_odd_on_stop: int = 50
## Slider block retractable after stop other sliders
@export_range(0, 100, .1) var block_full_retract_odd: int = 50
## Sliders type rules
@export var type_rules: Dictionary[String, int] = {
	"ADD": 45,
	"SUBTRACT": 45,
	"CHANGE_SIGN": 3,
	"BLOCK": 7
}
