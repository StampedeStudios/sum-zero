class_name GameUI extends Control

signal reset_level

var moves_left: int

@onready var moves_left_txt: Label = %MovesLeft


func _ready() -> void:
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
	moves_left_txt.text = "%s" % String.num(moves_left)
