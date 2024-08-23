extends Control

var _timer: Timer
var _total_seconds: int

@onready var timer_txt: Label = %Timer
@onready var next_level_button: TextureButton = %NextLevelButton
@onready var center_container = $CenterContainer
@onready var info_text: RichTextLabel = $CenterContainer/InfoText
@onready var bottom_right_container = $BottomRightContainer
@onready var bottom_left_container = $BottomLeftContainer
@onready var end_screen: AspectRatioContainer = $CenterContainer/EndScreen


func _ready() -> void:
	get_viewport().size_changed.connect(_update_ui_disposition)
	_update_ui_disposition()
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_increment_seconds)

	add_child(_timer)
	GameManager.level_start.connect(_start_timer)
	GameManager.level_end.connect(_spawn_next_level_button)
	GameManager.game_ended.connect(_on_game_ended)


func _start_timer() -> void:
	_total_seconds = 0
	timer_txt.text = "00:00"
	next_level_button.hide()

	_timer.start()
	_timer.paused = false


func _increment_seconds() -> void:
	_total_seconds += 1
	var minutes: int = int(_total_seconds / 60.0)
	var seconds: int = _total_seconds - 60 * minutes

	timer_txt.text = "%s:%s" % [String.num(minutes).pad_zeros(2), String.num(seconds).pad_zeros(2)]


func _spawn_next_level_button() -> void:
	next_level_button.show()
	_timer.paused = true


func _on_next_level_button_pressed() -> void:
	GameManager.load_next_level()


func _on_clear_button_pressed() -> void:
	info_text.visible = false
	center_container.visible = false
	GameManager.load_level()


func _update_ui_disposition() -> void:
	var v_size = get_viewport_rect().size
	center_container.position = v_size / 2 - center_container.size / 2
	bottom_left_container.position = Vector2(0, v_size.y - bottom_left_container.size.y)
	bottom_right_container.position = v_size - bottom_right_container.size


func _on_info_button_pressed():
	center_container.visible = !center_container.visible
	info_text.visible = !info_text.visible
	GameManager.toggle_level(!info_text.visible)
	_timer.paused = info_text.visible
	bottom_right_container.visible = !center_container.visible


func _on_game_ended() -> void:
	center_container.visible = true
	bottom_right_container.visible = false
	bottom_left_container.visible = false
	end_screen.visible = true
	GameManager.toggle_level(false)
	_timer.paused = true
