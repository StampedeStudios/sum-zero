class_name CreditsScreen extends Control

@onready var text: RichTextLabel = %RichTextLabel
@onready var margin: MarginContainer = %MarginContainer


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	text.add_theme_font_size_override("normal_font_size", GameManager.small_text_font_size)
	text.add_theme_font_size_override("bold_font_size", GameManager.small_text_font_size)
	text.add_theme_font_size_override("italic_font_size", GameManager.small_text_font_size)

	await get_tree().create_timer(3).timeout
	start_credits_scroll()


func start_credits_scroll() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var scrollbar := text.get_v_scroll_bar()
	var max_scroll := scrollbar.max_value
	tween.tween_property(scrollbar, "value", max_scroll, 60.0).from(0)


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		GameManager.change_state(Constants.GameState.MAIN_MENU)
		queue_free.call_deferred()
