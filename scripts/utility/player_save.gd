class_name PlayerSave extends Resource

@export var custom_levels: LevelContainer
@export var custom_progress: Dictionary
@export var persistent_progress: Dictionary


func initialize_player_save(save: LevelContainer) -> void:
	# initialize custom level container on new savegame
	if custom_levels == null:
		custom_levels = LevelContainer.new()
	# create new progress for each persistent level
	for level_name in save.levels.keys():
		if !persistent_progress.has(level_name):
			persistent_progress[level_name] = LevelProgress.new()
	# create new progress for each custom level
	for level_name in custom_levels.levels.keys():
		if !custom_progress.has(level_name):
			var progress := LevelProgress.new()
			progress.is_unlocked = true
			progress.is_completed = true
			progress.move_left = -1000
			custom_progress[level_name] = progress
	# unlock first main level
	persistent_progress.get(save.get_level_by_index(0)).is_unlocked = true


func reset_progress(group: GlobalConst.LevelGroup, level_name: String) -> void:
	match group:
		GlobalConst.LevelGroup.MAIN:
			persistent_progress[level_name] = LevelProgress.new()
		GlobalConst.LevelGroup.CUSTOM:
			var progress := LevelProgress.new()
			progress.is_unlocked = true
			progress.is_completed = true
			progress.move_left = -1000
			custom_progress[level_name] = progress


func unlock_level(group: GlobalConst.LevelGroup, level_name: String) -> void:
	match group:
		GlobalConst.LevelGroup.MAIN:
			persistent_progress.get(level_name).is_unlocked = true
		GlobalConst.LevelGroup.CUSTOM:
			custom_progress.get(level_name).is_unlocked = true
