class_name Tile
extends Node2D

@onready var target_value_txt: Label = %TargetValueTxt
@onready var sprite_2d: Sprite2D = $Sprite2D

var value: int = 0

var color_palette: Dictionary = {
	-2: Vector4(0, 0.1, 0, 1),
	-1: Vector4(0, 0.2, 0, 1),
	0: Vector4(0, 0.3, 0, 1),
	1: Vector4(0, 0.7, 0, 1),
	2: Vector4(0.5, 0.5, 0, 1),
	3: Vector4(0.8, 0.2, 0, 1),
	4: Vector4(1, 0.4, 0.7, 1)
}


func alter_value(value_variation: int) -> void:
	value += value_variation
	_update()


func init(cell_value: int) -> void:
	value = cell_value
	_update()


func _update() -> void:
	target_value_txt.text = String.num(value)
	sprite_2d.material.set_shader_parameter("base_color", color_palette.get(value))
