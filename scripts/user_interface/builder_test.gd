class_name BuilderTest extends Control

signal reset_test_level

var _moves: int

@onready var margin: MarginContainer = %MarginContainer
@onready var moves_count = %MovesCount
@onready var buttons: HBoxContainer = %BottomContainer


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	# Update margin percentage
	var screen_size = get_viewport_rect().size
	var vertical_margin: int = screen_size.y * GlobalConst.Y_MARGIN_PERCENTAGE
	var horizontal_margin: int = screen_size.x * GlobalConst.X_MARGIN_PERCENTAGE

	margin.add_theme_constant_override("margin_left", horizontal_margin)
	margin.add_theme_constant_override("margin_right", horizontal_margin)
	margin.add_theme_constant_override("margin_top", vertical_margin)
	margin.add_theme_constant_override("margin_bottom", vertical_margin)

	for child in buttons.get_children():
		child.add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)

	buttons.add_theme_constant_override("separation", GameManager.btns_separation)

	_reset_moves()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
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
