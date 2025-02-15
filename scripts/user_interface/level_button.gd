class_name LevelButton extends Button

signal on_delete_level_button(ref: LevelButton)

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button_hover.tres")
const LEVEL_INSPECT = preload("res://packed_scene/user_interface/LevelInspect.tscn")
const CUSTOM_LEVEL_INSPECT = preload("res://packed_scene/user_interface/CustomLevelInspect.tscn")
const THEME = preload("res://assets/resources/themes/default.tres")

# Icons
const LOCK_ICON: CompressedTexture2D = preload("res://assets/ui/lock_icon.png")
const ZERO_STARS = preload("res://assets/ui/zero_stars.png")
const ONE_STAR = preload("res://assets/ui/one_star.png")
const TWO_STARS = preload("res://assets/ui/two_stars.png")
const THREE_STARS = preload("res://assets/ui/three_stars.png")

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
			if !GameManager.level_inspect:
				var inspect_instance = LEVEL_INSPECT.instantiate()
				get_tree().root.add_child(inspect_instance)
				GameManager.level_inspect = inspect_instance

			_toggle_connection.call_deferred(true)
			GameManager.level_inspect.init_inspector.call_deferred(_level_id, _progress)
			GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_INSPECT)

		GlobalConst.LevelGroup.CUSTOM:
			if !GameManager.custom_inspect:
				var inspect_instance = CUSTOM_LEVEL_INSPECT.instantiate()
				get_tree().root.add_child(inspect_instance)
				GameManager.custom_inspect = inspect_instance

			_toggle_connection.call_deferred(true)
			GameManager.custom_inspect.init_inspector.call_deferred(_level_id, _progress)
			GameManager.change_state.call_deferred(GlobalConst.GameState.CUSTOM_LEVEL_INSPECT)


func _get_minimum_size() -> Vector2:
	return Vector2(128, 128)


func construct(level_id: int, progress: LevelProgress, group: GlobalConst.LevelGroup) -> void:
	if !progress.is_unlocked:
		icon = LOCK_ICON
		add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)

		add_theme_color_override("icon_normal_color", BROWN)
		add_theme_color_override("icon_hover_color", BROWN)
		add_theme_color_override("icon_pressed_color", BROWN)
	else:
		remove_theme_constant_override("icon_max_width")

		remove_theme_color_override("icon_normal_color")
		remove_theme_color_override("icon_hover_color")
		remove_theme_color_override("icon_pressed_color")

		if progress.is_completed:
			var stars_amount := _count_stars(progress.move_left)
			icon = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS][stars_amount]
		else:
			icon = ZERO_STARS

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
	lab.theme = THEME
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

	icon = ZERO_STARS
	get_child(0).show()


func _delete_level_button() -> void:
	AudioManager.play_click_sound()
	on_delete_level_button.emit(self)
	self.queue_free.call_deferred()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.LEVEL_PICK:
			_toggle_connection.call_deferred(false)


func _toggle_connection(is_connect: bool) -> void:
	if is_connect:
		GameManager.on_state_change.connect(_on_state_change)
		match _level_group:
			GlobalConst.LevelGroup.MAIN:
				GameManager.level_inspect.level_unlocked.connect(_unlock_level)
			GlobalConst.LevelGroup.CUSTOM:
				GameManager.custom_inspect.level_deleted.connect(_delete_level_button)
	else:
		GameManager.on_state_change.disconnect(_on_state_change)
		match _level_group:
			GlobalConst.LevelGroup.MAIN:
				GameManager.level_inspect.level_unlocked.disconnect(_unlock_level)
			GlobalConst.LevelGroup.CUSTOM:
				GameManager.custom_inspect.level_deleted.disconnect(_delete_level_button)
