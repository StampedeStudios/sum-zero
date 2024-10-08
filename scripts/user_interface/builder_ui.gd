class_name BuilderUI extends Control

signal reset_builder_level

func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
			
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = true
			
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_TEST:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_RESIZE:
			self.visible = false
		
	
func _on_reset_btn_pressed():
	reset_builder_level.emit()


func _on_resize_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_RESIZE)


func _on_play_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_TEST)


func _on_save_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_SAVE)


func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
