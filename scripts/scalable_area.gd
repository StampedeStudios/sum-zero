class_name ScalableArea
extends Node2D

signal scale_change

const MINUS = preload("res://assets/ui/minus.png")
const PLUS = preload("res://assets/ui/plus.png")

var target_scale: float
var fixed_scale: int
var is_scaling: bool
var _is_horizontal: bool
var _current_scale: int
var _reachable_tiles: Array[Tile]
var _area_increment: bool
var _last_scale: int
var _moves: int
var _orientation: Vector2

@onready var area: NinePatchRect = $Area
@onready var handle = $Handle
@onready var icon = $Icon
@onready var ray = $Ray
	
	
func init(is_horizontal: bool, reachable_tiles: Array[Tile], area_increment: bool) -> void:
	_is_horizontal = is_horizontal
	_reachable_tiles = reachable_tiles
	_area_increment = area_increment

	icon.texture = PLUS if area_increment else MINUS
	_orientation = Vector2(round(cos(self.rotation)), round(sin(self.rotation)))
	
func _process(_delta: float) -> void:
	# inizio a scalare mentre il mouse è premuto
	if is_scaling:
		var tile_distance: float
		var drag_direction: Vector2
		if _is_horizontal:
			tile_distance = get_global_mouse_position().x - global_position.x
			drag_direction = Vector2(tile_distance, 0).normalized()
		else:
			tile_distance = get_global_mouse_position().y - global_position.y
			drag_direction = Vector2(0, tile_distance).normalized()
		
		if drag_direction == _orientation:
			tile_distance = abs(tile_distance / GameManager.CELL_SIZE)
		else:
			tile_distance = 0
			
		target_scale = clamp(tile_distance, 0, _moves)
		fixed_scale = round(target_scale)
		_apply_scaling(target_scale)
		_update_changed_tiles()

		if Input.is_action_just_released("click"):
			release_handle()


func release_handle() -> void:
	if _current_scale != _last_scale:
		Ui.consume_move()

	is_scaling = false
	_apply_scaling(fixed_scale)
	scale_change.emit()
	area.material.set_shader_parameter("is_selected", false)


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
	area.size.x = GlobalConst.HANDLE_SIZE + _new_scale * GlobalConst.CELL_SIZE
	handle.position.x = _new_scale * GlobalConst.CELL_SIZE


func _on_handle_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed("click"):
			area.material.set_shader_parameter("is_selected", true)
			_check_limit()
			_last_scale = _current_scale
			is_scaling = true


func _check_limit() -> void:
	_moves = 0
	ray.force_raycast_update()
	while ray.is_colliding():
		var tile: Tile = ray.get_collider().owner
		if !tile.is_blocked:
			_moves += 1
			ray.add_exception( ray.get_collider() )
			ray.force_raycast_update()
		else:
			break 		
	ray.clear_exceptions()
