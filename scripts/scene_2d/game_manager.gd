extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = preload("res://packed_scene/user_interface/MainMenu.tscn")
const PERSISTENT_SAVE_PATH = "res://assets/resources/levels/persistent_levels.tres"
const PLAYER_SAVE_PATH = "user://sumzero.tres"
const TUTORIAL = preload("res://packed_scene/user_interface/Tutorial.tscn")

@export var palette: ColorPalette
@export var slider_collection: SliderCollection
@export var tutorials: Dictionary

var ui_scale: Vector2
var cell_size: float
var level_scale: Vector2
var level_manager: LevelManager
var level_builder: LevelBuilder
var game_ui: GameUI
var builder_ui: BuilderUI
var option_ui: Options
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
var _active_level_id: int
var _next_level_id: int
var _context: GlobalConst.LevelGroup


func _ready() -> void:
	_load_saved_data()
	_set_ui_scale()

	main_menu = MAIN_MENU.instantiate()
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)


func _set_ui_scale() -> void:
	var max_screen_width: float = get_viewport().size.x
	var max_screen_height: float = get_viewport().size.y
	var min_scale: float = min(max_screen_width / 720, max_screen_height / 1280)
	ui_scale = Vector2(min_scale, min_scale)


func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)

	if new_state == GlobalConst.GameState.LEVEL_START:
		if is_tutorial_visible and tutorials.has(_active_level_id):
			var tutorial: TutorialData = tutorials.get(_active_level_id)
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
	# set verified savegame
	_player_save = savegame
	return true


func set_levels_context(level_group: GlobalConst.LevelGroup) -> void:
	_context = level_group


func get_start_level_playable() -> LevelData:
	set_levels_context(GlobalConst.LevelGroup.MAIN)
	if !_persistent_save.is_empty():
		# get the first level available
		_active_level_id = 0
		# get the first level unlocked and not completed
		for id in range(_persistent_save.levels.size()):
			var progress := _player_save.persistent_progress[id] as LevelProgress
			if progress.is_unlocked and !progress.is_completed:
				_active_level_id = id
				break
		return get_active_level(_active_level_id)

	push_error("Nessun livello nel persistent save!")
	return null


func save_persistent_level(level_data: LevelData) -> void:
	_persistent_save.add_level(level_data.duplicate())
	_player_save.add_progress(GlobalConst.LevelGroup.MAIN, level_data.name)
	ResourceSaver.save.call_deferred(_persistent_save, PERSISTENT_SAVE_PATH)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func save_custom_level(level_data: LevelData) -> void:
	_player_save.custom_levels.add_level(level_data.duplicate())
	_player_save.add_progress(GlobalConst.LevelGroup.CUSTOM, level_data.name)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func _get_levels() -> LevelContainer:
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_levels
		GlobalConst.LevelGroup.MAIN:
			return _persistent_save
	return null


func _get_progress() -> Array[LevelProgress]:
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_progress
		GlobalConst.LevelGroup.MAIN:
			return _player_save.persistent_progress
	return []


func set_next_level() -> bool:
	var is_valid_level: bool
	_next_level_id = _active_level_id + 1
	is_valid_level = _get_levels().levels.size() > _next_level_id
	if is_valid_level:
		_player_save.unlock_level(_context, _next_level_id)
	return is_valid_level


func get_active_level(level_id: int = -1) -> LevelData:
	if level_id > -1:
		_active_level_id = level_id
	return _get_levels().levels[_active_level_id] as LevelData


func set_level_scale(level_width: int, level_height: int) -> void:
	var max_screen_width: float = get_viewport().size.x
	var max_screen_height: float = get_viewport().size.y * 0.8
	cell_size = min(max_screen_width / (level_width + 2), max_screen_height / (level_height + 2))
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)


func get_next_level() -> LevelData:
	_active_level_id = _next_level_id
	return get_active_level()


func update_level_progress(move_left: int) -> bool:
	var active_progress: LevelProgress
	var is_record: bool
	active_progress = _get_progress()[_active_level_id]
	if !active_progress.is_completed != (move_left > active_progress.move_left):
		active_progress.move_left = move_left
		is_record = true
	if !active_progress.is_completed:
		active_progress.is_completed = true
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
	return is_record


func get_page_levels(group: GlobalConst.LevelGroup, first: int, last: int) -> Array[LevelProgress]:
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_progress.slice(first - 1, last + 1)
		GlobalConst.LevelGroup.MAIN:
			return _player_save.persistent_progress.slice(first - 1, last + 1)
	return []


func get_num_levels(group: GlobalConst.LevelGroup) -> int:
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_levels.levels.size()
		GlobalConst.LevelGroup.MAIN:
			return _player_save.persistent_progress.size()
		_:
			return 0


func is_level_completed() -> bool:
	return _get_progress()[_active_level_id].is_completed


func unlock_level(group: GlobalConst.LevelGroup, level_id: int) -> void:
	_player_save.unlock_level(group, level_id)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func delete_level(level_id: int) -> void:
	_player_save.delete_level(level_id)
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func toggle_tutorial() -> void:
	is_tutorial_visible = !is_tutorial_visible
