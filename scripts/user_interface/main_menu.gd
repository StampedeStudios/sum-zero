class_name MainMenu extends Control

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")


func _ready():
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.visible = true
		_:
			self.visible = false


func _on_play_btn_pressed():
	var game_ui: GameUI
	game_ui = GAME_UI.instantiate()
	get_tree().root.add_child.call_deferred(game_ui)
	GameManager.game_ui = game_ui

	var level_manager: LevelManager
	level_manager = LEVEL_MANAGER.instantiate()
	get_tree().root.add_child.call_deferred(level_manager)
	level_manager.set_manager_mode.call_deferred(false)
	GameManager.level_manager = level_manager
	level_manager.init_level.call_deferred(GameManager.get_active_level())

	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _on_level_btn_pressed():
	print("open levels menu")


func _on_editor_btn_pressed():
	var builder_ui: BuilderUI
	builder_ui = BUILDER_UI.instantiate()
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	var level_builder: LevelBuilder
	level_builder = LEVEL_BUILDER.instantiate()
	get_tree().root.add_child.call_deferred(level_builder)
	GameManager.level_builder = level_builder

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func _on_quit_btn_pressed():
	get_tree().quit()
