class_name BuilderUI extends Control

signal reset_builder_level

const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_TEST = preload("res://packed_scene/user_interface/BuilderTest.tscn")

@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var buttons: HBoxContainer = %BottomContainer
@onready var top_buttons: HBoxContainer = %HBoxContainer


func _ready():
	if OS.has_feature("debug"):
		top_buttons.show()
	else:
		top_buttons.hide()

	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	for button in top_buttons.get_children():
		button.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	buttons.add_theme_constant_override("separation", GameManager.btns_separation)
	GameManager.on_state_change.connect(_on_state_change)


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


func _on_generate_hole_pressed() -> void:
	GameManager.level_builder.generate_level(GlobalConst.GenerationElement.HOLE)


func _on_generate_block_pressed() -> void:
	GameManager.level_builder.generate_level(GlobalConst.GenerationElement.BLOCK)


func _on_generate_slider_pressed() -> void:
	GameManager.level_builder.generate_level(GlobalConst.GenerationElement.SLIDER)
