class_name LevelUI extends Control

const PAGE_SIZE := 9

var _world: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN
var _current_page: int = 1
var _level_buttons: Array[LevelButton]
var _placeholder_buttons: Array[PlaceholderButton]

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
	var first_level: int = (_current_page - 1) * PAGE_SIZE + 1
	var last_level: int = _current_page * PAGE_SIZE
	title.text = "%d ~ %d" % [first_level, last_level]
	
	var levels_progress: Dictionary 
	# get extra level for test next page
	levels_progress = GameManager.get_page_levels(_world, first_level, last_level + 1)
	_update_buttons(levels_progress.size() > PAGE_SIZE)
	
	var max_level_btn := mini(levels_progress.size(), PAGE_SIZE)
	# remove excess level button 
	while _level_buttons.size() > max_level_btn:
		var button: LevelButton = _level_buttons.pop_back()
		button.queue_free()
	# remove excess placeholder button 
	while _placeholder_buttons.size() > PAGE_SIZE - max_level_btn:
		var button: PlaceholderButton = _placeholder_buttons.pop_back()
		button.queue_free()
		
	var level_btn_count := _level_buttons.size()
	var placeholder_btn_count := _placeholder_buttons.size()
	for btn_index in range(0,PAGE_SIZE):
		if btn_index < levels_progress.size():
			# add level button
			var level_button: LevelButton
			var level_name: String = levels_progress.keys()[btn_index]
			var progress: LevelProgress = levels_progress.get(level_name)
			if level_btn_count > 0:
				level_button = _level_buttons[level_btn_count - 1]
				level_btn_count -= 1
			else:
				level_button = LevelButton.new()
				level_button.on_delete_level_button.connect(_update_last_level)
				_level_buttons.append(level_button)
				level_grid.add_child(level_button)
			level_button.construct(level_name, progress, _world)
			level_grid.move_child(level_button,btn_index)
		else:
			# add placeholder button
			var placeholder_button: PlaceholderButton
			if placeholder_btn_count > 0:
				placeholder_button = _placeholder_buttons[placeholder_btn_count - 1]
				placeholder_btn_count -= 1
			else:
				placeholder_button = PlaceholderButton.new()
				_placeholder_buttons.append(placeholder_button)
				level_grid.add_child(placeholder_button)
			placeholder_button.construct(_world == GlobalConst.LevelGroup.CUSTOM)
	

func _update_last_level(ref: LevelButton) -> void:
	_level_buttons.erase(ref)
	# no more level in page: go back to previous page if this is not the first
	if _current_page > 1 and _level_buttons.size() == 0:
		_current_page -= 1
		_update_content()
		return
		
	var last_level: int = _current_page * PAGE_SIZE
	var levels_progress: Dictionary 
	# get extra level for test next page
	levels_progress = GameManager.get_page_levels(_world, last_level, last_level + 1)
	_update_buttons(levels_progress.size() > 1)

	if levels_progress.size() > 0:
		# add level button
		var level_name: String = levels_progress.keys()[0]
		var progress: LevelProgress = levels_progress.get(level_name)
		var level_button := LevelButton.new()		
		level_button.on_delete_level_button.connect(_update_last_level)
		_level_buttons.append(level_button)
		level_grid.add_child(level_button)
		level_button.construct(level_name, progress, _world)
	else:
		# add placeholder button
		var placeholder_button := PlaceholderButton.new()
		_placeholder_buttons.append(placeholder_button)
		level_grid.add_child(placeholder_button)
		placeholder_button.construct(_world == GlobalConst.LevelGroup.CUSTOM)
		

func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_current_page -= 1
		_update_content()


func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_action_pressed(Literals.Inputs.LEFT_CLICK):
		_current_page += 1
		_update_content()


func _update_buttons(has_next_page: bool):
	if _current_page == 1:
		left.hide()
	else:
		left.show()

	if has_next_page:
		right.show()
	else:
		right.hide()


func _on_world_btn_pressed() -> void:
	_world = GlobalConst.LevelGroup.MAIN
	_current_page = 1
	_update_content()


func _on_custom_btn_pressed() -> void:
	_world = GlobalConst.LevelGroup.CUSTOM
	_current_page = 1
	_update_content()
