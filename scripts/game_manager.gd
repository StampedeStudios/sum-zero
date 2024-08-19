extends Node

const LEVEL_FOLDER_PATH := "res://assets/resources/"

@export var level_data: Array[LevelData]
var current_level: int
var level_size: float

signal level_loading(level_data: LevelData)
signal level_start
signal level_end


func level_complete() -> void:
	level_end.emit()
	current_level += 1


func load_level() -> void:
	if current_level < level_data.size():
		level_loading.emit(level_data[current_level])
		level_size = level_data[current_level].cells_values[0].size() * GlobalConst.CELL_SIZE + GlobalConst.CELL_SIZE / 2
		level_start.emit()
		
