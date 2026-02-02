## BlockGenerator
##
## Responsible for creating blocked cells in the grid based on the provided
## options.
class_name BlockGenerator extends BaseGenerator


func _init(p_context: GenerationContext) -> void:
	super(p_context)


## Creates blocked cells in the grid.
func generate() -> void:
	var blocked_cells: Array[Vector2i] = _get_blocked_cells()

	while true:
		if _context.level_data.cells_list.is_empty():
			_remove_holes()

		_remove_blocks()
		if _context.options.locked_opt == null:
			return

		var blocked_options := _context.options.locked_opt
		var cell_count := _context.level_data.cells_list.size()
		var counter: int = 0

		if blocked_options.std_diffusion > 0:
			match _get_rule(blocked_options.diffusion_rules):
				"NONE":
					pass
				"LOWER":
					counter = ceili(float(cell_count) / 100 * blocked_options.std_diffusion)
					while true:
						if counter > 1:
							counter -= 1
						else:
							break
						if !_check_probability(blocked_options.remove_odd):
							break
				"MAX":
					counter = ceili(float(cell_count) / 100 * blocked_options.std_diffusion)

		await Engine.get_main_loop().process_frame
		var cells := _context.level_data.cells_list.keys()
		var new_blocked_cells: Array[Vector2i] = []

		if counter > 0:
			cells.shuffle()
			while counter > 0:
				var coord := cells.pop_back() as Vector2i
				var cell_data := _context.level_data.cells_list.get(coord) as CellData

				new_blocked_cells.append(coord)
				cell_data.is_blocked = true
				counter -= 1

		await Engine.get_main_loop().process_frame

		# lock orphan cells
		while true:
			var has_horphan: bool
			for coord: Vector2i in cells:
				var adiacents := _get_side_cells(coord, cells)
				var has_adiacent: bool
				for adiacent: Vector2i in adiacents:
					var cell_data := _context.level_data.cells_list.get(coord) as CellData
					if !cell_data.is_blocked:
						has_adiacent = true
						break

				if !has_adiacent:
					var cell_data := _context.level_data.cells_list.get(coord) as CellData
					new_blocked_cells.append(coord)
					cell_data.is_blocked = true
					cells.erase(coord)
					has_horphan = true
					break

			await Engine.get_main_loop().process_frame
			if !has_horphan:
				break

		if not _arrays_equal_unordered(blocked_cells, new_blocked_cells):
			break


## Fills all empty cells in the grid, effectively removing all holes.
func _remove_holes() -> void:
	for x in range(_context.level_data.width):
		for y in range(_context.level_data.height):
			var coord := Vector2i(x, y)
			if !_context.level_data.cells_list.has(coord):
				_context.level_data.cells_list[coord] = CellData.new()
	await Engine.get_main_loop().process_frame


## Resets the 'is_blocked' property of all cells in the grid.
func _remove_blocks() -> void:
	for coord: Vector2i in _context.level_data.cells_list.keys():
		var cell_data := _context.level_data.cells_list.get(coord) as CellData
		cell_data.is_blocked = false
	await Engine.get_main_loop().process_frame


## Gets the coordinates of all blocked cells in the grid.
## @return An array of blocked cell coordinates.
func _get_blocked_cells() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord: Vector2i in _context.level_data.cells_list.keys():
		var cell_data := _context.level_data.cells_list.get(coord) as CellData
		if cell_data.is_blocked:
			coords.append(coord)
	return coords


## Gets the cells adjacent to a given cell (no diagonals).
## @param pos The position of the cell.
## @param cells The array of all cells.
## @return An array of adjacent cell coordinates.
func _get_side_cells(pos: Vector2i, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]
	for direction: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
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
