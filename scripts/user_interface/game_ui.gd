class_name GameUI extends Control

signal reset_level

const TUTORIAL = preload("res://packed_scene/user_interface/Tutorial.tscn")

var moves_left: int

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

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)
	container.add_theme_constant_override("separation", GameManager.btns_separation)


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			_initialize_ui()
			self.visible = true
		GlobalConst.GameState.LEVEL_END:
			self.visible = false
			GameManager.level_end.update_score(moves_left)
		_:
			self.visible = false


func _initialize_ui():
	moves_left = GameManager.get_active_level().moves_left

	skip_btn.hide()
	if GameManager.is_level_completed():
		_has_next_level = GameManager.set_next_level()
		if _has_next_level:
			skip_btn.show()
	var tutorial: TutorialData = GameManager.get_tutorial()
	if tutorial != null:
		var tutorial_ui: Tutorial = TUTORIAL.instantiate()
		get_tree().root.add_child(tutorial_ui)
		tutorial_ui.setup.call_deferred(tutorial)


func consume_move() -> void:
	moves_left -= 1


func _on_reset_btn_pressed():
	AudioManager.play_click_sound()
	_initialize_ui()
	reset_level.emit()


func _on_skip_btn_pressed() -> void:
	AudioManager.play_click_sound()
	if !_has_next_level:
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	else:
		var level: LevelData
		level = GameManager.get_next_level()
		GameManager.level_manager.init_level.call_deferred(level)
