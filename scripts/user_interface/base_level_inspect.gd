## Base class for level inspection UI.
##
## Provides shared logic for displaying level details, star ratings,
## and handling transitions to the game or builder.
class_name BaseLevelInspect extends Control

const LEVEL_BUILDER = "res://packed_scene/scene_2d/LevelBuilder.tscn"
const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const BUILDER_UI = "res://packed_scene/user_interface/BuilderUI.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"

var _level_id: int

@onready var label: Label = %LevelName
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


## Closes the inspector and returns to the level pick state.
func close() -> void:
	panel.close()
	GameManager.change_state.call_deferred(Constants.GameState.LEVEL_PICK)
	self.queue_free.call_deferred()


## Initializes the inspector with level data and progress.
## @param level_id The unique identifier of the level.
## @param progress The LevelProgress resource containing completion data.
func init_inspector(level_id: int, progress: LevelProgress) -> void:
	_level_id = level_id
	_set_label_text(level_id, progress)

	var num_stars: int
	if !progress.is_completed:
		num_stars = 0
	else:
		num_stars = Constants.MAX_STARS_GAIN + progress.move_left
		if num_stars < 0:
			num_stars = 0
		# Finishing a level with less moves than required happens only for very few
		# levels and currently has no benefit other than showing a different message
		elif num_stars > 3:
			num_stars = 4

		update_stars(num_stars)

	_post_init(progress)


## Updates the star UI based on the count.
## @param star_count The number of stars to display.
func update_stars(star_count: int) -> void:
	if star_count >= 1:
		left_star.scale = Vector2(0.7, 0.7)

	if star_count >= 2:
		middle_star.scale = Vector2(0.8, 0.8)

	if star_count >= 3:
		right_star.scale = Vector2(0.7, 0.7)


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

	GameManager.set_levels_context(_get_level_group())
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

	GameManager.set_levels_context(_get_level_group())
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	level_manager.init_level(level_data)

	scene = ResourceLoader.load(GAME_UI) as PackedScene
	var game_ui := scene.instantiate() as GameUI
	get_tree().root.add_child(game_ui)
	game_ui.initialize_ui(Constants.GameState.LEVEL_PICK)
	GameManager.change_state(Constants.GameState.LEVEL_START)
	GameManager.game_ui = game_ui

	self.queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		close()


## Returns the level group context for this inspector.
func _get_level_group() -> Constants.LevelGroup:
	return Constants.LevelGroup.MAIN


## Sets the level name/label text.
## @param level_id The identifier used to format the label.
## @param _progress The LevelProgress resource (optional context).
func _set_label_text(level_id: int, _progress: LevelProgress) -> void:
	label.text = str("%03d" % [level_id + 1])


## Hook for additional initialization in subclasses.
## @param _progress The LevelProgress resource containing completion data.
func _post_init(_progress: LevelProgress) -> void:
	pass
