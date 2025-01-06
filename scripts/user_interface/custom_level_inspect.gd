class_name CustomLevelInspect extends Control

signal level_deleted

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")
const PASTE_CHECK_ICON = preload("res://assets/ui/paste_check_icon.png")
const STARS_SPRITE_SIZE := Vector2(350, 239)

var _level_id: int
var _level_code: String

@onready var label: Label = %LevelName
@onready var stars: Sprite2D = %Stars
@onready var delete_btn: Button = %DeleteBtn
@onready var build_btn: Button = %BuildBtn
@onready var play_btn: Button = %PlayBtn
@onready var copy_btn: Button = %CopyBtn


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func init_inspector(level_id: int, progress: LevelProgress):
	label.text = progress.name
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

	GameManager.set_levels_context(GlobalConst.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	_level_code = Encoder.encode(level_data)
	copy_btn.text = " " + _level_code


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

	GameManager.set_levels_context(GlobalConst.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_builder.construct_level.call_deferred(level_data.duplicate())

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

	GameManager.set_levels_context(GlobalConst.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_manager.init_level.call_deferred(level_data)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.CUSTOM_LEVEL_INSPECT:
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
		copy_btn.remove_theme_color_override("icon_normal_color")
		GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)


func _on_copy_btn_pressed() -> void:
	AudioManager.play_click_sound()
	DisplayServer.clipboard_set(_level_code)
	copy_btn.icon = PASTE_CHECK_ICON
	copy_btn.add_theme_color_override("icon_normal_color", Color.WEB_GREEN)


func _on_delete_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.delete_level(_level_id)
	level_deleted.emit()
	GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)


func _on_exit_btn_pressed() -> void:
	copy_btn.remove_theme_color_override("icon_normal_color")
	GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)
