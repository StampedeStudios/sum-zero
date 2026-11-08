class_name LevelButtonBase extends Button

# Icons
const ADD_ICON = "res://assets/ui/add_icon.png"
const PLACEHOLDER_ICON = "res://assets/ui/gear_icon.png"
const LOCK_ICON = "res://assets/ui/lock_icon.png"
const ZERO_STARS = "res://assets/ui/zero_stars.png"
const ONE_STAR = "res://assets/ui/one_star.png"
const TWO_STARS = "res://assets/ui/two_stars.png"
const THREE_STARS = "res://assets/ui/three_stars.png"
const EXTRA_STARS = "res://assets/ui/three_stars.png"


func construct(id := -1, is_locked := true, stars := 0) -> void:
	if is_locked:
		disabled = true
		icon = load(LOCK_ICON)

		text = ""
		theme_type_variation = &"LevelTileLocked"

	else:
		disabled = false

		theme_type_variation = &"LevelTile"
		var icon_path: String = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS, EXTRA_STARS][stars]

		icon = load(icon_path)
		text = str(id + 1)


func construct_empty() -> void:
	disabled = false
	text = ""
	icon = load(ADD_ICON)

	theme_type_variation = &"LevelTileEmpty"


func _pressed() -> void:
	if GameManager.level_ui.has_consumed_input:
		return
	AudioManager.play_click_sound()
