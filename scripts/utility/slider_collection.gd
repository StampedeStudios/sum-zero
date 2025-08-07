## Collection of all sliders informations.
class_name SliderCollection extends Resource

@export_group("Slider effect")
@export_file("*.png") var add := "res://assets/scenes_2d/plus_icon.png"
@export_file("*.png") var subtract := "res://assets/scenes_2d/minus_icon.png"
@export_file("*.png") var change_sign := "res://assets/scenes_2d/invert_icon.png"
@export_file("*.png") var block := "res://assets/scenes_2d/block.png"

@export_group("Slider behavior")
@export_file("*.png") var by_step := ""
@export_file("*.png") var out_by_step := "res://assets/scenes_2d/slider_outline.png"
@export_file("*.png") var full := "res://assets/scenes_2d/behavior_full_icon.png"
@export_file("*.png") var out_full := "res://assets/scenes_2d/auto_slider_outline.png"

@export_group("Slider block effect")
@export_file("*.png") var block_texture := "res://assets/scenes_2d/blocked_tile.png"
@export_file("*.gdshader") var block_shader := "res://scripts/shaders/Block.gdshader"


func get_effect_texture(effect: Constants.Sliders.Effect) -> Texture2D:
	var path: String
	match effect:
		Constants.Sliders.Effect.ADD:
			path = add
		Constants.Sliders.Effect.SUBTRACT:
			path = subtract
		Constants.Sliders.Effect.CHANGE_SIGN:
			path = change_sign
		Constants.Sliders.Effect.BLOCK:
			path = block
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


func get_behavior_texture(effect: Constants.Sliders.Behavior) -> Texture2D:
	var path: String
	match effect:
		Constants.Sliders.Behavior.BY_STEP:
			path = by_step
		Constants.Sliders.Behavior.FULL:
			path = full
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


func get_outline_texture(effect: Constants.Sliders.Behavior) -> Texture2D:
	var path: String
	match effect:
		Constants.Sliders.Behavior.BY_STEP:
			path = out_by_step
		Constants.Sliders.Behavior.FULL:
			path = out_full
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


func get_block_texture() -> Texture2D:
	if ResourceLoader.exists(block_texture):
		return ResourceLoader.load(block_texture)
	return null


func get_block_shader() -> Shader:
	if ResourceLoader.exists(block_shader):
		return ResourceLoader.load(block_shader)
	return null
