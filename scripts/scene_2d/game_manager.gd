extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")

@export var palette: ColorPalette
@export var slider_collection: SliderCollection
var cell_size: float
var level_scale: Vector2
var level_manager: LevelManager
var level_builder: LevelBuilder
var game_ui: GameUI
var builder_ui: BuilderUI
var builder_selection: BuilderSelection
var builder_save: BuilderSave
var builder_resize: BuilderResize
var builder_test: BuilderTest
var main_menu: MainMenu
var level_end: LevelEnd

var _levels: Array[LevelData]
var _active_level_index: int
var _next_level_index: int

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	var screen_side_shorter: float
	screen_side_shorter = min(get_viewport().size.x, get_viewport().size.y)
	cell_size = screen_side_shorter / (GlobalConst.MAX_LEVEL_SIZE + 2)
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)
	_load_levels()
	
	main_menu = MAIN_MENU.instantiate()
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)
	
	
func _load_levels() -> void:
	var levels_dir := "res://assets/resources/_levels/"
	var dir := DirAccess.open(levels_dir)
	for file_name in dir.get_files():
		var resource: Resource
		resource = ResourceLoader.load(levels_dir + file_name)
		_levels.append(resource)
			

func change_state(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.LEVEL_END:
			_set_next_level_index()
	on_state_change.emit(new_state)


func _set_next_level_index() -> void:
	if _active_level_index < _levels.size() - 1:
		_next_level_index = _active_level_index + 1


func get_active_level() -> LevelData:
	return _levels[_active_level_index]
	

func get_next_level() -> LevelData:
	_active_level_index = _next_level_index
	return _levels[_active_level_index]
