## HoleGenerator
##
## Responsible for creating holes in the grid based on the provided options.
class_name HoleGenerator extends BaseGenerator


func _init(p_context: GenerationContext) -> void:
	super(p_context)


## Creates holes in the grid.
func generate() -> void:
	var empty_cells: Array[Vector2i] = _get_empty_cells()

	while true:
		_remove_holes()
		if _context.options.hole_opt == null:
			return

		var hole_options := _context.options.hole_opt
		var cell_count := _context.level_data.cells_list.size()
		var counter: int = 0

		if hole_options.std_diffusion > 0:
			match _get_rule(hole_options.diffusion_rules):
				"NONE":
					pass
				"LOWER":
					counter = ceili(float(cell_count) / 100 * hole_options.std_diffusion)
					while true:
						if counter > 1:
							counter -= 1
						else:
							break
						if !_check_probability(hole_options.remove_odd):
							break
				"MAX":
					counter = ceili(float(cell_count) / 100 * hole_options.std_diffusion)

		var new_empty_cells: Array[Vector2i] = []

		await Engine.get_main_loop().process_frame
		var cells := _context.level_data.cells_list.keys()
		var origin := cells.pick_random() as Vector2i
		new_empty_cells.append(origin)
		_context.level_data.cells_list.erase(origin)
		counter -= 1

		while counter > 0:
			var adiacent := _get_round_cells(origin, cells)
			if adiacent.is_empty():
				break
			origin = adiacent.pick_random()
			new_empty_cells.append(origin)
			_context.level_data.cells_list.erase(origin)
			counter -= 1

		if not _arrays_equal_unordered(empty_cells, new_empty_cells):
			break


## Fills all empty cells in the grid, effectively removing all holes.
func _remove_holes() -> void:
	for x in range(_context.level_data.width):
		for y in range(_context.level_data.height):
			var coord := Vector2i(x, y)
			if !_context.level_data.cells_list.has(coord):
				_context.level_data.cells_list[coord] = CellData.new()
	await Engine.get_main_loop().process_frame


## Gets the coordinates of all empty cells in the grid.
## @return An array of empty cell coordinates.
func _get_empty_cells() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for x in range(_context.level_data.width):
		for y in range(_context.level_data.height):
			var coord := Vector2i(x, y)
			if !_context.level_data.cells_list.has(coord):
				coords.append(coord)
	return coords


## Gets all the cells surrounding a given cell, including diagonals.
## @param pos The position of the cell.
## @param cells The array of all cells.
## @return An array of surrounding cell coordinates.
func _get_round_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction: Vector2i in [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1),
		Vector2i(-1, 1)
	]:
		var adiacent: Vector2i = pos + direction
		if cells.has(adiacent):
			result.append(adiacent)
	return result


## Checks if two arrays of Vector2i are equal, ignoring the order of elements.
## @param a The first array.
## @param b The second array.
## @return True if the arrays are equal, false otherwise.
func _arrays_equal_unordered(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
	return a.size() == b.size() and a.all(func(v: Vector2i) -> bool: return b.has(v))
