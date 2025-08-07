## Handles logic for an individual slider.
##
## Each slider has a maximum extension length and a specific effect.
## Sliders are gradually extent and their effect is applied on each tile they cover.
class_name SliderArea extends Node2D

## Communicate grid variations indicating if a slider movement has changed the game state.
##
## Sometime a slider movement does not change the grid state, for example when a PLUS slider
## is moved toward a direction for at least a tile and than brought back at the exact same position.
signal alter_grid(is_effective_move: bool)

const SPAWN_TIME: float = 0.1
const SLIDER_COLLECTION = preload("res://assets/resources/utility/slider_collection.tres")
const MAX_EXTENSION: int = 5 * 256
const MAX_PITCH: float = 1.5
const SFX_STEP: int = 64
const HANDLE_START: int = 110

var _target_scale: float
var _is_scaling: bool
var _is_horizontal: bool
var _current_scale: int
var _reachable_cells: Array[Cell]
var _last_scale: int
var _max_scale: int
var _orientation: Vector2
var _data: SliderData
var _new_cell_size: float = GameManager.cell_size
var _is_manually_controlled: bool = false
var _is_extended: bool = false
var _blocking_sprite: Array[Sprite2D]
var _last_percentage: float = 0.1
var _last_affected_cells: Dictionary[Cell, int]

@onready var area_outline: NinePatchRect = %AreaOutline
@onready var area_effect: Sprite2D = %AreaEffect
@onready var area_behavior: Sprite2D = %AreaBehavior
@onready var handle: Node2D = %Handle
@onready var body: Sprite2D = %Body
@onready var start: Node2D = %Start


## Gradually updates extension of the slider and apply its effect on each affected tile.
func _process(_delta: float) -> void:
	if _is_scaling:

		if _is_manually_controlled:
			if Input.is_action_just_released(Literals.Inputs.LEFT_CLICK):
				release_handle()
				return

			var drag_direction: Vector2
			var tile_distance: float

			if _is_horizontal:
				tile_distance = get_global_mouse_position().x - start.global_position.x
				drag_direction = Vector2(tile_distance, 0).normalized()
			else:
				tile_distance = get_global_mouse_position().y - start.global_position.y
				drag_direction = Vector2(0, tile_distance).normalized()

			if drag_direction == _orientation:
				tile_distance = abs(tile_distance) / _new_cell_size
			else:
				tile_distance = 0

			_target_scale = clamp(tile_distance, 0, _max_scale)
		else:
			if _is_extended:
				_target_scale += 10 * _delta
				if _target_scale >= _max_scale:
					_is_scaling = false
					release_handle()
					return
			else:
				_target_scale -= 10 * _delta
				if _target_scale <= 0:
					_is_scaling = false
					release_handle()
					return

		_apply_scaling(_target_scale)
		_update_changed_tiles(round(_target_scale))


func init_slider(data: SliderData, reachable: Array[Cell]) -> void:
	_data = data
	_reachable_cells = reachable
	body.hide()

	var color: Color = GameManager.palette.slider_colors.get("BACKGROUND")
	body.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)

	area_outline.texture = SLIDER_COLLECTION.get_outline_texture(data.area_behavior)
	color = GameManager.palette.slider_colors.get("OUTLINE")
	area_outline.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)

	area_effect.texture = SLIDER_COLLECTION.get_effect_texture(data.area_effect)
	if data.area_effect != Constants.Sliders.Effect.BLOCK:
		var mat := ShaderMaterial.new()
		mat.shader = ResourceLoader.load("res://scripts/shaders/BasicTile.gdshader")

		match data.area_effect:
			Constants.Sliders.Effect.ADD:
				color = GameManager.palette.slider_colors.get("ADD")
			Constants.Sliders.Effect.SUBTRACT:
				color = GameManager.palette.slider_colors.get("SUBTRACT")
			Constants.Sliders.Effect.CHANGE_SIGN:
				color = GameManager.palette.slider_colors.get("CHANGE_SIGN")

		mat.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)
		area_effect.material = mat

	if data.area_behavior == Constants.Sliders.Behavior.FULL:
		area_behavior.texture = SLIDER_COLLECTION.get_behavior_texture(data.area_behavior)
		color = GameManager.palette.slider_colors.get("FULL")
	else:
		area_behavior.hide()

	_orientation = Vector2(round(cos(self.rotation)), round(sin(self.rotation)))
	_is_horizontal = _orientation.y == 0

	if _data.area_effect == Constants.Sliders.Effect.BLOCK:
		_create_blocked_cell()


