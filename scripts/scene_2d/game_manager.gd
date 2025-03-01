extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = "res://packed_scene/user_interface/MainMenu.tscn"
const SPLASH_SCREEN = "res://packed_scene/user_interface/SplashScreen.tscn"
const PERSISTENT_SAVE_PATH = "res://assets/resources/levels/persistent_levels.tres"
const PLAYER_SAVE_PATH = "user://sumzero.tres"
const DEFAULT_THEME = preload("res://assets/resources/themes/default.tres")
const PRIMARY_THEME = preload("res://assets/resources/themes/primary.tres")
const CENTER_OFFSET: int = 40

@export var palette: ColorPalette

var ui_scale: Vector2
var title_font_size: int
var subtitle_font_size: int
var text_font_size: int
var icon_max_width: int
var btn_icon_max_width: int
var btns_separation: int
var vertical_margin: int
var horizontal_margin: int
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
var level_ui: LevelUI
var arena_ui: ArenaUI

var _player_save: PlayerSave
var _persistent_save: LevelContainer
var _active_level_id: int
var _next_level_id: int
var _context: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN


func _ready() -> void:
	_set_ui_scale()
	var mode := ResourceLoader.CACHE_MODE_IGNORE_DEEP
	var	scene := ResourceLoader.load(SPLASH_SCREEN, "", mode) as PackedScene
	var splash_screen := scene.instantiate() as SplashScreen
	get_tree().root.add_child.call_deferred(splash_screen)

	if !_try_load_saved_data():
		get_tree().quit.call_deferred()


func start() -> void:
	# Set language
	TranslationServer.set_locale(get_options().language)

	# Start music
	AudioManager.start_music()

	# Instantiate main menu
	var	scene := ResourceLoader.load(MAIN_MENU) as PackedScene
	var main_menu := scene.instantiate() as MainMenu
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(GlobalConst.GameState.MAIN_MENU)


func _set_ui_scale() -> void:
	var screen_size: Vector2 = get_viewport().size
	var max_screen_width: float = screen_size.x
	var max_screen_height: float = screen_size.y
	var min_scale: float = min(
		max_screen_width / GlobalConst.SCREEN_SIZE_X, max_screen_height / GlobalConst.SCREEN_SIZE_Y
	)
	ui_scale = Vector2(min_scale, min_scale)

	title_font_size = int(ui_scale.x * GlobalConst.TITLE_FONT_SIZE)
	subtitle_font_size = int(ui_scale.x * GlobalConst.SUBTITLE_FONT_SIZE)
	text_font_size = int(ui_scale.x * GlobalConst.TEXT_FONT_SIZE)
	icon_max_width = int(ui_scale.x * GlobalConst.ICON_MAX_WIDTH)
	btn_icon_max_width = int(ui_scale.x * GlobalConst.BTN_ICON_MAX_WIDTH)

	btns_separation = int(ui_scale.x * GlobalConst.BTN_SEPARATION)

	# Update margin percentage
	vertical_margin = roundi(screen_size.y * GlobalConst.Y_MARGIN_PERCENTAGE)
	horizontal_margin = roundi(screen_size.x * GlobalConst.X_MARGIN_PERCENTAGE)

	# Update themes
	DEFAULT_THEME.set_constant("icon_max_width", "Button", GameManager.btn_icon_max_width)
	PRIMARY_THEME.set_constant("icon_max_width", "Button", GameManager.btn_icon_max_width)


func change_state(new_state: GlobalConst.GameState) -> void:
	on_state_change.emit(new_state)


func get_tutorial() -> TutorialData:
	if !_player_save.player_options.tutorial_on:
		return null
	if _context != GlobalConst.LevelGroup.MAIN:
		return null
	return _persistent_save.get_tutorial(_active_level_id)


