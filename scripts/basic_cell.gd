class_name Cell
extends Node2D

var is_blocked: bool = false
var _start_value: int = 0
var _value: int
var _slider_stack: Array[SliderArea]
var _effect_stack: Array[GlobalConst.AreaEffect]
var _color_palette: Dictionary = {
	-4: Vector4(0.49, 0.76, 0.24, 1),
	-3: Vector4(0.56, 0.8, 0.39, 1),
	-2: Vector4(0.36, 0.6, 0.196, 1),
	-1: Vector4(0.51, 0.78, 0.32, 1),
	0: Vector4(0.67, 0.89, 0.57, 1),
	1: Vector4(0.84, 0.93, 0.77, 1),
	2: Vector4(0.62, 0.68, 0.36, 1),
	3: Vector4(0.74, 0.15, 0.15, 1),
	4: Vector4(1, 0.4, 0.7, 1)
}

@onready var target_value_txt: Label = %TargetValueTxt
@onready var sprite_2d: Sprite2D = $Tile


func alter_value(slider: SliderArea, effect: GlobalConst.AreaEffect) -> void:
	# remove slider and effect
	for i in range(0, _slider_stack.size()):
		if _slider_stack[i] == slider:
			_slider_stack.remove_at(i)
			_effect_stack.remove_at(i)
			_update_value()
			return
	# add slider and effect
	_slider_stack.append(slider)
	_effect_stack.append(effect)
	_update_value()


func get_top_handle() -> SliderArea:
	var top: SliderArea = null
	if _slider_stack.size() > 0:
		top = _slider_stack[_slider_stack.size() - 1]
	return top


func init(new_value: int, blocked: bool) -> void:
	is_blocked = blocked
	_start_value = new_value
	_update_value()


func get_cell_value() -> int:
	return 0 if is_blocked else _value


func _update_value() -> void:
	_value = _start_value
	for effect in _effect_stack:
		match effect:
			GlobalConst.AreaEffect.ADD:
				_value += 1
			GlobalConst.AreaEffect.SUBTRACT:
				_value -= 1
				
	target_value_txt.text = String.num(_value)
	sprite_2d.material.set_shader_parameter("base_color", _color_palette.get(_value))
