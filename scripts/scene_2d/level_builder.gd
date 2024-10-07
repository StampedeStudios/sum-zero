extends Control

const CELL := preload("res://packed_scene/scene_2d/BuilderCell.tscn")
const SLIDER := preload("res://packed_scene/scene_2d/BuilderSlider.tscn")
const LEVEL_INFO_QUERY := preload("res://packed_scene/user_interface/ResizeQuery.tscn")
const SAVE_QUERY = preload("res://packed_scene/user_interface/SaveQuery.tscn")
const LEVEL_MANAGER = preload("res://packed_scene/scene_2d/LevelManager.tscn")

var cell_collection: Dictionary
var slider_collection: Dictionary

var _level_width: int = 3
var _level_height: int = 3
var _level_data := LevelData.new()
var _valid_level: bool = false

@onready var grid = %Grid
@onready var reset_btn = %ResetBtn
@onready var play_btn = %PlayBtn
@onready var exit_btn = %ExitBtn
@onready var save_btn = %SaveBtn
@onready var resize_btn = %ResizeBtn


func _ready():
	grid.position = get_viewport_rect().get_center()
	_init_level()


func _init_level() -> void:
	var half_grid := Vector2(_level_width, _level_height) * GameManager.cell_size / 2
	var half_cell := Vector2.ONE * GameManager.cell_size / 2
	var cell_scale: Vector2
	cell_scale.x = (GameManager.cell_size / GlobalConst.CELL_SIZE)
	cell_scale.y = (GameManager.cell_size / GlobalConst.CELL_SIZE)

	# add cell space
	for columun in range(0, _level_width):
		for row in range(0, _level_height):
			var cell_coord := Vector2i(columun, row)
			var cell_pos := cell_coord * GameManager.cell_size
			var cell: Node

			if cell_collection.has(cell_coord):
				cell = cell_collection.get(cell_coord)
			else:
				cell = CELL.instantiate()
				grid.add_child(cell)
				cell_collection[cell_coord] = cell

			cell.position = -half_grid + cell_pos + half_cell
			cell.scale = cell_scale
			cell.redraw_ui()

	for row in range(0, _level_height + 1):
		if cell_collection.has(Vector2i(_level_width, row)):
			var cell: Node = cell_collection.get(Vector2i(_level_width, row))
			cell.queue_free()
			cell_collection.erase(Vector2i(_level_width, row))

	for column in range(0, _level_height + 1):
		if cell_collection.has(Vector2i(column, _level_height)):
			var cell: Node = cell_collection.get(Vector2i(column, _level_height))
			cell.queue_free()
			cell_collection.erase(Vector2i(column, _level_height))

	# add slider space
	var slider_pos: Vector2
	var edge_start_pos: Vector2
	var slider: Node
	# TOP
	for column in range(0, _level_width):
		var id := Vector2i(0, column)
		if slider_collection.has(id):
			slider = slider_collection.get(id)
		else:
			slider = SLIDER.instantiate()
			grid.add_child(slider)
			slider_collection[id] = slider

		slider_pos.x = column * GameManager.cell_size
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y - half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.scale = cell_scale
		slider.rotation_degrees = 90
		slider.set_item_list_position()

	if slider_collection.has(Vector2i(0, _level_width)):
		slider = slider_collection.get(Vector2i(0, _level_width))
		slider.queue_free()
		slider_collection.erase(Vector2i(0, _level_width))
	# RIGHT
	for row in range(0, _level_height):
		var id := Vector2i(1, row)
		if slider_collection.has(id):
			slider = slider_collection.get(id)
		else:
			slider = SLIDER.instantiate()
			grid.add_child(slider)
			slider_collection[id] = slider

		slider_pos.x = 0
		slider_pos.y = row * GameManager.cell_size
		edge_start_pos.x = half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.scale = cell_scale
		slider.rotation_degrees = 180
		slider.set_item_list_position()

	if slider_collection.has(Vector2i(1, _level_height)):
		slider = slider_collection.get(Vector2i(1, _level_height))
		slider.queue_free()
		slider_collection.erase(Vector2i(1, _level_height))
	# BOTTOM
	for column in range(0, _level_width):
		var id := Vector2i(2, column)
		if slider_collection.has(id):
			slider = slider_collection.get(id)
		else:
			slider = SLIDER.instantiate()
			grid.add_child(slider)
			slider_collection[id] = slider

		slider_pos.x = column * GameManager.cell_size
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.scale = cell_scale
		slider.rotation_degrees = 270
		slider.set_item_list_position()

	if slider_collection.has(Vector2i(2, _level_width)):
		slider = slider_collection.get(Vector2i(2, _level_width))
		slider.queue_free()
		slider_collection.erase(Vector2i(2, _level_width))
	# LEFT
	for row in range(0, _level_height):
		var id := Vector2i(3, row)
		if slider_collection.has(id):
			slider = slider_collection.get(id)
		else:
			slider = SLIDER.instantiate()
			grid.add_child(slider)
			slider_collection[id] = slider

		slider_pos.x = 0
		slider_pos.y = row * GameManager.cell_size
		edge_start_pos.x = -half_grid.x - half_cell.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.scale = cell_scale
		slider.rotation_degrees = 0
		slider.set_item_list_position()

	if slider_collection.has(Vector2i(3, _level_height)):
		slider = slider_collection.get(Vector2i(3, _level_height))
		slider.queue_free()
		slider_collection.erase(Vector2i(3, _level_height))


func _on_reset_btn_pressed():
	for cell in cell_collection.values():
		cell.clear_cell()
	for slider in slider_collection.values():
		slider.clear_slider()


func _on_resize_btn_pressed():
	var query: ResizeQuery = LEVEL_INFO_QUERY.instantiate()
	get_tree().root.add_child(query)
	query.init_query(_level_width, _level_height)
	query.on_width_change.connect(_on_width_change)
	query.on_height_change.connect(_on_height_change)


func _on_play_btn_pressed():
	var level: LevelManager = LEVEL_MANAGER.instantiate()
	get_tree().root.add_child(level)
	if !_valid_level:
		_compose_level()
	level.init(_level_data)
	self.visible = false
	

func _on_save_btn_pressed():
	var query: SaveQuery = SAVE_QUERY.instantiate()
	get_tree().root.add_child(query)
	query.on_query_close.connect(_on_save_query_received)


func _on_save_query_received(validation: bool, level_name: String, level_moves: int):
	if validation:
		# Se faccio partire da editor creo una nuova risorsa direttamente
		# nella cartella dedicata alle risorse dei livelli
		if OS.has_feature("debug"):
			var dir := "res://assets/resources/levels/"
			var path := dir + level_name + ".tres"
			if !_valid_level:
				_compose_level()
			_level_data.moves_left = level_moves + 3
			ResourceSaver.save(_level_data, path)
			get_tree().quit()
		else:
			#TODO: aggiungere al salvataggio del giocatore
			print("build game")


func _compose_level() -> void:
	_level_data.width = _level_width
	_level_data.height = _level_height

	for coord in cell_collection.keys():
		var data: CellData = cell_collection[coord].get_cell_data()
		if data:
			_level_data.cells_list[coord] = data

	for coord in slider_collection.keys():
		var data: SliderData = slider_collection[coord].get_slider_data()
		if data:
			_level_data.slider_position[coord] = data
	_valid_level = true


func _on_width_change(new_width: int) -> void:
	_level_width = new_width
	_init_level()


func _on_height_change(new_height: int) -> void:
	_level_height = new_height
	_init_level()
