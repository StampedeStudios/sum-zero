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
@onready var margin: MarginContainer = %MarginContainer
@onready var play_btn: Button = %PlayBtn
@onready var left_btn: Button = %LeftBtn
@onready var right_btn: Button = %RightBtn


func _ready() -> void:

	GameManager.on_state_change.connect(_on_state_change)

	var h_margin: int = roundi(GameManager.horizontal_margin / 2.0)
	var v_margin: int = roundi(GameManager.horizontal_margin / 2.0)

	margin.add_theme_constant_override("margin_left", v_margin)
	margin.add_theme_constant_override("margin_right", h_margin)
	margin.add_theme_constant_override("margin_top", v_margin)
	margin.add_theme_constant_override("margin_bottom", h_margin)

	await panel.open()


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.visible = false
		Constants.GameState.MODE_SELECTION:
			self.visible = true
			setup()
		_:
			self.visible = false


func setup() -> void:
	# Insert each mode as scrollable element
	for mode: PlayMode in arena_modes:
		var scene := ResourceLoader.load(PLAY_MODE_UI) as PackedScene
		var mode_ui := scene.instantiate() as PlayModeUI
		mode_ui.custom_minimum_size.x = scroll_container.size.x
		hbox_container.add_child(mode_ui)
		mode_ui.setup(mode)

	_set_first_uncompleted_mode.call_deferred()

	if _current_mode_index == 0:
		left_btn.disabled = true


func _set_first_uncompleted_mode() -> void:
	for id: int in range(arena_modes.size()):
		_current_mode_index = id
		var mode := arena_modes[id]
		if mode is StoryMode and SaveManager.get_last_completed_level() >= (mode.id_end - 1):
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
	panel.close()
	GameManager.change_state(Constants.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var mode := arena_modes[_current_mode_index]
	if mode is ArenaMode:
		# Load Arena UI
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

			# Load Level Manager
			var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
			var level_manager := scene.instantiate() as LevelManager
			get_tree().root.add_child(level_manager)
			GameManager.level_manager = level_manager
			level_manager.init_level(playable_level)

			# Load game UI
			scene = ResourceLoader.load(GAME_UI) as PackedScene
			var game_ui := scene.instantiate() as GameUI
			get_tree().root.add_child(game_ui)
			game_ui.initialize_ui(Constants.GameState.MAIN_MENU)
			GameManager.change_state(Constants.GameState.LEVEL_START)
			GameManager.game_ui = game_ui

	queue_free.call_deferred()


func _on_left_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_select_mode(_current_mode_index - 1)
	_snap_to_current_mode()

	if _current_mode_index == 0:
		left_btn.disabled = true

	right_btn.disabled = false


func _on_right_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_select_mode(_current_mode_index + 1)
	_snap_to_current_mode()

	if _current_mode_index == arena_modes.size() - 1:
		right_btn.disabled = true

	left_btn.disabled = false


func _on_h_container_scroll_ended() -> void:
	var current_position := roundi(
		scroll_container.get_h_scroll_bar().value / scroll_container.size.x
	)

	_select_mode(current_position)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_close()
