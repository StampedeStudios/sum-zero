class_name BuilderCell extends Node2D

signal on_cell_change(ref: BuilderCell, data: CellData)

const BUILDER_SELECTION = preload("res://packed_scene/user_interface/BuilderSelection.tscn")

var _data: CellData

@onready var cell = $Cell
@onready var target_value_txt = %TargetValueTxt
@onready var block = %Block


func _ready():
	_data = CellData.new()
	block.visible = false
	target_value_txt.visible = false
	_change_color(GameManager.palette.builder_cell_color)


func _on_collision_input_event(_viewport, _event, _shape_idx):
	if _event is InputEventMouse and _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.on_state_change.connect(_on_state_change)
		GameManager.change_state(GlobalConst.GameState.BUILDER_SELECTION)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.BUILDER_IDLE:
			self.z_index = 0
			_toggle_ui.call_deferred(false)

		GlobalConst.GameState.BUILDER_SELECTION:
			if !GameManager.builder_selection:
				var builder_selection: BuilderSelection
				builder_selection = BUILDER_SELECTION.instantiate()
				get_tree().root.add_child.call_deferred(builder_selection)
				GameManager.builder_selection = builder_selection
			self.z_index = 10
			_toggle_ui.call_deferred(true)


func _toggle_ui(ui_visible: bool) -> void:
	if ui_visible:
		GameManager.builder_selection.backward_action.connect(_decrease_value)
		GameManager.builder_selection.forward_action.connect(_increase_value)
		GameManager.builder_selection.special_action.connect(_block_cell)
		GameManager.builder_selection.remove_action.connect(clear_cell)
		GameManager.builder_selection.init_selection(true, self)
	else:
		GameManager.on_state_change.disconnect(_on_state_change)
		GameManager.builder_selection.backward_action.disconnect(_decrease_value)
		GameManager.builder_selection.forward_action.disconnect(_increase_value)
		GameManager.builder_selection.special_action.disconnect(_block_cell)
		GameManager.builder_selection.remove_action.disconnect(clear_cell)


func _decrease_value():
	var value: int
	if target_value_txt.visible:
		value = _data.value
		value = clamp(_data.value - 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
	else:
		value = 0
	_change_value(value)


func _increase_value():
	var value: int
	if target_value_txt.visible:
		value = _data.value
		value = clamp(_data.value + 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
	else:
		value = 0
	_change_value(value)


func _change_value(new_value: int) -> void:
	if new_value == _data.value and !_data.is_blocked and target_value_txt.visible:
		return
	_data.value = new_value
	_data.is_blocked = false
	_change_aspect()
	on_cell_change.emit(self, _data)


func _block_cell():
	_data.is_blocked = !_data.is_blocked
	_data.value = 0
	_change_aspect()
	on_cell_change.emit(self, _data)


func _change_aspect() -> void:
	block.visible = _data.is_blocked
	target_value_txt.visible = !_data.is_blocked
	if !_data.is_blocked:
		target_value_txt.text = String.num(_data.value)
		_change_color(GameManager.palette.cell_color.get(_data.value))


func _change_color(new_color: Color) -> void:
	cell.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, new_color)


func clear_cell() -> void:
	_data.value = 0
	target_value_txt.visible = false
	_data.is_blocked = false
	block.visible = false
	_change_color(GameManager.palette.builder_cell_color)
	on_cell_change.emit(self, null)
