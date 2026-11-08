class_name BuilderSelection extends Control

signal backward_action
signal forward_action
signal special_action
signal remove_action

const STD_SIZE := Vector2(Constants.Sizes.CELL_SIZE, Constants.Sizes.CELL_SIZE)
const BUTTON_SIZE := Vector2(44, 44)

@export var backward_cell_texture: Texture2D
@export var forward_cell_texture: Texture2D
@export var special_cell_texture: Texture2D
@export var backward_slider_texture: Texture2D
@export var forward_slider_texture: Texture2D
@export var special_slider_texture: Texture2D

var _center: Vector2
var _area_size: Vector2

@onready var backward: Button = %Backward
@onready var forward: Button = %Forward
@onready var special: Button = %Special
@onready var remove: Button = %Remove
@onready var control: Control = %Control
@onready var panel: Panel = %Panel


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button: Button in [backward, forward, special, remove]:
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.theme_type_variation = &"IconOnlyButton"
		button.size = BUTTON_SIZE
		button.pivot_offset = BUTTON_SIZE / 2


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU, Constants.GameState.LEVEL_PICK:
			self.queue_free.call_deferred()
		_:
			self.visible = false


func init_selection(is_cell: bool, center: Vector2, area_size: Vector2) -> void:
	_center = GameManager.level_builder.grid.to_local(center)
	_area_size = area_size
	if is_cell:
		backward.icon = backward_cell_texture
		forward.icon = forward_cell_texture
		special.icon = special_cell_texture
	else:
		backward.icon = backward_slider_texture
		forward.icon = forward_slider_texture
		special.icon = special_slider_texture

	_update_layout()
	self.show.call_deferred()


func _process(_delta: float) -> void:
	if visible and is_instance_valid(GameManager.level_builder):
		_update_layout()


func _update_layout() -> void:
	var grid := GameManager.level_builder.grid
	var center := grid.to_global(_center)
	var half_area := _area_size * grid.global_scale / 2
	control.global_position = Vector2.ZERO
	backward.position = center + Vector2(-half_area.x - 6 - BUTTON_SIZE.x, -BUTTON_SIZE.y / 2)
	forward.position = center + Vector2(half_area.x + 6, -BUTTON_SIZE.y / 2)
	special.position = center + Vector2(-BUTTON_SIZE.x / 2, -half_area.y - 6 - BUTTON_SIZE.y)
	remove.position = center + Vector2(-BUTTON_SIZE.x / 2, half_area.y + 6)
	var limit := get_viewport_rect().size - BUTTON_SIZE - Vector2.ONE * 8
	for button: Button in [backward, forward, special, remove]:
		button.position = button.position.clamp(Vector2.ONE * 8, limit)


func _on_backward_pressed() -> void:
	AudioManager.play_click_sound()
	backward_action.emit()


func _on_forward_pressed() -> void:
	AudioManager.play_click_sound()
	forward_action.emit()


func _on_remove_pressed() -> void:
	AudioManager.play_click_sound()
	remove_action.emit()


func _on_special_pressed() -> void:
	AudioManager.play_click_sound()
	special_action.emit()


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_released(Literals.Inputs.LEFT_CLICK):
		GameManager.change_state(Constants.GameState.BUILDER_IDLE)
