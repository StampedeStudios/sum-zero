@tool
## Local animation and bounds: independent of the old global UI scale.
extends AnimatedPanel


func _ready() -> void:
	get_parent().resized.connect(_layout)
	_layout()


func _layout() -> void:
	size = (get_parent().size - Vector2.ONE * 40).min(Vector2(460, 320))
	position = (get_parent().size - size) / 2
	pivot_offset = size / 2


func open() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, anim_time).from(Vector2(1, 0))
	await tween.finished


func close() -> void:
	scale = Vector2(1, 0)
