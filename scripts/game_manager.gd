extends Node

const LEVEL_FOLDER_PATH := "res://assets/resources/"

var level_data: Array[LevelData]
var current_level: int

signal level_loading(level_data: LevelData)
signal level_start()
signal level_end()


func _ready() -> void:
	var level_folder: DirAccess = DirAccess.open(LEVEL_FOLDER_PATH)
	for file in level_folder.get_files():
		level_data.append(load(LEVEL_FOLDER_PATH + file))


func level_complete() ->void:
	level_end.emit()
	current_level += 1	
	

func load_level() -> void:
	if current_level <= level_data.size():
		level_loading.emit(level_data[current_level])
		level_start.emit()
