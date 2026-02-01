class_name SplashScreen extends Control

@onready var splash_top: AnimatedSprite2D = %SplashTop
@onready var splash_bottom: AnimatedSprite2D = %SplashBottom
@onready var version_label: Label = %VersionLabel
@onready var margin: MarginContainer = %MarginContainer


func _ready() -> void:
	version_label.text = ProjectSettings.get("application/config/version")
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	version_label.add_theme_font_size_override("font_size", GameManager.text_font_size)

	var new_scale: Vector2 = GameManager.ui_scale * 0.7
	var x: float = get_viewport_rect().size.x
	var y: float = get_viewport_rect().size.y

	splash_top.scale = new_scale
	splash_top.position = Vector2(x / 2, y / 2 - (175 / 2.0 * new_scale.x))

	splash_bottom.scale = new_scale
	splash_bottom.position = Vector2(x / 2, y / 2 + (175 / 2.0 * new_scale.x))

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

	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished

	Engine.set_time_scale(1)

	GameManager.start()
	queue_free()


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		Engine.set_time_scale(5)
