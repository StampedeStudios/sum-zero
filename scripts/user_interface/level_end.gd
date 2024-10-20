class_name LevelEnd extends Control

signal restart_level

const PLAY_ICON = preload("res://assets/ui/play_icon.png")
const EXIT_ICON = preload("res://assets/ui/exit_icon.png")
const PLAY_TEXT = "Next"
const EXIT_TEXT = "Exit"

var _has_next_level: bool

@onready var level_score_img = %LevelScoreImg
@onready var next_btn: Button = %NextBtn


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


func update_score(move_left: int) -> void:
	var percentage: float = 0.33 * (3 + move_left)
	var is_record: bool
	is_record = GameManager.update_level_progress(move_left)
	level_score_img.material.set_shader_parameter("percentage", percentage)
	if is_record:
		print("NEW RECORD")
	_has_next_level = GameManager.set_next_level()
	next_btn.icon = PLAY_ICON if _has_next_level else EXIT_ICON
	next_btn.text = PLAY_TEXT if _has_next_level else EXIT_TEXT


func _on_replay_btn_pressed():
	restart_level.emit()


func _on_next_btn_pressed():
	if !_has_next_level:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	else:
		var level: LevelData = GameManager.get_next_level()
		GameManager.level_manager.init_level.call_deferred(level)
