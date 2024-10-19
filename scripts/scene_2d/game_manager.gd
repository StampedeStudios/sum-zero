extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")
const PERSISTENT_SAVE_PATH = "res://assets/resources/levels/persistent_levels.tres"
const PLAYER_SAVE_PATH = "user://sumzero.tres"

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

var _player_save: PlayerSave
var _persistent_save: PersistentSave
var _active_level_name: String
var _next_level_name: String

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	var screen_side_shorter: float
	screen_side_shorter = min(get_viewport().size.x, get_viewport().size.y)
	cell_size = screen_side_shorter / (GlobalConst.MAX_LEVEL_SIZE + 2)
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)
	_load_saved_data()

	main_menu = MAIN_MENU.instantiate()
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)


func _load_saved_data() -> void:
	_persistent_save = load(PERSISTENT_SAVE_PATH) as PersistentSave	
	if FileAccess.file_exists(PLAYER_SAVE_PATH):
		_player_save = load(PLAYER_SAVE_PATH) as PlayerSave
	else:
		_player_save = PlayerSave.new()
		_player_save.initialize_persistent_progress(_persistent_save)
	_set_start_level_playable()
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func _set_start_level_playable() -> void:
	var last_level_complete := _player_save.last_level_complete
	if last_level_complete == "" or !_persistent_save.levels.has(last_level_complete):
		# first play or invalid name
		# try get the first level unlocked and not completed
		for level_name in _player_save.persistent_progress.keys():
			var progress := _player_save.persistent_progress.get(level_name) as LevelProgress
			if progress.is_unlocked and !progress.is_completed:
				_active_level_name = level_name
				return
		# get the first level available
		_active_level_name = _persistent_save.levels.keys()[0]
		
	else:
		# get the next level after the last level complete
		_active_level_name = last_level_complete
		_set_next_level()
		_active_level_name = _next_level_name


func save_persistent_level(level_name: String, level_data: LevelData) -> void:
	_persistent_save.levels[level_name] = level_data
	_player_save.reset_persistent_progress(level_name)
	ResourceSaver.save.call_deferred(_persistent_save, PERSISTENT_SAVE_PATH)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
	

func save_custom_level(level_name:  String, level_data: LevelData) -> void:
	_player_save.custom_levels[level_name] = level_data
	_player_save.reset_custom_level_progress(level_name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)


func _set_next_level() -> void:
	var found: bool
	_next_level_name = _active_level_name
	for level_name in _persistent_save.levels.keys():
		if found:
			_next_level_name = level_name
			break
		found = level_name == _active_level_name
	

func get_active_level() -> LevelData:
	return _persistent_save.levels.get(_active_level_name)


func get_next_level() -> LevelData:
	_active_level_name = _next_level_name
	return _persistent_save.levels.get(_active_level_name)
	

func update_level_progress(move_left: int) -> bool:
	var active_progress: LevelProgress
	var is_record: bool
	active_progress = _player_save.persistent_progress.get(_active_level_name) as LevelProgress
	if !active_progress.is_completed != (move_left > active_progress.move_left):
		active_progress.move_left = move_left
		is_record = true
	if !active_progress.is_completed:
		active_progress.is_completed = true
		_player_save.last_level_complete = _active_level_name
		_set_next_level()
		_player_save.persistent_progress.get(_next_level_name).is_unlocked = true
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
	return is_record
	
	
func has_next_page(group: GlobalConst.LevelGroup, page: int, size: int) -> bool:
	var last_in_page: int = page * size
	var last_level: int
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			last_level = _player_save.custom_levels.size()
		GlobalConst.LevelGroup.MAIN:
			last_level = _persistent_save.levels.size()
	return last_level > last_in_page


func get_page_levels(group: GlobalConst.LevelGroup, page: int, size: int) -> Dictionary:
	var levels_in_page: Dictionary
	var min_index: int = (page - 1) * size
	var max_index: int = page * size
	var temp_progress: Dictionary
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			temp_progress = _player_save.custom_progress
		GlobalConst.LevelGroup.MAIN:
			temp_progress = _player_save.persistent_progress
	max_index = mini(temp_progress.size(), max_index)
	var count: int = 0
	for level_name in temp_progress:
		count += 1
		if count > min_index and count <= max_index:
			levels_in_page[level_name] = temp_progress.get(level_name)
	return levels_in_page
	
