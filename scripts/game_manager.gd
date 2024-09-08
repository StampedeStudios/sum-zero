extends Node

signal level_loading(level_data: LevelData)
signal level_start
signal level_end
signal toggle_level_visibility(visibility: bool)
signal game_ended

const LEVEL_FOLDER_PATH := "res://assets/resources/"

@export var level_data: Array[LevelData]
var current_level: int
var CELL_SIZE: float

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	var screen_side_shorter: float
	screen_side_shorter = min(get_viewport().size.x, get_viewport().size.y)
	CELL_SIZE = screen_side_shorter / 7
	
	
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
	else:
		game_ended.emit()
