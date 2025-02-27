class_name LevelButton extends Button

signal on_delete_level_button(ref: LevelButton)

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button_hover.tres")
const THEME = "res://assets/resources/themes/default.tres"

# Icons
const LOCK_ICON = "res://assets/ui/lock_icon.png"
const ZERO_STARS = "res://assets/ui/zero_stars.png"
const ONE_STAR = "res://assets/ui/one_star.png"
const TWO_STARS = "res://assets/ui/two_stars.png"
const THREE_STARS = "res://assets/ui/three_stars.png"

const LEVEL_INSPECT = "res://packed_scene/user_interface/LevelInspect.tscn"
const CUSTOM_LEVEL_INSPECT = "res://packed_scene/user_interface/CustomLevelInspect.tscn"
const BROWN: Color = Color8(64, 47, 27)

var _level_id: int
var _progress: LevelProgress
var _level_group: GlobalConst.LevelGroup


func _draw():
	# Set size flags to allow expansion inside containers
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FocusMode.FOCUS_NONE
	mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS


func _init() -> void:
	add_theme_stylebox_override("normal", NORMAL_STYLE)
	add_theme_stylebox_override("hover", HOVER_STYLE)
	add_theme_stylebox_override("pressed", HOVER_STYLE)
	icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER

	expand_icon = true


func _pressed() -> void:
	if GameManager.level_ui.has_consume_input:
		return
	AudioManager.play_click_sound()
	match _level_group:
		GlobalConst.LevelGroup.MAIN:
			var scene := ResourceLoader.load(LEVEL_INSPECT) as PackedScene
			var inspect_instance = scene.instantiate() as LevelInspect
			inspect_instance.level_unlocked.connect(_unlock_level)
			get_tree().root.add_child(inspect_instance)
			inspect_instance.init_inspector.call_deferred(_level_id, _progress)
			GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_INSPECT)

		GlobalConst.LevelGroup.CUSTOM:
			var scene := ResourceLoader.load(CUSTOM_LEVEL_INSPECT) as PackedScene
			var inspect_instance = scene.instantiate() as CustomLevelInspect
			inspect_instance.level_deleted.connect(_delete_level_button)
			get_tree().root.add_child(inspect_instance)
			inspect_instance.init_inspector.call_deferred(_level_id, _progress)
			GameManager.change_state.call_deferred(GlobalConst.GameState.CUSTOM_LEVEL_INSPECT)


func _get_minimum_size() -> Vector2:
	return Vector2(128, 128)


func construct(level_id: int, progress: LevelProgress, group: GlobalConst.LevelGroup) -> void:
	if !progress.is_unlocked:
		icon = ResourceLoader.load(LOCK_ICON) as Texture2D
		add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)

		add_theme_color_override("icon_normal_color", BROWN)
		add_theme_color_override("icon_hover_color", BROWN)
		add_theme_color_override("icon_pressed_color", BROWN)
	else:
		remove_theme_constant_override("icon_max_width")

		remove_theme_color_override("icon_normal_color")
		remove_theme_color_override("icon_hover_color")
		remove_theme_color_override("icon_pressed_color")

		var icon_path: String
		if progress.is_completed:
			var stars_amount := _count_stars(progress.move_left)
			icon_path = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS][stars_amount]
		else:
			icon_path = ZERO_STARS
		icon = ResourceLoader.load(icon_path) as Texture2D
	_level_id = level_id
	_progress = progress
	_level_group = group
	if get_child_count() > 0:
		get_child(0).text = str(level_id + 1)
	else:
		add_child(_create_label(level_id + 1))
	get_child(0).visible = progress.is_unlocked


func _create_label(index: int) -> Label:
	var lab: Label = Label.new()
	lab.text = str(index)

	lab.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	lab.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	lab.theme = ResourceLoader.load(THEME) as Theme
	lab.add_theme_font_size_override("font_size", GameManager.text_font_size)

	lab.set_anchors_preset(PRESET_FULL_RECT)
	return lab


func _count_stars(moves_left: int) -> int:
	# Less than -2 moves is equal to 0 stars. Zero or more moves are equivalent to 3 stars
	return clamp(moves_left, -3, 0) + GlobalConst.MAX_STARS_GAIN


func _unlock_level() -> void:
	remove_theme_color_override("icon_normal_color")
	remove_theme_color_override("icon_hover_color")
	remove_theme_color_override("icon_pressed_color")
	remove_theme_constant_override("icon_max_width")

	icon = ResourceLoader.load(ZERO_STARS) as Texture2D
	get_child(0).show()


func _delete_level_button() -> void:
	AudioManager.play_click_sound()
	on_delete_level_button.emit()
