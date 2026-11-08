@tool
## Shared editor/runtime geometry; deliberately independent of game state.
extends Control


func _ready() -> void:
	get_parent().resized.connect(layout_pages)
	layout_pages.call_deferred()


func layout_pages() -> void:
	var host := get_parent() as Control
	size = Vector2(host.size.x * get_child_count(), host.size.y)
	position = Vector2(-host.size.x, 0)
	for index in range(get_child_count()):
		var page := get_child(index) as Control
		page.position = Vector2(host.size.x * index, 0)
		page.size = host.size
