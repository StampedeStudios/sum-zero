class_name PlayerSave extends Resource

@export var custom_levels: LevelContainer
@export var custom_progress: Array[LevelProgress]
@export var persistent_progress: Array[LevelProgress]
@export var player_options: PlayerOptions


func initialize_player_save(save: LevelContainer) -> void:
	# initialize player options
	if player_options == null:
		player_options = PlayerOptions.new()
	# initialize custom level container on new savegame
	if custom_levels == null:
		custom_levels = LevelContainer.new()
	# create new progress for each persistent level
	for id in range(persistent_progress.size(), save.levels.size()):
		var progress := LevelProgress.new()
		progress.name = save.levels[id].name
		persistent_progress.append(progress)
	# unlock first main level
	if save.levels.size() > 0:
		persistent_progress[0].is_unlocked = true


func add_progress(group: GlobalConst.LevelGroup, level_name: String) -> void:
	var progress := LevelProgress.new()
	progress.name = level_name
	match group:
		GlobalConst.LevelGroup.MAIN:
			persistent_progress.append(progress)
		GlobalConst.LevelGroup.CUSTOM:
			progress.is_unlocked = true
			progress.is_completed = true
			progress.move_left = -1000
			custom_progress.append(progress)


func unlock_level(group: GlobalConst.LevelGroup, level_id: int) -> void:
	match group:
		GlobalConst.LevelGroup.MAIN:
			persistent_progress[level_id].is_unlocked = true
		GlobalConst.LevelGroup.CUSTOM:
			custom_progress[level_id].is_unlocked = true


func delete_level(level_id: int) -> void:
	custom_progress.remove_at(level_id)
	custom_levels.levels.remove_at(level_id)
