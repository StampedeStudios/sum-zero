class_name LevelEnd extends Control

signal restart_level

const PLAY_TEXT = " Next "
const EXIT_TEXT = " Exit "

var _has_next_level: bool

@onready var score_sprite: AnimatedSprite2D = %LevelScoreImg
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
	await _animate(percentage)

	await get_tree().create_timer(0.3).timeout

	if is_record:
		print("New record!")

	_has_next_level = GameManager.set_next_level()
	next_btn.text = PLAY_TEXT if _has_next_level else EXIT_TEXT


func _animate(percentage: float) -> void:
	if percentage == 0:
		return

	if percentage > 0:
		await get_tree().create_timer(0.1).timeout
		await _play_frames(0, 6, 0.02)

	if percentage > 0.33:
		await get_tree().create_timer(0.2).timeout
		await _play_frames(6, 11, 0.02)

	if percentage > 0.66:
		await get_tree().create_timer(0.2).timeout
		await _play_frames(11, 16, 0.02)


func _play_frames(start_frame: int, end_frame: int, delay: float) -> void:
	for frame in range(start_frame, end_frame):
		score_sprite.frame = frame
		await get_tree().create_timer(delay).timeout


func _on_replay_btn_pressed():
	AudioManager.play_click_sound()
	restart_level.emit()
	_play_frames(0, 1, 0.02)


func _on_next_btn_pressed():
	AudioManager.play_click_sound()
	if !_has_next_level:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	else:
		var level: LevelData = GameManager.get_next_level()
		GameManager.level_manager.init_level.call_deferred(level)

	_play_frames(0, 1, 0.02)
