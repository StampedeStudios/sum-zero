class_name ScalableArea
extends Node2D

const CELL_SIZE: float = 128
const START_SIZE: float = 10

var is_scaling: bool
var _is_horizontal: bool
var _extend_limit: int
var min_scale: float
var area_limit: Vector2i
var target_scale: float
var _current_scale: int
var _reachable_tiles: Array[Tile]

signal clicked(me: ScalableArea)
signal scale_changed

@onready var area = $Area


func init(is_horizontal: bool, extend_limit: int, reachable_tiles: Array[Tile]) -> void:
	_is_horizontal = is_horizontal
	_extend_limit = extend_limit
	_reachable_tiles = reachable_tiles
	min_scale = START_SIZE / CELL_SIZE

	if _is_horizontal:
		if _extend_limit < 0:
			rotation_degrees = 180
			area_limit = Vector2i(_extend_limit, 0)
		else:
			area_limit = Vector2i(0, _extend_limit)
	else:
		if _extend_limit < 0:
			rotation_degrees = 270
			area_limit = Vector2i(_extend_limit, 0)
		else:
			rotation_degrees = 90
			area_limit = Vector2i(0, _extend_limit)

	area.scale = Vector2(min_scale, 1)
	area.position.x = -START_SIZE / 2


func _process(_delta: float) -> void:
	var fixed_scale: int
	# inizio a scalare mentre il mouse è premuto
	if is_scaling:
		var tile_distance: float
		if _is_horizontal:
			tile_distance = (get_global_mouse_position().x - global_position.x) / CELL_SIZE
		else:
			tile_distance = (get_global_mouse_position().y - global_position.y) / CELL_SIZE

		if tile_distance >= area_limit.x and tile_distance <= area_limit.y:
			target_scale = abs(tile_distance)
			fixed_scale = round(target_scale)
			_apply_scaling(target_scale)
			_update_changed_tiles(fixed_scale)

	# smetto di scalare e imposto la scala al piu vicino snap
	if is_scaling and Input.is_action_just_released("click"):
		clicked.emit(self)
		_apply_scaling(fixed_scale)
		_update_changed_tiles(fixed_scale)
		scale_changed.emit()


func _update_changed_tiles(fixed_scale: int) -> void:
	if fixed_scale != _current_scale:
		var changing_tile: Tile

		if fixed_scale > _current_scale:
			while _current_scale < fixed_scale:
				_current_scale += 1
				changing_tile = _reachable_tiles[_current_scale - 1]
				changing_tile.alter_value(-1)
		else:
			while _current_scale > fixed_scale:
				changing_tile = _reachable_tiles[_current_scale - 1]
				_current_scale -= 1
				changing_tile.alter_value(1)


func _apply_scaling(_new_scale: float) -> void:
	area.scale.x = min_scale + _new_scale
	area.position.x = -START_SIZE / 2 + _new_scale / 2 * CELL_SIZE


func _on_area_2d_mouse_entered() -> void:
	area.material.set_shader_parameter("is_hovered", true)


func _on_area_2d_mouse_exited() -> void:
	area.material.set_shader_parameter("is_hovered", false)


func _on_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed("click"):
			clicked.emit(self)
