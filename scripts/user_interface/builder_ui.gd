class_name BuilderUI extends Control

signal reset_builder_level

const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_TEST = preload("res://packed_scene/user_interface/BuilderTest.tscn")

@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var buttons: HBoxContainer = %BottomContainer


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	# Update margin percentage
	var screen_size = get_viewport_rect().size
	var vertical_margin: int = screen_size.y * GlobalConst.Y_MARGIN_PERCENTAGE
	var horizontal_margin: int = screen_size.x * GlobalConst.X_MARGIN_PERCENTAGE

	margin.add_theme_constant_override("margin_left", horizontal_margin)
	margin.add_theme_constant_override("margin_right", horizontal_margin)
	margin.add_theme_constant_override("margin_top", vertical_margin)
	margin.add_theme_constant_override("margin_bottom", vertical_margin)

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	for child in buttons.get_children():
		child.add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)

	buttons.add_theme_constant_override("separation", GameManager.btns_separation)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = true
		_:
			self.visible = false


func _on_reset_btn_pressed():
	AudioManager.play_click_sound()
	reset_builder_level.emit()


func _on_resize_btn_pressed():
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.BUILDER_RESIZE)


func _on_play_btn_pressed():
	AudioManager.play_click_sound()
	if !GameManager.builder_test:
		var builder_test: BuilderTest
		builder_test = BUILDER_TEST.instantiate()
		GameManager.builder_test = builder_test
		get_tree().root.add_child.call_deferred(builder_test)
	if GameManager.level_manager == null:
		var level_test = LEVEL_MANAGER.instantiate()
		get_tree().root.add_child.call_deferred(level_test)
		level_test.set_manager_mode.call_deferred(true)
		GameManager.level_manager = level_test

	GameManager.level_manager.init_level.call_deferred(GameManager.level_builder.get_level_data())
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_START)


func _on_save_btn_pressed():
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.BUILDER_SAVE)


func _on_exit_btn_pressed():
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
