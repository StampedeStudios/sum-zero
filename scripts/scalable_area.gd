class_name ScalableArea
extends Node2D

const MINUS = preload("res://assets/ui/minus.png")
const PLUS = preload("res://assets/ui/plus.png")

var is_scaling: bool
var _is_horizontal: bool
var _extend_limit: int
var min_scale: float
var area_limit: Vector2i
var target_scale: float
var fixed_scale: int
var _current_scale: int
var _reachable_tiles: Array[Tile]
var _area_increment: bool

signal click
signal enter(me: ScalableArea)
signal exit(me: ScalableArea)
signal scale_change

@onready var area = $Area
@onready var handle = $Handle
@onready var icon = $Icon


func init(is_horizontal: bool, extend_limit: int, reachable_tiles: Array[Tile], area_increment: bool) -> void:
	_is_horizontal = is_horizontal
	_extend_limit = extend_limit
	_reachable_tiles = reachable_tiles
	_area_increment = area_increment
	min_scale = GlobalConst.HANDLE_SIZE / GlobalConst.CELL_SIZE

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

	handle.scale = Vector2(min_scale, 1)
	handle.position.x = -GlobalConst.HANDLE_SIZE / 2
	area.scale = Vector2(min_scale, 1)
	area.position.x = -GlobalConst.HANDLE_SIZE / 2
	icon.position.x = -GlobalConst.HANDLE_SIZE / 2
	icon.rotation_degrees = 90
	icon.texture = PLUS if area_increment else MINUS

func _process(_delta: float) -> void:
	# inizio a scalare mentre il mouse è premuto
	if is_scaling:
		var tile_distance: float
		if _is_horizontal:
			tile_distance = (
				(get_global_mouse_position().x - global_position.x) / GlobalConst.CELL_SIZE
			)
		else:
			tile_distance = (
				(get_global_mouse_position().y - global_position.y) / GlobalConst.CELL_SIZE
			)

		target_scale = abs(clamp(tile_distance, area_limit.x, area_limit.y))
		fixed_scale = round(target_scale)
		_apply_scaling(target_scale)
		_update_changed_tiles()


func release_handle() -> void:
	is_scaling = false
	_apply_scaling(fixed_scale)
	_update_changed_tiles()
	scale_change.emit()


func _update_changed_tiles() -> void:
	if fixed_scale != _current_scale:
		var changing_tile: Tile

		if fixed_scale > _current_scale:
			while _current_scale < fixed_scale:
				_current_scale += 1
				changing_tile = _reachable_tiles[_current_scale - 1]
				changing_tile.alter_value(self, _area_increment)
		else:
			while _current_scale > fixed_scale:
				changing_tile = _reachable_tiles[_current_scale - 1]
				_current_scale -= 1
				changing_tile.alter_value(self, _area_increment)


func _apply_scaling(_new_scale: float) -> void:
	area.scale.x = min_scale + _new_scale
	area.position.x = -GlobalConst.HANDLE_SIZE / 2 + _new_scale / 2 * GlobalConst.CELL_SIZE


func toggle_highlight(is_on: bool) -> void:
	area.material.set_shader_parameter("is_hovered", is_on)


func _on_handle_mouse_exited():
	exit.emit(self)


func _on_handle_mouse_entered():
	enter.emit(self)


func _on_handle_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed("click"):
			click.emit()
