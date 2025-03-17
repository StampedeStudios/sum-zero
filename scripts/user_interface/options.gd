class_name Options extends Control

const CREDITS = "res://packed_scene/user_interface/CreditsScreen.tscn"
var _player_options: PlayerOptions

@onready var panel: AnimatedPanel = %Panel
@onready var music_btn: Button = %MusicBtn
@onready var sfx_btn: Button = %SfxBtn
@onready var tutorial_btn: Button = %TutorialBtn
@onready var options_btn: OptionButton = %OptionButton


func _ready() -> void:
	_player_options = SaveManager.get_options()

	music_btn.set_pressed_no_signal(_player_options.music_on)
	sfx_btn.set_pressed_no_signal(_player_options.sfx_on)
	tutorial_btn.set_pressed_no_signal(_player_options.tutorial_on)

	var index: int = GlobalConst.AVAILABLE_LANGS.find(_player_options.language)
	options_btn.selected = index

	await panel.open()


func _exit_options() -> void:
	SaveManager.save_player_data()
	await panel.close()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
	queue_free.call_deferred()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		_exit_options()


func _on_music_btn_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_music()
	_player_options.music_on = toggled_on


func _on_sfx_btn_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_sfx()
	AudioManager.play_click_sound()
	_player_options.sfx_on = toggled_on


func _on_tutorial_btn_toggled(toggled_on: bool) -> void:
	AudioManager.play_click_sound()
	_player_options.tutorial_on = toggled_on


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_exit_options()


func _on_option_button_item_selected(index: int) -> void:
	var preferred_locale: String = GlobalConst.AVAILABLE_LANGS[index]
	_player_options.language = preferred_locale
	TranslationServer.set_locale(preferred_locale)


func _on_link_button_pressed() -> void:
	var credits_scene := ResourceLoader.load(CREDITS) as PackedScene
	var credits := credits_scene.instantiate()
	get_tree().root.add_child.call_deferred(credits)
	queue_free.call_deferred()
