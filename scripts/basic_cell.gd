class_name Cell
extends Node2D

@export var _color_palette: Dictionary = {
	-4: Color(0.56, 0.8, 0.39, 1),
	-3: Color(0.56, 0.8, 0.39, 1),
	-2: Color(0.56, 0.8, 0.39, 1),
	-1: Color(0.56, 0.8, 0.39, 1),
	0: Color(0.56, 0.8, 0.39, 1),
	1: Color(0.56, 0.8, 0.39, 1),
	2: Color(0.56, 0.8, 0.39, 1),
	3: Color(0.56, 0.8, 0.39, 1),
	4: Color(0.56, 0.8, 0.39, 1),
}

var is_blocked: bool = false
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


func init(new_value: int, blocked: bool) -> void:
	is_blocked = blocked
	_start_value = new_value
	_value = _start_value
	_update_value()


func get_cell_value() -> int:
	return 0 if is_blocked else _value


func is_occupied() -> bool:
	return _slider_stack.size() > 0


func _ready() -> void:
	GameManager.reset.connect(_reset)


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
		Literals.Parameters.BASE_COLOR, _color_palette.get(_value)
	)


func _reset() -> void:
	_value = _start_value
	is_blocked = is_blocked and _slider_stack.size() == 0
	_slider_stack.clear()
	_effect_stack.clear()
	_update_value()
