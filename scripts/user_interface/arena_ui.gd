class_name ArenaUI extends Control

const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"
const ARENA_END := "res://packed_scene/user_interface/ArenaEnd.tscn"
const LEVEL_END = "res://packed_scene/user_interface/LevelEnd.tscn"
const TUTORIAL = "res://packed_scene/user_interface/TutorialUI.tscn"

var _current_mode: ArenaMode
var _tween: Tween
var _current_level: LevelData
var _moves_count: int
var _reset_count: int
var _time: int
var _timer: Timer
var _game_summary: GameSummary
var _randomizer: Randomizer

@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var container: HBoxContainer = %BottomRightContainer
@onready var loading: Control = %Loading
@onready var arena_time: Label = %ArenaTime
@onready var loading_icon: TextureRect = %LoadingIcon
@onready var skip_btn: Button = %SkipBtn


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)
	container.add_theme_constant_override("separation", GameManager.btns_separation)

	# adapt loading icon at screen size
	var screen_size := get_viewport_rect().size
	var min_edge := minf(screen_size.x, screen_size.y)
	var icon_size := Vector2(min_edge / 4, min_edge / 4)
	loading_icon.size = icon_size
	loading_icon.position = -icon_size / 2


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.ARENA_MODE:
			self.show()
			_hide_ui()
			_render_tutorial()
		GlobalConst.GameState.LEVEL_START:
			self.show()
			_moves_count = 0
			_reset_count = 0
		GlobalConst.GameState.PLAY_LEVEL:
			container.show()
			if _current_mode.timer_options:
				arena_time.show()
				_timer.start()
		GlobalConst.GameState.LEVEL_END:
			pass
		GlobalConst.GameState.ARENA_END:
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
	arena_time.hide()


func _reset_level() -> void:
	_set_arena_time(0)
	_init_level()


func set_arena_mode(mode: ArenaMode) -> void:
	_current_mode = mode
	GameManager.change_state(GlobalConst.GameState.ARENA_MODE)


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
	_hide_ui()
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
	# after 30 seconds of loading if you have not found playable levels go back to the menu
	_tween.finished.connect(GameManager.change_state.bind(GlobalConst.GameState.MAIN_MENU))


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
		GameManager.change_state(GlobalConst.GameState.LEVEL_START)
		GameManager.level_manager.animate_grid()


func _on_level_complete() -> void:
	if _timer:
		if _time <= 0:
			return
		_timer.stop()
		var options := _current_mode.timer_options
		if options and options.time_gained_per_move > 0:
			var extra_time := options.get_time_gained(_current_level.moves_left, _moves_count)
			_set_arena_time(_time + extra_time)

	if _current_mode.one_shoot_mode:
		GameManager.change_state(GlobalConst.GameState.ARENA_END)
	else:
		GameManager.change_state(GlobalConst.GameState.LEVEL_END)
		if _game_summary:
			var summary := LevelSummary.new()
			summary.set_star_count(_current_level.moves_left, _moves_count)
			summary.reset_used = _reset_count
			var chain := _game_summary.add_completed_level(summary)
			# TODO: show level streak
			print(chain)
		_get_new_random_level()


func _on_consumed_move() -> void:
	_moves_count += 1


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_reset_btn_pressed() -> void:
	AudioManager.play_click_sound()
	if _moves_count > 0:
		_reset_count += 1
		_moves_count = 0
		GameManager.level_manager.reset_level()


func _on_skip_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.LEVEL_END)
	if _current_mode.timer_options and _current_mode.timer_options.skip_cost < _time:
		_set_arena_time(_time - _current_mode.timer_options.skip_cost)
	if _game_summary:
		_game_summary.skip_level()
	_get_new_random_level()


func _set_arena_time(new_time: int) -> void:
	_time = new_time
	if _current_mode.is_skippable and _current_mode.timer_options:
		if _current_mode.timer_options.is_countdown:
			skip_btn.visible = _time > _current_mode.timer_options.skip_cost
	if _time <= 0:
		_time = 0
		if !_timer.is_stopped():
			_timer.stop()
			GameManager.change_state(GlobalConst.GameState.ARENA_END)
	arena_time.text = "%02d:%02d" % [floori(float(_time) / 60), _time % 60]


func _render_tutorial() -> void:
	var tutorial: TutorialData = _current_mode.tutorial
	if tutorial:
		var scene := ResourceLoader.load(TUTORIAL) as PackedScene
		var tutorial_ui := scene.instantiate() as TutorialUi
		tutorial_ui.on_tutorial_closed.connect(_init_arena)
		get_tree().root.add_child(tutorial_ui)
		tutorial_ui.setup(tutorial)
	else:
		_init_arena()
