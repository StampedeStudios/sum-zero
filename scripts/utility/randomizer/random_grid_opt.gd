class_name RandomGridOptions extends Resource

## Grid size rule
@export var size_rules: Dictionary[String, int] = {"STANDARD": 50, "LOWER": 10, "UPPER": 40}
## Lower subtract probability
@export_range(0, 100, .1) var lower_odd: int = 40
## Upper addiction probability
@export_range(0, 100, .1) var upper_odd: int = 50
## Standard grid size (random size in array)
@export var std_grid_sizes: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 4)]


func get_lower_size(current: Vector2i) -> Vector2i:
	var lower := Vector2i.ZERO
	if current.y <= current.x:
		lower.x = current.x - 1
		lower.y = current.y
	else:
		lower.x = current.x
		lower.y = current.y - 1
	return lower


func get_upper_size(current: Vector2i) -> Vector2i:
	var lower := Vector2i.ZERO
	if current.y > current.x:
		lower.x = current.x + 1
		lower.y = current.y
	else:
		lower.x = current.x
		lower.y = current.y + 1
	return lower
