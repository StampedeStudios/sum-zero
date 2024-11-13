class_name Tutorial extends Control

@onready var animated_tutorial: Control = %AnimatedTutorial
@onready var animation: AnimatedSprite2D = %Animation
@onready var texture: TextureRect = %Texture
@onready var static_tutorial: Control = %StaticTutorial
@onready var label: Label = %Label


func setup(tutorial: TutorialData) -> void:
	label.text = tutorial.hint

	if tutorial.animation != null:
		animation.sprite_frames = tutorial.animation
		animated_tutorial.show()
		animated_tutorial.scale = GameManager.level_scale
		animation.play()

	if tutorial.image != null:
		static_tutorial.show()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		queue_free()
