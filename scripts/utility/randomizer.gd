class_name Randomizer

const OPTIONS := preload("res://assets/resources/utility/randomizer_options.tres")
const SQUARE_DIRECTION := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
const CROSS_DIRECTION := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]


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
	# get all slider with reachable cells
	var possible_sliders := _get_possible_sliders(data)
	# filter random sliders with random extesion
	var filtered_sliders := _get_filtered_sliders(possible_sliders)
	# add sliders and calculate grid cells value
	_add_sliders(data, filtered_sliders)


static func _add_sliders(data: LevelData, filtered: Dictionary) -> void:
	var block_sliders: Array[Vector2i]
	var change_sliders: Array[Vector2i]
	var normal_sliders: Array[Vector2i]
	var locked_cells: Array[CellData]
	var receiver_cells: Dictionary

	var effect_slider_count := 0
	for slider_coord: Vector2i in filtered.keys():
		var slider_data := filtered.get(slider_coord) as RandomizerSlider
		match _get_rule(OPTIONS.type_rules):
			"ADD":
				effect_slider_count += 1
				slider_data.effect = GlobalConst.AreaEffect.ADD
				normal_sliders.append(slider_coord)
			"SUBTRACT":
				effect_slider_count += 1
				slider_data.effect = GlobalConst.AreaEffect.SUBTRACT
				normal_sliders.append(slider_coord)
			"CHANGE_SIGN":
				slider_data.effect = GlobalConst.AreaEffect.CHANGE_SIGN
				change_sliders.append(slider_coord)
			"BLOCK":
				slider_data.effect = GlobalConst.AreaEffect.BLOCK
				block_sliders.append(slider_coord)

	# check that at least one slider affects the grid
	if effect_slider_count == 0:
		var slider_coord := filtered.keys()[0] as Vector2i
		var slider_data := filtered.get(slider_coord) as RandomizerSlider
		slider_data.effect = GlobalConst.AreaEffect.ADD
		normal_sliders.append(slider_coord)
		block_sliders.erase(slider_coord)
		change_sliders.erase(slider_coord)

	# add slider-block
	for slider_coord in block_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.is_none() or slider.is_full():
			if _check_probability(OPTIONS.block_full_odd):
				slider.behavior = GlobalConst.AreaBehavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := data.cells_list[cell_coord] as CellData
			if cell_data.is_blocked:
				if i == 0:
					if !_check_probability(OPTIONS.extension_rules.NONE):
						# remove slider-block with no extension
						filtered.erase(slider_coord)
					break
				slider.is_stopped = true
				slider.reached.resize(i)
				if _check_probability(OPTIONS.block_full_odd_on_stop):
					slider.behavior = GlobalConst.AreaBehavior.FULL
				break
			# temporarily block for the next checks
			cell_data.is_blocked = true
			locked_cells.append(cell_data)
			var emitter_sliders: Array[Vector2i]
			if receiver_cells.has(cell_coord):
				emitter_sliders = receiver_cells.get(cell_coord)
			emitter_sliders.append(slider_coord)
			receiver_cells[cell_coord] = emitter_sliders

	# mix other sliders
	if !change_sliders.is_empty():
		normal_sliders.append_array(change_sliders)
		normal_sliders.shuffle()
	# add other sliders
	for slider_coord in normal_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.is_full():
			if _check_probability(OPTIONS.full_odd):
				slider.behavior = GlobalConst.AreaBehavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := data.cells_list.get(cell_coord) as CellData
			if cell_data.is_blocked:
				if i == 0:
					if !_check_probability(OPTIONS.extension_rules.NONE):
						# remove other slider with no extension
						filtered.erase(slider_coord)
					break
				if _check_probability(OPTIONS.full_odd_on_stop):
					slider.behavior = GlobalConst.AreaBehavior.FULL
				slider.is_stopped = true
				slider.reached.resize(i)
				break
			_apply_slider_effect(cell_data, slider.effect)
			var emitter_sliders: Array[Vector2i]
			if receiver_cells.has(cell_coord):
				emitter_sliders = receiver_cells.get(cell_coord)
			emitter_sliders.append(slider_coord)
			receiver_cells[cell_coord] = emitter_sliders

	# use unfull slider-block for check behavior-full probability
	for slider_coord: Vector2i in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.effect != GlobalConst.AreaEffect.BLOCK:
			continue
		if slider.is_stopped or slider.is_full():
			continue
		var cell_coord := slider.reachable[slider.reached.size()] as Vector2i
		if receiver_cells.has(cell_coord):
			var emitter_sliders := receiver_cells.get(cell_coord) as Array[Vector2i]
			if emitter_sliders.size() == 1:
				if _is_opposite_slider(emitter_sliders[0], slider_coord):
					var opposite := filtered.get(emitter_sliders[0]) as RandomizerSlider
					if opposite.behavior == GlobalConst.AreaBehavior.FULL:
						continue
			if _check_probability(OPTIONS.block_full_odd_on_stop):
				slider.behavior = GlobalConst.AreaBehavior.FULL

	# use stopped slider for check retractable slider-block
	var stopped_sliders: Dictionary
	for slider_coord: Vector2i in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.effect == GlobalConst.AreaEffect.BLOCK:
			continue
		if slider.is_stopped:
			stopped_sliders[slider_coord] = slider.reachable[slider.reached.size()]
	if stopped_sliders.size() > 1:
		for slider_coord in block_sliders:
			var blocked_sliders: Array[Vector2i]
			var slider_data := filtered.get(slider_coord) as RandomizerSlider
			for cell_coord in slider_data.reached:
				while true:
					var coord = stopped_sliders.find_key(cell_coord)
					if coord == null:
						break
					stopped_sliders.erase(coord)
					blocked_sliders.append(coord)
			if blocked_sliders.size() <= 1:
				continue
			if _check_probability(OPTIONS.block_full_retract_odd):
				# retract slider-block
				for coord in slider_data.reached:
					var cell_data := data.cells_list[coord] as CellData
					cell_data.is_blocked = false
					locked_cells.erase(cell_data)
				# extend other slider but last
				for i in range(blocked_sliders.size()):
					var slider := filtered.get(blocked_sliders[i]) as RandomizerSlider
					if i == blocked_sliders.size() - 1:
						# last slider blocked
						slider.behavior = GlobalConst.AreaBehavior.FULL
					else:
						if slider.effect != GlobalConst.AreaEffect.CHANGE_SIGN:
							for j in range(slider.reached.size(), slider.reachable.size()):
								var cell := data.cells_list[slider.reachable[j]] as CellData
								if cell.is_blocked:
									break
								_apply_slider_effect(cell, slider.effect)

	# add slider to level data
	for slider_coord in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		var slider_data := SliderData.new()
		slider_data.area_effect = slider.effect
		slider_data.area_behavior = slider.behavior
		data.slider_list[slider_coord] = slider_data

	# remove temporarily block
	for cell_data in locked_cells:
		cell_data.is_blocked = false
		_apply_slider_effect(cell_data, GlobalConst.AreaEffect.BLOCK)


