class_name GameUI extends Control

signal reset_level

var moves_left: int

@onready var moves_left_txt: Label = %MovesLeft
@onready var level_score_img: TextureRect = %LevelScoreImg


func _ready() -> void:
	level_score_img.visible = false
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			_reset_moves_left()
			self.visible = true
		GlobalConst.GameState.LEVEL_END:
			self.visible = false
			GameManager.level_end.update_score(moves_left)
		_:
			self.visible = false


func _reset_moves_left():
	moves_left = GameManager.get_active_level().moves_left
	_update_moves()


func consume_move() -> void:
	moves_left -= 1
	_update_moves()


func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_reset_btn_pressed():
	_reset_moves_left()
	reset_level.emit()


func _update_moves() -> void:
	if moves_left >= 0:
		level_score_img.visible = false
		moves_left_txt.visible = true
		moves_left_txt.text = "%s" % String.num(moves_left)
	else:
		moves_left_txt.visible = false
		level_score_img.visible = true
		var percentage: float = 0.33 * (3 + moves_left)
		level_score_img.material.set_shader_parameter("percentage", percentage)
