class_name ArenaMode extends PlayMode

## The level can be skipped
@export var is_skippable: bool
## Only one playable level
@export var one_shoot_mode: bool
## Parameters for manage game time (none: no time counter)
@export var timer_options: TimerOptions
## Parameters for random level generation
@export var level_options: RandomizerOptions