static func _get_filtered_sliders(possible: Dictionary) -> Dictionary:
	# calculate sliders diffusion
	var result: Dictionary
	var filterd := possible.keys()
	var slider_count := 0
	var max_diffusion := possible.size() if possible.size() % 2 == 0 else possible.size() + 1
	var diffusion_range := OPTIONS.occupation_std.get(max_diffusion) as Vector2i
	max_diffusion = possible.size()
	match _get_rule(OPTIONS.occupation_rules):
		"STANDARD":
			slider_count = randi_range(diffusion_range.x, diffusion_range.y)
		"LOWER":
			slider_count = diffusion_range.x
			while _check_probability(OPTIONS.occupation_lower):
				slider_count -= 1
				if slider_count <= 1:
					slider_count = 1
					break
		"UPPER":
			slider_count = diffusion_range.y
			while _check_probability(OPTIONS.occupation_upper):
				slider_count += 1
				if slider_count >= max_diffusion:
					slider_count = max_diffusion
					break
	filterd.shuffle()
	filterd.resize(slider_count)
	# calculate sliders extesion
	var extended_count := 0
	for slider_coord in filterd:
		var slider_data := RandomizerSlider.new()
		slider_data.reachable = possible.get(slider_coord) as Array[Vector2i]
		var reached := possible.get(slider_coord).duplicate() as Array[Vector2i]
		match _get_rule(OPTIONS.extension_rules):
			"MAX":
				extended_count += 1
			"NONE":
				reached.clear()
			"RANDOM":
				extended_count += 1
				if reached.size() > 1:
					reached.resize(randi_range(1, reached.size() - 1))
		slider_data.reached = reached
		result[slider_coord] = slider_data
	if extended_count == 0:
		var slider_data := result.get(result.keys()[0]) as RandomizerSlider
		slider_data.reached = slider_data.reachable
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
			# applies a random effect to mask the slider-block effect
			match randi_range(1, 2):
				1:
					cell.value -= randi_range(1, 2)
					cell.value = clamp(cell.value, -4, 4)
				2:
					cell.value += randi_range(1, 2)
					cell.value = clamp(cell.value, -4, 4)


static func _is_opposite_slider(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return false
	if a.x != b.x:
		if a.x % 2 == b.x % 2:
			return true
	return false


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


static func _get_rule(rules_odd: Dictionary) -> String:
	var random := randi_range(1, 100)
	var counter_odd := 0
	for rule: String in rules_odd.keys():
		counter_odd += rules_odd.get(rule) as int
		if random <= counter_odd:
			return rule
	push_error("No rules found!")
	return ""
