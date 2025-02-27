class_name Tutorial extends Control

@onready var animated_tutorial: Control = %AnimatedTutorial
@onready var animation: AnimatedSprite2D = %Animation
@onready var texture: TextureRect = %Texture
@onready var static_tutorial: Control = %StaticTutorial
@onready var animation_text: RichTextLabel = %AnimationText
@onready var static_text: Label = %StaticText


func _ready() -> void:
	var offset := Vector2(0, GameManager.CENTER_OFFSET)
	animated_tutorial.position = animated_tutorial.position - offset


func setup(tutorial: TutorialData) -> void:
	if tutorial.animation != null:
		animation.sprite_frames = tutorial.animation
		animation_text.text = tutorial.hint
		animated_tutorial.scale = GameManager.level_scale

		animated_tutorial.show()
		animation.play()
	else:
		animated_tutorial.hide()

	static_text.text = tutorial.hint
	if tutorial.image != null:
		static_text.text = tutorial.hint
		static_tutorial.show()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		queue_free.call_deferred()
