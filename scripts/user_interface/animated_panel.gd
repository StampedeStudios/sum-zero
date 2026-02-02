class_name AnimatedPanel extends Panel

@export var anim_time: float = 0.2

var _panel_center: Vector2


func _ready() -> void:
	_panel_center = position + scale * size / 2


func open() -> void:
	for child: CanvasItem in get_children():
		child.modulate.a = 0

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_method(
		_animate, Vector2(GameManager.ui_scale.x, 0), GameManager.ui_scale, anim_time
	)
	await tween.finished

	await get_tree().create_timer(0.1).timeout

	for child: CanvasItem in get_children():
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "modulate:a", 1.0, anim_time)


func close() -> void:
	scale = Vector2(GameManager.ui_scale.x, 0)


func _animate(animated_scale: Vector2) -> void:
	scale = animated_scale
	position = _panel_center - (scale * size / 2)
