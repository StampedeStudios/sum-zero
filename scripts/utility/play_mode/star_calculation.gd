class_name StarCalculation extends ScoreCalculation

enum Mode {
	STD,		## multiply value per multiplier and add to score
	BOOST	## multiply value per boost if no reset used
}

@export var mode: Mode
@export_range(0, 3, 0.1) var star_completation: int
@export var value: int
@export_range(1.5, 3, 0.5) var boost: float = 2

var _boost_per_levels: Array[bool]


func get_multiplier(game_summary: GameSummary) -> int:
	var counter: int = 0
	_boost_per_levels.clear()
	for level: LevelSummary in game_summary.get_levels():
		if level and level.star_count == star_completation:
			counter += 1
			if mode == Mode.BOOST:
				_boost_per_levels.append(level.reset_used == 0)
	return counter


func update_score(score:int, multiplier: int) -> int:
	match mode:
		Mode.STD:
			return score + value * multiplier
		Mode.BOOST:
			var fixed_score := score
			for bosted in _boost_per_levels:
				fixed_score += roundi(boost * value) if bosted else value
			return fixed_score
	return score
