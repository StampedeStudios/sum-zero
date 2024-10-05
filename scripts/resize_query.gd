class_name ResizeQuery extends Control

signal on_width_change(new_width: int)
signal on_height_change(new_height: int)

var _width: int
var _height: int

@onready var width_value = %WidthValue
@onready var height_value = %HeightValue


func init_query(width: int, height: int):
	_width = width
	_height = height
	width_value.text = String.num(_width)
	height_value.text = String.num(_height)
	

func _on_minus_width_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_width = clamp(_width - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_width()


func _on_plus_width_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_width = clamp(_width + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)			
			_update_width()


func _on_minus_height_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_height = clamp(_height - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_height()


func _on_plus_height_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_height = clamp(_height + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
			_update_height()


func _update_width() -> void:
	width_value.text = String.num(_width)
	on_width_change.emit(_width)


func _update_height() -> void:
	height_value.text = String.num(_height)
	on_height_change.emit(_height)


func _on_background_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			self.queue_free()
