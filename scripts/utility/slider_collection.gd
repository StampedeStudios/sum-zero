class_name SliderCollection extends Resource

@export_group("Slider effect")
@export var add: Texture2D
@export var subtract: Texture2D
@export var change_sign: Texture2D
@export var block: Texture2D

@export_group("Slider behavior")
@export var by_step: Texture2D
@export var full: Texture2D


func get_effect_texture(effect: GlobalConst.AreaEffect) -> Texture2D:
	match effect:
		GlobalConst.AreaEffect.ADD:
			return add
		GlobalConst.AreaEffect.SUBTRACT:
			return subtract
		GlobalConst.AreaEffect.CHANGE_SIGN:
			return change_sign
		GlobalConst.AreaEffect.BLOCK:
			return block
	return null


func get_behavior_texture(effect: GlobalConst.AreaBehavior) -> Texture2D:
	match effect:
		GlobalConst.AreaBehavior.BY_STEP:
			return by_step
		GlobalConst.AreaBehavior.FULL:
			return full
	return null
