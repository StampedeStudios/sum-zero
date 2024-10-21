class_name PlaceholderButton extends Button

# Styles
const NORMAL_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button.tres")
const HOVER_STYLE: StyleBoxFlat = preload("res://assets/resources/themes/level_button_hover.tres")

# Icons
const BUILD_ICON: CompressedTexture2D = preload("res://assets/ui/editor_icon.png")
const PLACEHOLDER_ICON: CompressedTexture2D = preload("res://assets/ui/gear_icon.png")

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")

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
		var builder_ui: BuilderUI
		builder_ui = BUILDER_UI.instantiate()
		get_tree().root.add_child.call_deferred(builder_ui)
		GameManager.builder_ui = builder_ui

		var level_builder: LevelBuilder
		level_builder = LEVEL_BUILDER.instantiate()
		get_tree().root.add_child.call_deferred(level_builder)
		level_builder.construct_level.call_deferred(LevelData.new())
		GameManager.level_builder = level_builder

		GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func construct(is_custom: bool) -> void:
	_is_custom = is_custom
	icon = BUILD_ICON if _is_custom else PLACEHOLDER_ICON


func _get_minimum_size() -> Vector2:
	return Vector2(300, 300)
