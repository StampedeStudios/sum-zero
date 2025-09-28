class_name BuilderTest extends Control

var _moves: int

@onready var margin: MarginContainer = %MarginContainer
@onready var moves_count: Label = %MovesCount
@onready var buttons: HBoxContainer = %BottomContainer


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	buttons.add_theme_constant_override("separation", GameManager.btns_separation)

	GameManager.on_state_change.connect(_on_state_change)
	_reset_moves()


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_START:
			self.visible = true
			if !GameManager.level_manager.on_consume_move.is_connected(_add_move):
				GameManager.level_manager.on_consume_move.connect(_add_move)
			GameManager.level_manager.spawn_grid(false)
		Constants.GameState.PLAY_LEVEL:
			self.visible = true
		_:
			self.visible = false


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(Constants.GameState.BUILDER_IDLE)
	_reset_moves()


func _on_reset_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.level_manager.reset_level()
	_reset_moves()


func _reset_moves() -> void:
	_moves = 0
	moves_count.text = String.num(_moves, 0)


func _add_move() -> void:
	_moves += 1
	moves_count.text = String.num(_moves, 0)
