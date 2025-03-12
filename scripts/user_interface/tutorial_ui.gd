class_name TutorialUi extends Control

signal on_tutorial_closed

const GAME_UI = "res://packed_scene/user_interface/GameUI.tscn"
const LEVEL_MANAGER = "res://packed_scene/scene_2d/LevelManager.tscn"

var _current_hint: int = 0
var _tips: Array[String] = []
var _images: Array[Texture2D]

@onready var hint: RichTextLabel = %Hint
@onready var label: Label = %Label
@onready var sprite: TextureRect = %TextureRect
@onready var playBtn: Button = %NextBtn


func _ready() -> void:
	hint.add_theme_font_size_override("normal_font_size", GameManager.small_text_font_size)
	hint.add_theme_font_size_override("bold_font_size", GameManager.small_text_font_size)
	hint.add_theme_font_size_override("italic_font_size", GameManager.small_text_font_size)


func setup(data: TutorialData) -> void:
	_tips = data.hints
	_images = data.images

	if _images.size():
		sprite.texture = _images[0]
	else:
		sprite.texture = null

	if _tips.size() > 0:
		hint.text = _tips[0]

	if _tips.size() <= 1:
		label.hide()
		playBtn.text = tr("PLAY")
	else:
		playBtn.text = tr("NEXT")
		label.text = "[Tip %d of %d]" % [1, _tips.size()]


func _on_next_btn_pressed() -> void:
	_current_hint += 1

	# Continue if there are more tips
	if _current_hint < _tips.size():
		hint.text = _tips[_current_hint]
		label.text = "[Tip %d of %d]" % [_current_hint + 1, _tips.size()]

		# Change image if there are any
		if _images.size() > _current_hint:
			sprite.texture = _images[_current_hint]

		if _current_hint == _tips.size() - 1:
			playBtn.text = tr("PLAY")
		print(_current_hint)

	else:
		on_tutorial_closed.emit()
		queue_free()
