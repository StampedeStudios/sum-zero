class_name ArenaUI extends Control

const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"

var _arena_mode: ArenaMode
var _tween: Tween
var _current_level: LevelData
var _moves_count: int
var _time: int
var _max_time: int

@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var container: HBoxContainer = %BottomRightContainer
@onready var loading: Control = %Loading
@onready var timer: Timer = %Timer
@onready var arena_time: Label = %ArenaTime


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)
	container.add_theme_constant_override("separation", GameManager.btns_separation)
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.ARENA_MODE:
			self.visible = true
			loading.hide()
			loading.rotation_degrees = 0
			container.hide()
			timer.stop()
			arena_time.hide()
			_moves_count = 0
		GlobalConst.GameState.LEVEL_START:
			self.visible = true
			loading.hide()
			_tween.kill()
			container.show()
		_:
			self.visible = false
			
	
func init_arena(selected_mode: ArenaMode = null) -> void:
	if selected_mode:
		_arena_mode = selected_mode
	GameManager.change_state(GlobalConst.GameState.ARENA_MODE)
	#TODO: manage various arena modes <----------------------------------------
	match _arena_mode:
		_:
			_time = 0
			_max_time = 12
			_set_arena_time(_max_time)
			timer.timeout.connect(func() -> void: _set_arena_time(_time - 1))
			_get_new_random_level()
	

func _get_new_random_level() -> void:
	_start_loading()
	while true:
		#TODO: get random level data from Randomizer <------------------------------------
		var id := randi_range(0, GameManager._persistent_save.levels_hash.size() - 1)
		_current_level = GameManager.get_active_level(id)
		await get_tree().create_timer(0.2).timeout
		if _current_level.is_valid_data(): break
	# start playng level
	_init_level()


func _start_loading() -> void:
	loading.show()
	_tween = create_tween()
	_tween.set_loops(30)
	var op := _tween.tween_property(loading, "rotation_degrees", 360, 1)
	op.finished.connect(func() -> void: loading.rotation_degrees = 0)
	# after 30 seconds of loading if you have not found playable levels go back to the menu
	_tween.finished.connect(func() -> void: GameManager.change_state(GlobalConst.GameState.MAIN_MENU))


func _init_level() -> void:
	if GameManager.level_manager == null:
		var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
		var level_manager := scene.instantiate() as LevelManager
		GameManager.level_manager = level_manager
		level_manager.on_level_complete.connect(_on_level_complete)
		level_manager.on_consume_move.connect(_on_consumed_move)
		get_tree().root.add_child.call_deferred(level_manager)
	# start level
	GameManager.level_manager.init_level.call_deferred(_current_level)
	arena_time.show()
	timer.start()
	

func _on_level_complete() -> void:
	GameManager.change_state(GlobalConst.GameState.ARENA_MODE)
	var remaing_moves := _current_level.moves_left - _moves_count
	#TODO: update score and timer <--------------------------------------
	print(remaing_moves)
	_get_new_random_level()


func _on_consumed_move() -> void:
	_moves_count += 1
		

func _on_exit_btn_pressed() -> void:	
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_reset_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.level_manager.reset_level()
		

func _on_skip_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.ARENA_MODE)
	#TODO: manage skip cost <--------------------------------------------
	_get_new_random_level()


func _set_arena_time(new_time: int) -> void:
	_time = clampi(new_time, 0, _max_time)
	arena_time.text = "%02d:%02d" % [floori(float(_time) / 60), _time % 60]
	#TODO: manage end mode <----------------------------------
	match _arena_mode:
		_:
			if _time == 0:
				GameManager.change_state(GlobalConst.GameState.ARENA_MODE)
				
