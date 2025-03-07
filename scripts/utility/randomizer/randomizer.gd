class_name Randomizer extends Node

var _options: RandomizerOptions
const SQUARE_DIRECTION := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
const CROSS_DIRECTION := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]


func _init(new_options: RandomizerOptions) -> void:
	_options = new_options
	

func generate_level(data: LevelData) -> void:
	await _generate_grid(data)
	await create_holes(data)
	await create_block(data)
	await create_sliders(data)
	

func _generate_grid(data: LevelData) -> void:
	if !_options.grid_opt:
		data.width = 3
		data.height = 3
		return
		
	var grid_options := _options.grid_opt
	var size := grid_options.std_grid_sizes.pick_random() as Vector2i
	
	match _get_rule(grid_options.size_rules):
		"STANDARD":
			pass
			
		"LOWER":
			while true:
				await get_tree().process_frame
				if !_check_probability(grid_options.lower_odd):
					break
				size = grid_options.get_lower_size(size)
				if size == Vector2i(2, 2):
					break
					
		"UPPER":
			while true:
				await get_tree().process_frame
				if !_check_probability(grid_options.upper_odd):
					break
				size = grid_options.get_upper_size(size)
				if size == Vector2i(5, 5):
					break	
	
	data.width = size.x
	data.height = size.y
	await get_tree().process_frame
	

func _remove_holes(data: LevelData) -> void:
	for x in range(data.width):
		for y in range(data.height):
			var coord := Vector2i(x, y)
			if !data.cells_list.has(coord):
				data.cells_list[coord] = CellData.new()
	await get_tree().process_frame


func create_holes(data: LevelData) -> void:
	await _remove_holes(data)
	if _options.hole_opt == null:
		return
		
	var hole_options := _options.hole_opt
	var cell_count := data.cells_list.size()
	var counter: int = 0
	
	if hole_options.std_diffusion > 0:	
		match _get_rule(hole_options.diffusion_rules):
			"NONE":
				pass
				
			"LOWER":
				counter = ceili(float(cell_count) / 100 * hole_options.std_diffusion)
				while true:
					if counter > 1 and _check_probability(hole_options.remove_odd):
						counter -= 1
					else:
						break
						
			"MAX":
				# max hole count is percetage of all cells
				counter = ceili(float(cell_count) / 100 * hole_options.std_diffusion)	
							
	if counter == 0:
		return
		
	await get_tree().process_frame
	var cells := data.cells_list.keys()
	var origin := cells.pick_random() as Vector2i
	data.cells_list.erase(origin)
	counter -= 1
	
	while counter > 0:
		var adiacent := _get_round_cells(origin, cells)
		if adiacent.is_empty():
			break
		origin = adiacent.pick_random()
		data.cells_list.erase(origin)
		counter -= 1
	await get_tree().process_frame


func _remove_blocks(data: LevelData) -> void:
	for coord: Vector2i in data.cells_list.keys():
		var cell_data := data.cells_list.get(coord) as CellData
		cell_data.is_blocked = false
	await get_tree().process_frame
	

func create_block(data: LevelData) -> void:
	if data.cells_list.is_empty():
		await _remove_holes(data)
	await _remove_blocks(data)
	if _options.locked_opt == null:
		return
		
	var blocked_options := _options.locked_opt
	var cell_count := data.cells_list.size()
	var counter: int = 0
	
	if blocked_options.std_diffusion > 0:
		match _get_rule(blocked_options.diffusion_rules):
			"NONE":
				pass
				
			"LOWER":
				counter = ceili(float(cell_count) / 100 * blocked_options.std_diffusion)
				while true:
					if counter > 1 and _check_probability(blocked_options.remove_odd):
						counter -= 1
					else:
						break
						
			"MAX":
				# max locked count is percetage of all remaing cells
				counter = ceili(float(cell_count) / 100 * blocked_options.std_diffusion)
				
	await get_tree().process_frame
	var cells := data.cells_list.keys()
	
	if counter > 0:
		cells.shuffle()
		while counter > 0:
			var coord := cells.pop_back() as Vector2i
			var cell_data := data.cells_list.get(coord) as CellData
			cell_data.is_blocked = true
			counter -= 1
	await get_tree().process_frame
	
	# lock orphan cells
	while true:
		var	has_horphan: bool
		for coord: Vector2i in cells:
			var adiacents := _get_side_cells(coord, cells)
			var has_adiacent: bool
			for adiacent: Vector2i in adiacents:
				var cell_data := data.cells_list.get(coord) as CellData
				if !cell_data.is_blocked:
					has_adiacent = true
					break
			if !has_adiacent:
				var cell_data := data.cells_list.get(coord) as CellData
				cell_data.is_blocked = true
				cells.erase(coord)
				has_horphan = true
				break
		await get_tree().process_frame
		if !has_horphan:
			break


