class_name TutorialUi extends Control

signal on_tutorial_closed

const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"

var _current_hint: int = 0
var _tips: Array[String] = []
var _images: Array[Texture2D]
var _name: String
var _hide_next_time: bool

@onready var hint: RichTextLabel = %Hint
@onready var label: Label = %Label
@onready var hint_label: Label = %HintLabel
@onready var sprite: TextureRect = %TextureRect
@onready var play_btn: Button = %NextBtn
@onready var margin: MarginContainer = %MarginContainer
@onready var hint_options: HBoxContainer = %HintOptions
@onready var show_hints: CheckBox = %ShowHints


func _ready() -> void:
	hint.add_theme_font_size_override("normal_font_size", GameManager.small_text_font_size)
	hint.add_theme_font_size_override("bold_font_size", GameManager.small_text_font_size)
	hint.add_theme_font_size_override("italic_font_size", GameManager.small_text_font_size)
	show_hints.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	label.add_theme_font_size_override("font_size", GameManager.text_font_size)
	hint_label.add_theme_font_size_override("font_size", GameManager.text_font_size)
	play_btn.add_theme_font_size_override("font_size", GameManager.title_font_size)

	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)


func setup(data: TutorialData) -> void:
	_tips = data.hints
	_images = data.images
	_name = data.tutorial_name
	hint_options.visible = data.is_skippable

	if _images.size():
		sprite.texture = _images[0]
	else:
		sprite.texture = null

	if _tips.size() > 0:
		hint.text = _tips[0]

	if _tips.size() <= 1:
		label.hide()
		play_btn.text = tr("PLAY")
	else:
		play_btn.text = tr("NEXT")
		label.text = tr("TIP_OF") % [1, _tips.size()]


func _on_next_btn_pressed() -> void:
	_current_hint += 1

	# Continue if there are more tips
	if _current_hint < _tips.size():
		hint.text = _tips[_current_hint]
		label.text = tr("TIP_OF") % [_current_hint + 1, _tips.size()]

		# Change image if there are any
		if _images.size() > _current_hint:
			sprite.texture = _images[_current_hint]

		if _current_hint == _tips.size() - 1:
			play_btn.text = tr("PLAY")

	else:
		on_tutorial_closed.emit()
		if _hide_next_time:
			SaveManager.get_options().disable_hint(_name)
			SaveManager.save_player_data()

		queue_free()


func _on_show_hints_toggled(toggled_on: bool) -> void:
	_hide_next_time = toggled_on
