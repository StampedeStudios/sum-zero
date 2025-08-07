## Persists and fetch user's saved data.
class_name PlayerSave extends Resource

## Custom levels built and saved by the user.
@export var custom_levels_hash: Array[String]
## Progress on customs level.
@export var custom_progress: Dictionary[String, Vector3i]
## Progress of in-game levels.
@export var persistent_progress: Dictionary[String, Vector3i]
## Player preferences.
@export var player_options: PlayerOptions
## Player stats.
@export var player_rewards: RewardData

var _persistent: LevelContainer


## Checks game state to detect if any persisted information is obsolete.
##
## @param world Type of levels checked (classic or custom).
## @return `true` if the state changed, `false` otherwise.
func check_savegame_integrity(world: LevelContainer) -> bool:
	_persistent = world
	var has_changed := false

	# Initialize player rewards
	if !player_rewards:
		print("No rewards found, resetting")
		player_rewards = RewardData.new()
		has_changed = true

	# Check custom progress (remove extra progress)
	for level_hash: String in custom_progress.keys():
		if !custom_levels_hash.has(level_hash):
			custom_progress.erase(level_hash)
			has_changed = true

	# Check custom levels (add missing progress)
	for level_hash in custom_levels_hash:
		if !custom_progress.has(level_hash):
			_add_custom_progress(level_hash)
			has_changed = true

	# Check persistent progress (remove extra progress)
	for level_hash: String in persistent_progress.keys():
		if !persistent_progress.has(level_hash):
			persistent_progress.erase(level_hash)
			has_changed = true

	# Check persistent levels (add missing progress)
	for level_hash: String in _persistent.levels_hash:
		if !persistent_progress.has(level_hash):
			add_world_progress(level_hash)
			has_changed = true

	# Check stars count on persistent levels
	var stars_count: int = 0
	for level_hash: String in _persistent.levels_hash:
		if persistent_progress.has(level_hash):
			var progress: Vector3i = persistent_progress.get(level_hash)
			if progress.x == 1 and progress.y == 1:
				var star := clampi(progress.z, -3, 0) + 3
				stars_count += star

	if player_rewards.stars_count != stars_count:
		player_rewards.stars_count = stars_count
		has_changed = true

	return has_changed


## Initializes player options.
func init_player_settings() -> void:
	if player_options == null:
		print("No settings preferences found, resetting")
		player_options = PlayerOptions.new()

		# Select starting language
		var language: String = OS.get_locale_language()
		print("No language set, reading from OS: [%s]" % language)
		if Constants.AVAILABLE_LANGS.has(language):
			player_options.language = language
		else:
			push_warning("[%s] not supported, falling back to English" % language)


func get_level(level_id: int) -> LevelData:
	if level_id < custom_levels_hash.size():
		return Encoder.decode(custom_levels_hash[level_id])
	return null


func add_custom_level(level_data: LevelData) -> void:
	var level_hash := Encoder.encode(level_data)
	if custom_levels_hash.has(level_hash):
		var i := 1
		var copy_hash := level_hash + str(i)
		while custom_levels_hash.has(copy_hash):
			i += 1
			copy_hash = level_hash + str(i)
		level_hash = copy_hash
	custom_levels_hash.append(level_hash)
	_add_custom_progress(level_hash)


func _add_custom_progress(level_hash: String) -> void:
	var progress := Vector3i(1, 1, -1000)
	custom_progress[level_hash] = progress


func add_world_progress(level_hash: String) -> void:
	var progress := Vector3i(0, 0, -1000)
	persistent_progress[level_hash] = progress


func unlock_level(level_id: int) -> void:
	var level_hash := _persistent.levels_hash[level_id] as String
	var current_progress := persistent_progress.get(level_hash) as Vector3i
	if current_progress.x == 0:
		var progress := Vector3i(1, 0, -1000)
		persistent_progress[level_hash] = progress


func delete_custom_level(level_id: int) -> void:
	var level_hash := custom_levels_hash.pop_at(level_id) as String
	custom_progress.erase(level_hash)


func get_progress(group: Constants.LevelGroup, level_id: int) -> LevelProgress:
	var level_hash: String
	var progress: Vector3i
	var result := LevelProgress.new()
	match group:
		Constants.LevelGroup.MAIN:
			if !_persistent.levels_hash.size() > level_id:
				return null
			level_hash = _persistent.levels_hash[level_id]
			progress = persistent_progress.get(level_hash)
		Constants.LevelGroup.CUSTOM:
			if !custom_levels_hash.size() > level_id:
				return null
			level_hash = custom_levels_hash[level_id]
			progress = custom_progress.get(level_hash)
	result.is_unlocked = progress.x == 1
	result.is_completed = progress.y == 1
	result.move_left = progress.z
	result.name = Encoder.decode_name(level_hash)
	return result


func set_progress(group: Constants.LevelGroup, level_id: int, progress: LevelProgress) -> void:
	var level_hash: String
	var hash_progress := Vector3i(progress.is_unlocked, progress.is_completed, progress.move_left)
	match group:
		Constants.LevelGroup.MAIN:
			level_hash = _persistent.levels_hash[level_id]
			persistent_progress[level_hash] = hash_progress
		Constants.LevelGroup.CUSTOM:
			level_hash = custom_levels_hash[level_id]
			custom_progress[level_hash] = hash_progress


func add_star(extra_star: int) -> void:
	player_rewards.stars_count += extra_star


func update_blitz_score(new: int) -> bool:
	if new > player_rewards.blitz_score:
		player_rewards.blitz_score = new
		return true
	return false
