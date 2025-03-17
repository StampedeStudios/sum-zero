class_name LevelEnd extends Control

signal on_replay_button
signal on_next_button

const PLAY_TEXT = "NEXT"
const EXIT_TEXT = "EXIT"
const HINT_ANIM_DURATION = 1
const STAR_ANIM_DURATION = 0.15
const STAR_ANIM_INTERVAL = 0.1

@export var frames: SpriteFrames

var _star_count: int
var _has_next_level: bool
var _is_record: bool

@onready var next_btn: Button = %NextBtn
@onready var hint: Label = %Hint
@onready var panel: AnimatedPanel = %Panel
@onready var level_score_img: TextureRect = %LevelScoreImg
@onready var new_record: TextureRect = %NewRecord


func _ready() -> void:
	new_record.hide()
	_update_shader_percentage(0)
	await panel.open()
	_update_score()


func init_score(star_count: int, has_next_level: bool, is_record: bool) -> void:
	_star_count = star_count
	_has_next_level = has_next_level
	_is_record = is_record


func _close() -> void:
	await panel.close()
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


func _update_score() -> void:
	next_btn.text = tr(PLAY_TEXT) if _has_next_level else tr(EXIT_TEXT)
	await _animate_stars(_star_count)
	await _animate_hint(_star_count)
	new_record.visible = _is_record


func _animate_stars(star_count: int) -> void:
	var tween := create_tween()
	if star_count == 0:
		_play_frames(0)

	if star_count > 0:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 1, 5, STAR_ANIM_DURATION)

	if star_count > 1:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 6, 10, STAR_ANIM_DURATION)

	if star_count > 2:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 11, 15, STAR_ANIM_DURATION)

	# extra reward for beating the developers (you think ...)
	if star_count > 3:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 16, 20, STAR_ANIM_DURATION)

	tween.tween_interval(STAR_ANIM_INTERVAL)
	await tween.finished


func _animate_hint(star_count: int) -> void:
	hint.text = _select_random_text(star_count)
	var tween := create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 100
	tween.tween_method(_update_shader_percentage, 0.0, 1.0, HINT_ANIM_DURATION)
	await tween.finished


func _update_shader_percentage(value: float) -> void:
	hint.material.set_shader_parameter("percentage", value)


func _select_random_text(num_stars: int) -> String:
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


func _play_frames(frame: int) -> void:
	level_score_img.texture = frames.get_frame_texture("default", frame)


func _on_replay_btn_pressed() -> void:
	AudioManager.play_click_sound()
	on_replay_button.emit()
	queue_free()


func _on_next_btn_pressed() -> void:
	AudioManager.play_click_sound()
	on_next_button.emit()
	queue_free()
