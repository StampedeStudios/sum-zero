class_name CustomLevelInspect extends Control

signal level_deleted

const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_BUILDER = "res://packed_scene/scene_2d/LevelBuilder.tscn"
const BUILDER_UI = "res://packed_scene/user_interface/BuilderUI.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"
const PASTE_CHECK_ICON = "res://assets/ui/paste_check_icon.png"
const STARS_SPRITE_SIZE := Vector2(350, 239)

var _level_id: int
var _level_code: String

@onready var label: Label = %LevelName
@onready var stars: Sprite2D = %Stars
@onready var delete_btn: Button = %DeleteBtn
@onready var build_btn: Button = %BuildBtn
@onready var play_btn: Button = %PlayBtn
@onready var copy_btn: Button = %CopyBtn
@onready var panel: Panel = %Panel


func _ready() -> void:
	create_tween().tween_method(animate, Vector2.ZERO, GameManager.ui_scale, 0.2)


func close() -> void:
	await create_tween().tween_method(animate, GameManager.ui_scale, Vector2.ZERO, 0.2).finished
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


func animate(animated_scale: Vector2) -> void:
	panel.scale = animated_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


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
	var scene := ResourceLoader.load(BUILDER_UI) as PackedScene
	var builder_ui := scene.instantiate() as BuilderUI
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	scene = ResourceLoader.load(LEVEL_BUILDER) as PackedScene
	var level_builder := scene.instantiate() as LevelBuilder
	get_tree().root.add_child.call_deferred(level_builder)
	GameManager.level_builder = level_builder

	GameManager.set_levels_context(GlobalConst.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_builder.construct_level.call_deferred(level_data.duplicate(), true)

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)
	self.queue_free.call_deferred()


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(GAME_UI) as PackedScene
	var game_ui := scene.instantiate() as GameUI
	get_tree().root.add_child.call_deferred(game_ui)		
	game_ui.initialize_ui.call_deferred(GlobalConst.GameState.LEVEL_PICK)
	GameManager.game_ui = game_ui

	scene = ResourceLoader.load(LEVEL_MANAGER) as PackedScene
	var level_manager := scene.instantiate() as LevelManager
	get_tree().root.add_child.call_deferred(level_manager)
	level_manager.set_manager_mode.call_deferred(false)
	GameManager.level_manager = level_manager

	GameManager.set_levels_context(GlobalConst.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_manager.init_level.call_deferred(level_data)
	self.queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		close()


func _on_copy_btn_pressed() -> void:
	AudioManager.play_click_sound()
	DisplayServer.clipboard_set(_level_code)
	copy_btn.icon = ResourceLoader.load(PASTE_CHECK_ICON) as Texture2D
	copy_btn.add_theme_color_override("icon_normal_color", Color.WEB_GREEN)


func _on_delete_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.delete_level(_level_id)
	level_deleted.emit()
	close()


func _on_exit_btn_pressed() -> void:
	close()
