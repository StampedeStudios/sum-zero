class_name BuilderSelection extends Control

signal backward_action
signal forward_action
signal special_action
signal remove_action

const STD_SIZE := Vector2(GlobalConst.CELL_SIZE, GlobalConst.CELL_SIZE)

@export var backward_cell_texture: Texture2D
@export var forward_cell_texture: Texture2D
@export var special_cell_texture: Texture2D
@export var backward_slider_texture: Texture2D
@export var forward_slider_texture: Texture2D
@export var special_slider_texture: Texture2D

@onready var backward: Button = %Backward
@onready var forward: Button = %Forward
@onready var special: Button = %Special
@onready var remove: Button = %Remove
@onready var control: Control = %Control
@onready var panel: Panel = %Panel


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	control.scale = GameManager.level_scale
	panel.size = get_viewport_rect().size


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		_:
			self.visible = false


func init_selection(is_cell: bool, center: Vector2, area_size: Vector2) -> void:
	const AREA_DISTANCE: int = 16
	if is_cell:
		backward.icon = backward_cell_texture
		forward.icon = forward_cell_texture
		special.icon = special_cell_texture
	else:
		backward.icon = backward_slider_texture
		forward.icon = forward_slider_texture
		special.icon = special_slider_texture

	backward.position.x = -area_size.x / 2 - AREA_DISTANCE
	forward.position.x = area_size.x / 2 + AREA_DISTANCE
	special.position.y = -area_size.y / 2 - AREA_DISTANCE - remove.size.y
	remove.position.y = area_size.y / 2 + AREA_DISTANCE
	control.global_position = center
	self.show.call_deferred()


func _on_backward_pressed():
	AudioManager.play_click_sound()
	backward_action.emit()


func _on_forward_pressed():
	AudioManager.play_click_sound()
	forward_action.emit()


func _on_remove_pressed():
	AudioManager.play_click_sound()
	remove_action.emit()


func _on_special_pressed():
	AudioManager.play_click_sound()
	special_action.emit()


func _on_panel_gui_input(event):
	if event is InputEventMouse and event.is_action_released(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)
