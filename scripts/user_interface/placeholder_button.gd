class_name PlaceholderButton extends Button

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button_hover.tres")

# Icons
const IMPORT_ICON: CompressedTexture2D = preload("res://assets/ui/import_icon.png")
const PLACEHOLDER_ICON: CompressedTexture2D = preload("res://assets/ui/gear_level_icon.png")

const LEVEL_IMPORT = preload("res://packed_scene/user_interface/LevelImport.tscn")

var _is_custom: bool


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
	if _is_custom:
		var level_import := LEVEL_IMPORT.instantiate()
		get_tree().root.add_child(level_import)


func construct(is_custom: bool) -> void:
	_is_custom = is_custom
	icon = IMPORT_ICON if _is_custom else PLACEHOLDER_ICON


func _get_minimum_size() -> Vector2:
	return Vector2(300, 300)
