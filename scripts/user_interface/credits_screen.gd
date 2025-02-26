class_name CreditsScreen extends Control

@onready var text: RichTextLabel = %RichTextLabel
@onready var margin: MarginContainer = %MarginContainer


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	await get_tree().create_timer(1).timeout
	start_credits_scroll()


func start_credits_scroll():
	var tween = create_tween()
	var scrollbar = text.get_v_scroll_bar()
	var max_scroll = scrollbar.max_value
	tween.tween_property(scrollbar, "value", max_scroll, 45.0).from(0)


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_git_hub_btn_pressed() -> void:
	OS.shell_open("https://github.com/StampedeStudios")


func _on_insta_btn_pressed() -> void:
	OS.shell_open("https://www.instagram.com/stampede_studios")


func _on_itch_btn_pressed() -> void:
	OS.shell_open("https://stampede-studios.itch.io/")


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
