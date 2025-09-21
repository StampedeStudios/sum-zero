class_name LevelEnd extends Control

signal on_replay_button
signal on_next_button

const PLAY_TEXT = "NEXT"
const EXIT_TEXT = "EXIT"
const HINT_ANIM_DURATION = 1
const STAR_ANIM_DURATION = 0.15
const STAR_ANIM_INTERVAL = 0.1
const EXTRA_STARS_MSGS: Array[String] = ["EXTRA_STAR_MSG_1", "EXTRA_STAR_MSG_2", "EXTRA_STAR_MSG_3"]
const THREE_STARS_MSGS: Array[String] = ["THREE_STAR_MSG_1", "THREE_STAR_MSG_2", "THREE_STAR_MSG_3"]
const TWO_STARS_MSGS: Array[String] = ["TWO_STAR_MSG_1", "TWO_STAR_MSG_2", "TWO_STAR_MSG_3"]
const ONE_STARS_MSGS: Array[String] = ["ONE_STAR_MSG_1", "ONE_STAR_MSG_2", "ONE_STAR_MSG_3"]
const NO_STARS_MSGS: Array[String] = ["ZERO_STAR_MSG_1", "ZERO_STAR_MSG_2", "ZERO_STAR_MSG_3"]


var _star_count: int
var _has_next_level: bool
var _is_record: bool

@onready var next_btn: Button = %NextBtn
@onready var hint: Label = %Hint
@onready var panel: AnimatedPanel = %Panel
@onready var left_star: TextureRect = %LeftStar
@onready var right_star: TextureRect = %RightStar
@onready var middle_star: TextureRect = %MiddleStar

func _ready() -> void:

	right_star.scale = Vector2(0, 0)
	left_star.scale = Vector2(0, 0)
	middle_star.scale = Vector2(0, 0)

	_update_shader_percentage(0)
	await panel.open()
	_update_score()


func init_score(star_count: int, has_next_level: bool, is_record: bool) -> void:
	_star_count = star_count
	_has_next_level = has_next_level
	_is_record = is_record


func _close() -> void:
	await panel.close()
	GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


func _update_score() -> void:
	next_btn.text = tr(PLAY_TEXT) if _has_next_level else tr(EXIT_TEXT)
	_animate_stars(_star_count)
	_animate_hint(_star_count)
	if _is_record:
		print("Player set a new record for this level")


func _animate_stars(star_count: int) -> void:

	if star_count != 0:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel()

		if star_count >= 1:
			tween.tween_property(left_star, "scale", Vector2(0.7, 0.7), STAR_ANIM_DURATION)
			tween.tween_interval(STAR_ANIM_INTERVAL)

		if star_count >= 2:
			tween.tween_property(middle_star, "scale", Vector2(0.8, 0.8), STAR_ANIM_DURATION)
			tween.tween_interval(STAR_ANIM_INTERVAL)

		if star_count == 3:
			tween.tween_property(right_star, "scale", Vector2(0.7, 0.7), STAR_ANIM_DURATION)
			tween.tween_interval(STAR_ANIM_INTERVAL)

		await tween.finished
	else:
		print("Player has lost all stars, no star is being animated")


func _animate_hint(star_count: int) -> void:
	hint.text = _select_random_text(star_count)
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 100
	tween.tween_method(_update_shader_percentage, 0.0, 1.0, HINT_ANIM_DURATION)
	await tween.finished


func _update_shader_percentage(value: float) -> void:
	hint.material.set_shader_parameter("percentage", value)


func _select_random_text(num_stars: int) -> String:
	if num_stars <= 0:
		return tr(NO_STARS_MSGS.pick_random())
	if num_stars == 1:
		return tr(ONE_STARS_MSGS.pick_random())
	if num_stars == 2:
		return tr(TWO_STARS_MSGS.pick_random())
	if num_stars == 3:
		return tr(THREE_STARS_MSGS.pick_random())

	# Extra reward for beating the developers (you think ...)
	return tr(EXTRA_STARS_MSGS.pick_random())

func _on_replay_btn_pressed() -> void:
	AudioManager.play_click_sound()
	on_replay_button.emit()
	queue_free()


func _on_next_btn_pressed() -> void:
	AudioManager.play_click_sound()
	on_next_button.emit()
	queue_free()
