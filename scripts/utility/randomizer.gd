class_name Randomizer

const HOLE_CELL_ODD := 75
const BLOCK_CELL_ODD := 60

const SLIDER_ODD := 85
const SLIDER_FULL_ODD := 15
const ADD_SLIDER_ODD := 40
const SUBTRACT_SLIDER_ODD := 40
const INVERT_SLIDER_ODD := 5

const BLOCK_SLIDER_ODD := 5
const BLOCK_SLIDER_FULL_ODD := 50

const MAX_CELLS := 25
const MIN_CELLS := 4
const SQUARE_DIRECTION := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
const CROSS_DIRECTION := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]


static func generate() -> LevelData:
	var data := LevelData.new()
	data.width = randi_range(2, 5)
	data.height = randi_range(2, 5)

	if _check_probability(HOLE_CELL_ODD):
		create_holes(data)
	if _check_probability(BLOCK_CELL_ODD):
		create_block(data)
	create_sliders(data)
	return data


static func _remove_holes(data: LevelData) -> void:
	for x in range(data.width):
		for y in range(data.height):
			var coord := Vector2i(x, y)
			if !data.cells_list.has(coord):
				data.cells_list[coord] = CellData.new()


static func create_holes(data: LevelData) -> void:
	_remove_holes(data)
	var cells = data.cells_list.keys()
	var origin = cells.pick_random() as Vector2i
	data.cells_list.erase(origin)
	# maximum holes 25% of cells including start
	var number := roundi(float(cells.size()) / 4) - 1
	while number > 0:
		var adiacent := _get_adiacent_cells(origin, cells)
		if adiacent.is_empty():
			break
		origin = adiacent.pick_random()
		data.cells_list.erase(origin)
		number -= 1


static func _remove_blocks(data: LevelData) -> void:
	for coord in data.cells_list.keys():
		var cell_data = data.cells_list.get(coord) as CellData
		cell_data.is_blocked = false


static func create_block(data: LevelData) -> void:
	if data.cells_list.is_empty():
		_remove_holes(data)
	_remove_blocks(data)
	var cells = data.cells_list.keys()
	var origin = cells.pick_random() as Vector2i
	var cell_data: CellData
	cell_data = data.cells_list.get(origin) as CellData
	cell_data.is_blocked = true
	# maximum holes 25% of cells including start
	var number := roundi(float(cells.size()) / 4) - 1
	while number > 0:
		var adiacent := _get_adiacent_cells(origin, cells)
		if adiacent.is_empty():
			break
		origin = adiacent.pick_random()
		cell_data = data.cells_list.get(origin) as CellData
		cell_data.is_blocked = true
		number -= 1


static func _remove_sliders(data: LevelData) -> void:
	data.slider_list.clear()
	for cell: CellData in data.cells_list.values():
		if cell.is_blocked == false:
			cell.value = 0


static func create_sliders(data: LevelData) -> void:
	if data.cells_list.is_empty():
		_remove_holes(data)
	_remove_sliders(data)
	# backup persistent blocked cells
	var persistent_blocks := _get_persistent_blocks(data.cells_list)
	# all slider with reachable cells
	var possible_sliders := _get_possible_sliders(data)
	# all cell with occupied sliders
	var cell_occupied := _get_cell_occupation(possible_sliders)
	# selected slider with reached cell
	var selected_slider := _get_selected_sliders(cell_occupied)
	# trying to fit block sliders into the remaining spots
	_add_block_sliders(data, possible_sliders, selected_slider)
	# add remaining sliders and calculate grid cells value
	_add_sliders(data, possible_sliders, selected_slider)
	# restore original blocked cells
	_remove_temporarily_blocks(data.cells_list, persistent_blocks)


