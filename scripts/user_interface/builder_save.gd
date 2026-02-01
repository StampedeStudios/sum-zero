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
@onready var panel: AnimatedPanel = %Panel


func init_info(old_name: String, old_moves: String, is_valid: bool) -> void:
	if old_name != "":
		level_name.text = old_name
	if old_moves != "":
		moves.text = old_moves
	level_name.caret_column = old_name.length()
	moves.caret_column = old_moves.length()
	_invalid_moves = moves.text.is_empty()
	_invalid_name = level_name.text.is_empty()
	_invalid_level = !is_valid
	_check_valid_info()
	await panel.open()


func close() -> void:
	panel.close()
	GameManager.change_state(Constants.GameState.BUILDER_IDLE)
	self.queue_free.call_deferred()


func _on_save_btn_pressed() -> void:
	AudioManager.play_click_sound()
	on_query_close.emit(level_name.text, int(moves.text))
	level_name.text = ""
	level_name.caret_column = 0
	moves.text = ""
	moves.caret_column = 0
	close()


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
	var regex := RegEx.new()
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
		close()
