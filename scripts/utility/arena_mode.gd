class_name ArenaMode extends PlayMode

@export var is_countdown: bool ## TRUE: the game ends when time is up
@export var max_game_time: int ## Maximum time for the match in seconds for countdown
@export var options: RandomizerOptions ## Parameters for random level generation
@export var score_calculation: ScoreCalculation ## Rule for calculate score at the end
