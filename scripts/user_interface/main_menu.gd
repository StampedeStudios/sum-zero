class_name MainMenu extends Control

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const OPTIONS = preload("res://packed_scene/user_interface/Options.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")
const LEVEL_UI = preload("res://packed_scene/user_interface/LevelUI.tscn")

@onready var version_label: Label = %VersionLabel


func _ready():
	version_label.text = ProjectSettings.get("application/config/version")
	GameManager.on_state_change.connect(_on_state_change)
	self.scale = GameManager.ui_scale
	self.position = get_viewport_rect().size / 2 - (self.size * self.scale) / 2


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.visible = true
		GlobalConst.GameState.OPTION_MENU:
			pass
		_:
			self.visible = false


func _on_play_btn_pressed():
	AudioManager.play_click_sound()
	var level_data: LevelData = GameManager.get_start_level_playable()
	if level_data != null:
		var game_ui: GameUI
		game_ui = GAME_UI.instantiate()
		get_tree().root.add_child.call_deferred(game_ui)
		GameManager.game_ui = game_ui

		var level_manager: LevelManager
		level_manager = LEVEL_MANAGER.instantiate()
		get_tree().root.add_child.call_deferred(level_manager)
		level_manager.set_manager_mode.call_deferred(false)
		GameManager.level_manager = level_manager

		level_manager.init_level.call_deferred(level_data)


func _on_level_btn_pressed():
	AudioManager.play_click_sound()
	var level_ui: LevelUI
	level_ui = LEVEL_UI.instantiate()
	get_tree().root.add_child.call_deferred(level_ui)

	GameManager.level_ui = level_ui
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)


func _on_editor_btn_pressed():
	AudioManager.play_click_sound()
	var builder_ui: BuilderUI
	builder_ui = BUILDER_UI.instantiate()
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	var level_builder: LevelBuilder
	level_builder = LEVEL_BUILDER.instantiate()
	get_tree().root.add_child.call_deferred(level_builder)
	level_builder.construct_level.call_deferred(LevelData.new())
	GameManager.level_builder = level_builder

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func _on_quit_btn_pressed():
	get_tree().quit()


func _on_option_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var option_ui: Options = OPTIONS.instantiate()
	get_tree().root.add_child.call_deferred(option_ui)
	GameManager.option_ui = option_ui
	GameManager.change_state.call_deferred(GlobalConst.GameState.OPTION_MENU)
