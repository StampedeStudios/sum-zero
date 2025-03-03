class_name ScoreCalculation extends Resource

## Time subtract when skip a level in arena
@export_range(0, 60, .1) var skip_cost: int = 15
## Time gained for each move that was foreseen in the solution
@export_range(0, 5, .1) var time_gained_per_move: float = 1
## Extra time for best scores
@export_exp_easing("inout") var bost_per_score: float = 2


func get_time_gained(moves: int, move_count: int) -> int:
	if time_gained_per_move > 0:
		var time_sum: float = moves * time_gained_per_move
		var move_left := clampi(moves - move_count, -3, 1)
		var result := remap(move_left, -3, 1, 0, 1)
		time_sum += time_sum * ease(result, bost_per_score)
		return floori(time_sum)
	return 0
