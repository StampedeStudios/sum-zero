class_name SliderArea
extends Node2D

signal scale_change

@export var block_texture: Texture
@export var block_shader: Shader

var _target_scale: float
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
var _blocking_sprite: Array[Sprite2D]

@onready var area_outline: NinePatchRect = %AreaOutline
@onready var handle: Area2D = %Handle
@onready var area_effect: Sprite2D = %AreaEffect
@onready var area_behavior = %AreaBehavior
@onready var ray: RayCast2D = %Ray


func init_slider(data: SliderData) -> void:
	var collection: SliderCollection = GameManager.slider_collection
	area_effect.texture = collection.get_effect_texture(data.area_effect)
	area_behavior.texture = collection.get_behavior_texture(data.area_behavior)
	_orientation = Vector2(round(cos(self.rotation)), round(sin(self.rotation)))
	_is_horizontal = _orientation.y == 0
	_area_effect = data.area_effect
	_area_behavior = data.area_behavior

	await get_tree().physics_frame
	if _area_effect == GlobalConst.AreaEffect.BLOCK:
		_check_limit.call_deferred()
		_create_blocked_cell.call_deferred()


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

			_target_scale = clamp(tile_distance, 0, _moves)
		else:
			if _is_extended:
				_target_scale += 10 * _delta
				if _target_scale >= _moves:
					release_handle()
					return
			else:
				_target_scale -= 10 * _delta
				if _target_scale <= 0:
					release_handle()
					return

		_apply_scaling(_target_scale)
		_update_changed_tiles(round(_target_scale))


func release_handle() -> void:
	_is_scaling = false
	_apply_scaling(_current_scale)
	area_outline.material.set_shader_parameter(Literals.Parameters.IS_SELECTED, false)

	if _current_scale != _last_scale:
		if GameManager.game_ui != null:
			GameManager.game_ui.consume_move()
		if GameManager.builder_test != null:
			GameManager.builder_test.add_move()
		scale_change.emit()


func _create_blocked_cell() -> void:
	for i in range(0, _moves):
		var sprite := Sprite2D.new()
		sprite.texture = block_texture
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = block_shader
		sprite.position.x = GlobalConst.CELL_SIZE * (i + 1)
		add_child.call_deferred(sprite)
		_blocking_sprite.append(sprite)


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
	area_outline.size.x = GlobalConst.SLIDER_SIZE + _new_scale * GlobalConst.CELL_SIZE
	if _area_effect == GlobalConst.AreaEffect.BLOCK:
		for i in range(0, _blocking_sprite.size()):
			_blocking_sprite[i].material.set_shader_parameter("percentage", _new_scale - i)

	if _is_manually_controlled:
		handle.position.x = GlobalConst.SLIDER_SIZE + _new_scale * GlobalConst.CELL_SIZE


func _on_handle_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			match _area_behavior:
				# move the area handle manually with your finger
				GlobalConst.AreaBehavior.BY_STEP:
					area_outline.material.set_shader_parameter(
						Literals.Parameters.IS_SELECTED, true
					)
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
	var is_obstacle_slider: bool
	is_obstacle_slider = _area_effect == GlobalConst.AreaEffect.BLOCK
	_moves = 0
	_reachable_cells.clear()
	ray.target_position.x = GlobalConst.CELL_SIZE / 2

	ray.force_raycast_update()
	while ray.is_colliding():
		ray.target_position.x += GlobalConst.CELL_SIZE
		var cell: Cell = ray.get_collider().owner

		if !cell.is_cell_blocked():
			# self is obstacle area and the cell is occupied by another slider
			if is_obstacle_slider and cell.is_occupied():
				break
			_moves += 1
			_reachable_cells.append(cell)
			ray.add_exception(ray.get_collider())
			ray.force_raycast_update()
		else:
			# self is obstacle area and the evaluated cell is blocked by the area itself
			if is_obstacle_slider and _moves < _current_scale:
				_moves += 1
				_reachable_cells.append(cell)
				ray.add_exception(ray.get_collider())
				ray.force_raycast_update()
			else:
				break
	ray.clear_exceptions()


func reset() -> void:
	_reachable_cells.clear()
	_target_scale = 0
	_current_scale = 0
	_last_scale = 0
	_is_extended = false
	_apply_scaling(_current_scale)
