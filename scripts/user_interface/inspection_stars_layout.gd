@tool
extends Control
## Fit the overlapping stars as one composition inside the reserved content area.


func _ready() -> void:
	resized.connect(_layout)
	theme_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var side := float(get_theme_constant("side_size", "InspectStars"))
	var front := float(get_theme_constant("front_size", "InspectStars"))
	var overlap := float(get_theme_constant("overlap", "InspectStars"))
	var rise := float(get_theme_constant("rise", "InspectStars"))
	var composition := Vector2(side * 2 + front - overlap * 2, maxf(front, rise + side))
	if composition.x <= 0 or composition.y <= 0:
		return
	var factor := minf(size.x / composition.x, size.y / composition.y)
	var origin := (size - composition * factor) / 2
	var rectangles: Array[Rect2] = [
		Rect2(Vector2(0, rise), Vector2.ONE * side),
		Rect2(Vector2(side - overlap, 0), Vector2.ONE * front),
		Rect2(Vector2(side + front - overlap * 2, rise), Vector2.ONE * side),
	]
	for index: int in range(3):
		var slot := get_child(index) as Control
		slot.position = origin + rectangles[index].position * factor
		slot.size = rectangles[index].size * factor
