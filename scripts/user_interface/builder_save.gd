class_name BuilderSave extends Control

signal on_query_close(validation: bool, level_name: String, level_moves: int)

const MAX_MOVES_CHAR: int = 2
const MAX_NAME_CHAR: int = 10

var _invalid_name: bool
var _invalid_moves: bool

@onready var level_name = %LevelName
@onready var moves = %Moves
@onready var save_btn = %SaveBtn


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	_invalid_moves = true
	_invalid_name = true
	_check_valid_info()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = true
		_:
			self.visible = false


func _on_exit_btn_pressed():
	on_query_close.emit(false, "", -1)
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)


func _on_save_btn_pressed():
	on_query_close.emit(true, level_name.text, int(moves.text))
	GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)


func _on_moves_text_changed():
	var text: String = moves.text
	var filtered_text := ""

	for char_index in range(0, min(text.length(), MAX_MOVES_CHAR)):
		if text[char_index].is_valid_int():
			filtered_text += text[char_index]

	if filtered_text != text:
		text = filtered_text
		moves.text = text
		moves.set_caret_column(text.length())

	_invalid_moves = text.is_empty()
	_check_valid_info()


func _on_level_name_text_changed():
	var text: String = level_name.text
	var filtered_text: String
	var regex = RegEx.new()

	regex.compile("\\w+")
	var result := regex.search(text)
	if result:
		filtered_text = result.get_string().substr(0, min(text.length(), MAX_NAME_CHAR))
	else:
		filtered_text = ""

	if filtered_text != text:
		text = filtered_text
		level_name.text = text
		level_name.set_caret_column(text.length())

	_invalid_name = text.is_empty()
	_check_valid_info()


func _check_valid_info() -> void:
	save_btn.disabled = _invalid_moves or _invalid_name
