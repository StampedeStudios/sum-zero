extends Control

const BUTTON_ERROR = preload("res://assets/resources/themes/button_error.tres")
var _inserted_code: String

@onready var code: Button = %Code
@onready var level_name: LineEdit = %LevelName
@onready var save_btn: Button = %SaveBtn


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		self.queue_free()


func _on_save_btn_pressed() -> void:
	var level_data: LevelData = Encoder.decode(_inserted_code)
	if level_data == null:
		_show_error()
	else:
		GameManager.save_custom_level(level_name.text, level_data)
		GameManager.level_ui.add_imported_level(level_name.text)
		code.text = ""
		level_name.text = ""
		self.hide()


func _on_code_pressed() -> void:
	var cb_content := DisplayServer.clipboard_get()
	_inserted_code = cb_content.split("\n")[0]

	code.text = " " + _inserted_code
	_update_save_btn()


func _on_level_name_text_changed(new_text: String) -> void:
	var regex = RegEx.new()
	regex.compile("\\w+")

	var result := regex.search(new_text)
	if result:
		level_name.text = result.get_string()
		level_name.caret_column = level_name.text.length()
	else:
		level_name.text = ""

	_update_save_btn()


func _update_save_btn() -> void:
	if code.text == "" or level_name.text == "":
		save_btn.disabled = true
	else:
		save_btn.disabled = false


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.LEVEL_IMPORT:
			self.show()
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_IDLE:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			self.queue_free.call_deferred()
		_:
			self.hide()


func _show_error() -> void:
	save_btn.disabled = true
	code.add_theme_stylebox_override("normal", BUTTON_ERROR)
	code.add_theme_color_override("icon_normal_color", Color.DARK_RED)
	code.add_theme_color_override("font_color", Color.DARK_RED)

	await get_tree().create_timer(1).timeout
	code.remove_theme_stylebox_override("normal")
	code.remove_theme_color_override("icon_normal_color")
	code.remove_theme_color_override("font_color")
	code.text = ""
