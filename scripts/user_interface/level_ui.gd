class_name LevelUI extends Control

const PAGE_SIZE := 9
const DISABLED_COLOR := Color(0.75, 0.75, 0.75, 1)
const ACTIVE_BTN_COLOR := Color(0.251, 0.184, 0.106)
const THEME = preload("res://assets/resources/themes/default.tres")

var _world: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN
var _current_page: int = 1
var _num_pages: int = 1
var _level_buttons: Array[LevelButton]
var _placeholder_buttons: Array[PlaceholderButton]

@onready var level_grid: GridContainer = %LevelGrid
@onready var left: TextureButton = %Left
@onready var right: TextureButton = %Right
@onready var title: Label = %Title
@onready var world_underline: Line2D = %WorldUnderline
@onready var custom_underline: Line2D = %CustomUnderline


func _ready() -> void:
	GameManager.on_state_change.connect(_on_state_change)
	_num_pages = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)
	_update_content()


func add_imported_level(level_name: String) -> void:
	_placeholder_buttons[-1].queue_free()
	_placeholder_buttons.remove_at(_placeholder_buttons.size() - 1)

	var level_button := LevelButton.new()
	level_button.on_delete_level_button.connect(_update_last_level)

	_level_buttons.append(level_button)
	level_grid.add_child(level_button)

	var progress = LevelProgress.new()
	progress.move_left = -1000
	progress.is_unlocked = true
	progress.is_completed = true

	level_button.construct(level_name, progress, GlobalConst.LevelGroup.CUSTOM)
	level_grid.move_child(level_button, _level_buttons.size() - 1)
	# Show next page button if there are no placeholder buttons
	_update_buttons(_placeholder_buttons.size() == 0)


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
		GlobalConst.GameState.CUSTOM_LEVEL_INSPECT:
			self.show()
		GlobalConst.GameState.LEVEL_PICK:
			self.show()
		_:
			self.hide()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(GlobalConst.GameState.MAIN_MENU)


func _update_content() -> void:
	var first_level: int = (_current_page - 1) * PAGE_SIZE + 1
	var last_level: int = _current_page * PAGE_SIZE

	var levels_progress: Dictionary
	# get extra level for test next page
	levels_progress = GameManager.get_page_levels(_world, first_level, last_level + 1)
	title.text = "%d of %d" % [_current_page, _num_pages]

	match _world:
		GlobalConst.LevelGroup.MAIN:
			_update_buttons(levels_progress.size() > PAGE_SIZE)
		GlobalConst.LevelGroup.CUSTOM:
			_update_buttons(levels_progress.size() > PAGE_SIZE - 1)

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
	for btn_index in range(0, PAGE_SIZE):
		if btn_index < levels_progress.size():
			# add level button
			var level_button: LevelButton
			var level_name: String = levels_progress.keys()[btn_index]
			var progress: LevelProgress = levels_progress.get(level_name)
			if level_btn_count > 0:
				level_button = _level_buttons[level_btn_count - 1]
				var lab: Label = level_button.get_child(0)
				lab.text = str(btn_index + 1 + (_current_page - 1) * PAGE_SIZE)

				level_btn_count -= 1
			else:
				level_button = LevelButton.new()
				level_button.on_delete_level_button.connect(_update_last_level)
				var lab: Label = Label.new()
				lab.text = str(btn_index + 1 + (_current_page - 1) * PAGE_SIZE)

				lab.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
				lab.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
				lab.theme = THEME
				lab.set_anchors_preset(PRESET_FULL_RECT)

				level_button.add_child(lab)

				_level_buttons.append(level_button)
				level_grid.add_child(level_button)
			level_button.construct(level_name, progress, _world)
			level_grid.move_child(level_button, btn_index)
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

	match _world:
		GlobalConst.LevelGroup.MAIN:
			_update_buttons(levels_progress.size() > 1)
		GlobalConst.LevelGroup.CUSTOM:
			_update_buttons(levels_progress.size() > 0)

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


func _on_left_pressed() -> void:
	AudioManager.play_click_sound()
	_current_page -= 1
	_update_content()


func _on_right_pressed() -> void:
	AudioManager.play_click_sound()
	_current_page += 1
	_update_content()


func _update_buttons(has_next_page: bool):
	if _current_page == 1:
		left.disabled = true
		left.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, DISABLED_COLOR)
	else:
		left.disabled = false
		left.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, ACTIVE_BTN_COLOR)

	if has_next_page:
		right.disabled = false
		right.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, ACTIVE_BTN_COLOR)
	else:
		right.disabled = true
		right.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, DISABLED_COLOR)


func _on_world_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = GlobalConst.LevelGroup.MAIN
	_current_page = 1
	_num_pages = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)
	_update_content()
	world_underline.show()
	custom_underline.hide()


func _on_custom_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = GlobalConst.LevelGroup.CUSTOM
	_current_page = 1
	_num_pages = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)
	world_underline.hide()
	custom_underline.show()
	_update_content()
