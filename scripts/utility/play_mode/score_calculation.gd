class_name ScoreCalculation extends Resource

@export var step_icon: Texture2D


func get_multiplier(_summary: GameSummary) -> int:
	return 0


func update_score(score: int, _multiplier: int) -> int:
	return score
