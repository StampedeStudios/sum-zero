extends Node

signal level_loading(level_data: LevelData)
signal level_start
signal level_end
signal toggle_level_visibility(visibility: bool)
signal game_ended
signal reset

signal on_state_change(new_state: GlobalConst.GameState)

@export var palette: ColorPalette
@export var slider_collection: SliderCollection
@export var level_data: Array[LevelData]
var current_level: int
var cell_size: float
var level_scale: Vector2
var game_ui: GameUI
var builder_ui: BuilderUI
var builder_selection: BuilderSelection
var builder_save: BuilderSave
var builder_resize: BuilderResize
var builder_test: BuilderTest


@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	var screen_side_shorter: float
	screen_side_shorter = min(get_viewport().size.x, get_viewport().size.y)
	cell_size = screen_side_shorter / (GlobalConst.MAX_LEVEL_SIZE + 2)
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)

func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)

func level_complete() -> void:
	level_end.emit()


func load_next_level() -> void:
	current_level += 1
	load_level()


func toggle_level(visibilty: bool) -> void:
	toggle_level_visibility.emit(visibilty)


func load_level() -> void:
	if current_level < level_data.size():
		var level_info: LevelData = level_data[current_level]
		level_loading.emit(level_info)
		level_start.emit()
	else:
		game_ended.emit()

	get_tree().paused = false


func get_move_left() -> int:
	return level_data[current_level].moves_left


func reset_level() -> void:
	var level_info: LevelData = level_data[current_level]
	game_ui.moves_left = level_info.moves_left
	reset.emit()
