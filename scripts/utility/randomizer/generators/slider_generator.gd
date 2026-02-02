## SliderGenerator
##
## Responsible for creating the sliders for the level based on the provided
## options. This is the core of the level generation, where the puzzle is
## actually created.
class_name SliderGenerator extends BaseGenerator


func _init(p_context: GenerationContext) -> void:
	super(p_context)


## Creates the sliders for the level.
func generate() -> void:
	if _context.level_data.cells_list.is_empty():
		_remove_holes()
	_remove_sliders()

	if !_context.options.slider_opt:
		_context.options.slider_opt = RandomSliderOptions.new()

	var possible_sliders: Dictionary[Vector2i, Array]
	await _get_possible_sliders(possible_sliders)
	if possible_sliders.is_empty():
		push_warning("Generated a level with no sliders. Generating again")
		return

	var filtered_sliders: Dictionary[Vector2i, RandomizerSlider]
	await _get_filtered_sliders(possible_sliders, filtered_sliders)

	await _add_sliders(filtered_sliders)

	await _remove_unnecessary_moves(filtered_sliders)


## Fills all empty cells in the grid, effectively removing all holes.
func _remove_holes() -> void:
	for x in range(_context.level_data.width):
		for y in range(_context.level_data.height):
			var coord := Vector2i(x, y)
			if !_context.level_data.cells_list.has(coord):
				_context.level_data.cells_list[coord] = CellData.new()
	await Engine.get_main_loop().process_frame


## Removes all sliders from the level and resets the value of all cells.
func _remove_sliders() -> void:
	_context.level_data.slider_list.clear()
	for cell: CellData in _context.level_data.cells_list.values():
		if cell.is_blocked == false:
			cell.value = 0
	await Engine.get_main_loop().process_frame


## Removes unnecessary moves from the level's move count.
func _remove_unnecessary_moves(filtered: Dictionary[Vector2i, RandomizerSlider]) -> void:
	var unnecessaty_moves: int = 0
	for edge: int in range(2):
		var max_pos := _context.level_data.width if edge % 2 == 0 else _context.level_data.height
		for position: int in range(max_pos):
			var slider_coord := Vector2i(edge, position)
			if !filtered.has(slider_coord):
				continue
			var slider_data := filtered.get(slider_coord) as RandomizerSlider
			if slider_data.reached.is_empty():
				continue
			var opposite_coord := Vector2i(edge + 2, position)
			if !filtered.has(opposite_coord):
				continue
			var opposite_data := filtered.get(opposite_coord) as RandomizerSlider
			if opposite_data.reached.is_empty():
				continue

			match slider_data.effect:
				Constants.Sliders.Effect.ADD:
					if opposite_data.effect != Constants.Sliders.Effect.SUBTRACT:
						continue
				Constants.Sliders.Effect.SUBTRACT:
					if opposite_data.effect != Constants.Sliders.Effect.ADD:
						continue
				_:
					continue

			var current_full := slider_data.reached.size() == slider_data.reachable.size()
			var opposite_full := opposite_data.reached.size() == opposite_data.reachable.size()

			if current_full and opposite_full:
				unnecessaty_moves += 2
			elif current_full and !opposite_full:
				if slider_data.behavior == Constants.Sliders.Behavior.BY_STEP:
					unnecessaty_moves += 1
			elif !current_full and opposite_full:
				if opposite_data.behavior == Constants.Sliders.Behavior.BY_STEP:
					unnecessaty_moves += 1
		await Engine.get_main_loop().process_frame

	_context.level_data.moves_left -= unnecessaty_moves
	await Engine.get_main_loop().process_frame


