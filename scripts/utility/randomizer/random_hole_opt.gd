class_name RandomHoleOptions extends Resource

## Holes diffusion rule
@export var diffusion_rules: Dictionary = {"NONE": 40, "LOWER": 30, "MAX": 30}
## Lower subtract probability
@export_range(0, 100, .1) var remove_odd: int = 50
## Standard diffusion percent of all cells
@export_range(0, 50, .1) var std_diffusion: int = 25
