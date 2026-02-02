## GenerationContext
##
## A data container for the level generation process. It holds the LevelData
## and the RandomizerOptions, and it is passed to each generator module.
class_name GenerationContext

var level_data: LevelData
var options: RandomizerOptions


func _init(p_level_data: LevelData, p_options: RandomizerOptions) -> void:
	level_data = p_level_data
	options = p_options
