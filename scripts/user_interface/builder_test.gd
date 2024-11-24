class_name BuilderTest extends Control

signal reset_test_level

var _moves: int

@onready var moves_count = %MovesCount


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	_reset_moves()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			GameManager.is_tutorial_visible = true
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			GameManager.is_tutorial_visible = false
			self.visible = true
		_:
			self.visible = false


func _on_exit_btn_pressed():
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)
	_reset_moves()


func _on_reset_btn_pressed():
	AudioManager.play_click_sound()
	reset_test_level.emit()
	_reset_moves()


func _reset_moves() -> void:
	_moves = 0
	moves_count.text = String.num(_moves)


func add_move() -> void:
	_moves += 1
	moves_count.text = String.num(_moves)
