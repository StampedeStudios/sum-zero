class_name TimerOptions extends Resource

## TRUE: the game ends when time is up
@export var is_countdown: bool
## Maximum time for the match in seconds for countdown
@export var max_game_time: int
## Time subtract when skip a level
@export_range(0, 60, .1) var skip_cost: int = 15
## Time gained for each move that was foreseen in the solution (for the worst solution)
@export_range(0, 5, .1) var time_gained_per_move: float
## Time boost for best scores (from ZERO-STAR to EXTRA-STAR)
@export_exp_easing("inout") var boost_per_score: float = 1.4


## Calculate time gained for complete level
func get_time_gained(needed_moves: int, used_moves: int) -> int:

	# Baseline for wasted moves
	if used_moves > needed_moves:
		print("[Arena Score] Suboptimal solution, gains 1s")
		return 1

	# Player-validated difficulty
	var estimated_needed_moves: int = min(needed_moves, used_moves)

	# 1. Difficulty normalization
	# 5–12 moves mapped into [0, 1]
	var difficulty := clampf(
		(float(estimated_needed_moves) - 5.0) / 7.0,
		0.0,
		1.0
	)

	# 2. Exponential growth via easing
	var growth := ease(difficulty, boost_per_score)

	# 3. Scale with existing variable
	var time_sum := growth * time_gained_per_move * 15.0

	# 4. Hard safety cap
	time_sum = min(time_sum, 15.0)

	return 1 + roundi(time_sum)
