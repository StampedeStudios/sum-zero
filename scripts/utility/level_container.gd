class_name LevelContainer extends Resource

@export var levels: Array[LevelData]


func is_empty() -> bool:
	return levels.is_empty()


func add_level(level_data: LevelData) -> void:
	levels.append(level_data)
