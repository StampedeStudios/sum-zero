## Keeps the editing board inside the space reserved by the toolbars.
extends Control


func _ready() -> void:
	resized.connect(_update_board)
	item_rect_changed.connect(_update_board)


func _update_board() -> void:
	if is_instance_valid(GameManager.level_builder) and size.x > 0 and size.y > 0:
		GameManager.level_builder.set_board_rect(get_global_rect())
