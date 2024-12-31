class_name LevelContainer extends Resource

@export var levels: Array[LevelData]
@export var tutorials: Dictionary


func is_empty() -> bool:
	return levels.is_empty()


func add_level(level_data: LevelData) -> void:
	levels.append(level_data)


func get_tutorial(id: int) -> TutorialData:
	if tutorials.has(id):
		return tutorials.get(id)
	return null
