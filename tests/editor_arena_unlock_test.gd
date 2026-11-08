## Run with: godot --headless --path . --script tests/editor_arena_unlock_test.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	root.child_entered_tree.connect(func(child: Node) -> void:
		if child.name == "SplashScreen":
			child.set_script(null)
	)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var splash := root.get_node_or_null("SplashScreen")
	if splash:
		splash.queue_free()
	await process_frame
	var saves := root.get_node("SaveManager")
	var stars_before: int = saves.get_star_count()
	var scene := load("res://packed_scene/user_interface/PlayModeUI.tscn") as PackedScene
	var card := scene.instantiate() as Control
	root.add_child(card)
	var mode := ArenaMode.new()
	mode.unlock_mode = PlayMode.UnlockMode.STAR
	mode.unlock_count = stars_before + 100
	card.setup(mode)
	_check(card.is_locked(), "Arena must remain locked by default")
	card.setup(mode, true)
	_check(card.is_locked() == not OS.has_feature("editor"), "Bypass must require an editor build")
	_check(card.get_node("%OverlayTexture").visible == card.is_locked(), "Lock overlay must match availability")
	card.setup(mode, false)
	_check(card.is_locked(), "Disabling bypass must restore lock")
	var story := StoryMode.new()
	story.unlock_mode = PlayMode.UnlockMode.STAR
	story.unlock_count = stars_before + 100
	card.setup(story, true)
	_check(card.is_locked(), "Bypass must not unlock campaign modes")
	_check(saves.get_star_count() == stars_before, "Bypass must not change saved stars")
	card.queue_free()
	await process_frame
	print("Editor arena unlock: %d failures" % _failures)
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
