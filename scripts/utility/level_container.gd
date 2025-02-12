class_name LevelContainer extends Resource

@export var tutorials: Dictionary
@export var levels_hash: Array[String]


func is_empty() -> bool:
	return levels_hash.is_empty()


func get_level(level_id: int) -> LevelData:
	if level_id < levels_hash.size():
		return Encoder.decode(levels_hash[level_id])
	return null


func add_level(level_data: LevelData) -> String:
	var level_hash := Encoder.encode(level_data)
	levels_hash.append(level_hash)
	return level_hash


func get_tutorial(id: int) -> TutorialData:
	if tutorials.has(id):
		print("Retrieving tutorial for level having id %s" % id)
		return tutorials.get(id)
	return null
