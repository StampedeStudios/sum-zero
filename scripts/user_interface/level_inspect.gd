class_name LevelInspect extends Control

signal level_unlocked

const LEVEL_BUILDER = "res://packed_scene/scene_2d/LevelBuilder.tscn"
const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const BUILDER_UI = "res://packed_scene/user_interface/BuilderUI.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"

var _level_id: int

@onready var label: Label = %LevelName
@onready var unlock_btn: Button = %UnlockBtn
@onready var build_btn: Button = %BuildBtn
@onready var play_btn: Button = %PlayBtn
@onready var panel: AnimatedPanel = %Panel
@onready var left_star: TextureRect = %LeftStar
@onready var right_star: TextureRect = %RightStar
@onready var middle_star: TextureRect = %MiddleStar


func _ready() -> void:
	right_star.scale = Vector2(0, 0)
	left_star.scale = Vector2(0, 0)
	middle_star.scale = Vector2(0, 0)

	await panel.open()


func init_inspector(level_id: int, progress: LevelProgress) -> void:
	label.text = str("%03d" % [level_id + 1])
	_level_id = level_id

	var num_stars: int
	if !progress.is_completed:
		num_stars = 0
	else:
		num_stars = Constants.MAX_STARS_GAIN + progress.move_left
		if num_stars < 0:
			num_stars = 0
		# extra reward for beating the developers (you think ...)
		elif num_stars > 3:
			num_stars = 4
		update_stars(num_stars)


	build_btn.disabled = !progress.is_completed
	_update_buttons(progress.is_unlocked)


func update_stars(star_count: int) -> void:

	if star_count >= 1:
		left_star.scale = Vector2(0.7, 0.7)

	if star_count >= 2:
		middle_star.scale = Vector2(0.8, 0.8)

	if star_count == 3:
		right_star.scale = Vector2(0.7, 0.7)


func _on_build_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var builder_ui: BuilderUI
	var scene := ResourceLoader.load(BUILDER_UI) as PackedScene
	builder_ui = scene.instantiate() as BuilderUI
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	scene = ResourceLoader.load(LEVEL_BUILDER) as PackedScene
	var level_builder := scene.instantiate() as LevelBuilder
	get_tree().root.add_child.call_deferred(level_builder)
	GameManager.level_builder = level_builder

	GameManager.set_levels_context(Constants.LevelGroup.MAIN)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_builder.construct_level.call_deferred(level_data.duplicate(), true)

	GameManager.change_state.call_deferred(Constants.GameState.BUILDER_IDLE)
	self.queue_free.call_deferred()


func _on_play_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(LEVEL_MANAGER) as PackedScene
	var level_manager := scene.instantiate() as LevelManager
	get_tree().root.add_child(level_manager)
	GameManager.level_manager = level_manager

	GameManager.set_levels_context(Constants.LevelGroup.MAIN)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_manager.init_level(level_data)

	scene = ResourceLoader.load(GAME_UI) as PackedScene
	var game_ui := scene.instantiate() as GameUI
	get_tree().root.add_child(game_ui)
	game_ui.initialize_ui(Constants.GameState.LEVEL_PICK)
	GameManager.change_state(Constants.GameState.LEVEL_START)
	GameManager.game_ui = game_ui

	self.queue_free.call_deferred()


func close() -> void:
	await panel.close()
	GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		close()


func _update_buttons(is_unlocked: bool) -> void:
	unlock_btn.disabled = is_unlocked
	play_btn.disabled = !is_unlocked


func _on_unlock_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_update_buttons(true)
	level_unlocked.emit()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	close()
