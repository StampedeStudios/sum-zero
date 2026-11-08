@tool
## Bounded dialog with a local opening animation, independent of global UI scale.
extends AnimatedPanel

@export var maximum_size := Vector2(460, 420):
	set(value):
		maximum_size = value
		if is_node_ready():
			_layout()


func _ready() -> void:
	get_parent().resized.connect(_layout)
	_layout()


func _layout() -> void:
	size = (get_parent().size - Vector2.ONE * 32).min(maximum_size).max(Vector2.ONE)
	position = (get_parent().size - size) / 2
	pivot_offset = size / 2


func open() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, anim_time).from(Vector2(1, 0))
	await tween.finished


func close() -> void:
	scale = Vector2(1, 0)
