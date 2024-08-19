extends Control

var _timer: Timer
var _total_seconds: int

@onready var timer_txt: Label = %Timer
@onready var next_level_button: TextureButton = %NextLevelButton


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_increment_seconds)

	add_child(_timer)
	GameManager.level_start.connect(_start_timer)
	GameManager.level_end.connect(_spawn_next_level_button)


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
	GameManager.load_level()


func _on_clear_button_pressed() -> void:
	GameManager.load_level()
