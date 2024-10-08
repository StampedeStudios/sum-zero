class_name BuilderSlider extends Node2D

signal on_slider_change(ref: BuilderSlider, data: SliderData)

const BUILDER_SELECTION = preload("res://packed_scene/user_interface/BuilderSelection.tscn")

var _is_valid: bool = false
var _data: SliderData

@onready var slider = %Slider
@onready var slider_effect = %SliderEffect
@onready var slider_behavior = %SliderBehavior


func _ready():
	_data = SliderData.new()
	slider_effect.visible = false
	slider_behavior.visible = false
	var shader_param := Literals.Parameters.BASE_COLOR
	var color := GameManager.palette.builder_slider_color
	slider.material.set_shader_parameter(shader_param, color)


func _on_collision_input_event(_viewport, _event, _shape_idx):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):			
			GameManager.on_state_change.connect(_on_state_change)
			GameManager.change_state(GlobalConst.GameState.BUILDER_SELECTION)


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:			
		GlobalConst.GameState.BUILDER_IDLE:
			self.z_index = 0
			_toggle_ui.call_deferred(false)
			
		GlobalConst.GameState.BUILDER_SELECTION:
			if !GameManager.builder_selection:
				var builder_selection: BuilderSelection 
				builder_selection = BUILDER_SELECTION.instantiate()
				get_tree().root.add_child.call_deferred(builder_selection)
				GameManager.builder_selection = builder_selection
			self.z_index = 10
			_toggle_ui.call_deferred(true)


func _toggle_ui(ui_visible: bool) -> void:
	if ui_visible:
		GameManager.builder_selection.backward_action.connect(_previous_effect)
		GameManager.builder_selection.forward_action.connect(_next_effect)
		GameManager.builder_selection.special_action.connect(_next_behavior)
		GameManager.builder_selection.remove_action.connect(clear_slider)
		GameManager.builder_selection.init_selection(false, self)
	else:
		GameManager.on_state_change.disconnect(_on_state_change)
		GameManager.builder_selection.backward_action.disconnect(_previous_effect)
		GameManager.builder_selection.forward_action.disconnect(_next_effect)
		GameManager.builder_selection.special_action.disconnect(_next_behavior)
		GameManager.builder_selection.remove_action.disconnect(clear_slider)


func _previous_effect() -> void:
	var i: int
	i = _data.area_effect 
	i -= 1
	if i < 0:
		i = GlobalConst.AreaEffect.size() - 1
	_data.area_effect = GlobalConst.AreaEffect.values()[i]
	_change_aspect()	
	on_slider_change.emit(self, _data)
	

func _next_effect() -> void:
	var i: int
	i = _data.area_effect 
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
	_is_valid = true
	slider_effect.visible = true
	slider_behavior.visible = true
	var collection := GameManager.slider_collection
	slider_effect.texture = collection.get_effect_texture(_data.area_effect)
	slider_behavior.texture = collection.get_behavior_texture(_data.area_behavior)
		

func clear_slider() -> void:
	slider_effect.visible = false
	slider_behavior.visible = false
	_is_valid = false
	on_slider_change.emit(self, null)
