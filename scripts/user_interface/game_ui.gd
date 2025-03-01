class_name GameUI extends Control

const TUTORIAL = "res://packed_scene/user_interface/Tutorial.tscn"
const LEVEL_UI = "res://packed_scene/user_interface/LevelUI.tscn"
const LEVEL_END = "res://packed_scene/user_interface/LevelEnd.tscn"

var moves_left: int
var _return_to: GlobalConst.GameState = GlobalConst.GameState.MAIN_MENU

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

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)
	container.add_theme_constant_override("separation", GameManager.btns_separation)


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	match _return_to:
		GlobalConst.GameState.MAIN_MENU:
			GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
		GlobalConst.GameState.LEVEL_PICK:
			var scene := ResourceLoader.load(LEVEL_UI) as PackedScene
			var level_ui := scene.instantiate() as LevelUI
			get_tree().root.add_child.call_deferred(level_ui)
			GameManager.level_ui = level_ui
			GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			moves_left = GameManager.get_active_level().moves_left
			if !GameManager.level_manager.on_consume_move.is_connected(_consume_move):
				GameManager.level_manager.on_consume_move.connect(_consume_move)
			if !GameManager.level_manager.on_level_complete.is_connected(_on_level_complete):
				GameManager.level_manager.on_level_complete.connect(_on_level_complete)
			self.visible = true
		GlobalConst.GameState.LEVEL_END:
			self.visible = false		
		_:
			self.visible = false


func _on_level_complete() -> void:
	var scene := ResourceLoader.load(LEVEL_END) as PackedScene
	var level_end := scene.instantiate() as LevelEnd
	get_tree().root.add_child.call_deferred(level_end)
	GameManager.change_state(GlobalConst.GameState.LEVEL_END)


func initialize_ui(prev_state: GlobalConst.GameState):
	_return_to = prev_state
	match _return_to:
		GlobalConst.GameState.MAIN_MENU:
			exit_btn.text = tr("BACK")
		GlobalConst.GameState.LEVEL_PICK:
			exit_btn.text = tr("LEVELS")
	skip_btn.hide()
	if GameManager.is_level_completed():
		skip_btn.visible = GameManager.set_next_level()
	var tutorial: TutorialData = GameManager.get_tutorial()
	if tutorial != null:
		var scene := ResourceLoader.load(TUTORIAL) as PackedScene
		var tutorial_ui := scene.instantiate() as Tutorial
		get_tree().root.add_child(tutorial_ui)
		tutorial_ui.setup.call_deferred(tutorial)


func _consume_move() -> void:
	moves_left -= 1


func _on_reset_btn_pressed():
	AudioManager.play_click_sound()
	GameManager.level_manager.reset_level()


func _on_skip_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var level: LevelData
	level = GameManager.get_next_level()
	GameManager.level_manager.init_level.call_deferred(level)
