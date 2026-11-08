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

## Defines color palette applied over all the game.
var palette: CustomColorPalette = preload("res://assets/resources/utility/rainbow_palette.tres")

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