static func _get_persistent_blocks(cells: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for cell_coord: Vector2i in cells.keys():
		var cell_data := cells.get(cell_coord) as CellData
		if cell_data.is_blocked:
			result.append(cell_coord)
	return result


static func _remove_temporarily_blocks(cells: Dictionary, blocks: Array[Vector2i]) -> void:
	for cell_coord: Vector2i in cells.keys():
		if blocks.has(cell_coord):
			continue
		var cell_data := cells.get(cell_coord) as CellData
		cell_data.is_blocked = false


static func _add_sliders(data: LevelData, possible: Dictionary, selected: Dictionary) -> void:
	for slider_coord: Vector2i in selected.keys():
		var slider_data := _get_random_slider()
		data.slider_list[slider_coord] = slider_data
		var reachable_cells := possible.get(slider_coord) as Array[Vector2i]
		var reached_cells := selected.get(slider_coord) as Array[Vector2i]
		if reached_cells.size() == reachable_cells.size():
			if _check_probability(SLIDER_FULL_ODD):
				slider_data.area_behavior = GlobalConst.AreaBehavior.FULL
		for cell_coord in reachable_cells:
			if !reached_cells.has(cell_coord):
				break
			var cell_data := data.cells_list.get(cell_coord) as CellData
			if cell_data.is_blocked:
				if _check_probability(SLIDER_FULL_ODD):
					slider_data.area_behavior = GlobalConst.AreaBehavior.FULL
				break
			_apply_slider_effect(cell_data, slider_data.area_effect)


static func _add_block_sliders(data: LevelData, possible: Dictionary, selected: Dictionary) -> void:
	var filtered: Array[Vector2i]
	for slider_coord: Vector2i in possible.keys():
		if selected.has(slider_coord):
			continue
		filtered.append(slider_coord)
	if filtered.is_empty():
		return
	for slider_coord in filtered:
		if _check_probability(BLOCK_SLIDER_ODD):
			var reachable := possible.get(slider_coord) as Array[Vector2i]
			var max_extension := reachable.size()
			var extension := randi_range(0, max_extension)
			reachable.resize(extension)
			var slider := SliderData.new()
			slider.area_effect = GlobalConst.AreaEffect.BLOCK
			if extension == 0 or extension == max_extension:
				if _check_probability(BLOCK_SLIDER_FULL_ODD):
					slider.area_behavior = GlobalConst.AreaBehavior.FULL
			data.slider_list[slider_coord] = slider
			for cell_coord in reachable:
				var cell_data := data.cells_list[cell_coord] as CellData
				_apply_slider_effect(cell_data, GlobalConst.AreaEffect.BLOCK)


static func _get_cell_occupation(sliders: Dictionary) -> Dictionary:
	var result: Dictionary

	for slider_coord: Vector2i in sliders.keys():
		var slider_reachable := sliders.get(slider_coord) as Array[Vector2i]
		for reachable in slider_reachable:
			var sliders_list: Array[Vector2i]
			if result.has(reachable):
				sliders_list = result.get(reachable)
			sliders_list.append(slider_coord)
			result[reachable] = sliders_list

	return result


static func _get_selected_sliders(cell_occupation: Dictionary) -> Dictionary:
	var result: Dictionary
	var discarded: Array[Vector2i]

	for cell_coord: Vector2i in cell_occupation.keys():
		for slider in cell_occupation.get(cell_coord):
			if discarded.has(slider):
				continue
			if _check_probability(SLIDER_ODD):
				var cell_list: Array[Vector2i]
				if result.has(slider):
					cell_list = result.get(slider)
				cell_list.append(cell_coord)
				result[slider] = cell_list
			else:
				discarded.append(slider)
				result.erase(slider)

	return result


static func _apply_slider_effect(cell: CellData, area_effect: GlobalConst.AreaEffect) -> void:
	match area_effect:
		GlobalConst.AreaEffect.ADD:
			cell.value -= 1
		GlobalConst.AreaEffect.SUBTRACT:
			cell.value += 1
		GlobalConst.AreaEffect.CHANGE_SIGN:
			cell.value *= -1
		GlobalConst.AreaEffect.BLOCK:
			# temporarily block for the next checks
			cell.is_blocked = true
			# applies a random effect to mask the block effect
			match randi_range(1, 3):
				1:
					cell.value -= 1
				2:
					cell.value += 1
				3:
					cell.value *= -1


static func _get_possible_sliders(data: LevelData) -> Dictionary:
	var result: Dictionary
	var size := Vector2i(data.width, data.height)

	for edge in range(4):
		var max_pos := data.width if edge % 2 == 0 else data.height
		for position in range(max_pos):
			var slider_coord := Vector2i(edge, position)
			var reference_cell := _get_slider_reference_cell(size, slider_coord)
			if data.cells_list.has(reference_cell):
				var cell_data := data.cells_list.get(reference_cell) as CellData
				if !cell_data.is_blocked:
					result[slider_coord] = _get_slider_extension(edge, reference_cell, data)
	return result


static func _get_slider_reference_cell(size: Vector2i, slider_coord: Vector2i) -> Vector2i:
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


static func _get_slider_extension(edge: int, origin: Vector2i, data: LevelData) -> Array[Vector2i]:
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


static func _get_adiacent_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction in SQUARE_DIRECTION + CROSS_DIRECTION:
		var adiacent: Vector2i = pos + direction
		if cells.has(adiacent):
			result.append(adiacent)
	return result


static func _check_probability(probability: float) -> bool:
	var random := randi_range(1, 100)
	return true if random <= probability else false


static func _get_random_slider() -> SliderData:
	var result := SliderData.new()
	var max_odd := ADD_SLIDER_ODD + SUBTRACT_SLIDER_ODD + INVERT_SLIDER_ODD
	var add_odd := Vector2i(0, ADD_SLIDER_ODD)
	var subtract_odd := Vector2i(add_odd.y, add_odd.y + SUBTRACT_SLIDER_ODD)
	var invert_odd := Vector2i(subtract_odd.y, subtract_odd.y + INVERT_SLIDER_ODD)
	var random := randi_range(1, max_odd)
	if random <= add_odd.y:
		result.area_effect = GlobalConst.AreaEffect.ADD
	elif random > subtract_odd.x and random <= subtract_odd.y:
		result.area_effect = GlobalConst.AreaEffect.SUBTRACT
	elif random > invert_odd.x:
		result.area_effect = GlobalConst.AreaEffect.CHANGE_SIGN
	return result
