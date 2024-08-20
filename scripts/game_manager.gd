extends Node

const LEVEL_FOLDER_PATH := "res://assets/resources/"

@export var level_data: Array[LevelData]
var current_level: int

signal level_loading(level_data: LevelData)
signal level_start
signal level_end
signal toggle_level_visibility(visibility: bool)

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func level_complete() -> void:
	level_end.emit()
	get_tree().paused = true

func load_next_level() -> void:
	current_level += 1
	load_level()
	
	
func toggle_level(visibilty: bool) -> void:
	toggle_level_visibility.emit(visibilty) 
	

func load_level() -> void:
	get_tree().paused = false
	if current_level < level_data.size():
		audio_stream_player_2d.play()
		level_loading.emit(level_data[current_level])
		level_start.emit()
