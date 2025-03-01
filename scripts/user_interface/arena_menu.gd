class_name ArenaMenu extends Control

const LAST_TUTORIAL_LEVEL: int = 30
const WARNING_MSG := "⚠ \nARENA ACCESS LOCKED \n\nYou must complete level %s to join the Arena."
const ARENA_UI := "res://packed_scene/user_interface/ArenaUI.tscn"

@export var arena_modes: Array[ArenaMode]

var _mode_selected: int = 0

@onready var panel: Panel = %Panel
@onready var arena_selection: VBoxContainer = %ArenaSelection
@onready var arena_warnings: Label = %ArenaWarnings
@onready var mode_title: Label = %ModeTitle
@onready var mode_description: Label = %ModeDescription



func _ready() -> void:
	# playable only after completing all tutorial levels
	var is_locked: bool = GameManager.get_start_level_playable() < LAST_TUTORIAL_LEVEL
	if is_locked:
		arena_warnings.text = WARNING_MSG % [str(LAST_TUTORIAL_LEVEL)]
		arena_warnings.show()
		arena_selection.hide()
	else:
		arena_warnings.hide()
		update_arena_mode()
		arena_selection.show()
		
	create_tween().tween_method(animate, Vector2.ZERO, GameManager.ui_scale, 0.2)


func update_arena_mode() -> void:
	var mode := arena_modes[_mode_selected] as ArenaMode
	mode_title.text = mode.mode_name
	mode_description.text = mode.mode_description
	

func animate(animated_scale: Vector2) -> void:
	panel.scale = animated_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)
	
	
func close() -> void:
	await create_tween().tween_method(animate, GameManager.ui_scale, Vector2.ZERO, 0.2).finished
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	close()	
	

func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		close()


func _on_prev_mode_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_mode_selected -= 1
		if _mode_selected < 0:
			_mode_selected = arena_modes.size() - 1
		update_arena_mode()
		

func _on_next_mode_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_mode_selected += 1
		if _mode_selected == arena_modes.size():
			_mode_selected = 0
		update_arena_mode()
		

func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(ARENA_UI) as PackedScene
	var arena_ui := scene.instantiate() as ArenaUI
	GameManager.arena_ui = arena_ui
	get_tree().root.add_child(arena_ui)
	arena_ui.init_arena.call_deferred(arena_modes[_mode_selected])
	queue_free.call_deferred()
	
