@tool
## Keep the same responsive grid geometry in the editor and at runtime.
extends CenterContainer


func _ready() -> void:
	get_parent().resized.connect(layout_grid)
	layout_grid.call_deferred()


func layout_grid() -> void:
	var extent: Vector2 = get_parent().size
	var side := clampf((minf(extent.x, extent.y) - 24.0) / 3.0, 48.0, 120.0)
	for button: Control in get_node("LevelGrid").get_children():
		button.custom_minimum_size = Vector2.ONE * side
