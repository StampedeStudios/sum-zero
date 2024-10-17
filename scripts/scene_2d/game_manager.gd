extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")
const PERSISTENT_LEVELS_PATH = "res://assets/resources/levels/persistent_levels.tres"

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
	var persistent_level:= load(PERSISTENT_LEVELS_PATH) as PersistentSave
	_levels = persistent_level.levels


func save_persistent_level(data: LevelData) -> void:
	var found: bool
	for index in range(0, _levels.size()):
		if _levels[index].name == data.name:
			_levels[index] = data
			found = true
			break	
	if !found:
		_levels.append(data)
	var persistent_save := PersistentSave.new()
	persistent_save.levels = _levels
	ResourceSaver.save(persistent_save, PERSISTENT_LEVELS_PATH)


func save_custom_level(data: LevelData) -> void:
	print("save in player save")


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
