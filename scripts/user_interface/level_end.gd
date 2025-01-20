class_name LevelEnd extends Control

signal restart_level

const PLAY_TEXT = " Next "
const EXIT_TEXT = " Exit "
const ANIMATION_DURATION = 300

var _has_next_level: bool

@onready var score_sprite: AnimatedSprite2D = %LevelScoreImg
@onready var next_btn: Button = %NextBtn
@onready var hint: Label = %Hint


func _ready():
	GameManager.on_state_change.connect(_on_state_change)

	self.scale = GameManager.ui_scale
	self.position = Vector2(get_viewport().size) / 2 - (self.scale * self.size / 2)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_END:
			self.visible = true
		_:
			self.visible = false


func update_score(move_left: int) -> void:
	GameManager.update_level_progress(move_left)
	_has_next_level = GameManager.set_next_level()
	next_btn.text = PLAY_TEXT if _has_next_level else EXIT_TEXT

	await _animate_stars(move_left)
	await _animate_hint(move_left)


func _animate_stars(move_left: int) -> void:
	var percentage: float = 0.33 * (GlobalConst.MAX_STARS_GAIN + move_left)

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


func _animate_hint(move_left: int):
	hint.text = _select_random_text(move_left)
	var tween := create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 100
	tween.tween_method(_update_shader_percentage, 0.0, 100.0, ANIMATION_DURATION)


func _update_shader_percentage(value: float):
	hint.material.set_shader_parameter("percentage", value)


func _select_random_text(move_left) -> String:
	var num_stars = clamp(GlobalConst.MAX_STARS_GAIN + move_left, 0, GlobalConst.MAX_STARS_GAIN)

	if num_stars == 0:
		return GlobalConst.NO_STARS_MSGS.pick_random()
	if num_stars == 1:
		return GlobalConst.ONE_STARS_MSGS.pick_random()
	if num_stars == 2:
		return GlobalConst.TWO_STARS_MSGS.pick_random()

	return GlobalConst.THREE_STARS_MSGS.pick_random()


func _play_frames(start_frame: int, end_frame: int, delay: float) -> void:
	for frame in range(start_frame, end_frame):
		score_sprite.frame = frame
		await get_tree().create_timer(delay).timeout


func _on_replay_btn_pressed():
	AudioManager.play_click_sound()

	restart_level.emit()
	queue_free()


func _on_next_btn_pressed():
	AudioManager.play_click_sound()

	if !_has_next_level:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	else:
		var level: LevelData = GameManager.get_next_level()
		GameManager.level_manager.init_level.call_deferred(level)
		queue_free()
