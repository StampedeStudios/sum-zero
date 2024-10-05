extends Node2D

@export var standard_color: Color = Color.GRAY
var _palette: ColorPalette
var data: CellData
var _is_valid: bool = false

@onready var cell = $Cell
@onready var cell_value = %TargetValueTxt
@onready var block = %Block
@onready var hud = $HUD
@onready var panel = %Panel
@onready var control = %Control


func _ready():
	data = CellData.new()
	_palette = GameManager.palette
	block.visible = false
	hud.visible = false
	cell_value.visible = false
	panel.size = get_viewport_rect().size
	_change_color(standard_color)

	
func redraw_ui() -> void:
	control.scale = self.scale
	control.position = self.global_position


func _on_collision_input_event(_viewport, _event, _shape_idx):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_toggle_hud(true)
						

func _on_minus_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !data.is_blocked:
			_is_valid = true
			if cell_value.visible:
				data.value = clamp(data.value - 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
			else:
				cell_value.visible = true
			cell_value.text = String.num(data.value)
			_change_color(_palette.cell_color.get(data.value))


func _on_plus_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !data.is_blocked:
			_is_valid = true
			if cell_value.visible:
				data.value = clamp(data.value + 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
			else:
				cell_value.visible = true
			cell_value.text = String.num(data.value)
			_change_color(_palette.cell_color.get(data.value))
				
			

func _on_remove_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			clear_cell()


func _on_block_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			data.is_blocked = !data.is_blocked
			block.visible = data.is_blocked
			_is_valid = true
			
			
func _on_panel_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_toggle_hud(false)


func _change_color(new_color: Color) -> void:
	cell.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, new_color)


func _toggle_hud(hud_visibility: bool) -> void:
	hud.visible = hud_visibility
	self.z_index = 10 if hud_visibility else 0
	

func clear_cell() -> void:
	_is_valid = true
	data.value = 0
	cell_value.visible = false
	data.is_blocked = false
	block.visible = false
	_change_color(standard_color)
	

func get_cell_data() -> CellData:
	if _is_valid:
		return data
	else:
		return null
