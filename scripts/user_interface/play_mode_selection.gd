class_name PlayModeSelection extends Control

const LOCKED_MSG := "You must reach level %d to join this MODE."
const ARENA_UI := "res://packed_scene/user_interface/ArenaUI.tscn"
const GAME_UI := "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"

@export var arena_modes: Array[PlayMode]

var _mode_selected: int = 0

@onready var panel: Panel = %Panel
@onready var arena_selection: VBoxContainer = %ArenaSelection
@onready var mode_title: Label = %ModeTitle
@onready var mode_icon: TextureRect = %ModeIcon
@onready var locked_msg: Label = %LockedMsg



func _ready() -> void:
	if arena_modes.is_empty():
		queue_free.call_deferred()
		return
	_update_play_mode()		
	create_tween().tween_method(_animate, Vector2.ZERO, GameManager.ui_scale, 0.2)


func _update_play_mode() -> void:
	var mode := arena_modes[_mode_selected] as PlayMode
	mode_title.text = mode.title
	if GameManager.get_start_level_playable() <= mode.unlock_level_id:
		mode_icon.hide()
		locked_msg.text = LOCKED_MSG % [mode.unlock_level_id + 1]
		locked_msg.show()
	else:	
		locked_msg.hide()
		mode_icon.texture = mode.icon
		mode_icon.show()
	

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
		arena_ui.init_arena.call_deferred(mode)
	if mode is StoryMode:
		var playable_id: int = GameManager.get_start_level_playable()
		if playable_id >= mode.id_end:
			playable_id = mode.id_start
		var playable_level: LevelData = GameManager.get_active_level(playable_id)
		if playable_level != null:
			# load game ui
			var scene := ResourceLoader.load(GAME_UI) as PackedScene
			var game_ui := scene.instantiate() as GameUI
			GameManager.game_ui = game_ui
			get_tree().root.add_child.call_deferred(game_ui)
			game_ui.initialize_ui.call_deferred(GlobalConst.GameState.MAIN_MENU)
			GameManager.change_state(GlobalConst.GameState.LEVEL_START)
			# load level manager
			scene = ResourceLoader.load(LEVEL_MANAGER) as PackedScene
			var level_manager := scene.instantiate() as LevelManager
			GameManager.level_manager = level_manager
			get_tree().root.add_child.call_deferred(level_manager)
			level_manager.init_level.call_deferred(playable_level)
		
	queue_free.call_deferred()
	
