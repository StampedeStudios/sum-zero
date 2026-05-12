## Handles logic of main menu UI panel.
class_name MainMenu extends Control

const OPTIONS = "res://packed_scene/user_interface/Options.tscn"
const LEVEL_UI = "res://packed_scene/user_interface/LevelUI.tscn"
const PLAY_MODE_SELECTION = "res://packed_scene/user_interface/PlayModeSelection.tscn"
const GAME_UI := "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"

## First unlockable mode, enable the Arcade mode if is unlocked
@export var first_mode: PlayMode

@onready var margin: MarginContainer = %MarginContainer
@onready var arcade_btn: Button = %Arcade


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	GameManager.on_state_change.connect(_on_state_change)

	self.scale = GameManager.ui_scale
	self.position = get_viewport_rect().size / 2 - (self.size * self.scale) / 2

	# Enable ARCADE mode if the first one is unlocked
	arcade_btn.disabled = SaveManager.get_last_completed_level() < first_mode.unlock_count


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.visible = true
			# Update arcade modes
			arcade_btn.disabled = SaveManager.get_last_completed_level() < first_mode.unlock_count
		_:
			self.visible = false


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var playable_id: int = SaveManager.get_start_level_playable()

	var playable_level: LevelData = GameManager.get_active_level(playable_id)
	if playable_level != null:
		# Load Level Manager
		var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
		var level_manager := scene.instantiate() as LevelManager
		get_tree().root.add_child(level_manager)
		GameManager.level_manager = level_manager
		level_manager.init_level(playable_level)

		# Load game UI
		scene = ResourceLoader.load(GAME_UI) as PackedScene
		var game_ui := scene.instantiate() as GameUI
		get_tree().root.add_child(game_ui)
		game_ui.initialize_ui(Constants.GameState.MAIN_MENU)
		GameManager.change_state(Constants.GameState.LEVEL_START)
		GameManager.game_ui = game_ui


func _on_level_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(LEVEL_UI) as PackedScene
	var level_ui := scene.instantiate() as LevelUI
	level_ui.set_context(Constants.LevelGroup.MAIN)

	get_tree().root.add_child.call_deferred(level_ui)
	GameManager.level_ui = level_ui
	GameManager.set_levels_context(Constants.LevelGroup.MAIN)
	GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)


func _on_editor_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(LEVEL_UI) as PackedScene
	var level_ui := scene.instantiate() as LevelUI
	level_ui.set_context(Constants.LevelGroup.CUSTOM)

	get_tree().root.add_child.call_deferred(level_ui)
	GameManager.level_ui = level_ui
	GameManager.set_levels_context(Constants.LevelGroup.CUSTOM)
	GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_option_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(OPTIONS) as PackedScene
	var option_ui := scene.instantiate() as Options
	get_tree().root.add_child.call_deferred(option_ui)

	GameManager.change_state(Constants.GameState.OPTIONS_MENU)


func _on_arcade_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(PLAY_MODE_SELECTION) as PackedScene
	var play_mode_selection := scene.instantiate() as PlayModeSelection

	get_tree().root.add_child(play_mode_selection)
	GameManager.change_state.call_deferred(Constants.GameState.MODE_SELECTION)
