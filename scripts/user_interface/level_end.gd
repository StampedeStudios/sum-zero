class_name LevelEnd extends Control

const PLAY_TEXT = "NEXT"
const EXIT_TEXT = "EXIT"
const HINT_ANIM_DURATION = 1
const STAR_ANIM_DURATION = 0.15
const STAR_ANIM_INTERVAL = 0.1
const CREDITS = "res://packed_scene/user_interface/CreditsScreen.tscn"

@export var frames: SpriteFrames

var _has_next_level: bool

@onready var next_btn: Button = %NextBtn
@onready var hint: Label = %Hint
@onready var panel: Panel = %Panel
@onready var level_score_img: TextureRect = %LevelScoreImg
@onready var new_record: TextureRect = %NewRecord


func _ready() -> void:
	new_record.hide()
	_update_shader_percentage(0)
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
	var tween: Tween
	if percentage == 0:
		return

	if percentage > 0:
		tween = create_tween()
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 0, 5, STAR_ANIM_DURATION)

	if percentage > 0.33:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 6, 10, STAR_ANIM_DURATION)

	if percentage > 0.66:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 11, 15, STAR_ANIM_DURATION)

	# extra reward for beating the developers (you think ...)
	if percentage > 1:
		tween.tween_interval(STAR_ANIM_INTERVAL)
		tween.tween_method(_play_frames, 16, 20, STAR_ANIM_DURATION)
		
	tween.tween_interval(STAR_ANIM_INTERVAL)
	await tween.finished


func _animate_hint(move_left: int) -> void:
	hint.text = _select_random_text(move_left)
	var tween := create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween from 0 to 100
	tween.tween_method(_update_shader_percentage, 0.0, 1.0, HINT_ANIM_DURATION)
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


func _play_frames(frame: int) -> void:
	level_score_img.texture = frames.get_frame_texture("default", frame)


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
		await GameManager.level_manager.init_level(level)
		GameManager.change_state(GlobalConst.GameState.LEVEL_START)
		queue_free()
