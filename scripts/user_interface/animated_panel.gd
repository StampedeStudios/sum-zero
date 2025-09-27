class_name AnimatedPanel extends Panel

@export var anim_time: float = 0.2

var _panel_center: Vector2


func _ready() -> void:
	_panel_center = position + scale * size / 2


func open() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_animate, Vector2.ZERO, GameManager.ui_scale, anim_time)
	await tween.finished


func close() -> void:
	scale = Vector2.ZERO


func _animate(animated_scale: Vector2) -> void:
	scale = animated_scale
	position = _panel_center - (scale * size / 2)
