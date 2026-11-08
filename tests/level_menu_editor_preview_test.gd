## Run with: godot --headless --editor --path . --script tests/level_menu_editor_preview_test.gd
extends SceneTree

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(Engine.is_editor_hint(), "Run this test with --editor to test actual tool-script execution")
	var scene := load("res://packed_scene/user_interface/LevelUI.tscn") as PackedScene
	var ui := scene.instantiate() as Control
	root.add_child(ui)
	for extent in [Vector2i(360, 640), Vector2i(480, 853), Vector2i(640, 360)]:
		root.size = extent
		for frame in range(12):
			await process_frame
		var host := ui.get_node("%PageHost") as Control
		var pages := ui.get_node("%Pages") as Control
		var current := pages.get_child(1) as Control
		_check(current.size.is_equal_approx(host.size), "Editor page must fill host at %s" % extent)
		_check(current.global_position.is_equal_approx(host.global_position), "Editor page must align with host at %s" % extent)
		var grid := current.get_node("%LevelGrid") as GridContainer
		_check(host.get_global_rect().grow(1).encloses(grid.get_global_rect()), "Editor grid must fit host at %s" % extent)
		_check(grid.size.x >= 168, "Editor grid must not collapse")
		_check((grid.get_child(0) as Button).text == "1", "Preview must provide numbered sample levels")
		_check((grid.get_child(4) as Button).disabled, "Preview must provide locked sample levels")
	ui.queue_free()
	# Allow the editor's own initial scene/dock setup to finish before shutdown.
	await create_timer(1).timeout
	print("Level menu editor preview: 3 cases, %d failures" % _failures)
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
