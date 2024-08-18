extends Node2D

const CELL_SIZE = 128

var is_scaling: bool
var starting_position: Vector2
var is_horizontal: bool = true


func _ready() -> void:
	global_position = Vector2(200, 200)
	starting_position = global_position

	if is_horizontal:
		scale = Vector2(0.1, 1)
	else:
		scale = Vector2(1, 0.1)


func _process(delta: float) -> void:
	if is_scaling:
		var ending_position: Vector2 = get_global_mouse_position()  # TODO: clamp

		if is_horizontal:
			var distance = ending_position.x - starting_position.x
			var scale_to_apply = distance / CELL_SIZE
			scale.x = scale_to_apply
			global_position = starting_position + Vector2(distance / 2, 0)
		else:
			var distance = ending_position.y - starting_position.y
			var scale_to_apply = distance / CELL_SIZE
			scale.y = scale_to_apply
			global_position = starting_position + Vector2(0, distance / 2)

	if Input.is_action_just_released("click"):
		is_scaling = false


func _on_area_2d_mouse_entered() -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouse:
		if event.is_action_pressed("click"):
			is_scaling = true
