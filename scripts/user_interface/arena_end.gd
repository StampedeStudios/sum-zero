class_name ArenaEnd extends Control

const UPDATE_TIME: float = 0.5

@export var steps: Array[ScoreCalculation]

var _score: int
var _tween: Tween
var _summary: GameSummary

@onready var panel: Panel = %Panel
@onready var stats: HBoxContainer = %Stats
@onready var stats_icon: TextureRect = %StatsIcon
@onready var stats_multiplier: Label = %StatsMultiplier
@onready var score: Label = %Score
@onready var actions: HBoxContainer = %Actions


func _ready() -> void:
	actions.hide()
	stats.hide()
	_update_score(_score)
	_tween = get_tree().create_tween()
	await _tween.tween_method(_animate, Vector2.ZERO, GameManager.ui_scale, 0.2).finished
	_calculate_score()


func _calculate_score() -> void:
	for step: ScoreCalculation in steps:
		var old_score := _score
		var multiplier := step.get_multiplier(_summary)
		_score = step.update_score(_score, multiplier)
		stats_icon.texture = step.step_icon
		_update_stats_multiplier(multiplier)
		stats.show()
		print("multiplier ", multiplier)
		print("score ", _score)

		await get_tree().create_timer(1).timeout
		_tween = get_tree().create_tween()
		_tween.tween_method(_update_score, old_score, _score, UPDATE_TIME)
		_tween.set_parallel()
		_tween.tween_method(_update_stats_multiplier, multiplier, 0, UPDATE_TIME)
		await _tween.finished
		stats.hide()
	actions.show()


func _close(next: GlobalConst.GameState) -> void:
	await create_tween().tween_method(_animate, GameManager.ui_scale, Vector2.ZERO, 0.2).finished
	GameManager.change_state(next)
	self.queue_free.call_deferred()


func _animate(animated_scale: Vector2) -> void:
	panel.scale = animated_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func initialize_score(game_summary: GameSummary) -> void:
	_summary = game_summary
	_score = 0


func _on_exit_btn_pressed() -> void:
	_close(GlobalConst.GameState.MAIN_MENU)


func _on_replay_btn_pressed() -> void:
	_close(GlobalConst.GameState.ARENA_MODE)


func _update_score(new_score: int) -> void:
	score.text = "%06d" % [new_score]


func _update_stats_multiplier(new_multiplier: int) -> void:
	stats_multiplier.text = "x%02d" % [new_multiplier]


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_tween.set_speed_scale(10)
