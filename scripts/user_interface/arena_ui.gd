class_name ArenaUI extends Control

@export var bonus_time_floating_curve: Curve2D

const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"
const ARENA_END := "res://packed_scene/user_interface/ArenaEnd.tscn"
const LEVEL_END = "res://packed_scene/user_interface/LevelEnd.tscn"
const TUTORIAL = "res://packed_scene/user_interface/TutorialUI.tscn"

var _current_mode: ArenaMode
var _tween: Tween
var _time_tween: Tween
var _displayed_time := 0
var _current_level: LevelData
var _moves_count: int
var _reset_count: int
var _time: int
var _timer: Timer
var _game_summary: GameSummary
var _randomizer: Randomizer

@onready var margin: MarginContainer = %MarginContainer
@onready var container: HBoxContainer = %BottomRightContainer
@onready var loading: Control = %Loading
@onready var arena_time: Label = %ArenaTime
@onready var added_time: Label = %AddedTime
@onready var loading_icon: TextureRect = %LoadingIcon
@onready var skip_btn: Button = %SkipBtn


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	container.add_theme_constant_override("separation", GameManager.btns_separation)
	arena_time.add_theme_font_size_override("font_size", GameManager.title_font_size)
	added_time.add_theme_font_size_override("font_size", GameManager.text_font_size)

	# Adapt loading icon at screen size
	var screen_size := get_viewport_rect().size
	var min_edge := minf(screen_size.x, screen_size.y)
	var icon_size := Vector2(min_edge / 4, min_edge / 4)
	loading_icon.size = icon_size
	loading_icon.position = -icon_size / 2


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		Constants.GameState.ARENA_MODE:
			self.show()
			_hide_ui()
			_render_tutorial()
		Constants.GameState.LEVEL_START:
			self.show()
			_moves_count = 0
			_reset_count = 0
		Constants.GameState.PLAY_LEVEL:

			self.show()
			if _current_mode.timer_options:
				_show_ui(true)
			else:
				_show_ui(false)
		Constants.GameState.LEVEL_END:
			pass
		Constants.GameState.ARENA_END:
			self.hide()
			if _current_mode.one_shoot_mode:
				var scene := ResourceLoader.load(LEVEL_END) as PackedScene
				var level_end := scene.instantiate() as LevelEnd
				var star_count := clampi(_current_level.moves_left - _moves_count, -3, 0) + 3
				level_end.init_score(star_count, true, false)
				level_end.on_next_button.connect(_init_arena)
				level_end.on_replay_button.connect(_reset_level)
				get_tree().root.add_child(level_end)
			else:
				var scene := ResourceLoader.load(ARENA_END) as PackedScene
				var arena_end := scene.instantiate() as ArenaEnd
				arena_end.initialize_score(_game_summary)
				get_tree().root.add_child(arena_end)
		_:
			self.hide()


func _hide_ui() -> void:
	container.hide()
	loading.hide()
	if arena_time:
		arena_time.modulate.a = 0


func _show_ui(show_timer: bool) -> void:

	if show_timer:
		var tween := create_tween()
		tween.tween_property(arena_time, "modulate:a", 1, 0.2)

		_timer.start()

	loading.hide()
	container.show()


func _reset_level() -> void:
	_set_arena_time(0)
	_init_level()


func set_arena_mode(mode: ArenaMode) -> void:
	_current_mode = mode
	GameManager.change_state(Constants.GameState.ARENA_MODE)


func _init_arena() -> void:
	self.show()
	if !_randomizer and _current_mode.level_options:
		_randomizer = Randomizer.new(_current_mode.level_options)
		get_tree().root.add_child(_randomizer)

	if !_current_mode.one_shoot_mode:
		_game_summary = GameSummary.new()

	skip_btn.visible = _current_mode.is_skippable
	if _current_mode.timer_options:
		if !_timer:
			_timer = Timer.new()
			_timer.one_shot = false
			_timer.autostart = false
			_timer.wait_time = 1
			add_child(_timer)
		if _current_mode.timer_options.is_countdown:
			_set_arena_time(_current_mode.timer_options.max_game_time)
			if _timer.timeout.get_connections().is_empty():
				_timer.timeout.connect(func() -> void: _set_arena_time(_time - 1))
		else:
			_set_arena_time(0)
			if _timer.timeout.get_connections().is_empty():
				_timer.timeout.connect(func() -> void: _set_arena_time(_time + 1))

	_get_new_random_level()


func _get_new_random_level() -> void:
	_start_loading()
	_current_level = LevelData.new()
	while true:
		await get_tree().process_frame
		if _randomizer:
			# get random level data from Randomizer
			await _randomizer.generate_level(_current_level)
		else:
			# get random level from world's levels
			var id := randi_range(0, GameManager._persistent_save.levels_hash.size() - 1)
			_current_level = GameManager.get_active_level(id)
		if _current_level.is_valid_data():
			break

	# start playing level
	await get_tree().process_frame
	loading.hide()
	loading.rotation_degrees = 0
	_tween.kill()
	_init_level()


func _start_loading() -> void:
	loading.show()
	_tween = create_tween()
	_tween.set_loops(30)
	_tween.tween_property(loading, "rotation_degrees", 360, 1).as_relative()

	# After 30 seconds of loading if no playable level has been generated send user back to the menu
	# This should never happen
	_tween.finished.connect(GameManager.change_state.bind(Constants.GameState.MAIN_MENU))


