class_name Solver extends Node

const ITERATION_PER_FRAME := 1000

class SliderRange:
	var effect: GlobalConst.AreaEffect
	var behavior: GlobalConst.AreaBehavior
	var reachable: Array[Vector2i]

class Action:
	var cell_affected: Array[Vector2i]
	var effect: GlobalConst.AreaEffect
	var is_applied: bool


class SolverState:
	var updated_cell: Dictionary
	var updated_move: Array[Vector3i]

	func _init(cell_list: Dictionary, moves: Array[Vector3i], next_action: Action) -> void:
		updated_cell = cell_list.duplicate()
		updated_move = moves
		
		for coord: Vector2i in next_action.cell_affected:
			var cell_state := updated_cell.get(coord) as Vector3i
			
			# stack update
			cell_state.z = cell_state.z + 1 if next_action.is_applied else cell_state.z - 1
					
			# apply effect
			match next_action.effect:
				GlobalConst.AreaEffect.ADD:
					cell_state.x = cell_state.x + 1 if next_action.is_applied else cell_state.x - 1
				GlobalConst.AreaEffect.SUBTRACT:
					cell_state.x = cell_state.x - 1 if next_action.is_applied else cell_state.x + 1
				GlobalConst.AreaEffect.CHANGE_SIGN:
					cell_state.x *= -1
				GlobalConst.AreaEffect.BLOCK:
					cell_state.y = int(next_action.is_applied)
					
			updated_cell[coord] = cell_state

	func is_solution() -> bool:
		for cell_state: Vector3i in updated_cell.values():
			if cell_state.y == 0 and cell_state.x != 0:
				# not blocked and not zero
				return false
		return true

# Move: Vector3i
# x: slider_coord.x
# y: slider_coord.y
# z: last_extesion

# CellState: Vector3i
# x: cell_value
# y: is_blocked
# z: stack_count

var visited: Dictionary
var branches: Array[SolverState]
var sliders: Dictionary
var iteration := 0


func find_solution(level_data: LevelData) -> void:
	var time := Time.get_ticks_msec()
	sliders = _get_sliders_range(level_data)
	var cells := _get_cells_state(level_data.cells_list)
	await get_tree().process_frame
	# first moves
	await _calculate_next_move(cells, [])
	
	while true:
		if branches.is_empty():
			print("no solution")
			return
		
		print("branch number: ", branches.size())
		# check solved
		for branch in branches:
			if branch.is_solution():
				print("solution moves: ", branch.updated_move.size())
				time = Time.get_ticks_msec() - time
				print("solution milliseconds: ", time)
				return
						
		# next moves
		var old_branches := branches.duplicate()
		branches.clear()
		await get_tree().process_frame
		for branch: SolverState in old_branches:
			await _calculate_next_move(branch.updated_cell, branch.updated_move)
		

