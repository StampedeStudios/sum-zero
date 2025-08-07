## Main UI scene — Handles grid rendering and main game loop events.
class_name GameUI extends Control

const TUTORIAL = "res://packed_scene/user_interface/TutorialUI.tscn"
const LEVEL_UI = "res://packed_scene/user_interface/LevelUI.tscn"
const LEVEL_END = "res://packed_scene/user_interface/LevelEnd.tscn"
const CREDITS = "res://packed_scene/user_interface/CreditsScreen.tscn"

var _moves_left: int
var _return_to: Constants.GameState = Constants.GameState.MAIN_MENU
var _has_next_level: bool

@onready var skip_btn: Button = %SkipBtn
@onready var exit_btn: Button = %ExitBtn

@onready var margin: MarginContainer = %MarginContainer
@onready var container: HBoxContainer = %BottomRightContainer


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)

	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	container.add_theme_constant_override("separation", GameManager.btns_separation)


func initialize_ui(prev_state: Constants.GameState) -> void:
	_return_to = prev_state


func next_level() -> void:
	if _has_next_level:
		var level: LevelData = GameManager.get_next_level()
		await GameManager.level_manager.init_level(level)
		GameManager.change_state(Constants.GameState.LEVEL_START)
	else:
		if GameManager.get_active_context() == Constants.LevelGroup.MAIN:
			var scene := ResourceLoader.load(CREDITS) as PackedScene
			var credits := scene.instantiate() as CreditsScreen
			get_tree().root.add_child(credits)
		else:
			_exit()


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		Constants.GameState.PLAY_LEVEL:
			_moves_left = GameManager.get_active_level().moves_left
			if !GameManager.level_manager.on_consume_move.is_connected(_consume_move):
				GameManager.level_manager.on_consume_move.connect(_consume_move)
			if !GameManager.level_manager.on_level_complete.is_connected(_on_level_complete):
				GameManager.level_manager.on_level_complete.connect(_on_level_complete)
			self.visible = true

		Constants.GameState.LEVEL_START:
			self.visible = true
			_render_tutorial()
			_has_next_level = GameManager.set_next_level()
			skip_btn.visible = _has_next_level and SaveManager.is_level_completed()

		Constants.GameState.LEVEL_END:
			self.visible = false
		_:
			self.visible = false


func _render_tutorial() -> void:
	var tutorial: TutorialData = SaveManager.get_tutorial()
	if tutorial:
		var scene := ResourceLoader.load(TUTORIAL) as PackedScene
		var tutorial_ui := scene.instantiate() as TutorialUi
		tutorial_ui.on_tutorial_closed.connect(GameManager.level_manager.spawn_grid)
		get_tree().root.add_child(tutorial_ui)
		tutorial_ui.setup(tutorial)
	else:
		GameManager.level_manager.spawn_grid()


func _on_level_complete() -> void:
	var is_record: bool = SaveManager.update_level_progress(_moves_left)
	var star_count := clampi(_moves_left, -3, 1) + 3
	var scene := ResourceLoader.load(LEVEL_END) as PackedScene
	var level_end := scene.instantiate() as LevelEnd

	level_end.on_replay_button.connect(GameManager.level_manager.reset_level)
	level_end.on_next_button.connect(next_level)
	level_end.init_score(star_count, _has_next_level, is_record)
	get_tree().root.add_child(level_end)

	GameManager.change_state(Constants.GameState.LEVEL_END)


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_exit()


func _consume_move() -> void:
	_moves_left -= 1


func _on_reset_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.level_manager.reset_level()


func _on_skip_btn_pressed() -> void:
	AudioManager.play_click_sound()
	next_level()


func _exit() -> void:
	match _return_to:
		Constants.GameState.MAIN_MENU:
			GameManager.change_state(Constants.GameState.MAIN_MENU)
		Constants.GameState.LEVEL_PICK:
			var scene := ResourceLoader.load(LEVEL_UI) as PackedScene
			var level_ui := scene.instantiate() as LevelUI
			get_tree().root.add_child.call_deferred(level_ui)
			GameManager.level_ui = level_ui
			GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)
