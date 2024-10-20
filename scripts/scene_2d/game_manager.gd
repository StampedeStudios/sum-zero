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
var level_ui: LevelUI
var level_inspect: LevelInspect
var active_level_name: String

var _player_save: PlayerSave
var _persistent_save: PersistentSave
var _next_level_name: String
var _active_level_group: Dictionary
var _active_progress_group: Dictionary

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
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func set_levels_context(group: GlobalConst.LevelGroup) -> void:
	match group:
		GlobalConst.LevelGroup.MAIN:
			_active_level_group = _persistent_save.levels
			_active_progress_group = _player_save.persistent_progress
		GlobalConst.LevelGroup.CUSTOM:
			_active_level_group = _player_save.custom_levels
			_active_progress_group = _player_save.custom_progress


func set_start_level_playable() -> void:
	set_levels_context(GlobalConst.LevelGroup.MAIN)
	if !_active_level_group.is_empty():
		# get the first level available
		active_level_name = _active_level_group.keys()[0]
		if !_active_progress_group.get(active_level_name).is_completed:
			_active_progress_group.get(active_level_name).is_unlocked = true
		else:
			# get the first level unlocked and not completed
			for level_name in _active_progress_group.keys():
				var progress := _active_progress_group.get(level_name) as LevelProgress
				if progress.is_unlocked and !progress.is_completed:
					active_level_name = level_name
					break
	else:
		push_error("Nessun livello nel persistent save!")
		

func save_persistent_level(level_name: String, level_data: LevelData) -> void:
	_persistent_save.levels[level_name] = level_data.duplicate()
	_player_save.reset_persistent_progress(level_name)
	ResourceSaver.save.call_deferred(_persistent_save, PERSISTENT_SAVE_PATH)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func save_custom_level(level_name: String, level_data: LevelData) -> void:
	_player_save.custom_levels[level_name] = level_data.duplicate()
	_player_save.reset_custom_progress(level_name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)


func set_next_level() -> bool:
	var found: bool
	_next_level_name = active_level_name
	for level_name in _active_level_group.keys():
		if found:
			_next_level_name = level_name
			unlock_level(_next_level_name)
			break
		found = level_name == active_level_name
	return _next_level_name != active_level_name


func get_active_level() -> LevelData:
	return _active_level_group.get(active_level_name)


func get_next_level() -> LevelData:
	active_level_name = _next_level_name
	return get_active_level()


func update_level_progress(move_left: int) -> bool:
	var active_progress: LevelProgress
	var is_record: bool
	
	active_progress = _active_progress_group.get(active_level_name)
	if !active_progress.is_completed != (move_left > active_progress.move_left):
		active_progress.move_left = move_left
		is_record = true
	if !active_progress.is_completed:
		active_progress.is_completed = true
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


func is_level_completed() -> bool:
	return _active_progress_group.get(active_level_name).is_completed


func unlock_level(level_name: String) -> void:
	_active_progress_group.get(level_name).is_unlocked = true
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
