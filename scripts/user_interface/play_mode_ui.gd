class_name PlayModeUI extends MarginContainer

const LOCKED_MODE = "res://assets/ui/locked_mode.png"
const COMPLETED_MODE = "res://assets/ui/completed_mode.png"

var _is_locked := false
var _is_completed := false

@onready var mode_texture: TextureRect = %ModeTexture
@onready var overlay_texture: TextureRect = %OverlayTexture
@onready var message: RichTextLabel = %OverlayMessage


func setup(mode: PlayMode, unlock_arena_modes_in_editor: bool = false) -> void:
	mode_texture.texture = mode.icon
	_is_completed = false
	message.text = ""

	match mode.unlock_mode:
		PlayMode.UnlockMode.NONE:
			# Modes with no unlock mode, are never locked but can be completed
			_is_completed = SaveManager.get_last_completed_level() >= mode.id_end - 1
			_is_locked = false
		PlayMode.UnlockMode.LEVEL:
			message.text = tr("LEVEL_LOCK_MSG")

			_is_completed = SaveManager.get_last_completed_level() >= (mode.id_end - 1)
			_is_locked = SaveManager.get_last_completed_level() + 1 < mode.id_start - 1

		PlayMode.UnlockMode.STAR:
			# Modes unlocked with stars are never completed
			var missing_stars: int = mode.unlock_count - SaveManager.get_star_count()
			message.text = tr("STAR_LOCK_MSG") % missing_stars
			_is_locked = SaveManager.get_star_count() < mode.unlock_count

	# The editor feature is absent from exported projects, including debug exports.
	if unlock_arena_modes_in_editor and OS.has_feature("editor") and mode is ArenaMode:
		_is_locked = false

	if _is_locked:
		overlay_texture.texture = load(LOCKED_MODE) as Texture2D
		overlay_texture.show()
	elif _is_completed:
		overlay_texture.texture = load(COMPLETED_MODE) as Texture2D
		message.text = tr("COMPLETED_MSG")
		overlay_texture.show()
	else:
		overlay_texture.hide()


func is_locked() -> bool:
	return _is_locked
