## Handles logic for an individual tile (cell) in the puzzle grid.
##
## Each tile maintains two stacks:
## - One for tracking which sliders are currently affecting the tile.
## - One for storing the sequence of applied effects (e.g., PLUS, MINUS, INVERT).
##
## The tile's value is recalculated from scratch each time based on the effect stack. This ensures
## that effects are applied in a strict, repeatable order.
##
## This design prevents value inflation through effect abuse — for example, repeatedly applying and
## removing an "INVERT" effect could otherwise be used to artificially increase the cell value.
## Using a stack-based system guarantees that only the currently applied effects matter,
## avoiding cumulative or exponential growth from toggling effects.
class_name Cell extends Node2D

const SPAWN_TIME: float = 0.1

@export_file("*.png") var locked_cell := "res://assets/scenes_2d/locked_cell.png"

var _origin_data: CellData
var _current_data: CellData
var _slider_stack: Array[SliderArea]
var _effect_stack: Array[Constants.Sliders.Effect]

@onready var target_value_txt: Label = %TargetValueTxt
@onready var tile: Sprite2D = %Tile


## Applies or removes a slider's effect on the tile.
##
## If the given slider is already affecting this tile, it is removed along with its effect.
## Otherwise, the slider and its associated effect are added to the stacks.
##
## After modifying the stack, the final value of the tile is recalculated.
##
## @param slider SliderArea instance affecting this tile.
## @param effect Effect (e.g., PLUS, MINUS, INVERT) to apply or remove.
func alter_value(slider: SliderArea, effect: Constants.Sliders.Effect) -> void:

	# Removes the slider and its effect
	for i in range(0, _slider_stack.size()):
		if _slider_stack[i] == slider:
			_slider_stack.remove_at(i)
			_effect_stack.remove_at(i)
			_calculate_effect()
			_update_value()
			return

	# Adds the slider and its effect to the stack
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


func reset() -> void:
	if !_origin_data.is_blocked:
		_current_data.value = _origin_data.value
		_current_data.is_blocked = _origin_data.is_blocked
		_slider_stack.clear()
		_effect_stack.clear()
		_update_value()


func show_cell(animate: bool = true) -> void:
	if tile.visible == false:
		tile.show()

		if animate:
			tile.scale = Vector2.ZERO
			tile.modulate.a = 0
			var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(tile, "modulate:a", 1.0, SPAWN_TIME)
			tween.tween_property(tile, "scale", Vector2.ONE, SPAWN_TIME)


## Applies all the effects on the stack updating the cell value.
func _calculate_effect() -> void:
	_current_data.value = _origin_data.value
	_current_data.is_blocked = false

	for effect in _effect_stack:
		match effect:
			Constants.Sliders.Effect.ADD:
				_current_data.value += 1
			Constants.Sliders.Effect.SUBTRACT:
				_current_data.value -= 1
			Constants.Sliders.Effect.CHANGE_SIGN:
				_current_data.value *= -1
			Constants.Sliders.Effect.BLOCK:
				_current_data.value = 0
				_current_data.is_blocked = true


func _update_value() -> void:
	var color: Color = GameManager.palette.cell_color.get(_current_data.value)
	tile.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)
	target_value_txt.text = String.num(_current_data.value, 0)