func reset() -> void:
	_target_scale = 0
	_current_scale = 0
	_last_scale = 0
	_is_extended = false
	_apply_scaling(_current_scale)


func get_slider_position() -> Vector2:
	return handle.global_position


## Handles slider release clamping its extension to the closest tile border.
func release_handle() -> void:
	var move_count: bool
	_is_scaling = false
	_apply_scaling(_current_scale)
	area_outline.material.set_shader_parameter(Literals.Parameters.IS_SELECTED, false)

	if _current_scale != _last_scale:
		_last_scale = _current_scale
		move_count = true
	else:
		for cell: Cell in _last_affected_cells:
			if cell.get_cell_value() != _last_affected_cells.get(cell):
				move_count = true
				break

	alter_grid.emit(move_count)


## Handles touch event for a slider.
##
## If it is a manual slider, sets up the state of the slider to update each tile.
## If it is an automatic slider, fully extends it to reach its maximum length.
func activate_slider() -> void:
	match _data.area_behavior:
		# Moves the area handle manually with the finger.
		Constants.Sliders.Behavior.BY_STEP:
			area_outline.material.set_shader_parameter(Literals.Parameters.IS_SELECTED, true)
			_check_limit()
			_last_scale = _current_scale
			_is_manually_controlled = true
			_is_scaling = true
			_last_affected_cells.clear()
			for cell_index in range(_current_scale):
				var cell: Cell = _reachable_cells[cell_index]
				_last_affected_cells[cell] = cell.get_cell_value()

		# Extends the slider to the maximum length to cover the last reachable cell.
		Constants.Sliders.Behavior.FULL:
			_check_limit()
			_is_extended = !_is_extended
			_is_manually_controlled = false
			_is_scaling = true


func show_slider(animate: bool = true) -> void:
	if body.visible == false:
		body.show()

		if animate:
			body.scale = Vector2.ZERO
			create_tween().tween_property(body, "scale", Vector2.ONE, SPAWN_TIME)


func _create_blocked_cell() -> void:
	for i in range(_reachable_cells.size()):
		var sprite := Sprite2D.new()
		sprite.texture = SLIDER_COLLECTION.get_block_texture()
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = SLIDER_COLLECTION.get_block_shader()
		sprite.position.x = Constants.Sizes.CELL_SIZE * (i + 1)
		add_child.call_deferred(sprite)
		_blocking_sprite.append(sprite)


func _update_changed_tiles(fixed_scale: int) -> void:
	if fixed_scale != _current_scale:
		var changing_cell: Cell

		if fixed_scale > _current_scale:
			while _current_scale < fixed_scale:
				_current_scale += 1
				changing_cell = _reachable_cells[_current_scale - 1]
				changing_cell.alter_value(self, _data.area_effect)
		else:
			while _current_scale > fixed_scale:
				changing_cell = _reachable_cells[_current_scale - 1]
				_current_scale -= 1
				changing_cell.alter_value(self, _data.area_effect)


func _apply_scaling(new_scale: float) -> void:
	var area_extension := Constants.Sizes.SLIDER_SIZE + new_scale * Constants.Sizes.CELL_SIZE
	_play_sound(area_extension)
	area_outline.size.x = area_extension

	if _data.area_effect == Constants.Sliders.Effect.BLOCK:
		for i in range(0, _blocking_sprite.size()):
			_blocking_sprite[i].material.set_shader_parameter("percentage", new_scale - i)

	if _is_manually_controlled:
		handle.position.x = HANDLE_START + new_scale * Constants.Sizes.CELL_SIZE


func _check_limit() -> void:
	_max_scale = _current_scale
	for i: int in range(_current_scale, _reachable_cells.size()):
		var cell := _reachable_cells[i] as Cell
		match _data.area_effect:
			Constants.Sliders.Effect.BLOCK:
				if cell.is_cell_blocked() or cell.is_occupied():
					break
			_:
				if cell.is_cell_blocked():
					break
		_max_scale += 1


func _play_sound(extension: float) -> void:
	var percentage: float = abs(snapped(extension, SFX_STEP))

	if percentage != _last_percentage:
		var pitch: float = clamp(MAX_PITCH * extension / MAX_EXTENSION, 0.3, MAX_PITCH)

		_last_percentage = percentage
		AudioManager.play_slider_sound(pitch)
