class_name Options extends Control

const TOGGLE_BUTTON_OFF_NORMAL = preload("res://assets/ui/toggle_button_off_normal.png")
const TOGGLE_BUTTON_ON_NORMAL = preload("res://assets/ui/toggle_button_on_normal.png")

@onready var music_btn: TextureButton = %MusicBtn
@onready var sfx_btn: TextureButton = %SfxBtn
@onready var tutorial_btn: TextureButton = %TutorialBtn

var _player_options: PlayerOptions


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	_player_options = GameManager.get_options()

	music_btn.set_pressed_no_signal(_player_options.music_on)
	sfx_btn.set_pressed_no_signal(_player_options.sfx_on)
	tutorial_btn.set_pressed_no_signal(_player_options.tutorial_on)
	_update_button_style(music_btn, _player_options.music_on)
	_update_button_style(sfx_btn, _player_options.sfx_on)
	_update_button_style(tutorial_btn, _player_options.tutorial_on)


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
	_update_button_style(music_btn, toggled_on)


func _on_sfx_btn_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_sfx()
	AudioManager.play_click_sound()
	_player_options.sfx_on = toggled_on
	_update_button_style(sfx_btn, toggled_on)


func _on_tutorial_btn_toggled(toggled_on: bool) -> void:
	AudioManager.play_click_sound()
	_player_options.tutorial_on = toggled_on
	_update_button_style(tutorial_btn, toggled_on)


func _update_button_style(toggled_button: TextureButton, toggled_on: bool) -> void:
	if toggled_on:
		toggled_button.texture_normal = TOGGLE_BUTTON_ON_NORMAL
		toggled_button.texture_hover = TOGGLE_BUTTON_ON_NORMAL
	else:
		toggled_button.texture_normal = TOGGLE_BUTTON_OFF_NORMAL
		toggled_button.texture_hover = TOGGLE_BUTTON_OFF_NORMAL


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)
