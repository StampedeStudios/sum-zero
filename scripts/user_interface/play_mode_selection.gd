class_name PlayModeSelection extends Control

const ARENA_UI := "res://packed_scene/user_interface/ArenaUI.tscn"
const GAME_UI := "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"

@export var arena_modes: Array[PlayMode]

var _mode_selected: int

@onready var panel: Panel = %Panel
@onready var arena_selection: VBoxContainer = %ArenaSelection
@onready var mode_title: Label = %ModeTitle
@onready var mode_icon: TextureRect = %ModeIcon
@onready var locked_msg: Label = %LockedMsg
@onready var play_btn: Button = %PlayBtn
@onready var completed_icon: TextureRect = %CompletedIcon


func _ready() -> void:
	if arena_modes.is_empty():
		queue_free.call_deferred()
		return
	_set_first_uncompleted_mode()
	_update_play_mode()
	create_tween().tween_method(_animate, Vector2.ZERO, GameManager.ui_scale, 0.2)


func _set_first_uncompleted_mode() -> void:
	for id: int in range(arena_modes.size()):
		_mode_selected = id
		var mode := arena_modes[id]
		if mode is StoryMode and GameManager.get_start_level_playable() > mode.id_end - 1:
			continue
		else:
			break

func _update_play_mode() -> void:
	var mode := arena_modes[_mode_selected] as PlayMode
	var is_locked: bool
	
	mode_title.text = mode.title
	mode_icon.texture = mode.icon
	
	match mode.unlock_mode:
		PlayMode.UnlockMode.NONE:
			pass
		PlayMode.UnlockMode.LEVEL:
			locked_msg.text = tr("LEVEL_LOCK_MSG %d") % [mode.unlock_count]
			is_locked = GameManager.get_start_level_playable() < mode.unlock_count
		PlayMode.UnlockMode.STAR:
			locked_msg.text = tr("STAR_LOCK_MSG %d") % [mode.unlock_count]
			is_locked = GameManager.get_star_count() < mode.unlock_count
	
	mode_icon.visible = !is_locked
	locked_msg.visible = is_locked
	play_btn.disabled = is_locked	
	
	if mode is StoryMode and !is_locked:
		completed_icon.visible = GameManager.get_start_level_playable() > mode.id_end - 1
	else:
		completed_icon.hide()


func _animate(animated_scale: Vector2) -> void:
	panel.scale = animated_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func _close() -> void:
	await create_tween().tween_method(_animate, GameManager.ui_scale, Vector2.ZERO, 0.2).finished
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_close()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_close()


func _on_prev_mode_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_mode_selected -= 1
		if _mode_selected < 0:
			_mode_selected = arena_modes.size() - 1
		_update_play_mode()


func _on_next_mode_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_mode_selected += 1
		if _mode_selected == arena_modes.size():
			_mode_selected = 0
		_update_play_mode()


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var mode := arena_modes[_mode_selected]
	if mode is ArenaMode:
		# load arena ui
		var scene := ResourceLoader.load(ARENA_UI) as PackedScene
		var arena_ui := scene.instantiate() as ArenaUI
		GameManager.arena_ui = arena_ui
		get_tree().root.add_child(arena_ui)
		arena_ui.init_arena(mode)
	if mode is StoryMode:
		var playable_id: int = GameManager.get_start_level_playable()
		if playable_id > mode.id_end - 1:
			playable_id = mode.id_start - 1
		var playable_level: LevelData = GameManager.get_active_level(playable_id)
		if playable_level != null:
			# load level manager
			var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
			var level_manager := scene.instantiate() as LevelManager
			GameManager.level_manager = level_manager
			get_tree().root.add_child(level_manager)
			level_manager.init_level(playable_level)
			# load game ui
			scene = ResourceLoader.load(GAME_UI) as PackedScene
			var game_ui := scene.instantiate() as GameUI
			GameManager.game_ui = game_ui
			get_tree().root.add_child(game_ui)
			game_ui.initialize_ui(GlobalConst.GameState.MAIN_MENU)
			GameManager.change_state(GlobalConst.GameState.LEVEL_START)

	queue_free.call_deferred()