## Adds the sliders to the level data and calculates the final state of the grid.
func _add_sliders(filtered: Dictionary[Vector2i, RandomizerSlider]) -> void:
	var move_counter: int = 0
	var locked_cells: Array[CellData] = []
	var receiver_cells: Dictionary[Vector2i, Array] = {}

	var categorized_sliders := _categorize_sliders(filtered)
	var block_sliders: Array[Vector2i] = categorized_sliders["block"]
	var change_sliders: Array[Vector2i] = categorized_sliders["change"]
	var normal_sliders: Array[Vector2i] = categorized_sliders["normal"]

	move_counter += await _apply_block_sliders(
		block_sliders, filtered, receiver_cells, locked_cells
	)
	move_counter += await _apply_normal_sliders(
		normal_sliders, change_sliders, filtered, receiver_cells
	)
	move_counter += await _handle_retractable_sliders(block_sliders, filtered, locked_cells)

	_finalize_sliders(filtered, locked_cells)

	_context.level_data.moves_left = move_counter
	await Engine.get_main_loop().process_frame


## Categorizes sliders based on their effect type and ensures at least one effect slider exists.
## @param filtered The dictionary of filtered sliders.
## @return A dictionary containing arrays of block, change, and normal sliders.
func _categorize_sliders(filtered: Dictionary[Vector2i, RandomizerSlider]) -> Dictionary:
	var block_sliders: Array[Vector2i] = []
	var change_sliders: Array[Vector2i] = []
	var normal_sliders: Array[Vector2i] = []
	var effect_slider_count: int = 0
	var slider_options := _context.options.slider_opt

	for slider_coord: Vector2i in filtered.keys():
		var slider_data := filtered.get(slider_coord) as RandomizerSlider
		var type_rule := _get_rule(slider_options.type_rules)
		match type_rule:
			"ADD":
				effect_slider_count += 1
				slider_data.effect = Constants.Sliders.Effect.ADD
				normal_sliders.append(slider_coord)
			"SUBTRACT":
				effect_slider_count += 1
				slider_data.effect = Constants.Sliders.Effect.SUBTRACT
				normal_sliders.append(slider_coord)
			"CHANGE_SIGN":
				slider_data.effect = Constants.Sliders.Effect.CHANGE_SIGN
				change_sliders.append(slider_coord)
			"BLOCK":
				slider_data.effect = Constants.Sliders.Effect.BLOCK
				block_sliders.append(slider_coord)

	if effect_slider_count == 0 and not filtered.is_empty():
		var slider_coord := filtered.keys()[0] as Vector2i
		var slider_data := filtered.get(slider_coord) as RandomizerSlider
		slider_data.effect = Constants.Sliders.Effect.ADD
		if block_sliders.has(slider_coord):
			block_sliders.erase(slider_coord)
		if change_sliders.has(slider_coord):
			change_sliders.erase(slider_coord)
		normal_sliders.append(slider_coord)

	return {"block": block_sliders, "change": change_sliders, "normal": normal_sliders}


## Applies the effects of block sliders to the grid.
## @param block_sliders An array of coordinates for block sliders.
## @param filtered The dictionary of all filtered sliders.
## @param receiver_cells A dictionary mapping cell coordinates to arrays of slider
## 		  coordinates that affect them.
## @param locked_cells An array of CellData objects that are temporarily locked.
## @return The number of moves added by block sliders.
func _apply_block_sliders(
	block_sliders: Array[Vector2i],
	filtered: Dictionary[Vector2i, RandomizerSlider],
	receiver_cells: Dictionary[Vector2i, Array],
	locked_cells: Array[CellData]
) -> int:
	var move_counter: int = 0
	var slider_options := _context.options.slider_opt

	for slider_coord in block_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if !slider.is_none():
			move_counter += 1
		if slider.is_none() or slider.is_full():
			if _check_probability(slider_options.block_full_odd):
				slider.behavior = Constants.Sliders.Behavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := _context.level_data.cells_list[cell_coord] as CellData
			if cell_data.is_blocked:
				if i == 0:
					if !_check_probability(slider_options.extension_rules.NONE):
						filtered.erase(slider_coord)
						move_counter -= 1
					break
				slider.is_stopped = true
				slider.reached.resize(i)
				if _check_probability(slider_options.block_full_odd_on_stop):
					slider.behavior = Constants.Sliders.Behavior.FULL
				break
			cell_data.is_blocked = true
			locked_cells.append(cell_data)
			var emitter_sliders: Array[Vector2i]
			if receiver_cells.has(cell_coord):
				emitter_sliders = receiver_cells.get(cell_coord)
			emitter_sliders.append(slider_coord)
			receiver_cells[cell_coord] = emitter_sliders

	await Engine.get_main_loop().process_frame
	return move_counter


