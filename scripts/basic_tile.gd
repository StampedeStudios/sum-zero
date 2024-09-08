class_name Tile
extends Node2D

var is_blocked: bool = false
var value: int = 0
var sc_stack: Array[ScalableArea]
var color_palette: Dictionary = {
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
@onready var led: Sprite2D = $Led


func alter_value(stack_variation: ScalableArea, is_increment: bool) -> void:
	var is_exist: bool
	var slider_direction: Vector2 = (
		(self.global_position - stack_variation.global_position).normalized()
	)

	for i in range(0, sc_stack.size()):
		if sc_stack[i] == stack_variation:
			is_exist = true
			sc_stack.remove_at(i)
			break
	if is_exist:
		_update_led(slider_direction, false)
		value -= 1 if is_increment else -1
	else:
		_update_led(slider_direction, true)
		sc_stack.append(stack_variation)
		value += 1 if is_increment else -1
	update()


func get_top_handle() -> ScalableArea:
	var top: ScalableArea = null
	if sc_stack.size() > 0:
		top = sc_stack[sc_stack.size() - 1]
	return top


func init(cell_value: int) -> void:
	value = cell_value
	update()


func update() -> void:
	target_value_txt.text = String.num(value)
	sprite_2d.material.set_shader_parameter("base_color", color_palette.get(value))


func _update_led(slider_direction: Vector2, is_on: bool):
	match slider_direction:
		Vector2(1, 0):
			led.material.set_shader_parameter("is_left", is_on)
		Vector2(-1, 0):
			led.material.set_shader_parameter("is_right", is_on)
		Vector2(0, 1):
			led.material.set_shader_parameter("is_top", is_on)
		Vector2(0, -1):
			led.material.set_shader_parameter("is_bottom", is_on)
