class_name LevelUI extends Control

const PAGE_SIZE := 9
const DISABLED_COLOR := Color(0.75, 0.75, 0.75, 1)
const ACTIVE_BTN_COLOR := Color(0.251, 0.184, 0.106)
const PAGE_PER_SECOND: float = 5

var has_consume_input: bool

var _world: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN
var _current_page: int = 1
var _start_drag: float
var _start_position: float
var _target_position: float
var _page_width: float
var _has_drag: bool
var _has_movement: bool
var _num_pages: int = 1
var _scroll_range: Vector2
var _tween: Tween
var _levels_page: Array[LevelPage]

@onready var left: TextureButton = %Left
@onready var right: TextureButton = %Right
@onready var title: Label = %Title
@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var world_btn: Button = %WorldBtn
@onready var custom_btn: Button = %CustomBtn
@onready var pages: HBoxContainer = %Pages


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)


	world_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	custom_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	title.add_theme_font_size_override("font_size", GameManager.text_font_size)
	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	_page_width = get_viewport().size.x
	pages.size.x = _page_width * 3
	pages.size.y = get_viewport().size.y - 350 - GameManager.vertical_margin * 2
	pages.position.x = _page_width / 2 - pages.size.x / 2
	pages.position.y = get_viewport().size.y - 128 - GameManager.vertical_margin - pages.size.y
	
	for child in pages.get_children():
		if child is LevelPage:
			_levels_page.append(child)
			child.level_deleted.connect(_on_level_deleted)

	GameManager.on_state_change.connect(_on_state_change)
	# Set starting page where the next playable level is
	var active_level_id: int = GameManager.get_active_level_id()
	_current_page = ceili(float(active_level_id + 1) / PAGE_SIZE)
	_check_pages()
	_init_pages()



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


func _check_pages() -> void:
	match _world:
		GlobalConst.LevelGroup.MAIN:
			_update_buttons(levels_progress.size() > PAGE_SIZE)
			var num_pages: int = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)
			title.text = "%02d of %d" % [_current_page, num_pages]
		GlobalConst.LevelGroup.CUSTOM:
			# Accounting for at least one placeholder_button, always present in custom level panel
			_num_pages = ceil(float(GameManager.get_num_levels(_world) + 1) / PAGE_SIZE)
	title.text = "%d of %d" % [_current_page, _num_pages]
<<<<<<< HEAD
	_scroll_range = Vector2(-_page_width, _page_width)

=======
	
>>>>>>> 494f102 (fix: improve level UI performance)
	if _current_page == 1:
		left.disabled = true
		left.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, DISABLED_COLOR)
		_levels_page[0].toggle_page(false)
		_scroll_range.y = _page_width / 10
	else:
		left.disabled = false
		left.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, ACTIVE_BTN_COLOR)
<<<<<<< HEAD
		level_grid_sx.show()
=======
		_levels_page[0].toggle_page(true)
		_scroll_range.y = _page_width
>>>>>>> 494f102 (fix: improve level UI performance)

	if _current_page >= _num_pages:
		right.disabled = true
		right.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, DISABLED_COLOR)
		_levels_page[2].toggle_page(false)
		_scroll_range.x = -_page_width / 10
	else:
		right.disabled = false
		right.material.set_shader_parameter(Literals.Parameters.BASE_COLOR, ACTIVE_BTN_COLOR)
		_levels_page[2].toggle_page(true)
		_scroll_range.x = -_page_width


<<<<<<< HEAD
func _update_left_page() -> void:
	_unfill_grid(level_grid_sx)
	if _current_page == 1:
		return

	var first_level: int = (_current_page - 2) * PAGE_SIZE + 1
	var last_level: int = (_current_page - 1) * PAGE_SIZE
	var levels_progress: Array[LevelProgress]
	levels_progress = GameManager.get_page_levels(_world, first_level, last_level)

	for i in range(levels_progress.size()):
		var button: LevelButton
		if _level_buttons.is_empty():
			button = LevelButton.new()
			button.on_delete_level_button.connect(_on_level_deleted)
			level_grid_sx.add_child(button)
		else:
			button = _level_buttons.pop_back() as LevelButton
			if button.get_parent() == null:
				level_grid_sx.add_child(button)
			else:
				button.reparent(level_grid_sx)
		var id := (_current_page - 2) * PAGE_SIZE + i
		button.construct(id, levels_progress[i], _world)
		level_grid_sx.move_child(button, i)


