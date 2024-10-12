extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")

@export var palette: ColorPalette
@export var slider_collection: SliderCollection
@export var levels: Array[LevelData]
var current_level: int
var cell_size: float
var level_scale: Vector2
var game_ui: GameUI
var builder_ui: BuilderUI
var builder_selection: BuilderSelection
var builder_save: BuilderSave
var builder_resize: BuilderResize
var builder_test: BuilderTest
var main_menu: MainMenu

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	var screen_side_shorter: float
	screen_side_shorter = min(get_viewport().size.x, get_viewport().size.y)
	cell_size = screen_side_shorter / (GlobalConst.MAX_LEVEL_SIZE + 2)
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)
	
	main_menu = MAIN_MENU.instantiate()
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)
	

func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)


func get_start_level() -> LevelData:
	return levels[0]



func get_move_left() -> int:
	return levels[current_level].moves_left
