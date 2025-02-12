class_name LevelInspect extends Control

signal level_unlocked

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")
const STARS_SPRITE_SIZE := Vector2(350, 239)

var _level_id: int

@onready var label: Label = %LevelName
@onready var stars: Sprite2D = %Stars
@onready var unlock_btn: Button = %UnlockBtn
@onready var build_btn: Button = %BuildBtn
@onready var play_btn: Button = %PlayBtn
@onready var panel: Panel = %Panel


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)

	panel.scale = GameManager.ui_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func init_inspector(level_id: int, progress: LevelProgress):
	label.text = str("%03d" % [level_id + 1])
	_level_id = level_id

	var num_stars = clamp(
		GlobalConst.MAX_STARS_GAIN + progress.move_left, 0, GlobalConst.MAX_STARS_GAIN
	)
	if !progress.is_completed:
		num_stars = 0

	var frame_per_star = 5

	stars.region_rect = Rect2(
		Vector2(frame_per_star * STARS_SPRITE_SIZE.x * num_stars, 0), STARS_SPRITE_SIZE
	)

	build_btn.disabled = !progress.is_completed
	_update_buttons(progress.is_unlocked)


func _on_build_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var builder_ui: BuilderUI
	builder_ui = BUILDER_UI.instantiate()
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	var level_builder: LevelBuilder
	level_builder = LEVEL_BUILDER.instantiate()
	get_tree().root.add_child.call_deferred(level_builder)
	GameManager.level_builder = level_builder

	GameManager.set_levels_context(GlobalConst.LevelGroup.MAIN)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_builder.construct_level.call_deferred(level_data.duplicate(), true)

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var game_ui: GameUI
	game_ui = GAME_UI.instantiate()
	get_tree().root.add_child.call_deferred(game_ui)
	GameManager.game_ui = game_ui

	var level_manager: LevelManager
	level_manager = LEVEL_MANAGER.instantiate()
	get_tree().root.add_child.call_deferred(level_manager)
	level_manager.set_manager_mode.call_deferred(false)
	GameManager.level_manager = level_manager

	GameManager.set_levels_context(GlobalConst.LevelGroup.MAIN)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_manager.init_level.call_deferred(level_data)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.LEVEL_INSPECT:
			self.show()
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_IDLE:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			self.queue_free.call_deferred()
		_:
			self.hide()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)


func _update_buttons(is_unlocked: bool) -> void:
	unlock_btn.disabled = is_unlocked
	play_btn.disabled = !is_unlocked


func _on_unlock_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.unlock_level(_level_id)
	_update_buttons(true)
	level_unlocked.emit()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)
