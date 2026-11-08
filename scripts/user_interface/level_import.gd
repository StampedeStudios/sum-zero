class_name LevelImport extends Control

signal level_imported

const BUTTON_ERROR = preload("res://assets/resources/themes/button_error.tres")
const BUTTON_NORMAL = preload("res://assets/resources/themes/copy_button.tres")

var _error_timer: Timer

@onready var paste: Button = %Paste
@onready var level_name: LineEdit = %LevelName
@onready var save_btn: Button = %SaveBtn
@onready var panel: AnimatedPanel = %Panel
@onready var code: LineEdit = %Code


func _ready() -> void:
	_error_timer = Timer.new()
	_error_timer.one_shot = true
	_error_timer.wait_time = 1.0
	_error_timer.timeout.connect(_clear_error)
	add_child(_error_timer)
	panel.open()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		AudioManager.play_click_sound()
		close()


func _on_save_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var level_data: LevelData = Encoder.decode(code.text)
	if level_data == null:
		_show_error()
	else:
		level_data.name = level_name.text
		SaveManager.save_custom_level(level_data)
		level_imported.emit()
		close()


func _on_code_pressed() -> void:
	AudioManager.play_click_sound()
	var cb_content := DisplayServer.clipboard_get()
	_on_code_text_changed(cb_content.split("\n")[0].strip_edges())


func _on_level_name_text_changed(new_text: String) -> void:
	var regex := RegEx.new()
	regex.compile("\\w+")

	var result := regex.search(new_text)
	if result:
		level_name.text = result.get_string()
		level_name.caret_column = level_name.text.length()
	else:
		level_name.text = ""
	_update_save_btn()


func _on_code_text_changed(new_text: String) -> void:
	if not _error_timer.is_stopped():
		_error_timer.stop()
		_clear_error(false)
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9-]+$")

	var result := regex.search(new_text)
	if result:
		code.text = result.get_string()
		code.caret_column = code.text.length()
	else:
		code.text = ""
	_update_save_btn()


func _update_save_btn() -> void:
	if code.text == "" or level_name.text == "":
		save_btn.disabled = true
	else:
		save_btn.disabled = false


func close() -> void:
	panel.close()
	self.queue_free.call_deferred()


func _show_error() -> void:
	save_btn.disabled = true
	paste.add_theme_stylebox_override("normal", BUTTON_ERROR)
	paste.add_theme_color_override("icon_normal_color", Color.DARK_RED)
	code.add_theme_color_override("font_color", Color.DARK_RED)

	_error_timer.start()


func _clear_error(clear_code: bool = true) -> void:
	paste.add_theme_stylebox_override("normal", BUTTON_NORMAL)
	paste.remove_theme_color_override("icon_normal_color")
	code.remove_theme_color_override("font_color")
	if clear_code:
		code.text = ""
	_update_save_btn()
