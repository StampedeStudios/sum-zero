class_name PlayModeSelection extends Control

const ARENA_UI := "res://packed_scene/user_interface/ArenaUI.tscn"
const GAME_UI := "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER := "res://packed_scene/scene_2d/LevelManager.tscn"
const PLAY_MODE_UI := "res://packed_scene/user_interface/PlayModeUI.tscn"

@export var arena_modes: Array[PlayMode]

var _current_mode_index := 0

@onready var panel: AnimatedPanel = %Panel
@onready var scroll_container: ScrollContainer = %HContainer
@onready var hbox_container: HBoxContainer = %HBoxContainer

@onready var arena_selection: VBoxContainer = %ArenaSelection
@onready var play_btn: Button = %PlayBtn
@onready var margin: MarginContainer = %MarginContainer


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.vertical_margin)

	# Animate entry
	await panel.open()


func setup() -> void:
	# Insert each mode as scrollable element
	for mode: PlayMode in arena_modes:
		var scene := ResourceLoader.load(PLAY_MODE_UI) as PackedScene
		var mode_ui := scene.instantiate() as PlayModeUI
		mode_ui.custom_minimum_size.x = scroll_container.size.x
		hbox_container.add_child(mode_ui)
		mode_ui.setup(mode)

	_set_first_uncompleted_mode.call_deferred()


func _set_first_uncompleted_mode() -> void:
	for id: int in range(arena_modes.size()):
		_current_mode_index = id
		var mode := arena_modes[id]
		if mode is StoryMode and SaveManager.get_start_level_playable() > mode.id_end - 1:
			continue
		else:
			break

	var step := scroll_container.get_h_scroll_bar().max_value / arena_modes.size()
	var target_scroll := ceili(_current_mode_index * step)
	scroll_container.scroll_horizontal = target_scroll


func _select_mode(index: int) -> void:
	index = clamp(index, 0, arena_modes.size() - 1)
	var mode_instance := hbox_container.get_child(index) as PlayModeUI
	play_btn.disabled = mode_instance.is_locked()

	_current_mode_index = index
	_snap_to_current_mode()


func _snap_to_current_mode() -> void:
	var step := scroll_container.get_h_scroll_bar().max_value / arena_modes.size()
	var target_scroll := ceili(_current_mode_index * step)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var distance := absf(target_scroll - scroll_container.get_h_scroll_bar().value)
	var duration := remap(distance, 0, step, 0, 0.6)
	tween.tween_property(scroll_container, "scroll_horizontal", target_scroll, duration)


func _close() -> void:
	await panel.close()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_close()


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var mode := arena_modes[_current_mode_index]
	if mode is ArenaMode:
		# load arena ui
		var scene := ResourceLoader.load(ARENA_UI) as PackedScene
		var arena_ui := scene.instantiate() as ArenaUI
		GameManager.arena_ui = arena_ui
		get_tree().root.add_child(arena_ui)
		arena_ui.set_arena_mode(mode)
	if mode is StoryMode:
		var playable_id: int = SaveManager.get_start_level_playable()
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


func _on_left_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_select_mode(_current_mode_index - 1)
	_snap_to_current_mode()


func _on_right_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_select_mode(_current_mode_index + 1)
	_snap_to_current_mode()


func _on_h_container_scroll_ended() -> void:
	var current_position := roundi(
		scroll_container.get_h_scroll_bar().value / scroll_container.size.x
	)

	_select_mode(current_position)
