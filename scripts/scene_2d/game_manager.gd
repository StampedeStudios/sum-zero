## Handles the whole game loop.
##
## - Initialize splash screen and main menu;
## - Handles settings and user preferences;
## - Communicate to the level_manager action over levels;
extends Node

## Emitted when a new phase must be entered.
## This signal triggers UI updates to transit from a scene to another scene.
signal on_state_change(new_state: Constants.GameState)

const MAIN_MENU = "res://packed_scene/user_interface/MainMenu.tscn"
const PARTICLES = "res://packed_scene/user_interface/BackgroundParticles.tscn"
const SPLASH_SCREEN = "res://packed_scene/user_interface/SplashScreen.tscn"
const DEFAULT_THEME = preload("res://assets/resources/themes/default.tres")
const PRIMARY_THEME = preload("res://assets/resources/themes/primary.tres")
const CENTER_OFFSET: int = 40

## Defines color palette applied over all the game.
var palette: CustomColorPalette = preload("res://assets/resources/utility/rainbow_palette.tres")

## Set of variables that handles different size dynamically applied for responsiveness.
var ui_scale: Vector2
var title_font_size: int
var subtitle_font_size: int
var text_font_size: int
var small_text_font_size: int
var icon_max_width: int
## Size of buttons scale up accordingly to resolution.
## It should only be set from Game Manager itself.
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
var _context: Constants.LevelGroup = Constants.LevelGroup.MAIN


func _ready() -> void:
	_set_ui_scale()
	var mode := ResourceLoader.CACHE_MODE_IGNORE_DEEP
	var scene := ResourceLoader.load(SPLASH_SCREEN, "", mode) as PackedScene
	var splash_screen := scene.instantiate() as SplashScreen

	get_tree().root.add_child.call_deferred(splash_screen)


func start() -> void:
	# Sets language based on user preferences.
	TranslationServer.set_locale(SaveManager.get_options().language)

	# Starts background music if not disabled.
	AudioManager.start_music()

	var particles := ResourceLoader.load(PARTICLES) as PackedScene
	get_tree().root.add_child(particles.instantiate())

	# Instantiates main menu.
	var scene := ResourceLoader.load(MAIN_MENU) as PackedScene
	var main_menu := scene.instantiate() as MainMenu
	get_tree().root.add_child.call_deferred(main_menu)
	change_state.call_deferred(Constants.GameState.MAIN_MENU)


## Fetches viewport size and update screen sizes to make the game responsive.
func _set_ui_scale() -> void:
	var screen_size: Vector2 = get_viewport().size
	var max_screen_width: float = screen_size.x
	var max_screen_height: float = screen_size.y
	var min_scale: float = min(
		max_screen_width / Constants.Sizes.SCREEN_SIZE_X, max_screen_height / Constants.Sizes.SCREEN_SIZE_Y
	)
	ui_scale = Vector2(min_scale, min_scale)

	title_font_size = int(ui_scale.x * Constants.Sizes.TITLE_FONT_SIZE)
	subtitle_font_size = int(ui_scale.x * Constants.Sizes.SUBTITLE_FONT_SIZE)
	text_font_size = int(ui_scale.x * Constants.Sizes.TEXT_FONT_SIZE)
	small_text_font_size = int(ui_scale.x * Constants.Sizes.SMALL_TEXT_FONT_SIZE)
	icon_max_width = int(ui_scale.x * Constants.Sizes.ICON_MAX_WIDTH)
	btn_icon_max_width = int(ui_scale.x * Constants.Sizes.BTN_ICON_MAX_WIDTH)

	btns_separation = int(ui_scale.x * Constants.Sizes.BTN_SEPARATION)

	vertical_margin = roundi(screen_size.y * Constants.Sizes.Y_MARGIN_PERCENTAGE)
	horizontal_margin = roundi(screen_size.x * Constants.Sizes.X_MARGIN_PERCENTAGE)

	# Updates buttons max_width according to the UI scale.
	DEFAULT_THEME.set_constant("icon_max_width", "Button", btn_icon_max_width)
	PRIMARY_THEME.set_constant("icon_max_width", "Button", btn_icon_max_width)


func change_state(new_state: Constants.GameState) -> void:
	on_state_change.emit(new_state)


func set_levels_context(level_group: Constants.LevelGroup) -> void:
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


func get_next_level() -> LevelData:
	return get_active_level(_next_level_id)


## Returns the currently active level menu separating game level from the custom ones.
func get_active_context() -> Constants.LevelGroup:
	return _context


func get_active_level(level_id: int = -1) -> LevelData:
	if level_id > -1:
		_active_level_id = level_id
	return SaveManager.get_level(_context, _active_level_id)


## Updates level UI size according to the size of the grid.
## This has the weird effect to make small grid levels visually too big and higher
## size grid levels too hard to visualize, but not having it would only worsen the problem.
##
## @param level_width  Width of the level.
## @param level_height Height of the level.
func set_level_scale(level_width: int, level_height: int) -> void:
	var max_screen_width: float = get_viewport().size.x
	var max_screen_height: float = get_viewport().size.y * 0.8
	cell_size = min(max_screen_width / (level_width + 2), max_screen_height / (level_height + 2))
	level_scale.x = (cell_size / Constants.Sizes.CELL_SIZE)
	level_scale.y = (cell_size / Constants.Sizes.CELL_SIZE)
