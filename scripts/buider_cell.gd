extends Node2D

@export var standard_color: Color = Color.GRAY
var _palette: ColorPalette
var _value: int = 0
var _is_blocked: bool = false

@onready var cell = $Cell
@onready var cell_value = %TargetValueTxt
@onready var block = %Block
@onready var hud = $HUD
@onready var panel = %Panel
@onready var control = %Control


func _ready():
	_palette = GameManager.palette
	block.visible = false
	hud.visible = false
	cell_value.visible = false
	panel.size = get_viewport_rect().size
	control.scale = self.scale
	control.position = self.global_position
	_change_color(standard_color)
	

func _on_collision_input_event(_viewport, _event, _shape_idx):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			hud.visible = true
			_toggle_priority(true)
						

func _on_minus_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !_is_blocked:
			if cell_value.visible:
				_value = clamp(_value - 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
			else:
				cell_value.visible = true
			cell_value.text = String.num(_value)
			_change_color(_palette.cell_color.get(_value))


func _on_plus_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !_is_blocked:
			if cell_value.visible:
				_value = clamp(_value + 1, GlobalConst.MIN_CELL_VALUE, GlobalConst.MAX_CELL_VALUE)
			else:
				cell_value.visible = true
			cell_value.text = String.num(_value)
			_change_color(_palette.cell_color.get(_value))
				
			

func _on_remove_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_value = 0
			cell_value.visible = false
			_is_blocked = false
			block.visible = false
			_change_color(standard_color)


func _on_block_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_is_blocked = !_is_blocked
			block.visible = _is_blocked
			
			
func _on_panel_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			hud.visible = false
			_toggle_priority(false)


func _change_color(new_color: Color) -> void:
	cell.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, new_color)


func _toggle_priority(is_selected: bool) -> void:
	self.z_index = 10 if is_selected else 0
