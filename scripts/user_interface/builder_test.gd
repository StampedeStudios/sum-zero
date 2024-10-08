class_name BuilderTest extends Control

signal reset_test_level

func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
			
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_TEST:
			self.visible = true
			
		GlobalConst.GameState.BUILDER_RESIZE:
			self.visible = false
		

func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)


func _on_reset_btn_pressed():
	reset_test_level.emit()