func _init_level() -> void:
	if !GameManager.level_manager:
		var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
		var level_manager := scene.instantiate() as LevelManager
		GameManager.level_manager = level_manager
		level_manager.on_level_complete.connect(_on_level_complete)
		level_manager.on_consume_move.connect(_on_consumed_move)
		get_tree().root.add_child(level_manager)

	if !_current_mode.timer_options or !_current_mode.timer_options.is_countdown or _time > 0:
		await GameManager.level_manager.init_level(_current_level)
		GameManager.change_state(Constants.GameState.PLAY_LEVEL)
		GameManager.level_manager.spawn_grid()


func _on_level_complete() -> void:
	if _timer:
		if _time <= 0:
			return
		_timer.stop()
		var options := _current_mode.timer_options
		if options and options.time_gained_per_move > 0:
			var extra_time := options.get_time_gained(_current_level.moves_left, _moves_count)

			if extra_time != 0:
				_animate_extra_time(extra_time)

			arena_time.text = "%02d:%02d" % [floori(float(_time) / 60), _time % 60]
			_set_arena_time(_time + extra_time)

	if _current_mode.one_shoot_mode:
		GameManager.change_state(Constants.GameState.ARENA_END)
	else:
		GameManager.change_state(Constants.GameState.LEVEL_END)
		if _game_summary:
			var summary := LevelSummary.new()
			summary.set_star_count(_current_level.moves_left, _moves_count)
			summary.reset_used = _reset_count
			_game_summary.add_completed_level(summary)
			_moves_count = 0
			# TODO: show level streak
		_get_new_random_level()


func _on_consumed_move() -> void:
	_moves_count += 1


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(Constants.GameState.MAIN_MENU)


func _on_reset_btn_pressed() -> void:
	AudioManager.play_click_sound()
	if _moves_count > 0:
		_reset_count += 1
		_moves_count = 0
		GameManager.level_manager.reset_level()


func _on_skip_btn_pressed() -> void:
	if _timer:
		_timer.stop()

	AudioManager.play_click_sound()
	GameManager.change_state(Constants.GameState.LEVEL_END)
	if _current_mode.timer_options and _current_mode.timer_options.skip_cost < _time:
		var has_cost : bool = _current_mode.timer_options.skip_cost > 0

		if has_cost:
			_set_arena_time(_time - _current_mode.timer_options.skip_cost)
			_animate_extra_time(-_current_mode.timer_options.skip_cost)

	if _game_summary:
		_game_summary.skip_level()
	_get_new_random_level()


func _set_arena_time(new_time: int) -> void:
	new_time = max(new_time, 0)

	# Update authoritative time immediately
	_time = new_time

	if _current_mode.is_skippable and _current_mode.timer_options:
		if _current_mode.timer_options.is_countdown:
			skip_btn.visible = _time > _current_mode.timer_options.skip_cost

	if _time <= 0:
		if !_timer.is_stopped():
			_timer.stop()
			GameManager.change_state(Constants.GameState.ARENA_END)

	if _time_tween and _time_tween.is_running():
		_time_tween.kill()

	var start := _displayed_time
	var end := _time

	if start == end:
		arena_time.text = "%02d:%02d" % [floori(float(end) / 60), end % 60]
		return

	var duration : float = clamp(abs(end - start) * 0.03, 0.15, 0.6)

	_time_tween = create_tween()
	_time_tween.tween_method(
		func(value: float) -> void:
			var t := int(value)
			if t != _displayed_time:
				_displayed_time = t
				arena_time.text = "%02d:%02d" % [floori(float(_displayed_time) / 60), _displayed_time % 60],
		start,
		end,
		duration
	).set_trans(Tween.TRANS_LINEAR)
	

func _render_tutorial() -> void:
	var tutorial: TutorialData = _current_mode.tutorial
	if tutorial and SaveManager.get_options().is_visible(tutorial.tutorial_name):
		var scene := ResourceLoader.load(TUTORIAL) as PackedScene
		var tutorial_ui := scene.instantiate() as TutorialUi
		tutorial_ui.on_tutorial_closed.connect(_init_arena)
		get_tree().root.add_child(tutorial_ui)
		tutorial_ui.setup(tutorial)
	else:
		_init_arena()


func _animate_extra_time(extra_time: int) -> void:

	added_time.show()
	added_time.text = "%+d" % floori(float(extra_time))

	var color_index: int = clampi(extra_time, 4, 8)

	# Using red for negative values as there are no different cases
	# other than skip which has a constant cost
	if extra_time < 0:
		color_index = -5

	var color: Color = GameManager.palette.cell_color.get(color_index)
	added_time.add_theme_color_override("font_color", color)

	added_time.modulate.a = 1.0

	var start_pos := added_time.position
	var tween := create_tween()

	tween.tween_method(
		func(t: float) -> void:
			added_time.position = start_pos + bonus_time_floating_curve.samplef(t),
		0.0,
		1.0,
		0.8
	)

	tween.parallel().tween_property( added_time, "modulate:a", 0.0, 0.6)

	tween.finished.connect(func() -> void:
		added_time.hide()
		added_time.position = start_pos
	)
