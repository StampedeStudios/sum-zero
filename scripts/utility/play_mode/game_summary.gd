class_name GameSummary

var _levels: Array[LevelSummary]
var _perfect_chain: int
var _new_chain: int


func get_levels() -> Array[LevelSummary]:
	return _levels


func get_perfect_chain() -> int:
	return _perfect_chain


func add_completed_level(summary: LevelSummary) -> int:
	_levels.append(summary)
	if summary.star_count == 3 and summary.reset_used == 0:
		_new_chain += 1
		if _new_chain > _perfect_chain:
			_perfect_chain = _new_chain
	return _new_chain


func skip_level() -> void:
	_levels.append(null)
	_new_chain = 0
