## UI for inspecting main story/campaign levels.
class_name LevelInspect extends BaseLevelInspect


## @param progress The LevelProgress resource containing completion data.
func _post_init(progress: LevelProgress) -> void:
	build_btn.disabled = !progress.is_completed
	_update_buttons(progress.is_unlocked)


## @param is_unlocked Whether the play button should be enabled.
func _update_buttons(is_unlocked: bool) -> void:
	play_btn.disabled = !is_unlocked
