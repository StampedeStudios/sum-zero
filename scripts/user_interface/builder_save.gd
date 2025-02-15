class_name BuilderSave extends Control

signal on_query_close(level_name: String, level_moves: int)

const MAX_MOVES_CHAR: int = 2
const MAX_NAME_CHAR: int = 10

var _invalid_name: bool
var _invalid_moves: bool
var _invalid_level: bool

@onready var level_name: LineEdit = %LevelName
@onready var moves: LineEdit = %Moves
@onready var save_btn: Button = %SaveBtn
@onready var panel: Panel = %Panel


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	_invalid_moves = true
	_invalid_name = true
	_check_valid_info()

	panel.scale = GameManager.ui_scale
	panel.position = Vector2(get_viewport().size) / 2 - (panel.scale * panel.size / 2)


func init_info(old_name: String, old_moves: String, invalid_level: bool) -> void:
	if old_name != "":
		level_name.text = old_name
	if old_moves != "":
		moves.text = old_moves
	level_name.caret_column = old_name.length()
	moves.caret_column = old_moves.length()
	_invalid_moves = moves.text.is_empty()
	_invalid_name = level_name.text.is_empty()
	_invalid_level = invalid_level
	_check_valid_info()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = true
		_:
			self.visible = false


func _on_save_btn_pressed():
	AudioManager.play_click_sound()
	on_query_close.emit(level_name.text, int(moves.text))
	level_name.text = ""
	level_name.caret_column = 0
	moves.text = ""
	moves.caret_column = 0
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)


func _on_moves_text_changed(new_text: String) -> void:
	var filtered_text := ""

	for character in new_text:
		if character.is_valid_int():
			filtered_text += character

	if filtered_text != new_text:
		new_text = filtered_text
		moves.text = new_text
		moves.set_caret_column(new_text.length())

	_invalid_moves = new_text.is_empty()
	_check_valid_info()


func _check_valid_info() -> void:
	save_btn.disabled = _invalid_moves or _invalid_name or _invalid_level


func _on_level_name_text_changed(new_text: String) -> void:
	var regex = RegEx.new()
	regex.compile("\\w+")

	var result := regex.search(new_text)
	if result:
		level_name.text = result.get_string()
		level_name.caret_column = level_name.text.length()
	else:
		level_name.text = ""

	_invalid_name = new_text.is_empty()
	_check_valid_info()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)
