class_name RandomizerOptions extends Resource

@export_group("CELLS")

@export_group("SLIDERS")
## Sliders occupation rule
@export var occupation_rules := {"STANDARD": 70, "LOWER": 10, "UPPER": 20}
## Standard occupancy by number of possible places
@export var occupation_std := {
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
@export var occupation_lower := 30
## Upper addiction probability
@export var occupation_upper := 60
## Sliders extension rule
@export var extension_rules := {"MAX": 60, "NONE": 10, "RANDOM": 30}
## Slider full probability
@export var full_odd := 10
## Slider full probability when stopped by another block
@export var full_odd_on_stop := 30
## Slider block full probability
@export var block_full_odd := 20
## Slider block full probability when stopped by another block
@export var block_full_odd_on_stop := 50
## Slider block retractable after stop other sliders
@export var block_full_retract_odd := 50
## Sliders type rules
@export var type_rules := {"ADD": 45, "SUBTRACT": 45, "CHANGE_SIGN": 3, "BLOCK": 7}
