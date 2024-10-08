class_name BuilderResize extends Control

signal on_width_change(new_width: int)
signal on_height_change(new_height: int)

var _width: int
var _height: int

@onready var width_value = %WidthValue
@onready var height_value = %HeightValue

func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
			
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_TEST:
			self.visible = false
			
		GlobalConst.GameState.BUILDER_RESIZE:
			self.visible = true
		

func init_query(width: int, height: int):
	_width = width
	_height = height
	width_value.text = String.num(_width)
	height_value.text = String.num(_height)


func _on_minus_width_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var	new_width: int
		new_width = clamp(_width - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
		_update_width(new_width)


func _on_plus_width_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_width: int
		new_width = clamp(_width + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
		_update_width(new_width)


func _on_minus_height_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_height: int
		new_height = clamp(_height - 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
		_update_height(new_height)


func _on_plus_height_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_height: int
		new_height = clamp(_height + 1, GlobalConst.MIN_LEVEL_SIZE, GlobalConst.MAX_LEVEL_SIZE)
		_update_height(new_height)


func _update_width(new_width: int) -> void:
	if new_width != _width:
		_width = new_width
		width_value.text = String.num(_width)
		on_width_change.emit(_width)


func _update_height(new_height: int) -> void:
	if new_height != _height:
		_height = new_height
		height_value.text = String.num(_height)
		on_height_change.emit(_height)


func _on_background_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)
