class_name LevelUI extends Control

const PAGE_SIZE := 9
const DISABLED_COLOR := Color(0.75, 0.75, 0.75, 1)
const ACTIVE_BTN_COLOR := Color(0.251, 0.184, 0.106)
const PAGE_PER_SECOND: float = 5

var has_consume_input: bool

var _world: Constants.LevelGroup
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

@onready var left: Button = %Left
@onready var right: Button = %Right
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

	left.add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)
	right.add_theme_constant_override("icon_max_width", GameManager.btn_icon_max_width)
	world_btn.add_theme_constant_override("icon_max_width", int(GameManager.icon_max_width * 1.5))
	custom_btn.add_theme_constant_override("icon_max_width", int(GameManager.icon_max_width * 1.5))

	_page_width = get_viewport().size.x
	pages.size.x = _page_width * 3
	pages.size.y = get_viewport().size.y
	pages.position.x = _page_width / 2 - pages.size.x / 2
	pages.position.y = get_viewport().size.y - pages.size.y

	for child in pages.get_children():
		if child is LevelPage:
			_levels_page.append(child)
			child.on_page_changed.connect(_refresh_next)
			child.on_start_drag.connect(_on_pages_drag)

	GameManager.on_state_change.connect(_on_state_change)
	_set_start_point()
	_check_pages()
	_init_pages()


func _set_start_point() -> void:
	# Set starting page where the next playable level is
	var active_level_id: int = GameManager.get_active_level_id()
	if active_level_id <= 0:
		active_level_id = SaveManager.get_start_level_playable()
	_current_page = ceili(float(active_level_id + 1) / PAGE_SIZE)
	# Set starting world where the next playable level is
	_world = GameManager.get_active_context()
	world_btn.visible = _world == Constants.LevelGroup.CUSTOM
	custom_btn.visible = _world == Constants.LevelGroup.MAIN


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			GameManager.reset_active_level_id()
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_START:
			self.queue_free.call_deferred()
		Constants.GameState.BUILDER_IDLE:
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_INSPECT:
			self.show()
		Constants.GameState.CUSTOM_LEVEL_INSPECT:
			self.show()
		Constants.GameState.LEVEL_PICK:
			self.show()
		_:
			self.hide()


func _on_exit_btn_pressed() -> void:
	AudioManager.play_click_sound()
	GameManager.change_state(Constants.GameState.MAIN_MENU)


func _check_pages() -> void:
	match _world:
		Constants.LevelGroup.MAIN:
			_num_pages = ceil(float(SaveManager.get_num_levels(_world)) / PAGE_SIZE)
		Constants.LevelGroup.CUSTOM:
			# Accounting for at least one placeholder_button, always present in custom level panel
			_num_pages = ceil(float(SaveManager.get_num_levels(_world) + 1) / PAGE_SIZE)
	title.text = "%02d of %02d" % [_current_page, _num_pages]
	if _current_page == 1:
		left.disabled = true
		_levels_page[0].toggle_page(false)
		_scroll_range.y = _page_width / 10
	else:
		left.disabled = false
		_levels_page[0].toggle_page(true)
		_scroll_range.y = _page_width

	if _current_page >= _num_pages:
		right.disabled = true
		_levels_page[2].toggle_page(false)
		_scroll_range.x = -_page_width / 10
	else:
		right.disabled = false
		_levels_page[2].toggle_page(true)
		_scroll_range.x = -_page_width


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
		AudioManager.play_click_sound()
		_start_position = pages.global_position.x
		_target_position = _start_position + _page_width
		_move_right(1 / PAGE_PER_SECOND)


func _on_right_pressed() -> void:
	if !_has_movement:
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
	_world = Constants.LevelGroup.MAIN
	# Set starting page where the next playable level is
	var active_level_id: int = SaveManager.get_start_level_playable()
	_current_page = ceili(float(active_level_id + 1) / PAGE_SIZE)
	world_btn.hide()
	custom_btn.show()
	_check_pages()
	_init_pages()


func _on_custom_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = Constants.LevelGroup.CUSTOM
	_current_page = 1
	custom_btn.hide()
	world_btn.show()
	_check_pages()
	_init_pages()


func _refresh_next() -> void:
	_check_pages()
	# next page
	if _current_page < _num_pages:
		_levels_page[2].update_page(_world, _current_page + 1)


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


func _on_pages_drag() -> void:
	if !_has_movement:
		_start_drag = get_global_mouse_position().x
		_start_position = pages.global_position.x
		_has_drag = true