func _try_load_saved_data() -> bool:
	_persistent_save = load(PERSISTENT_SAVE_PATH) as LevelContainer
	if _persistent_save == null or _persistent_save.is_empty():
		push_error("Nessun livello nel persistent save!")
		return false
	if !FileAccess.file_exists(PLAYER_SAVE_PATH):
		push_warning("Nessun file di salvataggio trovato sul disco!")
		_player_save = PlayerSave.new()
	else:
		_player_save = load(PLAYER_SAVE_PATH) as PlayerSave
	if _player_save == null:
		push_warning("File di salvataggio non leggibile!")
		_player_save = PlayerSave.new()
	var modified := _player_save.check_savegame_integrity(_persistent_save)
	if modified:
		save_player_data()
	return true


func set_levels_context(level_group: GlobalConst.LevelGroup) -> void:
	_context = level_group


func get_start_level_playable() -> int:
	set_levels_context(GlobalConst.LevelGroup.MAIN)
	# get the first level unlocked and not completed
	for id in range(_persistent_save.levels_hash.size()):
		var progress := _player_save.get_progress(_context, id)
		if progress.is_unlocked and !progress.is_completed:
			return id
	# fist play
	_player_save.unlock_level(0)
	return 0


func save_persistent_level(level_data: LevelData) -> void:
	var level_hash := _persistent_save.add_level(level_data)
	ResourceSaver.save.call_deferred(_persistent_save, PERSISTENT_SAVE_PATH)
	_player_save.add_world_progress(level_hash)
	save_player_data()


func save_custom_level(level_data: LevelData) -> void:
	_player_save.add_custom_level(level_data)
	save_player_data()


func set_next_level() -> bool:
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			if _player_save.custom_levels_hash.size() - 1 > _active_level_id:
				_next_level_id = _active_level_id + 1
				return true
		GlobalConst.LevelGroup.MAIN:
			if _persistent_save.levels_hash.size() - 1 > _active_level_id:
				_next_level_id = _active_level_id + 1
				_player_save.unlock_level(_next_level_id)
				return true
	return false


func get_active_level_id() -> int:
	return _active_level_id
	

func get_active_context() -> GlobalConst.LevelGroup:
	return _context


func get_active_level(level_id: int = -1) -> LevelData:
	if level_id > -1:
		_active_level_id = level_id
	match _context:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.get_level(_active_level_id)
		GlobalConst.LevelGroup.MAIN:
			return _persistent_save.get_level(_active_level_id)
	return null


func set_level_scale(level_width: int, level_height: int) -> void:
	var max_screen_width: float = get_viewport().size.x
	var max_screen_height: float = get_viewport().size.y * 0.8
	cell_size = min(max_screen_width / (level_width + 2), max_screen_height / (level_height + 2))
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)


func get_next_level() -> LevelData:
	return get_active_level(_next_level_id)


func update_level_progress(move_left: int) -> bool:
	var active_progress: LevelProgress
	var is_record: bool
	active_progress = _player_save.get_progress(_context, _active_level_id)
	if !active_progress.is_completed:
		active_progress.is_completed = true
	if move_left > active_progress.move_left:
		active_progress.move_left = move_left
		is_record = true
	_player_save.set_progress(_context, _active_level_id, active_progress)
	save_player_data()
	return is_record


func get_page_levels(group: GlobalConst.LevelGroup, first: int, last: int) -> Array[LevelProgress]:
	var result: Array[LevelProgress]
	for id in range(first - 1, last):
		var progress := _player_save.get_progress(group, id)
		if progress != null:
			result.append(progress)
	return result


func get_num_levels(group: GlobalConst.LevelGroup) -> int:
	match group:
		GlobalConst.LevelGroup.CUSTOM:
			return _player_save.custom_levels_hash.size()
		GlobalConst.LevelGroup.MAIN:
			return _persistent_save.levels_hash.size()
		_:
			return 0


func is_level_completed() -> bool:
	return _player_save.get_progress(_context, _active_level_id).is_completed


func unlock_level(level_id: int) -> void:
	_player_save.unlock_level(level_id)
	save_player_data()


func delete_level(level_id: int) -> void:
	_player_save.delete_custom_level(level_id)
	save_player_data()


func get_options() -> PlayerOptions:
	return _player_save.player_options


func save_player_data() -> void:
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)
