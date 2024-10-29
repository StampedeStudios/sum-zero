class_name MainMenu extends Control

const LEVEL_BUILDER = preload("res://packed_scene/scene_2d/LevelBuilder.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")
const BUILDER_UI = preload("res://packed_scene/user_interface/BuilderUI.tscn")
const GAME_UI = preload("res://packed_scene/user_interface/GameUI.tscn")
const LEVEL_UI = preload("res://packed_scene/user_interface/LevelUI.tscn")

# Icons
const SOUND_ON_ICON = preload("res://assets/ui/sound_on_icon.png")
const SOUND_OFF_ICON = preload("res://assets/ui/sound_off_icon.png")
const MUSIC_ON_ICON = preload("res://assets/ui/music_on_icon.png")
const MUSIC_OFF_ICON = preload("res://assets/ui/music_off_icon.png")

var _is_music_on: bool = true
var _is_sound_on: bool = true

@onready var music_btn: Button = %MusicBtn
@onready var sound_btn: Button = %SoundBtn


func _ready():
	GameManager.on_state_change.connect(_on_state_change)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.visible = true
		_:
			self.visible = false


func _on_play_btn_pressed():
	var level_data: LevelData = GameManager.get_start_level_playable()
	if level_data != null:
		var game_ui: GameUI
		game_ui = GAME_UI.instantiate()
		get_tree().root.add_child.call_deferred(game_ui)
		GameManager.game_ui = game_ui

		var level_manager: LevelManager
		level_manager = LEVEL_MANAGER.instantiate()
		get_tree().root.add_child.call_deferred(level_manager)
		level_manager.set_manager_mode.call_deferred(false)
		GameManager.level_manager = level_manager

		level_manager.init_level.call_deferred(level_data)


func _on_level_btn_pressed():
	var level_ui: LevelUI
	level_ui = LEVEL_UI.instantiate()
	get_tree().root.add_child.call_deferred(level_ui)

	GameManager.level_ui = level_ui
	GameManager.change_state.call_deferred(GlobalConst.GameState.LEVEL_PICK)


func _on_editor_btn_pressed():
	var builder_ui: BuilderUI
	builder_ui = BUILDER_UI.instantiate()
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	var level_builder: LevelBuilder
	level_builder = LEVEL_BUILDER.instantiate()
	get_tree().root.add_child.call_deferred(level_builder)
	level_builder.construct_level.call_deferred(LevelData.new())
	GameManager.level_builder = level_builder

	GameManager.change_state.call_deferred(GlobalConst.GameState.BUILDER_IDLE)


func _on_quit_btn_pressed():
	get_tree().quit()


func _on_music_btn_pressed() -> void:
	if _is_music_on:
		music_btn.icon = MUSIC_OFF_ICON
		AudioManager.toggle_music()
	else:
		music_btn.icon = MUSIC_ON_ICON
		AudioManager.toggle_music()

	_is_music_on = !_is_music_on


func _on_sound_btn_pressed() -> void:
	if _is_sound_on:
		sound_btn.icon = SOUND_OFF_ICON
		AudioManager.toggle_sfx()
	else:
		sound_btn.icon = SOUND_ON_ICON
		AudioManager.toggle_sfx()

	_is_sound_on = !_is_sound_on
