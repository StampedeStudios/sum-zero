class_name LevelContainer extends Resource

@export var levels: Dictionary
@export var levels_order: Array[String]


func get_level_by_index(level_index: int) -> String:
	if levels_order.size() > level_index:
		return levels_order[level_index]
	return ""
	

func get_levels_group_by_index(pivot: int, group_size: int) -> Array[String]:
	var levels_group: Array[String]
	var last := mini(levels_order.size(), pivot + group_size)
	for level_index in range(pivot, last):
		levels_group.append(levels_order[level_index])
	return levels_group


func set_level(level_name: String, level_data: LevelData) -> void:
	if !levels_order.has(level_name):
		levels_order.append(level_name)
	levels[level_name] = level_data


func get_next_level(current_level_name: String) -> String:
	for name_index in range(0, levels_order.size()):
		if levels_order[name_index] == current_level_name:
			if name_index + 1 < levels_order.size():
				return levels_order[name_index + 1]
	return ""
