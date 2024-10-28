extends Control

var _inserted_code: String

@onready var code: Button = %Code
@onready var level_name: LineEdit = %LevelName


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		self.queue_free()


func _on_save_btn_pressed() -> void:
	var level_data := Encoder.decode(_inserted_code)
	if level_data == null:
		pass
	GameManager.save_custom_level(level_name.text, level_data)


func _on_code_pressed() -> void:
	var cb_content := DisplayServer.clipboard_get()
	_inserted_code = cb_content.split("\n")[0]

	code.text = " " + _inserted_code


func _on_level_name_text_changed(new_text: String) -> void:
	var regex = RegEx.new()
	regex.compile("\\w+")

	var result := regex.search(new_text)
	if result:
		level_name.text = result.get_string()
		level_name.caret_column = level_name.text.length()
	else:
		level_name.text = ""
