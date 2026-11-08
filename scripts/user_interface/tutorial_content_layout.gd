@tool
extends BoxContainer
## Keep the illustration outside text scrolling, in both editor and runtime.

var _refresh_pending := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and not _refresh_pending:
		_refresh_pending = true
		refresh.call_deferred()


func refresh() -> void:
	_refresh_pending = false
	if not is_inside_tree():
		return
	var hint := get_node("Hint") as RichTextLabel
	var illustration := get_node("TextureRect") as TextureRect
	vertical = true
	if illustration.visible:
		# Let ordinary text use its natural height, but reserve most of the
		# available region for the illustration when a translation is longer.
		hint.size_flags_vertical = Control.SIZE_FILL
		hint.custom_minimum_size.y = minf(hint.get_content_height(), size.y * 0.38)
	else:
		hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hint.custom_minimum_size.y = 0
