## Handles UI panel that shows all playable levels and their state.
##
## Levels are selectable from a specific interface that renders existing levels in multiple pages.
## Previous and next page are also pre-rendered and moved away from the screen to better handling
## transition from page to page.
class_name LevelUI extends Control

const PAGE_SIZE := 9
const PAGE_PER_SECOND: float = 5
const BUILDER_UI = "res://packed_scene/user_interface/BuilderUI.tscn"
const LEVEL_BUILDER = "res://packed_scene/scene_2d/LevelBuilder.tscn"

var has_consumed_input: bool

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
@onready var exit_btn: Button = %ExitBtn
@onready var pages: Control = %Pages
@onready var page_host: Control = %PageHost
@onready var builder_btn: Button = %BuilderBtn


func _ready() -> void:
	if _world == Constants.LevelGroup.CUSTOM:
		builder_btn.show()

	page_host.resized.connect(_layout_pages)

	for child in pages.get_children():
		if child is LevelPage:
			_levels_page.append(child)
			child.on_page_changed.connect(_refresh_next)
			child.on_start_drag.connect(_on_pages_drag)

	GameManager.on_state_change.connect(_on_state_change)
	_set_start_point()
	_check_pages()
	_init_pages()
	_layout_pages.call_deferred()


func _layout_pages() -> void:
	# A resize cancels an unfinished swipe, retaining the last settled page.
	if _tween:
		_tween.kill()
	_has_drag = false
	_end_animation()
	_page_width = page_host.size.x
	pages.layout_pages()
	_check_pages()


func set_context(world: Constants.LevelGroup) -> void:
	_world = world


## Sets starting page to show the next playable level.
func _set_start_point() -> void:
	var active_level_id: int = GameManager.get_active_level_id()
	if active_level_id <= 0:
		if _world == Constants.LevelGroup.MAIN:
			active_level_id = SaveManager.get_start_level_playable()
		else:
			active_level_id = 0
	_current_page = ceili(float(active_level_id + 1) / PAGE_SIZE)


func _on_state_change(new_state: Constants.GameState) -> void:
	match new_state:
		Constants.GameState.MAIN_MENU:
			GameManager.reset_active_level_id()
			self.queue_free.call_deferred()
		Constants.GameState.LEVEL_PICK:
			_check_pages()
			_init_pages()
			self.show()
			_layout_pages.call_deferred()
		_:
			_layout_pages()
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

	_num_pages = maxi(1, _num_pages)
	_current_page = clampi(_current_page, 1, _num_pages)
	title.text = "%02d / %02d" % [_current_page, _num_pages]
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
	# Previous page
	if _current_page > 1:
		_levels_page[0].update_page(_world, _current_page - 1)
	# Current page
	_levels_page[1].update_page(_world, _current_page)
	# Next page
	if _current_page < _num_pages:
		_levels_page[2].update_page(_world, _current_page + 1)


func _on_left_pressed() -> void:
	if !_has_movement and not left.disabled:
		AudioManager.play_click_sound()
		_start_position = pages.global_position.x
		_target_position = _start_position + _page_width
		_move_right(1 / PAGE_PER_SECOND)


func _on_right_pressed() -> void:
	if !_has_movement and not right.disabled:
		AudioManager.play_click_sound()
		_start_position = pages.global_position.x
		_target_position = _start_position - _page_width
		_move_left(1 / PAGE_PER_SECOND)


func _move_left(transition_time: float) -> void:
	_has_movement = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(pages, "global_position:x", _target_position, transition_time)
	_tween.finished.connect(_finish_move_left)


func _finish_move_left() -> void:
	_current_page += 1

	var page := _levels_page.pop_front() as LevelPage
	pages.move_child(page, 2)
	_levels_page.push_back(page)
	_layout_pages()

	if _current_page < _num_pages:
		page.update_page(_world, _current_page + 1)
	_check_pages()
	_end_animation.call_deferred()


func _move_right(transition_time: float) -> void:
	_has_movement = true
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(pages, "global_position:x", _target_position, transition_time)
	_tween.finished.connect(_finish_move_right)


func _finish_move_right() -> void:
	_current_page -= 1

	var page := _levels_page.pop_back() as LevelPage
	pages.move_child(page, 0)
	_levels_page.push_front(page)
	_layout_pages()

	if _current_page > 1:
		page.update_page(_world, _current_page - 1)
	_check_pages()
	_end_animation.call_deferred()


func _refresh_next() -> void:
	_check_pages()
	_init_pages()


func _process(_delta: float) -> void:
	if _has_drag:
		var offset_position: float = get_global_mouse_position().x - _start_drag
		offset_position = clamp(offset_position, _scroll_range.x, _scroll_range.y)
		var current := absf(offset_position)
		pages.global_position.x = _start_position + offset_position
		if !has_consumed_input:
			has_consumed_input = current > 10

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
				_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(
					Tween.EASE_OUT
				)
				_tween.tween_property(pages, "global_position:x", _target_position, interp)
				_tween.finished.connect(_end_animation)
			return


func _end_animation() -> void:
	has_consumed_input = false
	_has_movement = false


func _on_pages_drag() -> void:
	if !_has_movement and visible:
		_start_drag = get_global_mouse_position().x
		_start_position = pages.global_position.x
		_has_drag = true


func _on_builder_btn_pressed() -> void:
	AudioManager.play_click_sound()
	var scene := ResourceLoader.load(BUILDER_UI) as PackedScene
	var builder_ui := scene.instantiate() as BuilderUI
	get_tree().root.add_child.call_deferred(builder_ui)
	GameManager.builder_ui = builder_ui

	scene = ResourceLoader.load(LEVEL_BUILDER) as PackedScene
	var level_builder := scene.instantiate() as LevelBuilder
	get_tree().root.add_child.call_deferred(level_builder)
	level_builder.construct_level.call_deferred(LevelData.new())
	GameManager.level_builder = level_builder

	GameManager.change_state.call_deferred(Constants.GameState.BUILDER_IDLE)
