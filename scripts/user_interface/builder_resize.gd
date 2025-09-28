class_name BuilderResize extends Control

signal on_width_change(new_width: int)
signal on_height_change(new_height: int)
signal on_zoom_change(new_scale: Vector2)

var _width: int
var _height: int
var _scale: float

@onready var control: Control = %Control


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	for child: TextureRect in control.get_children():
		child.position.y = child.position.y - GameManager.CENTER_OFFSET


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		Constants.GameState.BUILDER_RESIZE:
			self.visible = true
		_:
			self.visible = false


func init_query(level_size: Vector2i) -> void:
	_width = level_size.x
	_height = level_size.y
	_scale = 0
	_update_zoom.call_deferred()


func _on_minus_width_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_width: int
		new_width = clamp(_width - 1, Constants.MIN_LEVEL_SIZE, Constants.MAX_LEVEL_SIZE)
		_update_width(new_width)


func _on_plus_width_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_width: int
		new_width = clamp(_width + 1, Constants.MIN_LEVEL_SIZE, Constants.MAX_LEVEL_SIZE)
		_update_width(new_width)


func _on_minus_height_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_height: int
		new_height = clamp(_height - 1, Constants.MIN_LEVEL_SIZE, Constants.MAX_LEVEL_SIZE)
		_update_height(new_height)


func _on_plus_height_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		var new_height: int
		new_height = clamp(_height + 1, Constants.MIN_LEVEL_SIZE, Constants.MAX_LEVEL_SIZE)
		_update_height(new_height)


func _update_width(new_width: int) -> void:
	if new_width != _width:
		_width = new_width
		_update_zoom()
		on_width_change.emit(_width)


func _update_height(new_height: int) -> void:
	if new_height != _height:
		_height = new_height
		_update_zoom()
		on_height_change.emit(_height)


func _update_zoom() -> void:
	var new_scale: float
	var max_size := maxi(_width, _height) + 2
	new_scale = control.size.x / Constants.Sizes.CELL_SIZE / max_size
	if new_scale != _scale:
		_scale = new_scale
		on_zoom_change.emit(Vector2(_scale, _scale))


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(Constants.GameState.BUILDER_IDLE)


func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(Constants.GameState.BUILDER_IDLE)
