class_name LevelUI extends Control

const PAGE_SIZE := 9
const DISABLED_COLOR := Color(0.75, 0.75, 0.75, 1)
const ACTIVE_BTN_COLOR := Color(0.251, 0.184, 0.106)
const DEFAULT_THEME = preload("res://assets/resources/themes/default.tres")
const PRIMARY_THEME = preload("res://assets/resources/themes/primary.tres")

var _world: GlobalConst.LevelGroup = GlobalConst.LevelGroup.MAIN
var _current_page: int = 1
var _num_pages: int = 1
var _level_buttons: Array[LevelButton]
var _placeholder_buttons: Array[PlaceholderButton]

@onready var level_grid: GridContainer = %LevelGrid
@onready var left: TextureButton = %Left
@onready var right: TextureButton = %Right
@onready var title: Label = %Title
@onready var margin: MarginContainer = %MarginContainer
@onready var exit_btn: Button = %ExitBtn
@onready var world_btn: Button = %WorldBtn
@onready var custom_btn: Button = %CustomBtn


func _ready() -> void:
	margin.add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	margin.add_theme_constant_override("margin_top", GameManager.vertical_margin)
	margin.add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	level_grid.add_theme_constant_override("h_separation", GameManager.vertical_margin)
	level_grid.add_theme_constant_override("v_separation", GameManager.vertical_margin)

	world_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	custom_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	title.add_theme_font_size_override("font_size", GameManager.text_font_size)
	exit_btn.add_theme_font_size_override("font_size", GameManager.subtitle_font_size)
	exit_btn.add_theme_constant_override("icon_max_width", GameManager.icon_max_width)

	GameManager.on_state_change.connect(_on_state_change)
	_num_pages = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)

	update_content()


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


func update_content() -> void:
	var first_level: int = (_current_page - 1) * PAGE_SIZE + 1
	var last_level: int = _current_page * PAGE_SIZE

	var levels_progress: Array[LevelProgress]
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
			if level_btn_count > 0:
				level_button = _level_buttons[level_btn_count - 1]
				level_btn_count -= 1
			else:
				level_button = LevelButton.new()
				level_button.on_delete_level_button.connect(_on_level_deleted)
				_level_buttons.append(level_button)
				level_grid.add_child(level_button)

			var id := btn_index + (_current_page - 1) * PAGE_SIZE
			level_button.construct(id, levels_progress[btn_index], _world)
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


func _on_level_deleted(ref: LevelButton) -> void:
	_level_buttons.erase(ref)
	update_content()


func _on_left_pressed() -> void:
	AudioManager.play_click_sound()
	_current_page -= 1
	update_content()


func _on_right_pressed() -> void:
	AudioManager.play_click_sound()
	_current_page += 1
	update_content()


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
	update_content()
	world_btn.theme = PRIMARY_THEME
	custom_btn.theme = DEFAULT_THEME


func _on_custom_btn_pressed() -> void:
	AudioManager.play_click_sound()
	_world = GlobalConst.LevelGroup.CUSTOM
	_current_page = 1
	_num_pages = ceil(float(GameManager.get_num_levels(_world)) / PAGE_SIZE)
	update_content()
	custom_btn.theme = PRIMARY_THEME
	world_btn.theme = DEFAULT_THEME
