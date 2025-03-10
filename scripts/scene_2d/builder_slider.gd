class_name BuilderSlider extends Node2D

signal on_slider_change(ref: BuilderSlider, data: SliderData)

const SLIDER_COLLECTION = preload("res://assets/resources/utility/slider_collection.tres")

var _data: SliderData
var _is_valid: bool = false

@onready var slider: Sprite2D = %Slider
@onready var slider_effect: Sprite2D = %SliderEffect
@onready var slider_behavior: Sprite2D = %SliderBehavior


func _ready() -> void:
	_data = SliderData.new()
	slider_effect.visible = false
	slider_behavior.visible = false
	var color: Color = GameManager.palette.builder_slider_color
	slider.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)


func _on_collision_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.on_state_change.connect(_on_state_change)
		GameManager.change_state(GlobalConst.GameState.BUILDER_SELECTION)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.BUILDER_IDLE:
			self.z_index = 0
			GameManager.level_builder.move_grid(Vector2.ZERO)
			_toggle_ui.call_deferred(false)

		GlobalConst.GameState.BUILDER_SELECTION:
			self.z_index = 10
			_check_screen_margin.call_deferred()


func _check_screen_margin() -> void:
	var margin: float
	var offset: Vector2
	var screen_size: Vector2

	margin = GlobalConst.HALF_BUILDER_SELECTION * GameManager.level_scale.x
	screen_size = get_viewport_rect().size
	# orizzontal check
	if global_position.x < margin:
		offset.x = margin - global_position.x
	elif global_position.x > screen_size.x - margin:
		offset.x = screen_size.x - margin - global_position.x
	# vertical check
	if global_position.y < margin:
		offset.y = margin - global_position.y
	elif global_position.y > screen_size.y - margin:
		offset.y = screen_size.y - margin - global_position.y
	# valid offset
	if offset != Vector2.ZERO:
		await GameManager.level_builder.move_grid(offset)
		_toggle_ui.call_deferred(true)
	else:
		_toggle_ui.call_deferred(true)


func _toggle_ui(ui_visible: bool) -> void:
	if ui_visible:
		GameManager.builder_selection.backward_action.connect(_previous_effect)
		GameManager.builder_selection.forward_action.connect(_next_effect)
		GameManager.builder_selection.special_action.connect(_next_behavior)
		GameManager.builder_selection.remove_action.connect(clear_slider)
		var size: Vector2
		if int(rotation_degrees) == 0 or int(rotation_degrees) == 180:
			size = Vector2(GlobalConst.SLIDER_SIZE, GlobalConst.CELL_SIZE)
		else:
			size = Vector2(GlobalConst.CELL_SIZE, GlobalConst.SLIDER_SIZE)
		GameManager.builder_selection.init_selection(false, self.global_position, size)
	else:
		GameManager.on_state_change.disconnect(_on_state_change)
		GameManager.builder_selection.backward_action.disconnect(_previous_effect)
		GameManager.builder_selection.forward_action.disconnect(_next_effect)
		GameManager.builder_selection.special_action.disconnect(_next_behavior)
		GameManager.builder_selection.remove_action.disconnect(clear_slider)


func _previous_effect() -> void:
	var i: int
	i = _data.area_effect
	if _is_valid:
		i -= 1
	if i < 0:
		i = GlobalConst.AreaEffect.size() - 1
	_data.area_effect = GlobalConst.AreaEffect.values()[i]
	_change_aspect()
	on_slider_change.emit(self, _data)


func _next_effect() -> void:
	var i: int
	i = _data.area_effect
	if _is_valid:
		i += 1
	if i > GlobalConst.AreaEffect.size() - 1:
		i = 0
	_data.area_effect = GlobalConst.AreaEffect.values()[i]
	_change_aspect()
	on_slider_change.emit(self, _data)


func _next_behavior() -> void:
	var i: int
	i = _data.area_behavior
	i += 1
	if i > GlobalConst.AreaBehavior.size() - 1:
		i = 0
	_data.area_behavior = GlobalConst.AreaBehavior.values()[i]
	_change_aspect()
	on_slider_change.emit(self, _data)


func _change_aspect() -> void:
	var color: Color
	_is_valid = true	
	
	color = GameManager.palette.slider_colors.get("BG")
	slider.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)

	slider_effect.visible = true
	slider_effect.texture = SLIDER_COLLECTION.get_effect_texture(_data.area_effect)
	if _data.area_effect == GlobalConst.AreaEffect.BLOCK:
		slider_effect.material = null
	else:
		if !slider_effect.material:
			var mat := ShaderMaterial.new()
			mat.shader = ResourceLoader.load("res://scripts/shaders/BasicTile.gdshader")
			slider_effect.material = mat
		match _data.area_effect:
			GlobalConst.AreaEffect.ADD:
				color = GameManager.palette.slider_colors.get("ADD")			
			GlobalConst.AreaEffect.SUBTRACT:
				color = GameManager.palette.slider_colors.get("SUBTRACT")
			GlobalConst.AreaEffect.CHANGE_SIGN:
				color = GameManager.palette.slider_colors.get("CHANGE_SIGN")
		slider_effect.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)		
	
	if _data.area_behavior == GlobalConst.AreaBehavior.FULL:
		slider_behavior.show()
		slider_behavior.texture = SLIDER_COLLECTION.get_behavior_texture(_data.area_behavior)
		color = GameManager.palette.slider_colors.get("FULL")
		slider_behavior.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)
	else:
		slider_behavior.hide()



func set_slider_data(slider_data: SliderData) -> void:
	_data = slider_data.duplicate()
	_change_aspect()


func clear_slider() -> void:
	var color: Color = GameManager.palette.builder_slider_color
	slider.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, color)
	_data = SliderData.new()
	slider_effect.visible = false
	slider_behavior.visible = false
	_is_valid = false
	on_slider_change.emit(self, null)
