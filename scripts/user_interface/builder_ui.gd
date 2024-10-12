class_name BuilderUI extends Control

signal reset_builder_level

const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_TEST = preload("res://packed_scene/user_interface/BuilderTest.tscn")


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = true
		_:
			self.visible = false
		
	
func _on_reset_btn_pressed():
	reset_builder_level.emit()


func _on_resize_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_RESIZE)


func _on_play_btn_pressed():
	if !GameManager.builder_test:
		var builder_test: BuilderTest
		builder_test = BUILDER_TEST.instantiate()
		GameManager.builder_test = builder_test
		get_tree().root.add_child.call_deferred(builder_test)
	if GameManager.level_manager == null:
		var level_test = LEVEL_MANAGER.instantiate()
		get_tree().root.add_child.call_deferred(level_test)
		level_test.set_manager_mode.call_deferred(true)
		GameManager.level_manager = level_test
	
	GameManager.level_manager.init_level.call_deferred(GameManager.level_builder.get_level_data())
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _on_save_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_SAVE)


func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
