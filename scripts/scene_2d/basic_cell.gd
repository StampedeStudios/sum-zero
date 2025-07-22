class_name Cell extends Node2D

const SPAWN_TIME: float = 0.1

@export_file("*.png") var locked_cell := "res://assets/scenes_2d/locked_cell.png"

var _origin_data: CellData
var _current_data: CellData
var _slider_stack: Array[SliderArea]
var _effect_stack: Array[GlobalConst.AreaEffect]

@onready var target_value_txt: Label = %TargetValueTxt
@onready var tile: Sprite2D = %Tile


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
	tile.hide()
	_origin_data = data
	if _origin_data.is_blocked:
		_current_data = data
		tile.texture = ResourceLoader.load(locked_cell) as Texture2D
		target_value_txt.visible = false
	else:
		_current_data = CellData.new()
		_current_data.is_blocked = _origin_data.is_blocked
		_current_data.value = _origin_data.value
		_update_value()


func get_cell_value() -> int:
	if _origin_data.is_blocked or _current_data.is_blocked:
		return 0

	return _current_data.value


func is_cell_blocked() -> bool:
	return _current_data.is_blocked


func is_occupied() -> bool:
	return _slider_stack.size() > 0


func _calculate_effect() -> void:
	_current_data.value = _origin_data.value
	_current_data.is_blocked = false
	for effect in _effect_stack:
		match effect:
			GlobalConst.AreaEffect.ADD:
				_current_data.value += 1
			GlobalConst.AreaEffect.SUBTRACT:
				_current_data.value -= 1
			GlobalConst.AreaEffect.CHANGE_SIGN:
				_current_data.value *= -1
			GlobalConst.AreaEffect.BLOCK:
				_current_data.value = 0
				_current_data.is_blocked = true


func _update_value() -> void:
	var color: Color
	color = GameManager.palette.cell_color.get(_current_data.value)
	tile.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)
	target_value_txt.text = String.num(_current_data.value, 0)


func reset() -> void:
	if !_origin_data.is_blocked:
		_current_data.value = _origin_data.value
		_current_data.is_blocked = _origin_data.is_blocked
		_slider_stack.clear()
		_effect_stack.clear()
		_update_value()


func show_cell(instant_anim: bool = false) -> void:
	if tile.visible == false:
		tile.show()
		if !instant_anim:
			tile.scale = Vector2.ZERO
			create_tween().tween_property(tile, "scale", Vector2.ONE, SPAWN_TIME)
