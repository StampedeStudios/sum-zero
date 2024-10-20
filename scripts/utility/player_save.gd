class_name PlayerSave extends Resource

@export var custom_levels: Dictionary
@export var custom_progress: Dictionary
@export var persistent_progress: Dictionary


func initialize_persistent_progress(save: PersistentSave) -> void:
	for name in save.levels.keys():
		if !persistent_progress.has(name):
			persistent_progress[name] = LevelProgress.new()
	if !persistent_progress.is_empty():
		persistent_progress.values()[0].is_unlocked = true


func reset_custom_progress(level_name: String) -> void:
	var progress := LevelProgress.new()
	progress.is_unlocked = true
	progress.is_completed = true
	progress.move_left = -100
	custom_progress[level_name] = progress


func reset_persistent_progress(level_name: String) -> void:
	persistent_progress[level_name] = LevelProgress.new()