func _remove_sliders(data: LevelData) -> void:
	data.slider_list.clear()
	for cell: CellData in data.cells_list.values():
		if cell.is_blocked == false:
			cell.value = 0
	await get_tree().process_frame


func create_sliders(data: LevelData) -> void:
	if data.cells_list.is_empty():
		await _remove_holes(data)
	await _remove_sliders(data)
	
	if !_options.slider_opt:
		_options.slider_opt = RandomSliderOptions.new()
		
	# get all slider with reachable cells
	var possible_sliders: Dictionary
	await _get_possible_sliders(data, possible_sliders)
	if possible_sliders.is_empty():
		printerr("no one slider")
		return
		
	# filter random sliders with random extesion
	var filtered_sliders: Dictionary
	await _get_filtered_sliders(possible_sliders, filtered_sliders)
	
	# add sliders and calculate grid cells value
	await _add_sliders(data, filtered_sliders)


func _add_sliders(data: LevelData, filtered: Dictionary) -> void:
	var slider_options := _options.slider_opt
	var block_sliders: Array[Vector2i]
	var change_sliders: Array[Vector2i]
	var normal_sliders: Array[Vector2i]
	var locked_cells: Array[CellData]
	var receiver_cells: Dictionary
	var effect_slider_count := 0

	for slider_coord: Vector2i in filtered.keys():
		var slider_data := filtered.get(slider_coord) as RandomizerSlider
		
		match _get_rule(slider_options.type_rules):
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

	await get_tree().process_frame
	# add slider-block
	for slider_coord in block_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.is_none() or slider.is_full():
			if _check_probability(slider_options.block_full_odd):
				slider.behavior = GlobalConst.AreaBehavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := data.cells_list[cell_coord] as CellData
			if cell_data.is_blocked:
				if i == 0:
					if !_check_probability(slider_options.extension_rules.NONE):
						# remove slider-block with no extension
						filtered.erase(slider_coord)
					break
				slider.is_stopped = true
				slider.reached.resize(i)
				if _check_probability(slider_options.block_full_odd_on_stop):
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

	await get_tree().process_frame
	# mix other sliders
	if !change_sliders.is_empty():
		normal_sliders.append_array(change_sliders)
		normal_sliders.shuffle()
	# add other sliders
	for slider_coord in normal_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.is_full():
			if _check_probability(slider_options.full_odd):
				slider.behavior = GlobalConst.AreaBehavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := data.cells_list.get(cell_coord) as CellData
			if cell_data.is_blocked:
				if i == 0:
					if !_check_probability(slider_options.extension_rules.NONE):
						# remove other slider with no extension
						filtered.erase(slider_coord)
					break
				if _check_probability(slider_options.full_odd_on_stop):
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

	await get_tree().process_frame
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
			if _check_probability(slider_options.block_full_odd_on_stop):
				slider.behavior = GlobalConst.AreaBehavior.FULL

	await get_tree().process_frame
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
			if !filtered.has(slider_coord):
				continue
			var slider_data := filtered.get(slider_coord) as RandomizerSlider
			var blocked_sliders: Array[Vector2i]
			for cell_coord in slider_data.reached:
				while true:
					if !stopped_sliders.values().has(cell_coord):
						break
					var coord := stopped_sliders.find_key(cell_coord) as Vector2i
					stopped_sliders.erase(coord)
					blocked_sliders.append(coord)
			if blocked_sliders.size() <= 1:
				continue
			if _check_probability(slider_options.block_full_retract_odd):
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

	await get_tree().process_frame
	# add slider to level data
	for slider_coord: Vector2i in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		var slider_data := SliderData.new()
		slider_data.area_effect = slider.effect
		slider_data.area_behavior = slider.behavior
		data.slider_list[slider_coord] = slider_data

	# remove temporarily block
	for cell_data in locked_cells:
		cell_data.is_blocked = false
		_apply_slider_effect(cell_data, GlobalConst.AreaEffect.BLOCK)
	await get_tree().process_frame
	

