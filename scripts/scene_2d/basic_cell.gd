class_name Cell
extends Node2D

var is_blocked: bool = false
var _palette: ColorPalette
var _start_value: int = 0
var _value: int
var _slider_stack: Array[SliderArea]
var _effect_stack: Array[GlobalConst.AreaEffect]

@onready var target_value_txt: Label = %TargetValueTxt
@onready var sprite_2d: Sprite2D = $Tile


func alter_value(slider: SliderArea, effect: GlobalConst.AreaEffect) -> void:
	# remove slider and effect
	for i in range(0, _slider_stack.size()):
		if _slider_stack[i] == slider:
			_slider_stack.remove_at(i)
			_effect_stack.remove_at(i)
			_calculate_effect()
			_update_value()
			return
	# add slider and effect
	_slider_stack.append(slider)
	_effect_stack.append(effect)
	_calculate_effect()
	_update_value()


func init_cell(data: CellData) -> void:
	is_blocked = data.is_blocked
	_start_value = data.value
	_value = _start_value
	_update_value()


func get_cell_value() -> int:
	return 0 if is_blocked else _value


func is_occupied() -> bool:
	return _slider_stack.size() > 0


func _ready() -> void:
	GameManager.reset.connect(_reset)
	_palette = GameManager.palette


func _calculate_effect() -> void:
	_value = _start_value
	is_blocked = false
	for effect in _effect_stack:
		match effect:
			GlobalConst.AreaEffect.ADD:
				_value += 1
			GlobalConst.AreaEffect.SUBTRACT:
				_value -= 1
			GlobalConst.AreaEffect.CHANGE_SIGN:
				_value *= -1
			GlobalConst.AreaEffect.BLOCK:
				_value = 0
				is_blocked = true


func _update_value() -> void:
	target_value_txt.text = String.num(_value)
	sprite_2d.material.set_shader_parameter(
		Literals.Parameters.BASE_COLOR, _palette.cell_color.get(_value)
	)


func _reset() -> void:
	_value = _start_value
	is_blocked = is_blocked and _slider_stack.size() == 0
	_slider_stack.clear()
	_effect_stack.clear()
	_update_value()
