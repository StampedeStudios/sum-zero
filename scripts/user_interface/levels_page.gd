class_name LevelPage extends Control

signal on_page_changed

const LEVEL_INSPECT = "res://packed_scene/user_interface/LevelInspect.tscn"
const CUSTOM_LEVEL_INSPECT = "res://packed_scene/user_interface/CustomLevelInspect.tscn"
const LEVEL_IMPORT = "res://packed_scene/user_interface/LevelImport.tscn"

var _levels: Array[LevelButtonBase]
var _current_world: GlobalConst.LevelGroup
var _current_page: int

@onready var level_grid: GridContainer = %LevelGrid


func _ready() -> void:
	add_theme_constant_override("margin_left", GameManager.horizontal_margin)
	add_theme_constant_override("margin_right", GameManager.horizontal_margin)
	add_theme_constant_override("margin_top", GameManager.vertical_margin)
	add_theme_constant_override("margin_bottom", GameManager.vertical_margin)

	level_grid.add_theme_constant_override("h_separation", int(GameManager.vertical_margin / 2.0))
	level_grid.add_theme_constant_override("v_separation", int(GameManager.vertical_margin / 2.0))

	for child in level_grid.get_children():
		if child is LevelButtonBase:
			_levels.append(child)


func toggle_page(page_visible: bool) -> void:
	level_grid.visible = page_visible


func update_page(world: GlobalConst.LevelGroup, page: int) -> void:
	_current_world = world
	_current_page = page
	refresh_page()


func refresh_page() -> void:
	var first_level: int = (_current_page - 1) * _levels.size()
	var last_level: int = _current_page * _levels.size()
	var levels_progress: Array[LevelProgress]
	levels_progress = SaveManager.get_page_levels(_current_world, first_level, last_level)

	# construct level buttons
	for i: int in range(_levels.size()):
		var level := _levels[i] as LevelButtonBase
		_disconnect_all(level.pressed)
		if i < levels_progress.size():
			var level_id := first_level + i
			var is_locked := !levels_progress[i].is_unlocked
			var star_count := clampi(levels_progress[i].move_left, -3, 1) + 3
			level.costruct(_current_world, level_id, is_locked, star_count)
			match _current_world:
				GlobalConst.LevelGroup.CUSTOM:
					level.pressed.connect(show_custom_inspect.bind(level_id, levels_progress[i]))
				GlobalConst.LevelGroup.MAIN:
					level.pressed.connect(show_inspect.bind(level_id, levels_progress[i]))
		else:
			level.costruct(_current_world)
			match _current_world:
				GlobalConst.LevelGroup.CUSTOM:
					level.pressed.connect(show_import)


func _delete_level(id: int) -> void:
	SaveManager.delete_level(id)
	refresh_page()
	on_page_changed.emit()


func _disconnect_all(button_pressed: Signal) -> void:
	for connection: Dictionary in button_pressed.get_connections():
		button_pressed.disconnect(connection.callable)


func show_import() -> void:
	if GameManager.level_ui.has_consume_input:
		return
	var scene := load(LEVEL_IMPORT) as PackedScene
	var level_import := scene.instantiate() as LevelImport
	get_tree().root.add_child(level_import)
	level_import.level_imported.connect(_import_level)


func show_inspect(id: int, progress: LevelProgress) -> void:
	if GameManager.level_ui.has_consume_input:
		return
	var scene := load(LEVEL_INSPECT) as PackedScene
	var level_inspect := scene.instantiate() as LevelInspect
	get_tree().root.add_child(level_inspect)
	level_inspect.init_inspector(id, progress)
	level_inspect.level_unlocked.connect(_unlock_level.bind(id))


func show_custom_inspect(id: int, progress: LevelProgress) -> void:
	if GameManager.level_ui.has_consume_input:
		return
	var scene := load(CUSTOM_LEVEL_INSPECT) as PackedScene
	var custom_level_inspect := scene.instantiate() as CustomLevelInspect
	get_tree().root.add_child(custom_level_inspect)
	custom_level_inspect.init_inspector(id, progress)
	custom_level_inspect.level_deleted.connect(_delete_level.bind(id))


func _unlock_level(id: int) -> void:
	SaveManager.unlock_level(id)
	refresh_page()


func _import_level() -> void:
	refresh_page()
	on_page_changed.emit()
