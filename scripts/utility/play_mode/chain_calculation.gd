class_name ChainCalculation extends ScoreCalculation

enum Mode { STD, BOOST }

@export var mode: Mode
@export var value: int


func get_multiplier(_summary: GameSummary) -> int:
	return _summary.get_perfect_chain()


func update_score(score: int, multiplier: int) -> int:
	match mode:
		Mode.STD:
			return score + value * multiplier
		Mode.BOOST:
			return score + score * multiplier
	return score
