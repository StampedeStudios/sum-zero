class_name CreditsScreen extends Control

var _scroll_tween: Tween

@onready var text: RichTextLabel = %RichTextLabel

func _ready() -> void:
	$ScrollDelay.start()
	text.get_v_scroll_bar().scrolling.connect(_stop_auto_scroll)


func start_credits_scroll() -> void:
	_stop_auto_scroll()
	_scroll_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_method(_scroll_to_progress, 0.0, 1.0, 60.0)


func _scroll_to_progress(progress: float) -> void:
	var scrollbar := text.get_v_scroll_bar()
	# Re-read the range so reflow/resizing cannot leave an obsolete endpoint.
	scrollbar.value = progress * maxf(0, scrollbar.max_value - scrollbar.page)


func _stop_auto_scroll() -> void:
	$ScrollDelay.stop()
	if _scroll_tween:
		_scroll_tween.kill()


func _on_text_gui_input(event: InputEvent) -> void:
	if event is InputEventPanGesture or event is InputEventScreenDrag:
		_stop_auto_scroll()
	elif (
		event is InputEventMouseButton
		and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
	):
		_stop_auto_scroll()


func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_close()


func _close() -> void:
	_stop_auto_scroll()
	AudioManager.play_click_sound()
	GameManager.change_state(Constants.GameState.MAIN_MENU)
	queue_free.call_deferred()
