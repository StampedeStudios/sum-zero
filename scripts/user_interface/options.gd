class_name Options extends Control

const CREDITS = "res://packed_scene/user_interface/CreditsScreen.tscn"
var _player_options: PlayerOptions

@onready var music_btn: Button = %MusicBtn
@onready var sfx_btn: Button = %SfxBtn
@onready var tutorial_btn: Button = %TutorialBtn
@onready var options_btn: OptionButton = %OptionButton
@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var tutorial_label: Label = %TutorialLabel
@onready var link_button: LinkButton = %LinkButton


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	# Override font size to all option labels
	music_label.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	sfx_label.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	tutorial_label.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	link_button.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	options_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)

	var font_size := GameManager.small_text_font_size
	options_btn.get_popup().add_theme_font_size_override("font_size", font_size)

	_player_options = SaveManager.get_options()
	GameManager.on_state_change.connect(_on_state_change)

	music_btn.set_pressed_no_signal(_player_options.music_on)
	sfx_btn.set_pressed_no_signal(_player_options.sfx_on)
	tutorial_btn.set_pressed_no_signal(_player_options.tutorial_on)

	var index: int = Constants.AVAILABLE_LANGS.find(_player_options.language)
	options_btn.selected = index


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.OPTIONS_MENU:
			self.visible = true
		_:
			self.visible = false


func _exit_options() -> void:
	GameManager.change_state(Constants.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_exit_options()


func _on_music_btn_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_music()
	_player_options.music_on = toggled_on
	SaveManager.save_player_data()


func _on_sfx_btn_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_sfx()
	AudioManager.play_click_sound()
	_player_options.sfx_on = toggled_on
	SaveManager.save_player_data()


func _on_tutorial_btn_toggled(toggled_on: bool) -> void:
	AudioManager.play_click_sound()
	_player_options.set_tutorial_visibility(toggled_on)
	SaveManager.save_player_data()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_exit_options()


func _on_option_button_item_selected(index: int) -> void:
	var preferred_locale: String = Constants.AVAILABLE_LANGS[index]
	_player_options.language = preferred_locale
	print("[Options] Select '%s' as preferred language" % preferred_locale)
	TranslationServer.set_locale(preferred_locale)
	SaveManager.save_player_data()


func _on_link_button_pressed() -> void:
	var credits_scene := ResourceLoader.load(CREDITS) as PackedScene
	var credits := credits_scene.instantiate()
	get_tree().root.add_child.call_deferred(credits)
	queue_free.call_deferred()
