extends Node2D

const BASIC_TILE = preload("res://scenes/BasicTile.tscn")
const SCALABLE_AREA = preload("res://scenes/ScalableArea.tscn")
const RESOURCE_PATH = "res://assets/resources/level"

@export_range(2,5) var level_width: int = 2
@export_range(2,5) var level_height: int = 2
@export_range(0,100) var level_index: int

var selected_tile: Tile
var selected_handle: ScalableArea

var cells_values: Dictionary
var cells_list: Array[Array]
var handles_value: Dictionary
var handles_list: Array
var counter_list: Array

func _ready() -> void:
	var level_size: Vector2i
	level_size = Vector2i(level_height, level_width)
	
	var grid = Node2D.new()
	self.add_child(grid)
	
	grid.position = get_viewport_rect().get_center()


	var half_grid_size = level_size * GlobalConst.CELL_SIZE / 2

	# placing tiles
	for row in range(0, level_size.y):
		var row_cells: Array
		
		for column in range(0, level_size.x):
			var tile_instance := BASIC_TILE.instantiate()
			var tile_x_pos := (column - float(level_size.x) / 2) * GlobalConst.CELL_SIZE
			var tile_y_pos := (row - float(level_size.y) / 2) * GlobalConst.CELL_SIZE

			tile_instance.position = Vector2(tile_x_pos, tile_y_pos)
			grid.add_child(tile_instance)
			row_cells.append(tile_instance)
			cells_values[tile_instance] = 0
			tile_instance.enter.connect(_tile_select)
			tile_instance.exit.connect(_tile_deselect)
			
		cells_list.append(row_cells)


	# placing scalable areas clockwise
	for sc_index in range(1, level_height * 2 + level_width * 2 + 1):
		var x_pos: float
		var y_pos: float
		var is_horizontal: bool
		var extend_limit: int

		if sc_index > 0 and sc_index <= level_size.x:
			extend_limit = level_size.y
			is_horizontal = false
			x_pos = -half_grid_size.x - GlobalConst.CELL_SIZE / 2 + GlobalConst.CELL_SIZE * sc_index
			y_pos = -half_grid_size.y


		elif sc_index > level_size.x and sc_index <= (level_size.x + level_size.y):
			extend_limit = -level_size.x
			is_horizontal = true
			x_pos = half_grid_size.x
			y_pos = (
				-half_grid_size.y
				- GlobalConst.CELL_SIZE / 2
				+ GlobalConst.CELL_SIZE * (sc_index - level_size.x)
			)

		elif (
			sc_index > (level_size.x + level_size.y)
			and sc_index <= (level_size.x * 2 + level_size.y)
		):
			extend_limit = -level_size.y
			is_horizontal = false
			x_pos = (
				half_grid_size.x
				+ GlobalConst.CELL_SIZE / 2
				- GlobalConst.CELL_SIZE * (sc_index - level_size.x - level_size.y)
			)
			y_pos = half_grid_size.y

		elif sc_index > (level_size.x * 2 + level_size.y):
			extend_limit = level_size.x
			is_horizontal = true
			x_pos = -half_grid_size.x
			y_pos = (
				half_grid_size.y
				+ GlobalConst.CELL_SIZE / 2
				- GlobalConst.CELL_SIZE * (sc_index - level_size.x * 2 - level_size.y)
			)

		var sc_instance = SCALABLE_AREA.instantiate()
		var arr: Array[Tile]
		grid.add_child(sc_instance)
		handles_list.append(sc_instance)
		handles_value[sc_instance] = 0
		sc_instance.position = Vector2(x_pos, y_pos)		
		sc_instance.init(is_horizontal, extend_limit, arr, false)
		sc_instance.enter.connect(_handle_select)
		sc_instance.exit.connect(_handle_deselect)
		var counter: Label = Label.new()
		counter.text = "0"
		counter.add_theme_font_size_override("font_size", 32)
		counter.add_theme_color_override("font_color",Color.BLACK)	
		counter.position = Vector2(-50,0)
		counter.size = Vector2(30,30)
		counter_list.append(counter)
		sc_instance.add_child(counter)
		counter.rotation -= sc_instance.rotation


func _process(_delta) -> void:
	if Input.is_action_just_pressed("crea"):
		_create_resource()
	
	if Input.is_action_just_pressed("click"):
		_increment()
		
	if Input.is_action_just_pressed("click_dx"):
		_decrement()
	

func _tile_select(tile: Tile, _handle: ScalableArea) -> void:
	selected_tile = tile


func _tile_deselect(tile: Tile) -> void:
	if selected_tile == tile:
		selected_tile = null
	

func _handle_select(handle: ScalableArea) -> void:
	selected_handle = handle


func _handle_deselect(handle: ScalableArea) -> void:
	if selected_handle == handle:
		selected_handle = null


func _create_resource() -> void:
	var new_resource = LevelData.new()
	new_resource.cells_values = _get_cells()
	new_resource.handles_positions = _get_handle()
	new_resource.handles_increment = _get_increment()
	var save_result = ResourceSaver.save(new_resource, RESOURCE_PATH + String.num(level_index) + ".tres")
	if save_result != OK:
		print(save_result)


func _get_cells() -> Array[Array]:
	for row in range(0, cells_list[0].size()):
		for column in range(0, cells_list.size()):
			var cell: Tile = cells_list[column][row]
			var val: int = cells_values.get(cell)
			cells_list[column][row] = val
	return cells_list


func _get_handle() -> Array[int]:
	var result: Array[int]
	for i in range(0,handles_list.size()):
		if handles_value.get(handles_list[i]) != 0:
			result.append(i+1)
	return result

func _get_increment() -> Array[bool]:
	var result: Array[bool]
	for i in range(0,counter_list.size()):
		if handles_value.get(handles_list[i]) > 0:
			result.append(true)
		elif handles_value.get(handles_list[i]) < 0:
			result.append(false)
	return result
	
	
func _increment() -> void:
	if selected_handle != null:
		handles_value[selected_handle] += 1
		selected_handle.toggle_highlight(handles_value[selected_handle] != 0)
		for i in range(0, handles_list.size()):
			if handles_list[i] == selected_handle:
				counter_list[i].text = String.num(handles_value[selected_handle])
		
	if selected_tile != null:
		selected_tile.value +=1
		selected_tile._update()
		cells_values[selected_tile] = selected_tile.value


func _decrement() -> void:
	if selected_handle != null:
		handles_value[selected_handle] -= 1
		selected_handle.toggle_highlight(handles_value[selected_handle] != 0)
		for i in range(0, handles_list.size()):
			if handles_list[i] == selected_handle:
				counter_list[i].text = String.num(handles_value[selected_handle])
		
	if selected_tile != null:
		selected_tile.value -=1
		selected_tile._update()
		cells_values[selected_tile] = selected_tile.value
		