func _update_current_page() -> void:
	_unfill_grid(level_grid)

	var first_level: int = (_current_page - 1) * PAGE_SIZE + 1
	var last_level: int = _current_page * PAGE_SIZE
	var levels_progress: Array[LevelProgress]
	levels_progress = GameManager.get_page_levels(_world, first_level, last_level)
	# add level buttons
	for i in range(levels_progress.size()):
		var button: LevelButton
		if _level_buttons.is_empty():
			button = LevelButton.new()
			button.on_delete_level_button.connect(_on_level_deleted)
			level_grid.add_child(button)
		else:
			button = _level_buttons.pop_back() as LevelButton
			if button.get_parent() == null:
				level_grid.add_child(button)
			else:
				button.reparent(level_grid)
		var id := (_current_page - 1) * PAGE_SIZE + i
		button.construct(id, levels_progress[i], _world)
		level_grid.move_child(button, i)
	# add placeholder when level buttons don't fill the page
	if levels_progress.size() < PAGE_SIZE:
		for i in range(levels_progress.size(), PAGE_SIZE):
			var button: PlaceholderButton
			if _placeholder_buttons.is_empty():
				button = PlaceholderButton.new()
				level_grid.add_child(button)
			else:
				button = _placeholder_buttons.pop_back() as PlaceholderButton
			if button.get_parent() == null:
				level_grid.add_child(button)
			else:
				button.reparent(level_grid)
			level_grid.move_child(button, i)
			button.construct(_world == GlobalConst.LevelGroup.CUSTOM)


func _update_right_page() -> void:
	_unfill_grid(level_grid_dx)

	var first_level: int = _current_page * PAGE_SIZE + 1
	var last_level: int = (_current_page + 1) * PAGE_SIZE
	var levels_progress: Array[LevelProgress]
	levels_progress = GameManager.get_page_levels(_world, first_level, last_level)
	# add level buttons
	for i in range(levels_progress.size()):
		var button: LevelButton
		if _level_buttons.is_empty():
			button = LevelButton.new()
			button.on_delete_level_button.connect(_on_level_deleted)
			level_grid_dx.add_child(button)
		else:
			button = _level_buttons.pop_back() as LevelButton
			if button.get_parent() == null:
				level_grid_dx.add_child(button)
			else:
				button.reparent(level_grid_dx)
		var id := _current_page * PAGE_SIZE + i
		button.construct(id, levels_progress[i], _world)
		level_grid_dx.move_child(button, i)
	# add placeholder when level buttons don't fill the page
	if levels_progress.size() < PAGE_SIZE:
		for i in range(levels_progress.size(), PAGE_SIZE):
			var button: PlaceholderButton
			if _placeholder_buttons.is_empty():
				button = PlaceholderButton.new()
				level_grid_dx.add_child(button)
			else:
				button = _placeholder_buttons.pop_back() as PlaceholderButton
			if button.get_parent() == null:
				level_grid_dx.add_child(button)
			else:
				button.reparent(level_grid_dx)
			level_grid_dx.move_child(button, i)
			button.construct(_world == GlobalConst.LevelGroup.CUSTOM)


func _unfill_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		if child is LevelButton:
			_level_buttons.append(child)
		elif child is PlaceholderButton:
			_placeholder_buttons.append(child)
		else:
			child.queue_free.call_deferred()


func _transfer_page(current: GridContainer, to: GridContainer) -> void:
	for child in current.get_children():
		child.reparent(to)


func _remove_extra_buttons() -> void:
	for button in _level_buttons:
		button.queue_free.call_deferred()
	_level_buttons.clear()
	for button in _placeholder_buttons:
		button.queue_free.call_deferred()
	_placeholder_buttons.clear()


func _on_level_deleted(ref: LevelButton) -> void:
	_level_buttons.erase(ref)
	_update_current_page()
	_update_right_page()
	_remove_extra_buttons()


func _on_left_pressed() -> void:
	if _has_movement:
		_tween.set_speed_scale(3)
	else:
