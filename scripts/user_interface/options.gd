class_name Options extends Control

const TOGGLE_BUTTON_OFF_NORMAL = preload("res://assets/ui/toggle_button_off_normal.png")
const TOGGLE_BUTTON_ON_NORMAL = preload("res://assets/ui/toggle_button_on_normal.png")
const PANEL = preload("res://assets/resources/themes/panel.tres")

var _player_options: PlayerOptions

@onready var panel: Panel = %Panel
@onready var music_btn: Button = %MusicBtn
@onready var sfx_btn: Button = %SfxBtn
@onready var tutorial_btn: Button = %TutorialBtn
@onready var options_btn: OptionButton = %OptionButton


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	_player_options = GameManager.get_options()

	music_btn.set_pressed_no_signal(_player_options.music_on)
	sfx_btn.set_pressed_no_signal(_player_options.sfx_on)
	tutorial_btn.set_pressed_no_signal(_player_options.tutorial_on)

	var index: int = GlobalConst.AVAILABLE_LANGS.find(_player_options.language)
	options_btn.selected = index

	panel.scale = GameManager.ui_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			GameManager.save_player_data()
			self.queue_free.call_deferred()
		GlobalConst.GameState.OPTION_MENU:
			self.visible = true
		_:
			self.visible = false


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


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
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _on_option_button_item_selected(index: int) -> void:
	var preferred_locale: String = GlobalConst.AVAILABLE_LANGS[index]
	_player_options.language = preferred_locale
	TranslationServer.set_locale(preferred_locale)
