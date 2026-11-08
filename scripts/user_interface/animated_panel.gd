@tool
class_name AnimatedPanel extends Panel

@export var anim_time: float = 0.2

func _ready() -> void:
	pivot_offset = size / 2
	resized.connect(func() -> void: pivot_offset = size / 2)


func open() -> void:
	for child: CanvasItem in get_children():
		child.modulate.a = 0

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE, anim_time).from(Vector2(1, 0))
	await tween.finished

	await get_tree().create_timer(0.1).timeout

	for child: CanvasItem in get_children():
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "modulate:a", 1.0, anim_time)


func close() -> void:
	scale = Vector2(1, 0)
