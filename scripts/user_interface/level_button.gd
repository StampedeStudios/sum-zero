class_name LevelButton extends Button

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/LevelButton.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/LevelButtonHover.tres")
const LEVEL_INSPECT = preload("res://packed_scene/user_interface/LevelInspect.tscn")

# Icons
const LOCK_ICON: CompressedTexture2D = preload("res://assets/ui/lock_icon.png")
const PLAY_ICON: CompressedTexture2D = preload("res://assets/ui/play_icon.png")
const ZERO_STARS = preload("res://assets/ui/zero_stars.png")
const ONE_STAR = preload("res://assets/ui/one_star.png")
const TWO_STARS = preload("res://assets/ui/two_stars.png")
const THREE_STARS = preload("res://assets/ui/three_stars.png")

var _level_name: String
var _progress: LevelProgress
var _is_custom: bool


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func _draw():
	# Set size flags to allow expansion inside containers
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FocusMode.FOCUS_NONE


func _init() -> void:
	add_theme_stylebox_override("normal", NORMAL_STYLE)
	add_theme_stylebox_override("hover", HOVER_STYLE)
	add_theme_stylebox_override("pressed", HOVER_STYLE)
	icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER


func _pressed() -> void:
	if !GameManager.level_inspect:
		var inspect_instance = LEVEL_INSPECT.instantiate()
		get_tree().root.add_child(inspect_instance)
		GameManager.level_inspect = inspect_instance

	GameManager.level_inspect.level_unlocked.connect(_unlock_level)
	GameManager.level_inspect.init_inspector(_level_name, _progress, _is_custom)
	GameManager.change_state(GlobalConst.GameState.LEVEL_INSPECT)


func _get_minimum_size() -> Vector2:
	return Vector2(300, 300)


func construct(level_name: String, progress: LevelProgress, is_custom: bool) -> void:
	if !progress.is_unlocked:
		icon = LOCK_ICON
	elif progress.is_completed:
		var stars_amount := _count_stars(progress.move_left)
		icon = [ZERO_STARS, ONE_STAR, TWO_STARS, THREE_STARS][stars_amount]
	else:
		icon = PLAY_ICON

	_level_name = level_name
	_progress = progress
	_is_custom = is_custom


func _count_stars(moves_left: int) -> int:
	# Less than -2 moves is equal to 0 stars. Zero or more moves are equivalent to 3 stars
	return clamp(moves_left, -3, 0) + GlobalConst.MAX_STARS_GAIN


func _unlock_level() -> void:
	icon = PLAY_ICON


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.LEVEL_PICK:
			if GameManager.level_inspect != null:
				if GameManager.level_inspect.level_unlocked.is_connected(_unlock_level):
					GameManager.level_inspect.level_unlocked.disconnect(_unlock_level)