class_name RandomLockedOptions extends Resource

## Locked cell diffusion rule
@export var diffusion_rules: Dictionary[String, int] = {"NONE": 40, "LOWER": 50, "MAX": 10}
## Lower subtract probability
@export_range(0, 100, .1) var remove_odd: int = 50
## Standard diffusion of locked cells
##[br]The percentage is calculated on the remainig cells after create the holes
@export_range(0, 50, .1) var std_diffusion: int = 15
