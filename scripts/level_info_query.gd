class_name Query extends Control

signal on_confirm(width: int, height: int)


var _width: int
var _height: int

@onready var width_value = $VBoxContainer/WidthContainer/WidthValue
@onready var height_value = $VBoxContainer/HeightContainer/HeightValue


func _ready():
	_width = GlobalConst.MIN_LEVEL_SIZE
	_update_width()
	_height = GlobalConst.MIN_LEVEL_SIZE
	_update_height()
	

func _on_minus_width_gui_input(event):
	if event is InputEventMouse:
		if event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_width = clamp(_width - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_width()


func _on_plus_width_gui_input(event):
	if event is InputEventMouse:
		if event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_width = clamp(_width + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_width()


func _on_minus_height_gui_input(event):
	if event is InputEventMouse:
		if event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_height = clamp(_height - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_height()


func _on_plus_height_gui_input(event):
	if event is InputEventMouse:
		if event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_height = clamp(_height + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_height()


func _update_width() -> void:
	width_value.text = String.num(_width)


func _update_height() -> void:
	height_value.text = String.num(_height)


func _on_confirm_pressed():
	on_confirm.emit(_width, _height)
	self.queue_free()
