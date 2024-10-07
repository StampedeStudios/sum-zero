extends Node2D

const REMOVE_NAME: String = "REMOVE"

@export var standard_color: Color = Color.GRAY
@export var remove_icon: Texture2D
@export var sliders_list: Array[SliderData]

var slider_index: int

@onready var item_list = %ItemList
@onready var slider = $Slider
@onready var slider_effect = $SliderEffect
@onready var hud = $HUD


func _ready():
	hud.visible = false
	slider_effect.visible = false
	slider_index = -1
	slider.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, standard_color)
	item_list.add_item(REMOVE_NAME, remove_icon)
	for slider_item in sliders_list:
		item_list.add_item(slider_item.name, slider_item.area_effect_texture)
	set_item_list_position()


func set_item_list_position() -> void:
	var offset: Vector2
	item_list.size.y = item_list.item_count * item_list.fixed_icon_size.y + 20
	match int(self.rotation_degrees):
		0:
			offset.x = GameManager.cell_size / 2
			offset.y = -item_list.size.y / 2 * self.scale.y
		90:
			offset.x = -item_list.size.x / 2 * self.scale.x
			offset.y = GameManager.cell_size / 2
		180:
			offset.x = -item_list.size.x * self.scale.x - GameManager.cell_size / 2
			offset.y = -item_list.size.y / 2 * self.scale.y
		270:
			offset.x = -item_list.size.x / 2 * self.scale.x
			offset.y = -item_list.size.y * self.scale.y - GameManager.cell_size / 2

	item_list.position = self.global_position + offset
	item_list.scale = self.scale


func _on_item_list_item_selected(index):
	var selected_slider_name: String = item_list.get_item_text(index)

	if selected_slider_name == REMOVE_NAME:
		clear_slider()
	else:
		for i in range(0, sliders_list.size()):
			if sliders_list[i].name == selected_slider_name:
				slider_effect.texture = sliders_list[i].area_effect_texture
				slider_effect.visible = true
				slider_index = i
				break


func _on_item_list_empty_clicked(_at_position, _mouse_button_index):
	item_list.deselect_all()
	_toggle_hud(false)


func _on_collision_input_event(_viewport, _event, _shape_idx):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_toggle_hud(true)


func _on_panel_gui_input(_event):
	if _event is InputEventMouse:
		if _event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
			_toggle_hud(false)


func _toggle_hud(hud_visibility: bool) -> void:
	hud.visible = hud_visibility
	self.z_index = 10 if hud_visibility else 0


func clear_slider() -> void:
	slider_effect.visible = false
	slider_index = -1


func get_slider_data() -> SliderData:
	if slider_index < 0:
		return null

	return sliders_list[slider_index]
