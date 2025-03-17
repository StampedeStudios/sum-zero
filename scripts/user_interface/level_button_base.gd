class_name LevelButtonBase extends Button

# Icons
const IMPORT_ICON = "res://assets/ui/import_icon.png"
const PLACEHOLDER_ICON = "res://assets/ui/gear_icon.png"
const LOCK_ICON = "res://assets/ui/lock_icon.png"
const ZERO_STARS = "res://assets/ui/zero_stars.png"
const ONE_STAR = "res://assets/ui/one_star.png"
const TWO_STARS = "res://assets/ui/two_stars.png"
const THREE_STARS = "res://assets/ui/three_stars.png"
const EXTRA_STARS = "res://assets/ui/three_stars.png"


func costruct(world: GlobalConst.LevelGroup, id := -1, is_locked := true, stars := 0) -> void:
	if id < 0:
		match world:
			GlobalConst.LevelGroup.MAIN:
				icon = load(PLACEHOLDER_ICON)
			GlobalConst.LevelGroup.CUSTOM:
				icon = load(IMPORT_ICON)
		if has_theme_color_override("icon_normal_color"):
			remove_theme_color_override("icon_normal_color")
			remove_theme_color_override("icon_hover_color")
			remove_theme_color_override("icon_pressed_color")
		text = ""
		return

	if is_locked:
		icon = load(LOCK_ICON)
		if has_theme_color_override("icon_normal_color"):
			remove_theme_color_override("icon_normal_color")
			remove_theme_color_override("icon_hover_color")
			remove_theme_color_override("icon_pressed_color")
		text = ""
		return

	if !has_theme_color_override("icon_normal_color"):
		add_theme_color_override("icon_normal_color", Color.WHITE)
		add_theme_color_override("icon_hover_color", Color.WHITE)
		add_theme_color_override("icon_pressed_color", Color.WHITE)
	var icon_path: String
	icon_path = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS, EXTRA_STARS][stars]
	icon = load(icon_path)
	text = str(id + 1)


func _pressed() -> void:
	if GameManager.level_ui.has_consume_input:
		return
	AudioManager.play_click_sound()
