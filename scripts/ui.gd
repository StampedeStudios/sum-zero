class_name UserInteface
extends Control

var moves_left: int:
	set = set_moves_left

@onready var next_level_button: TextureButton = %NextLevelButton
@onready var bottom_right_container = $BottomRightContainer
@onready var moves_left_txt: Label = %MovesLeft


func _ready() -> void:
	GameManager.level_end.connect(_spawn_next_level_button)
	GameManager.level_start.connect(func (): set_moves_left(GameManager.get_move_left()))
	set_moves_left(GameManager.get_move_left())


func set_moves_left(new_moves: int):
	moves_left = new_moves

	if moves_left >= 0:
		moves_left_txt.text = "%s" % String.num(moves_left)


func consume_move() -> void:
	moves_left -= 1


func _spawn_next_level_button() -> void:
	next_level_button.show()


func _on_next_level_button_pressed() -> void:
	GameManager.load_next_level()


func _on_clear_button_pressed() -> void:
	GameManager.reset_level()
