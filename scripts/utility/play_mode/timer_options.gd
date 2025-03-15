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
@export_exp_easing("inout") var boost_per_score: float = 2


## Calculate time gained for complete level
func get_time_gained(moves: int, move_count: int) -> int:
	if time_gained_per_move > 0:
		var time_sum: float = moves * time_gained_per_move
		var move_left := clampi(moves - move_count, -3, 1)
		var result := remap(move_left, -3, 1, 0, 1)
		time_sum *= ease(result, boost_per_score)
		return roundi(time_sum)
	return 0
