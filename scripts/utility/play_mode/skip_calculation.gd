class_name SkipCalculation extends ScoreCalculation

@export var bonus: int
@export var value: int

func get_multiplier(game_summary: GameSummary) -> int:
	var counter: int = 0
	for level: LevelSummary in game_summary.get_levels():
		if !level:
			counter += 1
	return counter


func update_score(score: int, multiplier: int) -> int:
	if multiplier > 0:
		return clampi(score + multiplier * value, 0, 999999)
	else:
		return score + bonus
