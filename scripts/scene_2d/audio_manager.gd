extends Node2D

var _is_music_on: bool = true
var _is_sfx_on: bool = true
var _music_playback_position: float

@onready var music_player: AudioStreamPlayer2D = %MusicPlayer
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer


func toggle_music() -> void:
	if _is_music_on:
		_music_playback_position = music_player.get_playback_position()
		music_player.stop()
	else:
		music_player.play(_music_playback_position)

	_is_music_on = !_is_music_on


func toggle_sfx() -> void:
	if _is_sfx_on:
		print("Sfx OFF")
	else:
		print("Sfx ON")

	_is_sfx_on = !_is_sfx_on