func _get_filtered_sliders(possible: Dictionary, result: Dictionary) -> void:
	# calculate sliders diffusion
	var slider_options := _options.slider_opt
	var filterd := possible.keys()
	var slider_count: int = 0
	var max_diffusion: int = possible.size()
	var diffusion_range: Vector2i
	
	if max_diffusion % 2 == 0:
		diffusion_range = slider_options.std_occupation.get(max_diffusion) as Vector2i
	else:
		diffusion_range = slider_options.std_occupation.get(max_diffusion + 1) as Vector2i
		
	match _get_rule(slider_options.occupation_rules):
		"STANDARD":
			slider_count = randi_range(diffusion_range.x, diffusion_range.y)
			
		"LOWER":
			slider_count = diffusion_range.x
			while _check_probability(slider_options.lower_odd):
				slider_count -= 1
				if slider_count <= 1:
					slider_count = 1
					break
					
		"UPPER":
			slider_count = diffusion_range.y
			while _check_probability(slider_options.upper_odd):
				slider_count += 1
				if slider_count >= max_diffusion:
					slider_count = max_diffusion
					break
					
	await get_tree().process_frame
	filterd.shuffle()
	filterd.resize(slider_count)
	
	# calculate sliders extesion
	var extended_count: int = 0
	for slider_coord: Vector2i in filterd:
		await get_tree().process_frame
		var slider_data := RandomizerSlider.new()
		slider_data.reachable = possible.get(slider_coord) as Array[Vector2i]
		var reached := possible.get(slider_coord).duplicate() as Array[Vector2i]
		
		match _get_rule(slider_options.extension_rules):
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
		
	# no extended slider so force the first one manually
	if extended_count == 0:
		var slider_data := result.get(result.keys()[0]) as RandomizerSlider
		slider_data.reached = slider_data.reachable
	await get_tree().process_frame


func _apply_slider_effect(cell: CellData, area_effect: GlobalConst.AreaEffect) -> void:
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


func _is_opposite_slider(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return false
		
	if a.x != b.x:
		if a.x % 2 == b.x % 2:
			return true
			
	return false


func _get_possible_sliders(data: LevelData, result: Dictionary) -> void:
	var size := Vector2i(data.width, data.height)
	
	for edge: int in range(4):
		var max_pos := data.width if edge % 2 == 0 else data.height
		
		for position: int in range(max_pos):
			var slider_coord := Vector2i(edge, position)
			var reference_cell := _get_slider_reference_cell(size, slider_coord)
			
			if data.cells_list.has(reference_cell):
				var cell_data := data.cells_list.get(reference_cell) as CellData
				
				if !cell_data.is_blocked:
					result[slider_coord] = _get_slider_extension(edge, reference_cell, data)
			await get_tree().process_frame
		

func _get_slider_reference_cell(size: Vector2i, slider_coord: Vector2i) -> Vector2i:
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


func _get_slider_extension(edge: int, origin: Vector2i, data: LevelData) -> Array[Vector2i]:
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


func _get_round_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction: Vector2i in SQUARE_DIRECTION + CROSS_DIRECTION:
		var adiacent: Vector2i = pos + direction
		if cells.has(adiacent):
			result.append(adiacent)
	return result


func _get_side_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction: Vector2i in SQUARE_DIRECTION:
		var adiacent: Vector2i = pos + direction
		if cells.has(adiacent):
			result.append(adiacent)
	return result
	

func _check_probability(probability: float) -> bool:
	var random := randi_range(1, 100)
	return true if random <= probability else false


func _get_rule(rules_odd: Dictionary) -> String:
	var random := randi_range(1, 100)
	var counter_odd := 0
	
	for rule: String in rules_odd.keys():
		counter_odd += rules_odd.get(rule) as int
		if random <= counter_odd:
			return rule
			
	push_error("No rules found!")
	return ""
