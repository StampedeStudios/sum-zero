class_name RandomSliderOptions extends Resource

## Sliders occupation rule
@export var occupation_rules := {"STANDARD": 70, "LOWER": 10, "UPPER": 20}
## Lower subtract probability
@export var lower_odd := 30
## Upper addiction probability
@export var upper_odd := 60
## Standard occupancy by number of possible places
@export var std_occupation := {
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
@export var extension_rules := {"NONE": 10, "MAX": 60, "RANDOM": 30}
## Slider behavior-full probability for max extended
@export var full_odd := 15
## Slider behavior-full probability when stopped by another block
@export var full_odd_on_stop := 30
## Slider block behavior-full probability
@export var block_full_odd := 50
## Slider block behavior-full probability when stopped by another block
@export var block_full_odd_on_stop := 50
## Slider block retractable after stop other sliders
@export var block_full_retract_odd := 50
## Sliders type rules
@export var type_rules := {"ADD": 45, "SUBTRACT": 45, "CHANGE_SIGN": 3, "BLOCK": 7}
