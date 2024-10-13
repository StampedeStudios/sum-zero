class_name BuilderSelection extends Control

signal backward_action
signal forward_action
signal special_action
signal remove_action

@export var backward_cell_texture: Texture2D
@export var forward_cell_texture: Texture2D
@export var special_cell_texture: Texture2D
@export var backward_slider_texture: Texture2D
@export var forward_slider_texture: Texture2D
@export var special_slider_texture: Texture2D

@onready var backward = %Backward
@onready var forward = %Forward
@onready var special = %Special
@onready var control = %Control
@onready var panel = %Panel


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	control.scale = GameManager.level_scale
	panel.size = get_viewport_rect().size


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = true
		_:
			self.visible = false


func init_selection(is_cell: bool, selected_piece: Node2D) -> void:
	if is_cell:
		backward.icon = backward_cell_texture
		forward.icon = forward_cell_texture
		special.icon = special_cell_texture
	else:
		backward.icon = backward_slider_texture
		forward.icon = forward_slider_texture
		special.icon = special_slider_texture

	control.global_position = selected_piece.global_position


func _on_backward_pressed():
	backward_action.emit()


func _on_forward_pressed():
	forward_action.emit()


func _on_remove_pressed():
	remove_action.emit()


func _on_special_pressed():
	special_action.emit()


func _on_panel_gui_input(event):
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(GlobalConst.GameState.BUILDER_IDLE)
