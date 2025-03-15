class_name LevelSummary

var star_count: int
var reset_used: int


func set_star_count(move_required: int, move_count: int) -> void:
	star_count = clampi(move_required - move_count, -3, 0) + 3
