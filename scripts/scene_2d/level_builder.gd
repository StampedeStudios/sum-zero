class_name LevelBuilder extends Node2D

const BUILDER_CELL := preload("res://packed_scene/scene_2d/BuilderCell.tscn")
const BUILDER_SLIDER := preload("res://packed_scene/scene_2d/BuilderSlider.tscn")
const BUILDER_RESIZE = preload("res://packed_scene/user_interface/BuilderResize.tscn")
const BUILDER_SAVE = preload("res://packed_scene/user_interface/BuilderSave.tscn")

var cell_collection: Dictionary
var slider_collection: Dictionary

var _level_data: LevelData

@onready var grid = %Grid


func _ready():
	GameManager.on_state_change.connect(_on_state_change)
	GameManager.builder_ui.reset_builder_level.connect(_reset_builder_grid)
	grid.position = get_viewport_rect().get_center()
	_level_data = LevelData.new()
	_level_data.width = 3
	_level_data.height = 3
	_construct_level()	


func _on_scale_change(new_scale: Vector2) -> void:
	grid.scale = new_scale
	

func _on_state_change(new_state: GlobalConst.GameState) -> void:
	match new_state:
		GlobalConst.GameState.MAIN_MENU:
			self.queue_free.call_deferred()
					
		GlobalConst.GameState.BUILDER_IDLE:
			self.visible = true
			_on_scale_change(GameManager.level_scale)
					
		GlobalConst.GameState.BUILDER_SAVE:
			self.visible = true
			if !GameManager.builder_save:
				var builder_save: BuilderSave 
				builder_save = BUILDER_SAVE.instantiate()
				get_tree().root.add_child.call_deferred(builder_save)
				builder_save.on_query_close.connect(_on_save_query_received)
				GameManager.builder_save = builder_save
			
		GlobalConst.GameState.BUILDER_RESIZE:			
			self.visible = true
			if !GameManager.builder_resize:
				var builder_resize: BuilderResize 
				builder_resize = BUILDER_RESIZE.instantiate()
				get_tree().root.add_child.call_deferred(builder_resize)
				builder_resize.on_height_change.connect(_on_height_change)
				builder_resize.on_width_change.connect(_on_width_change)
				builder_resize.on_zoom_change.connect(_on_scale_change)
				GameManager.builder_resize = builder_resize
			GameManager.builder_resize.init_query.call_deferred(_level_data.width,_level_data.height)
		
		GlobalConst.GameState.BUILDER_RESIZE:
			self.visible = true
		GlobalConst.GameState.BUILDER_SELECTION:
			self.visible = true	
		_:
			self.visible = false


func _construct_level() -> void:
	var half_grid := Vector2(_level_data.width, _level_data.height) * GlobalConst.CELL_SIZE / 2
	var half_cell := Vector2.ONE * GlobalConst.CELL_SIZE / 2
	var old_collection: Dictionary
	
	# add cell space
	old_collection = cell_collection.duplicate()
	for columun in range(0, _level_data.width):
		for row in range(0, _level_data.height):
			var cell_coord := Vector2i(columun, row)
			var cell_pos := cell_coord * GlobalConst.CELL_SIZE
			var cell: BuilderCell

			if cell_collection.has(cell_coord):
				cell = cell_collection.get(cell_coord)
				old_collection.erase(cell_coord)
			else:
				cell = BUILDER_CELL.instantiate()
				grid.add_child(cell)
				cell.on_cell_change.connect(_on_cell_change)
				cell_collection[cell_coord] = cell

			cell.position = -half_grid + half_cell + cell_pos

	for coord in old_collection.keys():
		cell_collection.erase(coord)
		_level_data.cells_list.erase(coord)
		old_collection.get(coord).queue_free()
		
	# add slider space
	old_collection = slider_collection.duplicate()	
	var half_slider := Vector2.ONE * GlobalConst.SLIDER_SIZE / 2
	var slider_pos: Vector2
	var edge_start_pos: Vector2
	var slider: BuilderSlider
	# TOP
	for column in range(0, _level_data.width):
		var slider_coord := Vector2i(0, column)
		if slider_collection.has(slider_coord):
			slider = slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			slider_collection[slider_coord] = slider

		slider_pos.x = column * GlobalConst.CELL_SIZE
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = -half_grid.y - half_slider.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 90

	# RIGHT
	for row in range(0, _level_data.height):
		var slider_coord := Vector2i(1, row)
		if slider_collection.has(slider_coord):
			slider = slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			slider_collection[slider_coord] = slider

		slider_pos.x = 0
		slider_pos.y = row * GlobalConst.CELL_SIZE
		edge_start_pos.x = half_grid.x + half_slider.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 180

	# BOTTOM
	for column in range(0, _level_data.width):
		var slider_coord := Vector2i(2, column)
		if slider_collection.has(slider_coord):
			slider = slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			slider_collection[slider_coord] = slider

		slider_pos.x = column * GlobalConst.CELL_SIZE
		slider_pos.y = 0
		edge_start_pos.x = -half_grid.x + half_cell.x
		edge_start_pos.y = half_grid.y + half_slider.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 270
	
	# LEFT
	for row in range(0, _level_data.height):
		var slider_coord := Vector2i(3, row)
		if slider_collection.has(slider_coord):
			slider = slider_collection.get(slider_coord)
			old_collection.erase(slider_coord)
		else:
			slider = BUILDER_SLIDER.instantiate()
			grid.add_child(slider)
			slider.on_slider_change.connect(_on_slider_change)
			slider_collection[slider_coord] = slider

		slider_pos.x = 0
		slider_pos.y = row * GlobalConst.CELL_SIZE
		edge_start_pos.x = -half_grid.x - half_slider.x
		edge_start_pos.y = -half_grid.y + half_cell.y
		slider.position = edge_start_pos + slider_pos
		slider.rotation_degrees = 0

	for coord in old_collection.keys():
		slider_collection.erase(coord)
		_level_data.slider_list.erase(coord)
		old_collection.get(coord).queue_free()
		

func _on_cell_change(ref: BuilderCell, data: CellData) -> void:
	for key in cell_collection.keys():
		if ref == cell_collection.get(key):
			if data:
				_level_data.cells_list[key] = data
			else:
				_level_data.cells_list.erase(key)


func _on_slider_change(ref: BuilderSlider, data: SliderData) -> void:
	for key in slider_collection.keys():
		if ref == slider_collection.get(key):
			if data:
				_level_data.slider_list[key] = data
			else:
				_level_data.slider_list.erase(key)
	
	
func _on_save_query_received(validation: bool, level_name: String, level_moves: int):
	if validation:
		# Se faccio partire da editor creo una nuova risorsa direttamente
		# nella cartella dedicata alle risorse dei livelli
		if OS.has_feature("debug"):
			var dir := "res://assets/resources/levels/"
			var path := dir + level_name + ".tres"
			_level_data.moves_left = level_moves
			ResourceSaver.save(_level_data, path)
			get_tree().quit()
		else:
			#TODO: aggiungere al salvataggio del giocatore
			print("build game")


func _reset_builder_grid():
	for cell in cell_collection.values():
		cell.clear_cell()
	for slider in slider_collection.values():
		slider.clear_slider()
	_level_data = LevelData.new()

func _on_width_change(new_width: int) -> void:
	_level_data.width = new_width
	_construct_level()


func _on_height_change(new_height: int) -> void:
	_level_data.height = new_height
	_construct_level()
	

func get_level_data() -> LevelData:
	return _level_data
