class_name ArenaEnd extends Control


func initialize_score(summarys: Array[LevelSummary], calculation: ScoreCalculation) -> void:
	for summary in summarys:
		print("size ", summary.level_size)
		print("moves ", summary.required_moves)
		print("left ", summary.required_moves - summary.used_moves)
		print("time ", summary.time_used)
	print("score calculation ", calculation)