=======
func _init_pages() -> void:
	# previous page
	if _current_page > 1:
		_levels_page[0].update_page(_world, _current_page - 1)
	# current page
	_levels_page[1].update_page(_world, _current_page)
	# next page
	if _current_page < _num_pages:
		_levels_page[2].update_page(_world, _current_page + 1)


func _on_left_pressed() -> void:
	if !_has_movement:
>>>>>>> 494f102 (fix: improve level UI performance)
		AudioManager.play_click_sound()
		_start_position = pages.global_position.x
		_target_position = _start_position + _page_width
		_move_right(1 / PAGE_PER_SECOND)


func _on_right_pressed() -> void:
<<<<<<< HEAD
	if _has_movement:
		_tween.set_speed_scale(3)
	else:
=======
	if !_has_movement:
>>>>>>> 494f102 (fix: improve level UI performance)
		AudioManager.play_click_sound()
		_start_position = pages.global_position.x
		_target_position = _start_position - _page_width
		_move_left(1 / PAGE_PER_SECOND)


func _move_left(transition_time: float) -> void:
	_has_movement = true
	_tween = get_tree().create_tween()
	_tween.tween_property(pages, "global_position:x", _target_position, transition_time)
	await _tween.finished
	_current_page += 1
	var page := _levels_page.pop_front() as LevelPage
	pages.move_child(page, 2)
	_levels_page.push_back(page)
	pages.global_position.x = _start_position
	if _current_page < _num_pages:
		page.update_page(_world, _current_page + 1)
	_check_pages()
	_end_animation.call_deferred()


func _move_right(transition_time: float) -> void:
	_has_movement = true
	_tween = get_tree().create_tween()
	_tween.tween_property(pages, "global_position:x", _target_position, transition_time)
	await _tween.finished
	_current_page -= 1
	var page := _levels_page.pop_back() as LevelPage
	pages.move_child(page, 0)
	_levels_page.push_front(page)
	pages.global_position.x = _start_position
	if _current_page > 1:
		page.update_page(_world, _current_page - 1)		
	_check_pages()
	_end_animation.call_deferred()


func _on_world_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = GlobalConst.LevelGroup.MAIN
	# Set starting page where the next playable level is
	var active_level_id: int = GameManager.get_active_level_id()
	_current_page = ceil(float(active_level_id + 1) / PAGE_SIZE)
	world_btn.hide()
	custom_btn.show()
	_check_pages()
	_init_pages()


func _on_custom_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = GlobalConst.LevelGroup.CUSTOM
	_current_page = 1
	custom_btn.hide()
	world_btn.show()
	_check_pages()
	_init_pages()


func _on_level_deleted() -> void:
	_check_pages()
	_init_pages()
	
	
func update_content() -> void:
	_check_pages()
	_init_pages()


func _process(_delta: float) -> void:
	if _has_drag:
		var offset_position: float = get_global_mouse_position().x - _start_drag
		offset_position = clamp(offset_position, _scroll_range.x, _scroll_range.y)
		var current := absf(offset_position)
		pages.global_position.x = _start_position + offset_position
		if !has_consume_input:
			has_consume_input = current > 10

		if Input.is_action_just_released(Literals.Inputs.LEFT_CLICK):
			var start: float
			var end: float
			var interp: float
			_has_drag = false
			if current > _page_width / 9:
				start = 0
				end = _page_width
				interp = (1 - remap(current, start, end, 0, 1)) / PAGE_PER_SECOND
				if offset_position > 0:
					_target_position = _start_position + _page_width
					_move_right(interp)
				else:
					_target_position = _start_position - _page_width
					_move_left(interp)
			else:
				start = _page_width
				end = 0
				interp = (1 - remap(current, start, end, 0, 1)) / PAGE_PER_SECOND
				_target_position = _start_position
				_tween = get_tree().create_tween()
				_tween.tween_property(pages, "global_position:x", _target_position, interp)
				_tween.finished.connect(_end_animation)
			return


func _end_animation() -> void:
	has_consume_input = false
	_has_movement = false


func _on_pages_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if event.is_action_pressed(Literals.Inputs.LEFT_CLICK) and !_has_movement:
			_start_drag = get_global_mouse_position().x
			_start_position = pages.global_position.x
			_has_drag = true
