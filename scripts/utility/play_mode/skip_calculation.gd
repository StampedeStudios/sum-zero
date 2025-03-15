class_name SkipCalculation extends ScoreCalculation

@export_range(1, 2, 0.1) var boost: float
@export var malus: int


func get_multiplier(game_summary: GameSummary) -> int:
	var counter: int = 0
	for level: LevelSummary in game_summary.get_levels():
		if !level:
			counter += 1
	return counter


func update_score(score: int, multiplier: int) -> int:
	if multiplier > 0:
		return clampi(score - multiplier * abs(malus), 0, score)
	else:
		return roundi(score * boost)
