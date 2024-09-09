class_name SliderArea
extends Node2D

signal scale_change

var is_scaling: bool
var _is_horizontal: bool
var _current_scale: int
var _reachable_tiles: Array[Tile]
var _area_increment: bool
var _last_scale: int
var _moves: int
var _orientation: Vector2
var _area_effect: GlobalConst.AreaEffect
var _area_behavior: GlobalConst.AreaBehavior

@onready var area: NinePatchRect = $Area
@onready var handle: Area2D = $Handle
@onready var icon: Sprite2D = $Icon
@onready var ray: RayCast2D = $Ray


func init(slider_data: SliderData) -> void:
	icon.texture = slider_data.area_effect_texture
	
	_orientation = Vector2(round(cos(self.rotation)), round(sin(self.rotation)))
	_is_horizontal = _orientation.y == 0
	_area_effect = slider_data.area_effect
	_area_behavior = slider_data.area_behavior


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
			tile_distance = abs(tile_distance / GameManager.cell_size)
		else:
			tile_distance = 0
			
		var target_scale: float
		target_scale = clamp(tile_distance, 0, _moves)
		_apply_scaling(target_scale)
		_update_changed_tiles(round(target_scale))

		if Input.is_action_just_released("click"):
			release_handle()


func release_handle() -> void:
	if _current_scale != _last_scale:
		Ui.consume_move()

	is_scaling = false
	_apply_scaling(_current_scale)
	scale_change.emit()
	area.material.set_shader_parameter("is_selected", false)


func _update_changed_tiles(fixed_scale: int) -> void:
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
	_reachable_tiles.clear()
	ray.force_raycast_update()
	while ray.is_colliding():
		var tile: Tile = ray.get_collider().owner
		if !tile.is_blocked:
			_moves += 1
			_reachable_tiles.append(tile)
			ray.add_exception(ray.get_collider())
			ray.force_raycast_update()
		else:
			break
	ray.clear_exceptions()