## Applies the effects of normal and change-sign sliders to the grid.
## @param normal_sliders An array of coordinates for normal sliders.
## @param change_sliders An array of coordinates for change-sign sliders.
## @param filtered The dictionary of all filtered sliders.
## @param receiver_cells A dictionary mapping cell coordinates to arrays of slider
## 		  coordinates that affect them.
## @return The number of moves added by normal and change-sign sliders.
func _apply_normal_sliders(
	normal_sliders: Array[Vector2i],
	change_sliders: Array[Vector2i],
	filtered: Dictionary[Vector2i, RandomizerSlider],
	receiver_cells: Dictionary[Vector2i, Array]
) -> int:
	var move_counter: int = 0
	var slider_options := _context.options.slider_opt

	if !change_sliders.is_empty():
		normal_sliders.append_array(change_sliders)
		normal_sliders.shuffle()

	for slider_coord in normal_sliders:
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.is_none():
			continue
		move_counter += 1
		if slider.is_full():
			if _check_probability(slider_options.full_odd):
				slider.behavior = Constants.Sliders.Behavior.FULL
		for i in range(slider.reached.size()):
			var cell_coord := slider.reached[i]
			var cell_data := _context.level_data.cells_list.get(cell_coord) as CellData
			if cell_data.is_blocked:
				if i == 0:
					move_counter -= 1
					if !_check_probability(slider_options.extension_rules.NONE):
						filtered.erase(slider_coord)
					break
				if _check_probability(slider_options.full_odd_on_stop):
					slider.behavior = Constants.Sliders.Behavior.FULL
				slider.is_stopped = true
				slider.reached.resize(i)
				break
			_apply_slider_effect(cell_data, slider.effect)
			var emitter_sliders: Array[Vector2i]
			if receiver_cells.has(cell_coord):
				emitter_sliders = receiver_cells.get(cell_coord)
			emitter_sliders.append(slider_coord)
			receiver_cells[cell_coord] = emitter_sliders

	await Engine.get_main_loop().process_frame
	return move_counter


## Handles retractable block sliders, potentially adding extra moves.
## @param block_sliders An array of coordinates for block sliders.
## @param filtered The dictionary of all filtered sliders.
## @param locked_cells An array of CellData objects that are temporarily locked.
## @return The number of moves added by retractable block sliders.
func _handle_retractable_sliders(
	block_sliders: Array[Vector2i],
	filtered: Dictionary[Vector2i, RandomizerSlider],
	locked_cells: Array[CellData]
) -> int:
	var move_counter: int = 0
	var slider_options := _context.options.slider_opt
	var stopped_sliders: Dictionary[Vector2i, Vector2i] = {}

	for slider_coord: Vector2i in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		if slider.effect != Constants.Sliders.Effect.BLOCK and slider.is_stopped:
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
				move_counter += 1
				for coord in slider_data.reached:
					var cell_data := _context.level_data.cells_list[coord] as CellData
					cell_data.is_blocked = false
					locked_cells.erase(cell_data)
				for i in range(blocked_sliders.size()):
					var slider := filtered.get(blocked_sliders[i]) as RandomizerSlider
					if i == blocked_sliders.size() - 1:
						slider.behavior = Constants.Sliders.Behavior.FULL
					else:
						move_counter += 1
						if slider.effect != Constants.Sliders.Effect.CHANGE_SIGN:
							for j in range(slider.reached.size(), slider.reachable.size()):
								var cell := (
									_context.level_data.cells_list[slider.reachable[j]] as CellData
								)
								if cell.is_blocked:
									break
								_apply_slider_effect(cell, slider.effect)

	await Engine.get_main_loop().process_frame
	return move_counter


