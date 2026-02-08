## UI for inspecting user-created or imported custom levels.
class_name CustomLevelInspect extends BaseLevelInspect

signal level_deleted

const PASTE_CHECK_ICON = "res://assets/ui/paste_check_icon.png"

var _level_code: String

@onready var delete_btn: Button = %DeleteBtn
@onready var copy_btn: Button = %CopyBtn


func _get_level_group() -> Constants.LevelGroup:
	return Constants.LevelGroup.CUSTOM


func _set_label_text(_lev_id: int, progress: LevelProgress) -> void:
	label.text = progress.name


## @param _progress The LevelProgress resource (not used in this implementation).
func _post_init(_progress: LevelProgress) -> void:
	GameManager.set_levels_context(Constants.LevelGroup.CUSTOM)
	var level_data: LevelData = GameManager.get_active_level(_level_id)
	_level_code = Encoder.encode(level_data)
	copy_btn.text = " " + _level_code


func _on_copy_btn_pressed() -> void:
	AudioManager.play_click_sound()
	DisplayServer.clipboard_set(_level_code)
	copy_btn.icon = ResourceLoader.load(PASTE_CHECK_ICON) as Texture2D
	copy_btn.add_theme_color_override("icon_normal_color", Color.WEB_GREEN)


func _on_delete_btn_pressed() -> void:
	AudioManager.play_click_sound()
	level_deleted.emit()
	close()
