class_name SplashScreen extends Control

@onready var splash_top: AnimatedSprite2D = %SplashTop
@onready var splash_bottom: AnimatedSprite2D = %SplashBottom
@onready var version_label: Label = %VersionLabel
@onready var logo_host: Control = %LogoHost


func _ready() -> void:
	version_label.text = ProjectSettings.get("application/config/version")
	logo_host.layout_logo()

	await get_tree().create_timer(1).timeout
	for frame in range(17):
		splash_top.frame = frame
		AudioManager.play_slider_sound(0.3)

		await get_tree().create_timer(0.02).timeout

	await get_tree().create_timer(0.4).timeout
	for frame in range(17):
		splash_bottom.frame = frame
		AudioManager.play_slider_sound(0.3)

		await get_tree().create_timer(0.02).timeout

	await get_tree().create_timer(1.2).timeout

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished

	Engine.set_time_scale(1)

	GameManager.start()
	queue_free()


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		Engine.set_time_scale(5)
