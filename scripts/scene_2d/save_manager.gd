## Handles data persistence and provides a set of useful methods the retrieve saved data.
extends Node

const PERSISTENT_SAVE_PATH = "res://assets/resources/levels/persistent_levels.tres"
const PLAYER_SAVE_PATH = "user://sumzero.tres"

var _player_save: PlayerSave
var _persistent_save: LevelContainer


func _ready() -> void:
	if !_try_load_saved_data():
		get_tree().quit.call_deferred()

	_player_save.init_player_settings()


func get_tutorial() -> TutorialData:
	if !_player_save.player_options.tutorial_on:
		return null
	if GameManager.get_active_context() == Constants.LevelGroup.MAIN:
		return _persistent_save.get_tutorial(GameManager.get_active_level_id())
	return null


func get_num_levels(group: Constants.LevelGroup) -> int:
	match group:
		Constants.LevelGroup.CUSTOM:
			return _player_save.custom_levels_hash.size()
		Constants.LevelGroup.MAIN:
			return _persistent_save.levels_hash.size()
		_:
			return 0


func get_page_levels(group: Constants.LevelGroup, first: int, last: int) -> Array[LevelProgress]:
	var result: Array[LevelProgress]
	for id in range(first, last + 1):
		var progress := _player_save.get_progress(group, id)
		if progress != null:
			result.append(progress)
	return result


## Returns the first unlocked level yet to be completed.
##
## @return The most suited level to be played. If there is an unlocked level yet to be
## completed than it returns its id. Returns the first level otherwise.
func get_start_level_playable() -> int:
	GameManager.set_levels_context(Constants.LevelGroup.MAIN)
	for id in range(_persistent_save.levels_hash.size()):
		var progress := _player_save.get_progress(Constants.LevelGroup.MAIN, id)
		if progress.is_unlocked and !progress.is_completed:
			return id

	# If there is not suitable levels, returns the first playable level
	_player_save.unlock_level(0)
	return 0


## Returns the last completed level.
##
## @return The last completed level, useful to check real player progress.
func get_last_completed_level() -> int:
	GameManager.set_levels_context(Constants.LevelGroup.MAIN)
	var last_id := -1
	for id in range(_persistent_save.levels_hash.size()):
		var progress := _player_save.get_progress(Constants.LevelGroup.MAIN, id)
		if progress.is_completed and id > last_id:
			last_id = id

	return last_id


func update_level_progress(move_left: int) -> bool:
	var is_record: bool
	var context: Constants.LevelGroup = GameManager.get_active_context()
	var id: int = GameManager.get_active_level_id()
	var active_progress: LevelProgress = _player_save.get_progress(context, id)

	if !active_progress.is_completed:
		active_progress.is_completed = true
		if id < _persistent_save.levels_hash.size() - 1:
			_player_save.unlock_level(id + 1)

	if move_left > active_progress.move_left:
		var old_star := clampi(active_progress.move_left, -3, 0) + 3
		var new_star := clampi(move_left, -3, 0) + 3
		active_progress.move_left = move_left
		_player_save.add_star(new_star - old_star)
		is_record = true

	_player_save.set_progress(context, id, active_progress)
	save_player_data()
	return is_record


func save_custom_level(level_data: LevelData) -> void:
	_player_save.add_custom_level(level_data)
	save_player_data()


func get_star_count() -> int:
	return _player_save.player_rewards.stars_count


func get_level(world: Constants.LevelGroup, id: int) -> LevelData:
	match world:
		Constants.LevelGroup.CUSTOM:
			return _player_save.get_level(id)
		Constants.LevelGroup.MAIN:
			return _persistent_save.get_level(id)
	return null


func is_level_completed() -> bool:
	var context: Constants.LevelGroup = GameManager.get_active_context()
	var id: int = GameManager.get_active_level_id()
	return _player_save.get_progress(context, id).is_completed


func unlock_level(level_id: int) -> void:
	_player_save.unlock_level(level_id)
	save_player_data()


func delete_level(level_id: int) -> void:
	_player_save.delete_custom_level(level_id)
	save_player_data()


func get_options() -> PlayerOptions:
	return _player_save.player_options


func save_player_data() -> void:
	ResourceSaver.save.call_deferred(_player_save, PLAYER_SAVE_PATH)


func update_blitz_score(new: int) -> bool:
	if _player_save.update_blitz_score(new):
		save_player_data()
		return true
	return false


func _try_load_saved_data() -> bool:
	_persistent_save = load(PERSISTENT_SAVE_PATH) as LevelContainer
	if _persistent_save == null or _persistent_save.is_empty():
		push_error("No levels found on persisted data")
		return false
	if !FileAccess.file_exists(PLAYER_SAVE_PATH):
		push_warning("No data found on disk, generating fresh save game")
		_player_save = PlayerSave.new()
	else:
		_player_save = load(PLAYER_SAVE_PATH) as PlayerSave
	if _player_save == null:
		push_error("Saved data corrupted, impossible to read")
		_player_save = PlayerSave.new()

	var modified := _player_save.check_savegame_integrity(_persistent_save)

	if modified:
		save_player_data()
	return true
