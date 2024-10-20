class_name LevelInspect extends Control

signal level_unlocked

const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")
const TRASH_ICON = preload("res://assets/ui/trash_icon.png")
const UNLOCK_ICON = preload("res://assets/ui/unlock_icon.png")

var _level_name: String
var _is_custom: bool

@onready var label: Label = %LevelName
@onready var level_score_img: TextureRect = %LevelScoreImg
@onready var unlock_delete_btn: Button = %UnlockDeleteBtn
@onready var build_btn: Button = %BuildBtn
@onready var play_btn: Button = %PlayBtn


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func init_inspector(level_name: String, level_progress: LevelProgress, is_custom: bool):
	_level_name = level_name
	_is_custom = is_custom
	label.text = _level_name

	var percentage: float
	if level_progress.is_completed:
		percentage = 0.33 * (3 + level_progress.move_left)
	else:
		percentage = 0

	level_score_img.material.set_shader_parameter("percentage", percentage)
	build_btn.disabled = !level_progress.is_completed
	_update_buttons(level_progress.is_unlocked)

	unlock_delete_btn.icon = TRASH_ICON if _is_custom else UNLOCK_ICON


func _on_unlock_delete_btn_pressed() -> void:
	if _is_custom:
		# TODO: Handle deletion
		pass
	else:
		GameManager.unlock_level(GlobalConst.LevelGroup.MAIN, _level_name)
		_update_buttons(true)
		level_unlocked.emit()


func _on_build_btn_pressed() -> void:
	# TODO: load level in builder
	pass  # Replace with function body.


func _on_play_btn_pressed() -> void:
	var game_ui: GameUI
	game_ui = GAME_UI.instantiate()
	get_tree().root.add_child.call_deferred(game_ui)
	GameManager.game_ui = game_ui

	var level_manager: LevelManager
	level_manager = LEVEL_MANAGER.instantiate()
	get_tree().root.add_child.call_deferred(level_manager)
	level_manager.set_manager_mode.call_deferred(false)
	GameManager.level_manager = level_manager

	var group := GlobalConst.LevelGroup.CUSTOM if _is_custom else GlobalConst.LevelGroup.MAIN
	GameManager.set_levels_context(group)
	var level_data: LevelData = GameManager.get_active_level(_level_name)
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
		GameManager.change_state(GlobalConst.GameState.LEVEL_PICK)


func _update_buttons(is_unlocked: bool) -> void:
	unlock_delete_btn.disabled = is_unlocked if !_is_custom else false
	play_btn.disabled = !is_unlocked
