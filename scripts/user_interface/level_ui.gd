class_name LevelUI extends Control

const PAGE_SIZE := 9

var _world: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN
var _current_page: int = 1
var _visible_buttons: Array

@onready var level_grid: GridContainer = %LevelGrid
@onready var left: TextureRect = %Left
@onready var right: TextureRect = %Right
@onready var title: Label = %Title


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	_update_content()


func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_START:
			self.queue_free.call_deferred()
		GlobalConst.GameState.BUILDER_IDLE:
			self.queue_free.call_deferred()
		GlobalConst.GameState.LEVEL_INSPECT:
			self.show()
		GlobalConst.GameState.LEVEL_PICK:
			self.show()
		_:
			self.hide()


func _on_exit_btn_pressed() -> void:
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _update_content() -> void:
	# Removing all old buttons if present
	for button in _visible_buttons:
		button.queue_free()
	_visible_buttons.clear()

	var levels_progress: Dictionary = GameManager.get_page_levels(_world, _current_page, PAGE_SIZE)

	for _name in levels_progress.keys():
		var button := LevelButton.new()
		var progress := levels_progress.get(_name) as LevelProgress
		button.construct(_name, progress, _world)
		_visible_buttons.append(button)

	# Fill remaining slots with placeholders
	for index in range(levels_progress.size(), PAGE_SIZE):
		var button := PlaceholderButton.new()
		button.construct(_world == GlobalConst.LevelGroup.CUSTOM)
		_visible_buttons.append(button)

	# Adding all new buttons
	for button in _visible_buttons:
		level_grid.add_child(button)

	var index_first: int = (_current_page - 1) * PAGE_SIZE + 1
	var index_last: int = _current_page * PAGE_SIZE
	title.text = "%d ~ %d" % [index_first, index_last]
	_update_buttons()


func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_current_page -= 1
		_update_content()


func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_current_page += 1
		_update_content()


func _update_buttons():
	if _current_page == 1:
		left.hide()
	else:
		left.show()

	if !GameManager.has_next_page(_world, _current_page, PAGE_SIZE):
		right.hide()
	else:
		right.show()


func _on_world_btn_pressed() -> void:
	_world = GlobalConst.LevelGroup.MAIN
	_current_page = 1
	_update_content()


func _on_custom_btn_pressed() -> void:
	_world = GlobalConst.LevelGroup.CUSTOM
	_current_page = 1
	_update_content()
