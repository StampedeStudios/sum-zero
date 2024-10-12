class_name GameUI extends Control

signal reset_level

var moves_left: int:
	set = set_moves_left

@onready var moves_left_txt: Label = %MovesLeft


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	set_moves_left(GameManager.get_move_left())


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
						
		GlobalConst.GameState.LEVEL_START:
			self.visible = true
		
		GlobalConst.GameState.LEVEL_END:
			self.visible = false
			
			

func set_moves_left(new_moves: int):
	moves_left = new_moves

	if moves_left >= 0:
		moves_left_txt.text = "%s" % String.num(moves_left)


func consume_move() -> void:
	moves_left -= 1


func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_reset_btn_pressed():
	reset_level.emit()
	
