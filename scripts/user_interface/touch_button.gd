@tool
extends Button
## Theme-driven touch bounds, independent of icon size and container expansion.


var _scene_minimum: Vector2


func _ready() -> void:
	_scene_minimum = custom_minimum_size
	_update_touch_bounds()


func _update_touch_bounds() -> void:
	custom_minimum_size = _scene_minimum.max(Vector2(
		get_theme_constant("touch_minimum_width"),
		get_theme_constant("touch_minimum_height")
	))


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_update_touch_bounds()
