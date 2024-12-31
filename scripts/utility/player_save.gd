class_name PlayerSave extends Resource

@export var custom_levels: LevelContainer
@export var custom_progress: Array[LevelProgress]
@export var persistent_progress: Array[LevelProgress]
@export var player_options: PlayerOptions


func check_savegame_integrity(world: LevelContainer) -> bool:
	var has_change := false
	# initialize player options
	if player_options == null:
		print("opzioni non trovate e resettate")
		player_options = PlayerOptions.new()
		has_change = true
	# initialize custom level container on new savegame
	if custom_levels == null:
		print("livelli custom non trovati e resettati")
		custom_levels = LevelContainer.new()
		custom_progress.clear()
		has_change = true
	for id in range(world.levels.size()):
		var level_name := world.levels[id].name
		if id < persistent_progress.size():
			if level_name != persistent_progress[id].name:
				var progress := LevelProgress.new()
				progress.name = level_name
				persistent_progress[id] = progress
				has_change = true
		else:
			var progress := LevelProgress.new()
			progress.name = level_name
			if id == 0:
				progress.is_unlocked = true
			persistent_progress.append(progress)
			has_change = true
	return has_change
		


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
