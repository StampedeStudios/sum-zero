class_name LevelPage extends Control

signal level_deleted

const PAGE_SIZE := 9

var _level_buttons: Array[LevelButton]
var _placeholder_buttons: Array[PlaceholderButton]

@onready var level_grid: GridContainer = %LevelGrid
@onready var margin: MarginContainer = %Margin


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)
	level_grid.add_theme_constant_override("h_separation", GameManager.vertical_margin)
	level_grid.add_theme_constant_override("v_separation", GameManager.vertical_margin)
	

func toggle_page(page_visible: bool) -> void:
	if page_visible:
		level_grid.show()
	else:
		level_grid.hide()
		_unfill_grid.call_deferred()
		_remove_extra_buttons.call_deferred()


func update_page(world: GlobalConst.LevelGroup, page: int) -> void:
	_unfill_grid()

	var first_level: int = (page - 1) * PAGE_SIZE + 1
	var last_level: int = page * PAGE_SIZE
	var levels_progress: Array[LevelProgress]
	levels_progress = GameManager.get_page_levels(world, first_level, last_level)
	
	# add level buttons
	for i in range(levels_progress.size()):
		var button : LevelButton
		if _level_buttons.is_empty():
			button = LevelButton.new()
			button.on_delete_level_button.connect(_on_level_deleted)
			level_grid.add_child(button)
		else:
			button = _level_buttons.pop_back() as LevelButton
		if button.get_parent() == null:
			level_grid.add_child(button)
		var id := (page - 1) * PAGE_SIZE + i
		button.construct(id, levels_progress[i], world)
		level_grid.move_child(button, i)
	
	# add placeholder when level buttons don't fill the page
	for i in range(levels_progress.size(), PAGE_SIZE):
		var button: PlaceholderButton
		if _placeholder_buttons.is_empty():
			button = PlaceholderButton.new()
			level_grid.add_child(button)
		else:
			button = _placeholder_buttons.pop_back() as PlaceholderButton
		if button.get_parent() == null:
			level_grid.add_child(button)
		level_grid.move_child(button, i)
		button.construct(world == GlobalConst.LevelGroup.CUSTOM)
	_remove_extra_buttons()


func _unfill_grid() -> void:
	for child in level_grid.get_children():
		if child is LevelButton:
			_level_buttons.append(child)
		elif child is PlaceholderButton:
			_placeholder_buttons.append(child)
		else:
			child.queue_free.call_deferred()


func _remove_extra_buttons() -> void:
	for button in _level_buttons:
		button.queue_free.call_deferred()
	_level_buttons.clear()
	for button in _placeholder_buttons:
		button.queue_free.call_deferred()
	_placeholder_buttons.clear()
	

func _on_level_deleted() -> void:
	level_deleted.emit()
