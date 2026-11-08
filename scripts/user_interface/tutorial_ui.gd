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
@onready var hint_options: HBoxContainer = %HintOptions
@onready var show_hints: CheckBox = %ShowHints


func setup(data: TutorialData) -> void:
	_current_hint = 0
	_hide_next_time = false
	show_hints.set_pressed_no_signal(false)
	hint.scroll_to_line(0)
	_tips = data.hints
	_images = data.images
	_name = data.tutorial_name
	hint_options.visible = data.is_skippable

	if _images.size():
		sprite.texture = _images[0]
	else:
		sprite.texture = null
	sprite.visible = sprite.texture != null

	hint.text = _tips[0] if not _tips.is_empty() else ""
	label.visible = _tips.size() > 1

	if _tips.size() <= 1:
		label.hide()
		play_btn.text = tr("PLAY")
	else:
		play_btn.text = tr("NEXT")
		label.text = tr("TIP_OF") % [1, _tips.size()]
	get_node("%Content").refresh.call_deferred()


func _on_next_btn_pressed() -> void:
	_current_hint += 1

	# Continue if there are more tips
	if _current_hint < _tips.size():
		hint.scroll_to_line(0)
		hint.text = _tips[_current_hint]
		label.text = tr("TIP_OF") % [_current_hint + 1, _tips.size()]

		# Change image if there are any
		if _images.size() > _current_hint:
			sprite.texture = _images[_current_hint]
		sprite.visible = sprite.texture != null

		if _current_hint == _tips.size() - 1:
			play_btn.text = tr("PLAY")
		get_node("%Content").refresh.call_deferred()

	else:
		on_tutorial_closed.emit()
		if _hide_next_time:
			SaveManager.get_options().disable_hint(_name)
			SaveManager.save_player_data()

		queue_free()


func _on_show_hints_toggled(toggled_on: bool) -> void:
	_hide_next_time = toggled_on