## Finalizes the slider data and updates the level data.
## @param filtered The dictionary of all filtered sliders.
## @param locked_cells An array of CellData objects that are temporarily locked.
func _finalize_sliders(
	filtered: Dictionary[Vector2i, RandomizerSlider], locked_cells: Array[CellData]
) -> void:
	for slider_coord: Vector2i in filtered.keys():
		var slider := filtered.get(slider_coord) as RandomizerSlider
		var slider_data := SliderData.new()
		slider_data.area_effect = slider.effect
		slider_data.area_behavior = slider.behavior
		_context.level_data.slider_list[slider_coord] = slider_data

	for cell_data in locked_cells:
		cell_data.is_blocked = false
		_apply_slider_effect(cell_data, Constants.Sliders.Effect.BLOCK)

	await Engine.get_main_loop().process_frame


## Filters the possible sliders based on the provided options and calculates their extension.
func _get_filtered_sliders(
	possible: Dictionary, result: Dictionary[Vector2i, RandomizerSlider]
) -> void:
	var slider_options := _context.options.slider_opt
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
			while true:
				if slider_count > 1:
					slider_count -= 1
				else:
					break
				if !_check_probability(slider_options.lower_odd):
					break

		"UPPER":
			slider_count = diffusion_range.y
			while true:
				if slider_count < max_diffusion:
					slider_count += 1
				else:
					break
				if !_check_probability(slider_options.upper_odd):
					break

	await Engine.get_main_loop().process_frame
	filterd.shuffle()
	filterd.resize(slider_count)

	var extended_count: int = 0
	for slider_coord: Vector2i in filterd:
		await Engine.get_main_loop().process_frame
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

	if extended_count == 0:
		var slider_data := result.get(result.keys()[0]) as RandomizerSlider
		slider_data.reached = slider_data.reachable
	await Engine.get_main_loop().process_frame


## Applies the effect of a slider to a cell.
func _apply_slider_effect(cell: CellData, area_effect: Constants.Sliders.Effect) -> void:
	match area_effect:
		Constants.Sliders.Effect.ADD:
			cell.value -= 1

		Constants.Sliders.Effect.SUBTRACT:
			cell.value += 1

		Constants.Sliders.Effect.CHANGE_SIGN:
			cell.value *= -1

		Constants.Sliders.Effect.BLOCK:
			match randi_range(1, 2):
				1:
					cell.value -= randi_range(1, 2)
					cell.value = clamp(cell.value, -4, 4)
				2:
					cell.value += randi_range(1, 2)
					cell.value = clamp(cell.value, -4, 4)


## Checks if two sliders are opposite to each other.
func _is_opposite_slider(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return false

	if a.x != b.x:
		if a.x % 2 == b.x % 2:
			return true

	return false


## Gets all possible sliders for the current grid configuration.
func _get_possible_sliders(result: Dictionary[Vector2i, Array]) -> void:
	var size := Vector2i(_context.level_data.width, _context.level_data.height)

	for edge: int in range(4):
		var max_pos := _context.level_data.width if edge % 2 == 0 else _context.level_data.height

		for position: int in range(max_pos):
			var slider_coord := Vector2i(edge, position)
			var reference_cell := _get_slider_reference_cell(size, slider_coord)

			if _context.level_data.cells_list.has(reference_cell):
				var cell_data := _context.level_data.cells_list.get(reference_cell) as CellData

				if !cell_data.is_blocked:
					result[slider_coord] = _get_slider_extension(edge, reference_cell)
			await Engine.get_main_loop().process_frame


## Gets the reference cell for a slider.
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


## Gets the extension of a slider.
func _get_slider_extension(edge: int, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]
	var direction: Vector2i
	var max_extension: int

	match edge:
		0:
			direction = Vector2i.DOWN
			max_extension = _context.level_data.height
		1:
			direction = Vector2i.LEFT
			max_extension = _context.level_data.width
		2:
			direction = Vector2i.UP
			max_extension = _context.level_data.height
		3:
			direction = Vector2i.RIGHT
			max_extension = _context.level_data.width

	result.append(origin)
	for i in range(1, max_extension):
		var coord := origin + direction * i
		if !_context.level_data.cells_list.has(coord):
			break
		var cell := _context.level_data.cells_list.get(coord) as CellData
		if cell.is_blocked:
			break
		result.append(coord)
	return result
