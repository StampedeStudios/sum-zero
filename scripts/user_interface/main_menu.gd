class_name MainMenu extends Control

const LEVEL_BUILDER = "res://packed_scene/scene_2d/LevelBuilder.tscn"
const OPTIONS = "res://packed_scene/user_interface/Options.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"
const BUILDER_UI = "res://packed_scene/user_interface/BuilderUI.tscn"
const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_UI = "res://packed_scene/user_interface/LevelUI.tscn"

@onready var version_label: Label = %VersionLabel
@onready var margin: MarginContainer = %MarginContainer


func _ready():
	version_label.text = ProjectSettings.get("application/config/version")
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	GameManager.on_state_change.connect(_on_state_change)

	self.scale = GameManager.ui_scale
	self.position = get_viewport_rect().size / 2 - (self.size * self.scale) / 2


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.visible = true
		_:
			self.visible = false


func _on_play_btn_pressed():
	AudioManager.play_click_sound()
	var playable_level = GameManager.get_active_level(GameManager.get_start_level_playable())
	if playable_level != null:
		var scene := ResourceLoader.load(GAME_UI) as PackedScene
		var game_ui := scene.instantiate() as GameUI
		get_tree().root.add_child.call_deferred(game_ui)
		game_ui.initialize_ui.call_deferred(GlobalConst.GameState.MAIN_MENU)
		GameManager.game_ui = game_ui

		scene = ResourceLoader.load(LEVEL_MANAGER) as PackedScene
		var level_manager := scene.instantiate() as LevelManager
		get_tree().root.add_child.call_deferred(level_manager)
		level_manager.set_manager_mode.call_deferred(false)
		GameManager.level_manager = level_manager

		level_manager.init_level.call_deferred(playable_level)


func _on_level_btn_pressed():
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(LEVEL_UI) as PackedScene
	var level_ui := scene.instantiate() as LevelUI
	get_tree().root.add_child.call_deferred(level_ui)
	GameManager.level_ui = level_ui
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)


func _on_editor_btn_pressed():
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(BUILDER_UI) as PackedScene
	var builder_ui := scene.instantiate() as BuilderUI
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	scene = ResourceLoader.load(LEVEL_BUILDER) as PackedScene	
	var level_builder := scene.instantiate() as LevelBuilder
	get_tree().root.add_child.call_deferred(level_builder)
	level_builder.construct_level.call_deferred(LevelData.new())
	GameManager.level_builder = level_builder

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func _on_quit_btn_pressed():
	get_tree().quit()


func _on_option_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(OPTIONS) as PackedScene
	var option_ui := scene.instantiate() as Options
	get_tree().root.add_child.call_deferred(option_ui)
