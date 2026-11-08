extends SceneTree
## Shared headless setup. Keep scaling enabled only in the canvas integration test.

var _failures := 0


func _initialize() -> void:
	if not _uses_canvas_scaling():
		root.content_scale_size = Vector2i.ZERO
	root.child_entered_tree.connect(func(child: Node) -> void:
		if child.name == "SplashScreen":
			child.set_script(null)
	)
	_start.call_deferred()


func _start() -> void:
	await process_frame
	var splash := root.get_node_or_null("SplashScreen")
	if splash:
		splash.queue_free()
	await process_frame
	root.get_node("AudioManager")._is_sfx_on = false
	await _run()


func _run() -> void:
	pass


func _uses_canvas_scaling() -> bool:
	return false


func _settle() -> void:
	for frame in range(12):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
