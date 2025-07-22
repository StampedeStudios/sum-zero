extends Node

signal on_state_change(new_state: GlobalConst.GameState)

const MAIN_MENU = "res://packed_scene/user_interface/MainMenu.tscn"
const SPLASH_SCREEN = "res://packed_scene/user_interface/SplashScreen.tscn"
const DEFAULT_THEME = preload("res://assets/resources/themes/default.tres")
const PRIMARY_THEME = preload("res://assets/resources/themes/primary.tres")
const CENTER_OFFSET: int = 40

var palette: CustomColorPalette = preload("res://assets/resources/utility/rainbow_palette.tres")

var ui_scale: Vector2
var title_font_size: int
var subtitle_font_size: int
var text_font_size: int
var small_text_font_size: int
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

var _active_level_id: int = -1
var _next_level_id: int
var _context: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN


func _ready() -> void:
	_set_ui_scale()
	var mode := ResourceLoader.CACHE_MODE_IGNORE_DEEP
	var scene := ResourceLoader.load(SPLASH_SCREEN, "", mode) as PackedScene
	var splash_screen := scene.instantiate() as SplashScreen
	get_tree().root.add_child.call_deferred(splash_screen)


func start() -> void:
	# Set language
	TranslationServer.set_locale(SaveManager.get_options().language)

	# Start music
	AudioManager.start_music()

	# Instantiate main menu
	var scene := ResourceLoader.load(MAIN_MENU) as PackedScene
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
	small_text_font_size = int(ui_scale.x * GlobalConst.SMALL_TEXT_FONT_SIZE)
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


func set_levels_context(level_group: GlobalConst.LevelGroup) -> void:
	_context = level_group


func set_next_level() -> bool:
	if _active_level_id < SaveManager.get_num_levels(_context) - 1:
		_next_level_id = _active_level_id + 1
		return true
	return false


func reset_active_level_id() -> void:
	_active_level_id = -1


func get_active_level_id() -> int:
	return _active_level_id


func get_active_context() -> GlobalConst.LevelGroup:
	return _context


func get_active_level(level_id: int = -1) -> LevelData:
	if level_id > -1:
		_active_level_id = level_id
	return SaveManager.get_level(_context, _active_level_id)


func set_level_scale(level_width: int, level_height: int) -> void:
	var max_screen_width: float = get_viewport().size.x
	var max_screen_height: float = get_viewport().size.y * 0.8
	cell_size = min(max_screen_width / (level_width + 2), max_screen_height / (level_height + 2))
	level_scale.x = (cell_size / GlobalConst.CELL_SIZE)
	level_scale.y = (cell_size / GlobalConst.CELL_SIZE)


func get_next_level() -> LevelData:
	return get_active_level(_next_level_id)
