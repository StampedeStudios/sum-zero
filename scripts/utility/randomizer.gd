class_name Randomizer

const HOLE_CELL_ODD := 75
const BLOCK_CELL_ODD := 60

const SLIDER_ODD := 50
const ADD_SLIDER_ODD := 40
const SUBTRACT_SLIDER_ODD := 40
const INVERT_SLIDER_ODD := 5
const BLOCK_SLIDER_ODD := 0

const MAX_CELLS := 25
const MIN_CELLS := 4
const SQUARE_DIRECTION := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
const CROSS_DIRECTION := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]


static func generate() -> LevelData:
	var data := LevelData.new()
	data.width = randi_range(2, 5)
	data.height = randi_range(2, 5)

	if check_probability(HOLE_CELL_ODD):
		create_holes(data)
	if check_probability(BLOCK_CELL_ODD):
		create_block(data)
	return data


static func remove_holes(data: LevelData) -> void:
	for x in range(data.width):
		for y in range(data.height):
			var coord := Vector2i(x, y)
			if !data.cells_list.has(coord):
				data.cells_list[coord] = CellData.new()


static func create_holes(data: LevelData) -> void:
	remove_holes(data)
	var cells = data.cells_list.keys()
	var origin = cells.pick_random() as Vector2i
	data.cells_list.erase(origin)
	# maximum holes 25% of cells including start
	var number := roundi(float(cells.size()) / 4) - 1
	while number > 0:
		var adiacent := get_adiacent_cells(origin, cells)
		if adiacent.is_empty():
			break
		origin = adiacent.pick_random()
		data.cells_list.erase(origin)
		number -= 1


static func remove_blocks(data: LevelData) -> void:
	for coord in data.cells_list.keys():
		var cell_data = data.cells_list.get(coord) as CellData
		cell_data.is_blocked = false


static func create_block(data: LevelData) -> void:
	if data.cells_list.is_empty():
		remove_holes(data)
	remove_blocks(data)
	var cells = data.cells_list.keys()
	var origin = cells.pick_random() as Vector2i
	var cell_data: CellData
	cell_data = data.cells_list.get(origin) as CellData
	cell_data.is_blocked = true
	# maximum holes 25% of cells including start
	var number := roundi(float(cells.size()) / 4) - 1
	while number > 0:
		var adiacent := get_adiacent_cells(origin, cells)
		if adiacent.is_empty():
			break
		origin = adiacent.pick_random()
		cell_data = data.cells_list.get(origin) as CellData
		cell_data.is_blocked = true
		number -= 1


static func remove_sliders(data: LevelData) -> void:
	data.slider_list.clear()
	for cell: CellData in data.cells_list.values():
		if cell.is_blocked == false:
			cell.value = 0


static func create_sliders(data: LevelData) -> void:
	if data.cells_list.is_empty():
		remove_holes(data)
	remove_sliders(data)
	var possible_sliders := get_possible_sliders(data)

	for edge_group in possible_sliders:
		if edge_group.is_empty():
			continue
		var group_coord := edge_group.keys()
		group_coord.shuffle()
		while group_coord.size() > 0:
			var coord := group_coord.pop_back() as Vector2i
			if check_probability(SLIDER_ODD):
				var reachable_cell := edge_group.get(coord) as Array[Vector2i]
				var slider := get_random_slider()
				data.slider_list[coord] = slider
				for i in range(randi_range(0, reachable_cell.size())):
					var cell := data.cells_list.get(reachable_cell[i]) as CellData
					apply_slider_effect(cell, slider)


static func apply_slider_effect(cell: CellData, slider: SliderData) -> void:
	match slider.area_effect:
		GlobalConst.AreaEffect.ADD:
			cell.value -= 1
		GlobalConst.AreaEffect.SUBTRACT:
			cell.value += 1
		GlobalConst.AreaEffect.CHANGE_SIGN:
			cell.value *= -1
		GlobalConst.AreaEffect.BLOCK:
			cell.value = 0  #TODO gestire quando inserito block
			cell.is_blocked = true


static func get_possible_sliders(data: LevelData) -> Array[Dictionary]:
	var result: Array[Dictionary]
	var size := Vector2i(data.width, data.height)
	for edge in range(4):
		var edge_group: Dictionary
		var max_pos := data.width if edge % 2 == 0 else data.height
		for position in range(max_pos):
			var slider_coord := Vector2i(edge, position)
			var reference_cell := get_slider_reference_cell(size, slider_coord)
			if data.cells_list.has(reference_cell):
				var cell_data := data.cells_list.get(reference_cell) as CellData
				if !cell_data.is_blocked:
					edge_group[slider_coord] = get_slider_extension(edge, reference_cell, data)
		result.append(edge_group)
	return result


static func get_slider_reference_cell(size: Vector2i, slider_coord: Vector2i) -> Vector2i:
	match slider_coord.x:
		0:
			return Vector2i(slider_coord.y, 0)
		1:
			return Vector2i(size.x - 1, slider_coord.y)
		2:
			return Vector2i(slider_coord.y, size.y - 1)
		3:
			return Vector2i(0, slider_coord.y)
	return Vector2i.ZERO


static func get_slider_extension(edge: int, origin: Vector2i, data: LevelData) -> Array[Vector2i]:
	var result: Array[Vector2i]
	var direction: Vector2i
	var max_extension: int

	match edge:
		0:
			direction = Vector2i.DOWN
			max_extension = data.height
		1:
			direction = Vector2i.LEFT
			max_extension = data.width
		2:
			direction = Vector2i.UP
			max_extension = data.height
		3:
			direction = Vector2i.RIGHT
			max_extension = data.width

	result.append(origin)
	for i in range(1, max_extension):
		var coord := origin + direction * i
		if !data.cells_list.has(coord):
			break
		var cell := data.cells_list.get(coord) as CellData
		if cell.is_blocked:
			break
		result.append(coord)
	return result


static func get_adiacent_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction in SQUARE_DIRECTION + CROSS_DIRECTION:
		var adiacent: Vector2i = pos + direction
		if cells.has(adiacent):
			result.append(adiacent)
	return result


static func check_probability(probability: float) -> bool:
	var random := randi_range(1, 100)
	return true if random <= probability else false


static func get_random_slider() -> SliderData:
	var result := SliderData.new()
	var max_odd := ADD_SLIDER_ODD + SUBTRACT_SLIDER_ODD + INVERT_SLIDER_ODD + BLOCK_SLIDER_ODD
	var add_odd := Vector2i(0, ADD_SLIDER_ODD)
	var subtract_odd := Vector2i(add_odd.y, add_odd.y + SUBTRACT_SLIDER_ODD)
	var invert_odd := Vector2i(subtract_odd.y, subtract_odd.y + INVERT_SLIDER_ODD)
	var block_odd := Vector2i(invert_odd.y, max_odd)
	var random := randi_range(1, max_odd)
	if random <= add_odd.y:
		result.area_effect = GlobalConst.AreaEffect.ADD
	elif random > subtract_odd.x and random <= subtract_odd.y:
		result.area_effect = GlobalConst.AreaEffect.SUBTRACT
	elif random > invert_odd.x and random <= invert_odd.y:
		result.area_effect = GlobalConst.AreaEffect.CHANGE_SIGN
	elif random > block_odd.x:
		result.area_effect = GlobalConst.AreaEffect.BLOCK
	return result
