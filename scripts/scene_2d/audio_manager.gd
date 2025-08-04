## Handles all sound effects and its options.
##
## Has three distinct audio player:
## - An audio player always plays the background music if enabled.
## - An audio player is strictly dedicated to play sliders sound effects and can overlap other SFX.
## - A third audio player handles all other — less important — sound effects.
extends Node2D

var _is_music_on: bool = true
var _is_sfx_on: bool = true
var _music_playback_position: float

@onready var music_player: AudioStreamPlayer2D = $MusicPlayer
@onready var button_plyer: AudioStreamPlayer2D = $ButtonPlayer
@onready var slider_player: AudioStreamPlayer2D = $SliderPlayer


func _ready() -> void:
	var options := SaveManager.get_options()
	_is_music_on = options.music_on
	_is_sfx_on = options.sfx_on


func start_music() -> void:
	if _is_music_on:
		music_player.play()


func toggle_music() -> void:
	if _is_music_on:
		_music_playback_position = music_player.get_playback_position()
		music_player.stop()
	else:
		music_player.play(_music_playback_position)

	_is_music_on = !_is_music_on


func toggle_sfx() -> void:
	_is_sfx_on = !_is_sfx_on


func play_click_sound() -> void:
	if _is_sfx_on:
		button_plyer.play()


## Slider's sounds are based on a single sound whose pitch increases as they reach their full length.
##
## @param percentage Value in range 0-1 that indicates the percentage of extension.
func play_slider_sound(percentage: float) -> void:
	if _is_sfx_on:
		slider_player.pitch_scale = percentage
		slider_player.play()


func is_music_on() -> bool:
	return _is_music_on


func is_sfx_on() -> bool:
	return _is_sfx_on
