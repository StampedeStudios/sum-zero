extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")
const PERSISTENT_SAVE_PATH = "res://assets/resources/levels/persistent_levels.tres"
const PLAYER_SAVE_PATH = "user://sumzero.tres"
const TUTORIAL = preload("res://packed_scene/user_interface/Tutorial.tscn")

@export var palette: ColorPalette
@export var slider_collection: SliderCollection
@export var tutorials: Dictionary

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
var custom_inspect: CustomLevelInspect
var is_tutorial_visible: bool = true

var _player_save: PlayerSave
var _persistent_save: LevelContainer
var _active_level_name: String
var _next_level_name: String
var _context: GlobalConst.LevelGroup


func _ready() -> void:
	_load_saved_data()

	main_menu = MAIN_MENU.instantiate()
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)


func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)

	if new_state == GlobalConst.GameState.LEVEL_START:
		if is_tutorial_visible and tutorials.has(_active_level_name):
			var tutorial: TutorialData = tutorials.get(_active_level_name)
			var tutorial_ui: Tutorial = TUTORIAL.instantiate()
			get_tree().root.add_child(tutorial_ui)
			tutorial_ui.setup.call_deferred(tutorial)


func _load_saved_data() -> void:
	_persistent_save = load(PERSISTENT_SAVE_PATH) as LevelContainer
	if !FileAccess.file_exists(PLAYER_SAVE_PATH) or !_set_and_check_save_integrity():
		push_warning("No saved data found on file system")
		_player_save = PlayerSave.new()
	_player_save.initialize_player_save(_persistent_save)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func _set_and_check_save_integrity() -> bool:
	var savegame := load(PLAYER_SAVE_PATH) as PlayerSave
	# inconsistent counting between levels and progress
	if _persistent_save.levels.size() != savegame.persistent_progress.size():
		return false
	# inconsistent naming between levels and progress
	for level_name in _persistent_save.levels.keys():
		if !savegame.persistent_progress.has(level_name):
			return false
	# set verified savegame
	_player_save = savegame
	return true


func set_levels_context(level_group: GlobalConst.LevelGroup) -> void:
	_context = level_group


func get_start_level_playable() -> LevelData:
	_context = GlobalConst.LevelGroup.MAIN
	if !_persistent_save.levels.is_empty():
		# get the first level available
		_active_level_name = _persistent_save.get_level_by_index(0)
		# get the first level unlocked and not completed
		for level_name in _persistent_save.levels_order:
			var progress := _player_save.persistent_progress.get(level_name) as LevelProgress
			if progress.is_unlocked and !progress.is_completed:
				_active_level_name = level_name
				break
		set_levels_context(GlobalConst.LevelGroup.MAIN)
		return get_active_level(_active_level_name)

	push_error("Nessun livello nel persistent save!")
	return null


func save_persistent_level(level_name: String, level_data: LevelData) -> void:
	_persistent_save.set_level(level_name, level_data.duplicate())
	_player_save.reset_progress(GlobalConst.LevelGroup.MAIN, level_name)
	ResourceSaver.save.call_deferred(_persistent_save, PERSISTENT_SAVE_PATH)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func save_custom_level(level_name: String, level_data: LevelData) -> void:
	_player_save.custom_levels.set_level(level_name, level_data.duplicate())
	_player_save.reset_progress(GlobalConst.LevelGroup.CUSTOM, level_name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func _get_levels() -> LevelContainer:
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_levels
		GlobalConst.LevelGroup.MAIN:
			return _persistent_save
	return null


func _get_progress() -> Dictionary:
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_progress
		GlobalConst.LevelGroup.MAIN:
			return _player_save.persistent_progress
	return {}


func set_next_level() -> bool:
	var is_valid_level: bool
	_next_level_name = _get_levels().get_next_level(_active_level_name)
	is_valid_level = _next_level_name != ""
	if is_valid_level:
		_player_save.unlock_level(_context, _next_level_name)
	return is_valid_level


func get_active_level(level_name: String = "") -> LevelData:
	if level_name != "":
		_active_level_name = level_name
	var data := _get_levels().levels.get(_active_level_name) as LevelData
	return data


func set_level_scale(level_width: int, level_height: int) -> void:
	var max_screen_width : float = get_viewport().size.x
	var max_screen_height : float = get_viewport().size.y * 0.8
	cell_size = min(max_screen_width / (level_width + 2), max_screen_height / (level_height + 2))
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)
	

func get_next_level() -> LevelData:
	_active_level_name = _next_level_name
	return get_active_level()


func update_level_progress(move_left: int) -> bool:
	var active_progress: LevelProgress
	var is_record: bool
	active_progress = _get_progress().get(_active_level_name)
	if !active_progress.is_completed != (move_left > active_progress.move_left):
		active_progress.move_left = move_left
		is_record = true
	if !active_progress.is_completed:
		active_progress.is_completed = true
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
	return is_record


func get_page_levels(group: GlobalConst.LevelGroup, first: int, last: int) -> Dictionary:
	var levels_in_page: Dictionary
	var temp_levels: LevelContainer
	var temp_progress: Dictionary
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			temp_levels = _player_save.custom_levels
			temp_progress = _player_save.custom_progress
		GlobalConst.LevelGroup.MAIN:
			temp_levels = _persistent_save
			temp_progress = _player_save.persistent_progress
	if temp_levels != null:
		for level_name in temp_levels.get_levels_group_by_index(first - 1, last):
			levels_in_page[level_name] = temp_progress.get(level_name)
	return levels_in_page


func is_level_completed() -> bool:
	return _get_progress().get(_active_level_name).is_completed


func unlock_level(group: GlobalConst.LevelGroup, level_name: String) -> void:
	_player_save.unlock_level(group, level_name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func delete_level(level_name: String) -> void:
	_player_save.delete_level(level_name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