func _calculate_next_move(cell_updated: Dictionary, moves: Array[Vector3i]) -> void:
	for slider_coord: Vector2i in sliders.keys():		
		# calculate last extension and move count
		var move_count: int = 0
		var prev_extension: int = 0
		for move in moves:
			if move.x == slider_coord.x and move.y == slider_coord.y:
				move_count += 1
				prev_extension = move.z
		
		# ignore sliders that have already been moved 2 times
		if move_count > 1:
			continue
				
		var slider_range := sliders.get(slider_coord) as SliderRange
			
		# full extension reached
		if prev_extension == slider_range.reachable.size():
			#TODO: handle slider block retract
			continue
			
		# add solver state for each possible next move
		match slider_range.behavior:
			GlobalConst.AreaBehavior.BY_STEP:
				var cell_rechable: Array[Vector2i]
				
				# get possible cell rechable from last extesion
				for i in range(prev_extension, slider_range.reachable.size()):
					var cell_coord := slider_range.reachable[i]
					var cell_state := cell_updated.get(cell_coord) as Vector3i
					match slider_range.effect:
						GlobalConst.AreaEffect.BLOCK:
							if cell_state.z > 0:
								break
						_:
							if cell_state.y == 1:
								break						
					cell_rechable.append(cell_coord)
					
				# add a state for each possible move
				for i in range(cell_rechable.size()):
					var cell_affected: Array[Vector2i]
					for n in range(i + 1):
						cell_affected.append(cell_rechable[n])
					var new_move: Vector3i
					new_move.x = slider_coord.x
					new_move.y = slider_coord.y
					new_move.z = prev_extension + i + 1
					var new_moves := moves.duplicate(true)
					new_moves.append(new_move)
					var next_action := Action.new()
					next_action.cell_affected = cell_affected
					next_action.is_applied = true
					next_action.effect = slider_range.effect
					var new_state := SolverState.new(cell_updated, new_moves, next_action)
					await _try_add_state(new_state)	
						
			GlobalConst.AreaBehavior.FULL:
				# try reach max extesion
				if move_count == 0:
					var cell_affected: Array[Vector2i]
					
					for cell_coord in slider_range.reachable:
						var cell_state := cell_updated.get(cell_coord) as Vector3i						
						match slider_range.effect:
							GlobalConst.AreaEffect.BLOCK:
								if cell_state.z > 0:
									break
							_:
								if cell_state.y == 1:
									break
						
						cell_affected.append(cell_coord)					
					# add state	
					if !cell_affected.is_empty():
						var new_move: Vector3i
						new_move.x = slider_coord.x
						new_move.y = slider_coord.y
						new_move.z = cell_affected.size()
						var new_moves := moves.duplicate(true)
						new_moves.append(new_move)
						var next_action := Action.new()
						next_action.cell_affected = cell_affected
						next_action.is_applied = true
						next_action.effect = slider_range.effect
						var new_state := SolverState.new(cell_updated, new_moves, next_action)
						await _try_add_state(new_state)


func _try_add_state(state: SolverState) -> void:
	# check state alredy visited
	var grid_hash := _generate_hash(state.updated_cell)
	if !visited.has(grid_hash):
		visited[grid_hash] = true
		branches.append(state)
	iteration += 1
	if iteration % ITERATION_PER_FRAME == 0:
		print("end frame")
		await get_tree().process_frame


func _get_cells_state(cell_list: Dictionary) -> Dictionary:
	var result: Dictionary
	for cell_coord: Vector2i in cell_list.keys():
		var cell_data := cell_list.get(cell_coord) as CellData
		var cell_state: Vector3i
		cell_state.x = cell_data.value
		cell_state.y = int(cell_data.is_blocked)
		cell_state.z = 0
		result[cell_coord] = cell_state
	return result


func _get_sliders_range(level_data: LevelData) -> Dictionary:
	var result: Dictionary
	for slider_coord: Vector2i in level_data.slider_list.keys():
		var reachable := _get_slider_extension(slider_coord, level_data)
		# slider with no extesion
		if reachable.is_empty():
			continue
		var slider_data := level_data.slider_list.get(slider_coord) as SliderData
		var slider_range := SliderRange.new()
		slider_range.effect = slider_data.area_effect
		slider_range.behavior = slider_data.area_behavior
		slider_range.reachable = reachable
		result[slider_coord] = slider_range
		
	return result


func _get_slider_extension(slider_coord: Vector2i, data: LevelData) -> Array[Vector2i]:
	var result: Array[Vector2i]
	var origin: Vector2i
	var direction: Vector2i
	var max_extension: int

	match slider_coord.x:
		0:
			origin = Vector2i(slider_coord.y, 0)
			direction = Vector2i.DOWN
			max_extension = data.height
		1:
			origin = Vector2i(data.width - 1, slider_coord.y)
			direction = Vector2i.LEFT
			max_extension = data.width
		2:
			origin = Vector2i(slider_coord.y, data.height - 1)
			direction = Vector2i.UP
			max_extension = data.height
		3:
			origin = Vector2i(0, slider_coord.y)
			direction = Vector2i.RIGHT
			max_extension = data.width

	for i in range(max_extension):
		var coord := origin + direction * i
		if !data.cells_list.has(coord):
			break
		var cell := data.cells_list.get(coord) as CellData
		if cell.is_blocked:
			break
		result.append(coord)
	return result


func _generate_hash(cell_list: Dictionary) -> PackedByteArray:
	var hash_data := []
	for coord: Vector2i in cell_list.keys():
		var cell := cell_list[coord] as Vector3i
		hash_data.append(coord.x)
		hash_data.append(coord.y)
		hash_data.append(cell.x)
		hash_data.append(cell.y)
		hash_data.append(cell.z)
	return hash_data
