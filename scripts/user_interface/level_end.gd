class_name LevelEnd extends Control

signal restart_level

@onready var level_score_img = %LevelScoreImg


func _ready():
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_END:
			self.visible = true
		_:
			self.visible = false


func update_score(score: int) -> void:
	var percentage: float = 0.33 * (3 + score)
	level_score_img.material.set_shader_parameter("percentage", percentage)


func _on_replay_btn_pressed():
	restart_level.emit()
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _on_next_btn_pressed():
	var level: LevelData
	level = GameManager.get_next_level()
	GameManager.level_manager.init_level.call_deferred(level)
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)
