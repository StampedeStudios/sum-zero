class_name SliderCollection extends Resource

@export_group("Slider effect")
@export_file("*.png") var add := "res://assets/scenes_2d/plus_icon.png"
@export_file("*.png") var subtract := "res://assets/scenes_2d/minus_icon.png"
@export_file("*.png") var change_sign := "res://assets/scenes_2d/invert_icon.png"
@export_file("*.png") var block := "res://assets/scenes_2d/block.png"

@export_group("Slider behavior")
@export_file("*.png") var by_step := ""
@export_file("*.png") var full := "res://assets/scenes_2d/full_behavior_icon.png"

@export_group("Slider block effect")
@export_file("*.png") var block_texture := "res://assets/scenes_2d/blocked_tile.png"
@export_file("*.gdshader") var block_shader := "res://scripts/shaders/Block.gdshader"


func get_effect_texture(effect: GlobalConst.AreaEffect) -> Texture2D:
	var path: String
	match effect:
		GlobalConst.AreaEffect.ADD:
			path = add
		GlobalConst.AreaEffect.SUBTRACT:
			path = subtract
		GlobalConst.AreaEffect.CHANGE_SIGN:
			path = change_sign
		GlobalConst.AreaEffect.BLOCK:
			path = block
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


func get_behavior_texture(effect: GlobalConst.AreaBehavior) -> Texture2D:
	var path: String
	match effect:
		GlobalConst.AreaBehavior.BY_STEP:
			path = by_step
		GlobalConst.AreaBehavior.FULL:
			path = full
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
