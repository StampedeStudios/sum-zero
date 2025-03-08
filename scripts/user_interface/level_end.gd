class_name LevelEnd extends Control

const PLAY_TEXT = "NEXT"
const EXIT_TEXT = "EXIT"
const ANIMATION_DURATION = 300
const CREDITS = "res://packed_scene/user_interface/CreditsScreen.tscn"

var _has_next_level: bool

@onready var score_sprite: AnimatedSprite2D = %LevelScoreImg
@onready var next_btn: Button = %NextBtn
@onready var hint: Label = %Hint
@onready var panel: Panel = %Panel
@onready var new_record: Sprite2D = %NewRecord


func _ready() -> void:
	await create_tween().tween_method(animate, Vector2.ZERO, GameManager.ui_scale, 0.2).finished
	update_score()


func close() -> void:
	await create_tween().tween_method(animate, GameManager.ui_scale, Vector2.ZERO, 0.2).finished
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


func animate(animated_scale: Vector2) -> void:
	panel.scale = animated_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func update_score() -> void:
	var move_left: int = GameManager.game_ui.moves_left
	var is_record: bool = GameManager.update_level_progress(move_left)
	_has_next_level = GameManager.set_next_level()
	next_btn.text = tr(PLAY_TEXT) if _has_next_level else tr(EXIT_TEXT)

	await _animate_stars(move_left)
	await _animate_hint(move_left)
	new_record.visible = is_record


func _animate_stars(move_left: int) -> void:
	var percentage: float = 0.33 * (GlobalConst.MAX_STARS_GAIN + move_left)

	if percentage == 0:
		return

	if percentage > 0:
		await get_tree().create_timer(0.1).timeout
		await _play_frames(0, 5, 0.02)

	if percentage > 0.33:
		await get_tree().create_timer(0.2).timeout
		await _play_frames(6, 10, 0.02)

	if percentage > 0.66:
		await get_tree().create_timer(0.2).timeout
		await _play_frames(11, 15, 0.02)

	# extra reward for beating the developers (you think ...)
	if percentage > 1:
		await get_tree().create_timer(0.2).timeout
		await _play_frames(16, 20, 0.02)


func _animate_hint(move_left: int) -> void:
	hint.text = _select_random_text(move_left)
	var tween := create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 100
	tween.tween_method(_update_shader_percentage, 0.0, 100.0, ANIMATION_DURATION)
	await tween.finished


func _update_shader_percentage(value: float) -> void:
	hint.material.set_shader_parameter("percentage", value)


func _select_random_text(move_left: int) -> String:
	var num_stars := GlobalConst.MAX_STARS_GAIN + move_left

	if num_stars <= 0:
		return tr(GlobalConst.NO_STARS_MSGS.pick_random())
	if num_stars == 1:
		return tr(GlobalConst.ONE_STARS_MSGS.pick_random())
	if num_stars == 2:
		return tr(GlobalConst.TWO_STARS_MSGS.pick_random())
	if num_stars == 3:
		return tr(GlobalConst.THREE_STARS_MSGS.pick_random())
	# extra reward for beating the developers (you think ...)
	return tr(GlobalConst.EXTRA_STARS_MSGS.pick_random())


func _play_frames(start_frame: int, end_frame: int, delay: float) -> void:
	for frame in range(start_frame, end_frame + 1):
		score_sprite.frame = frame
		await get_tree().create_timer(delay).timeout


func _on_replay_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.level_manager.reset_level()
	queue_free()


func _on_next_btn_pressed() -> void:
	AudioManager.play_click_sound()

	if !_has_next_level:
		var scene := ResourceLoader.load(CREDITS) as PackedScene
		var credits := scene.instantiate() as CreditsScreen
		get_tree().root.add_child(credits)
		queue_free()
	else:
		var level: LevelData = GameManager.get_next_level()
		GameManager.level_manager.init_level(level)
		GameManager.change_state(GlobalConst.GameState.LEVEL_START)
		queue_free()
