class_name ArenaEnd extends Control

const UPDATE_TIME: float = 0.5

@export var steps: Array[ScoreCalculation]

var _score: int
var _tween: Tween
var _summary: GameSummary

@onready var panel: AnimatedPanel = %Panel
@onready var stats: HBoxContainer = %Stats
@onready var stats_icon: TextureRect = %StatsIcon
@onready var stats_multiplier: Label = %StatsMultiplier
@onready var score: Label = %Score
@onready var separator: HSeparator = %Separator
@onready var actions: HBoxContainer = %Actions
@onready var record_icon: TextureRect = %RecordIcon
@onready var replay_btn: Button = %ReplayBtn


func _ready() -> void:
	stats.hide()
	record_icon.hide()
	_update_score(_score)

	await panel.open()
	_calculate_score()


func _calculate_score() -> void:
	for step: ScoreCalculation in steps:
		if step.get_multiplier(_summary) == 0:
			# If does not change total score, should not be visible
			continue

		var old_score := _score
		var multiplier := step.get_multiplier(_summary)
		_score = step.update_score(_score, multiplier)
		stats_icon.texture = step.step_icon
		_update_stats_multiplier(multiplier)
		stats.show()

		_tween = get_tree().create_tween()
		_tween.tween_interval(1)
		_tween.tween_method(_update_score, old_score, _score, UPDATE_TIME)
		_tween.set_parallel()
		_tween.tween_method(_update_stats_multiplier, multiplier, 0, UPDATE_TIME)
		await _tween.finished
		stats.hide()

	_tween = create_tween()
	_tween.tween_interval(0.5)

	_tween.tween_method(_update_separation, 0, 250, 0.3)

	await _tween.finished

	var new_record: bool = SaveManager.update_blitz_score(_score)
	if new_record:
		_tween = get_tree().create_tween()
		_tween.tween_interval(0.5)
		await _tween.finished
		record_icon.show()

	await _tween.finished


func _update_separation(separation: int) -> void:
	separator.add_theme_constant_override("separation", separation)


func _close(next: Constants.GameState) -> void:
	panel.close()
	GameManager.change_state(next)
	self.queue_free.call_deferred()


func initialize_score(game_summary: GameSummary) -> void:
	_summary = game_summary
	_score = 0


func _on_exit_btn_pressed() -> void:
	_close(Constants.GameState.MAIN_MENU)


func _on_replay_btn_pressed() -> void:
	_close(Constants.GameState.ARENA_MODE)


func _update_score(new_score: int) -> void:
	score.text = str(new_score)


func _update_stats_multiplier(new_multiplier: int) -> void:
	stats_multiplier.text = "*%01d" % [new_multiplier]


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		if _tween:
			_tween.set_speed_scale(10)
