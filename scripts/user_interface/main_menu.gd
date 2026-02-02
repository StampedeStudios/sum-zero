## Handles logic of main menu UI panel.
class_name MainMenu extends Control

const OPTIONS = "res://packed_scene/user_interface/Options.tscn"
const LEVEL_UI = "res://packed_scene/user_interface/LevelUI.tscn"
const PLAY_MODE_SELECTION = "res://packed_scene/user_interface/PlayModeSelection.tscn"

@onready var margin: MarginContainer = %MarginContainer


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	GameManager.on_state_change.connect(_on_state_change)

	self.scale = GameManager.ui_scale
	self.position = get_viewport_rect().size / 2 - (self.size * self.scale) / 2


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.visible = true
		_:
			self.visible = false


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(PLAY_MODE_SELECTION) as PackedScene
	var play_mode_selection := scene.instantiate() as PlayModeSelection

	get_tree().root.add_child(play_mode_selection)
	GameManager.change_state.call_deferred(Constants.GameState.MODE_SELECTION)


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
