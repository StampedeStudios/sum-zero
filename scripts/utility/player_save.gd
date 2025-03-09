class_name PlayerSave extends Resource

@export var custom_levels_hash: Array[String]
@export var custom_progress: Dictionary
@export var persistent_progress: Dictionary
@export var player_options: PlayerOptions
@export var player_rewards: RewardData

var _persistent: LevelContainer


func check_savegame_integrity(world: LevelContainer) -> bool:
	_persistent = world
	var has_change := false
	
	# initialize player rewards
	if !player_rewards:
		print("No rewards found, resetting")
		player_rewards = RewardData.new()
		has_change = true
		
	# initialize player options
	if player_options == null:
		print("No settings preferences found, resetting")
		player_options = PlayerOptions.new()
		has_change = true

		# Select starting language
		var language: String = OS.get_locale_language()
		print("No language set, reading from OS: [%s]" % language)
		if GlobalConst.AVAILABLE_LANGS.has(language):
			player_options.language = language
		else:
			print("[%s] not supported, falling back to English" % language)

	# check custom progress (remove extra progress)
	for level_hash: String in custom_progress.keys():
		if !custom_levels_hash.has(level_hash):
			custom_progress.erase(level_hash)
			has_change = true

	# check custom levels (add missing progress)
	for level_hash in custom_levels_hash:
		if !custom_progress.has(level_hash):
			_add_custom_progress(level_hash)
			has_change = true

	# check persistent progress (remove extra progress)
	for level_hash: String in persistent_progress.keys():
		if !persistent_progress.has(level_hash):
			persistent_progress.erase(level_hash)
			has_change = true

	# check persistent levels (add missing progress)
	for level_hash: String in _persistent.levels_hash:
		if !persistent_progress.has(level_hash):
			add_world_progress(level_hash)
			has_change = true
			
	# check stars count on persistent levels
	var stars_count: int = 0
	for level_hash: String in _persistent.levels_hash:
		if persistent_progress.has(level_hash):
			var progress: Vector3i = persistent_progress.get(level_hash)
			if progress.x == 1 and progress.y == 1:
				var star := clampi(progress.z, -3, 0) + 3
				stars_count += star
	if player_rewards.stars_count != stars_count:
		player_rewards.stars_count = stars_count
		has_change = true
		
	return has_change


func get_level(level_id: int) -> LevelData:
	if level_id < custom_levels_hash.size():
		return Encoder.decode(custom_levels_hash[level_id])
	return null


func add_custom_level(level_data: LevelData) -> void:
	var level_hash := Encoder.encode(level_data)
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


func get_progress(group: GlobalConst.LevelGroup, level_id: int) -> LevelProgress:
	var level_hash: String
	var progress: Vector3i
	var result := LevelProgress.new()
	match group:
		GlobalConst.LevelGroup.MAIN:
			if !_persistent.levels_hash.size() > level_id:
				return null
			level_hash = _persistent.levels_hash[level_id]
			progress = persistent_progress.get(level_hash)
		GlobalConst.LevelGroup.CUSTOM:
			if !custom_levels_hash.size() > level_id:
				return null
			level_hash = custom_levels_hash[level_id]
			progress = custom_progress.get(level_hash)
	result.is_unlocked = progress.x == 1
	result.is_completed = progress.y == 1
	result.move_left = progress.z
	result.name = Encoder.decode_name(level_hash)
	return result


func set_progress(group: GlobalConst.LevelGroup, level_id: int, progress: LevelProgress) -> void:
	var level_hash: String
	var hash_progress := Vector3i(progress.is_unlocked, progress.is_completed, progress.move_left)
	match group:
		GlobalConst.LevelGroup.MAIN:
			level_hash = _persistent.levels_hash[level_id]
			persistent_progress[level_hash] = hash_progress
		GlobalConst.LevelGroup.CUSTOM:
			level_hash = custom_levels_hash[level_id]
			custom_progress[level_hash] = hash_progress


func add_star(extra_star: int) -> void:
	print(extra_star)
	player_rewards.stars_count += extra_star
