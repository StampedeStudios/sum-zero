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
const FONT = "res://assets/ui/fonts/FiraMono-Bold.ttf"


func construct(id := -1, is_locked := true, stars := 0) -> void:

	if is_locked:
		disabled = true
		icon = load(LOCK_ICON)

		text = ""
		add_theme_color_override("icon_normal_color", Color(0.251, 0.184, 0.106, 1.0))
		add_theme_color_override("icon_hover_color", Color(0.251, 0.184, 0.106, 1.0))
		add_theme_color_override("icon_pressed_color", Color(0.251, 0.184, 0.106, 1.0))

	else:
		disabled = false

		add_theme_color_override("icon_normal_color", Color.WHITE)
		add_theme_color_override("icon_hover_color", Color.WHITE)
		add_theme_color_override("icon_pressed_color", Color.WHITE)

		var font := ResourceLoader.load(FONT) as Font
		var icon_path: String = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS, EXTRA_STARS][stars]

		icon = load(icon_path)
		text = str(id + 1)

		self.add_theme_font_size_override("font_size", GameManager.text_font_size)
		self.add_theme_font_override("font", font)


func construct_empty() -> void:
	text = ""
	icon = load(ADD_ICON)

	add_theme_color_override("icon_normal_color", Color(0.251, 0.184, 0.106, 1.0))
	add_theme_color_override("icon_hover_color", Color(0.251, 0.184, 0.106, 1.0))
	add_theme_color_override("icon_pressed_color", Color(0.251, 0.184, 0.106, 1.0))


func _pressed() -> void:
	if GameManager.level_ui.has_consumed_input:
		return
	AudioManager.play_click_sound()
