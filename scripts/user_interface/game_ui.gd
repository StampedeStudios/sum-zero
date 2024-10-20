class_name GameUI extends Control

signal reset_level

var moves_left: int

var _has_next_level: bool

@onready var moves_left_txt: Label = %MovesLeft
@onready var level_score_img: TextureRect = %LevelScoreImg
@onready var skip_btn: Button = %SkipBtn


func _ready() -> void:
	level_score_img.visible = false
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			_initialize_ui()
			self.visible = true
		GlobalConst.GameState.LEVEL_END:
			self.visible = false
			GameManager.level_end.update_score(moves_left)
		_:
			self.visible = false


func _initialize_ui():
	moves_left = GameManager.get_active_level().moves_left
	skip_btn.hide()
	if GameManager.is_level_completed():
		_has_next_level = GameManager.set_next_level()
		if _has_next_level:
			skip_btn.show()
	_update_moves()


func consume_move() -> void:
	moves_left -= 1
	_update_moves()


func _on_exit_btn_pressed():
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_reset_btn_pressed():
	_initialize_ui()
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


func _on_skip_btn_pressed() -> void:
	if !_has_next_level:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	else:
		var level: LevelData
		level = GameManager.get_next_level()
		GameManager.level_manager.init_level.call_deferred(level)
