## Defines the logic of a cell in the Level Editor.
##
## A builder cell is fundamentally different from a basic cell because it can be selected and
## modified alone or together with other cells. Has to handle variations in color, value and
## logic in order to be correctly saved as part of a puzzle.
class_name BuilderCell extends Node2D

signal on_cell_change(ref: BuilderCell, data: CellData)
## Signal emitted when a cell is selected with multiple cell selection by the player.
## In such cases, each cell will be updated altogether.
signal start_multiselection

var _data: CellData

@onready var cell: Sprite2D = $Cell
@onready var target_value_txt: Label = %TargetValueTxt
@onready var block: Sprite2D = %Block


func _ready() -> void:
	_data = CellData.new()
	block.visible = false
	target_value_txt.visible = false
	_change_color(GameManager.palette.builder_cell_color)


func _on_collision_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		start_multiselection.emit()


func toggle_connection(ui_visible: bool) -> void:
	if ui_visible:
		GameManager.on_state_change.connect(_on_state_change)
		GameManager.builder_selection.backward_action.connect(_decrease_value)
		GameManager.builder_selection.forward_action.connect(_increase_value)
		GameManager.builder_selection.special_action.connect(_block_cell)
		GameManager.builder_selection.remove_action.connect(_clear_cell)
	else:
		GameManager.on_state_change.disconnect(_on_state_change)
		GameManager.builder_selection.backward_action.disconnect(_decrease_value)
		GameManager.builder_selection.forward_action.disconnect(_increase_value)
		GameManager.builder_selection.special_action.disconnect(_block_cell)
		GameManager.builder_selection.remove_action.disconnect(_clear_cell)


func set_cell_data(cell_data: CellData) -> void:
	_data = cell_data.duplicate()
	_change_aspect()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.BUILDER_IDLE:
			self.z_index = 0
			toggle_connection.call_deferred(false)


func _decrease_value() -> void:
	var value: int = 0
	if target_value_txt.visible:
		value = _data.value
		value = clamp(_data.value - 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)

	_change_value(value)


func _increase_value() -> void:
	var value: int = 0
	if target_value_txt.visible:
		value = _data.value
		value = clamp(_data.value + 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)

	_change_value(value)


func _change_value(new_value: int) -> void:
	if new_value == _data.value and !_data.is_blocked and target_value_txt.visible:
		return

	_data.value = new_value
	_data.is_blocked = false
	_change_aspect()
	on_cell_change.emit(self, _data)


func _block_cell() -> void:
	_data.is_blocked = !_data.is_blocked
	_data.value = 0
	_change_aspect()
	on_cell_change.emit(self, _data)


func _change_aspect() -> void:
	block.visible = _data.is_blocked
	target_value_txt.visible = !_data.is_blocked
	if !_data.is_blocked:
		target_value_txt.text = String.num(_data.value, 0)
		_change_color(GameManager.palette.cell_color.get(_data.value))


func _change_color(new_color: Color) -> void:
	cell.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, new_color)


func _clear_cell() -> void:
	_data = CellData.new()
	target_value_txt.visible = false
	block.visible = false
	_change_color(GameManager.palette.builder_cell_color)
	on_cell_change.emit(self, null)
