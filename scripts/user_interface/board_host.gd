## Reserves layout space for a separately-rendered Node2D puzzle board.
extends Control

var _level_manager: LevelManager


func _ready() -> void:
	resized.connect(_update_board)
	item_rect_changed.connect(_update_board)


func bind_level_manager(manager: LevelManager) -> void:
	_level_manager = manager
	_update_board()


func _update_board() -> void:
	if is_instance_valid(_level_manager) and size.x > 0 and size.y > 0:
		_level_manager.set_board_rect(get_global_rect())
