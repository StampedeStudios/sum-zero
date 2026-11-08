## Run with: godot --headless --path . --script tests/main_menu_layout_test.gd
extends SceneTree

const MENU_SCENE_PATH = "res://packed_scene/user_interface/MainMenu.tscn"
const VIEWPORT_SIZES: Array[Vector2i] = [
	Vector2i(360, 640),
	Vector2i(480, 853),
	Vector2i(720, 1280),
	Vector2i(720, 1600),
	Vector2i(960, 1280),
	Vector2i(480, 320),
]

var _failures: int = 0


func _initialize() -> void:
	root.child_entered_tree.connect(_disable_splash)
	_run.call_deferred()


func _disable_splash(child: Node) -> void:
	# Prevent the autoload-created splash from starting animation timers.
	if child.name == "SplashScreen":
		child.set_script(null)


func _run() -> void:
	# Autoloads also run for script tests. Stop the splash before it starts the game.
	await process_frame
	for child in root.get_children():
		if child.name == "SplashScreen":
			child.queue_free()
	await process_frame

	var scene := load(MENU_SCENE_PATH) as PackedScene
	var menu := scene.instantiate() as Control
	root.add_child(menu)
	var scroll := menu.get_node("MarginContainer/ScrollContainer") as ScrollContainer
	var buttons := scroll.get_node("Content/Buttons") as VBoxContainer
	var cases: int = 0

	for viewport_size in VIEWPORT_SIZES:
		root.size = viewport_size
		for locale in Constants.AVAILABLE_LANGS:
			TranslationServer.set_locale(locale)
			scroll.scroll_vertical = 0
			await _settle_layout()
			var context := "%s / %s" % [viewport_size, locale]
			_check(menu.scale == Vector2.ONE, context + ": menu must not be manually scaled")
			_check(menu.size.is_equal_approx(Vector2(viewport_size)), context + ": root must fill viewport")
			_check(buttons.size.x <= scroll.size.x, context + ": buttons overflow horizontally")
			_check(buttons.size.x < 400, context + ": buttons must stay bounded on wide screens")

			var previous_bottom: float = -INF
			for child in buttons.get_children():
				var control := child as Control
				_check(control.position.y >= previous_bottom, context + ": controls overlap")
				previous_bottom = control.position.y + control.size.y
				if child is Button:
					var button := child as Button
					_check(button.size.y >= button.get_combined_minimum_size().y, context + ": text is clipped")
					_check(button.size.y >= 48, context + ": button is too short")
					_check(button.pressed.get_connections().size() == 1, context + ": missing button action")

			if buttons.size.y <= scroll.size.y:
				var center := buttons.get_global_rect().get_center()
				_check(absf(center.y - scroll.get_global_rect().get_center().y) <= 1, context + ": menu is not centered")
			else:
				scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
				await _settle_layout()
				var quit_button := buttons.get_node("QuitBtn") as Button
				_check(scroll.get_global_rect().encloses(quit_button.get_global_rect()), context + ": last button is unreachable")
			cases += 1

	var manager := root.get_node("GameManager")
	manager.change_state(Constants.GameState.OPTIONS_MENU)
	_check(not menu.visible, "Menu must hide when navigating away")
	manager.change_state(Constants.GameState.MAIN_MENU)
	_check(menu.visible, "Menu must show when returning")

	menu.queue_free()
	await process_frame
	print("Main menu layout: %d cases, %d failures" % [cases, _failures])
	quit(1 if _failures else 0)


func _settle_layout() -> void:
	for frame in range(8):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
