class_name PlayModeUI extends MarginContainer

const LOCKED_MODE = "res://assets/ui/locked_mode.png"
const COMPLETED_MODE = "res://assets/ui/completed_mode.png"

var _is_locked := false

@onready var mode_texture: TextureRect = %ModeTexture
@onready var overlay_texture: TextureRect = %OverlayTexture
@onready var message: RichTextLabel = %OverlayMessage


func _ready() -> void:
	message.add_theme_font_size_override("normal_font_size", GameManager.small_text_font_size)
	message.add_theme_font_size_override("bold_font_size", GameManager.small_text_font_size)
	message.add_theme_font_size_override("italic_font_size", GameManager.small_text_font_size)


func setup(mode: PlayMode) -> void:
	mode_texture.texture = mode.icon

	match mode.unlock_mode:
		PlayMode.UnlockMode.NONE:
			pass
		PlayMode.UnlockMode.LEVEL:
			message.text = tr("LEVEL_LOCK_MSG") % mode.unlock_count
			_is_locked = GameManager.get_start_level_playable() < mode.unlock_count
		PlayMode.UnlockMode.STAR:
			message.text = tr("STAR_LOCK_MSG") % mode.unlock_count
			_is_locked = GameManager.get_star_count() < mode.unlock_count

	if _is_locked:
		overlay_texture.texture = load(LOCKED_MODE) as Texture2D
		overlay_texture.show()
	elif mode is StoryMode and GameManager.get_start_level_playable() > mode.id_end - 1:
		overlay_texture.texture = load(COMPLETED_MODE) as Texture2D
		message.text = tr("COMPLETED_MSG")
		overlay_texture.show()
	else:
		overlay_texture.hide()


func is_locked() -> bool:
	return _is_locked
