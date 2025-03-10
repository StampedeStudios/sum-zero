class_name PlaceholderButton extends Button

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button_hover.tres")

# Icons
const IMPORT_ICON = "res://assets/ui/import_icon.png"
const PLACEHOLDER_ICON = "res://assets/ui/gear_icon.png"

const BROWN: Color = Color8(64, 47, 27)
const LEVEL_IMPORT = "res://packed_scene/user_interface/LevelImport.tscn"

var _is_custom: bool


func _draw() -> void:
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
	mouse_filter = Control.MouseFilter.MOUSE_FILTER_PASS
	expand_icon = true


func _pressed() -> void:
	AudioManager.play_click_sound()
	if _is_custom:
		var scene := ResourceLoader.load(LEVEL_IMPORT) as PackedScene
		var level_import := scene.instantiate() as LevelImport
		get_tree().root.add_child(level_import)


func construct(is_custom: bool) -> void:
	_is_custom = is_custom
	var icon_path := IMPORT_ICON if _is_custom else PLACEHOLDER_ICON
	icon = ResourceLoader.load(icon_path) as Texture2D
	add_theme_color_override("icon_normal_color", BROWN)
	add_theme_color_override("icon_hover_color", BROWN)
	add_theme_color_override("icon_pressed_color", BROWN)


func _get_minimum_size() -> Vector2:
	return Vector2(300, 300)
