class_name SliderArea
extends Node2D

signal scale_change

var _is_scaling: bool
var _is_horizontal: bool
var _current_scale: int
var _reachable_cells: Array[Cell]
var _last_scale: int
var _moves: int
var _orientation: Vector2
var _area_effect: GlobalConst.AreaEffect
var _area_behavior: GlobalConst.AreaBehavior
var _new_cell_size: float = GameManager.cell_size
var _is_manually_controlled: bool = false
var _is_extended: bool = false
var target_scale: float


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
	if _is_scaling:
		if _is_manually_controlled:
			if Input.is_action_just_released(Literals.Inputs.LEFT_CLICK):
				release_handle()
				return
				
			var drag_direction: Vector2
			var tile_distance: float

			if _is_horizontal:
				tile_distance = get_global_mouse_position().x - ray.global_position.x
				drag_direction = Vector2(tile_distance, 0).normalized()
			else:
				tile_distance = get_global_mouse_position().y - ray.global_position.y
				drag_direction = Vector2(0, tile_distance).normalized()

			if drag_direction == _orientation:
				tile_distance = abs(tile_distance) / _new_cell_size
			else:
				tile_distance = 0
			
			target_scale = clamp(tile_distance, 0, _moves)
		else:
			if _is_extended:
				target_scale += 10 * _delta
				if target_scale >= _moves:
					release_handle()
					return
			else:
				target_scale -= 10 * _delta
				if target_scale <= 0:
					release_handle()
					return
				
		_apply_scaling(target_scale)
		_update_changed_tiles(round(target_scale))


func release_handle() -> void:
	_is_scaling = false
	_apply_scaling(_current_scale)
	area.material.set_shader_parameter(Literals.Parameters.IS_SELECTED, false)

	if _current_scale != _last_scale:
		Ui.consume_move()
		scale_change.emit()


func _update_changed_tiles(fixed_scale: int) -> void:
	if fixed_scale != _current_scale:
		var changing_cell: Cell

		if fixed_scale > _current_scale:
			while _current_scale < fixed_scale:
				_current_scale += 1
				changing_cell = _reachable_cells[_current_scale - 1]
				changing_cell.alter_value(self, _area_effect)
		else:
			while _current_scale > fixed_scale:
				changing_cell = _reachable_cells[_current_scale - 1]
				_current_scale -= 1
				changing_cell.alter_value(self, _area_effect)


func _apply_scaling(_new_scale: float) -> void:
	area.size.x = GlobalConst.HANDLE_SIZE + _new_scale * GlobalConst.CELL_SIZE
	if _is_manually_controlled:
		handle.position.x = GlobalConst.HANDLE_SIZE + _new_scale * GlobalConst.CELL_SIZE


func _on_handle_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			match _area_behavior:
				# move the area handle manually with your finger
				GlobalConst.AreaBehavior.BY_STEP:
					area.material.set_shader_parameter(Literals.Parameters.IS_SELECTED, true)
					_check_limit()
					_last_scale = _current_scale
					_is_manually_controlled = true
					_is_scaling = true
				# extend the area to the maximum reachable cell
				GlobalConst.AreaBehavior.FULL:
					_check_limit()
					_is_extended = !_is_extended
					_is_manually_controlled = false
					_is_scaling = true


func _check_limit() -> void:
	var is_obstacle_slider: bool = _area_effect == GlobalConst.AreaEffect.BLOCK
	_moves = 0
	_reachable_cells.clear()
	
	ray.force_raycast_update()
	while ray.is_colliding():
		ray.target_position.x += GlobalConst.CELL_SIZE
		var cell: Cell = ray.get_collider().owner
		
		if !cell.is_blocked:
			# self is obstacle area and the cell is occupied by another slider
			if is_obstacle_slider and cell.is_occupied():
				break
			_moves += 1
			_reachable_cells.append(cell)
			ray.add_exception(ray.get_collider())
			ray.force_raycast_update()
		else:
			# self is obstacle area and the evaluated cell is blocked by the area itself
			if (is_obstacle_slider and _moves < _current_scale):
				_moves += 1
				_reachable_cells.append(cell)
				ray.add_exception(ray.get_collider())
				ray.force_raycast_update()
			else:
				break
				
	ray.clear_exceptions()
