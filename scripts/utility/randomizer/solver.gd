class_name Solver extends Node

# Numero di branch da processare per batch
const MAX_THREADS := 4
const MAX_BRANCHES := 2000

class SliderRange:
	var effect: GlobalConst.AreaEffect
	var behavior: GlobalConst.AreaBehavior
	var reachable: Array[Vector2i]

class Action:
	var cell_affected: Array[Vector2i]
	var effect: GlobalConst.AreaEffect
	var is_applied: bool
	
	func _init(affected: Array[Vector2i], add: bool, cell_effect: GlobalConst.AreaEffect) -> void:
		cell_affected = affected
		is_applied = add
		effect = cell_effect

class SolverState:
	var updated_cell: Dictionary
	var updated_move: Array[Vector3i]
	var score: float

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

	func calculate_heuristic(width: int, height: int) -> void:
		# score last slider if already move
		var last_move := updated_move.back() as Vector3i
		for move: Vector3i in updated_move:
			if move.x == last_move.x and move.y == last_move.y:
				score += 100
				break
		# score each row
		for row in range(height):
			var row_score := 0
			for w in range(width):
				var coord := Vector2i(w, row)
				if updated_cell.has(coord):
					var state := updated_cell.get(coord) as Vector3i
					if state.y == 0:
						row_score = maxi(row_score, abs(state.x))
						# score each cell with value relative to slider affected it
						score += abs(state.x) * state.z
			score += row_score
		# score each column	
		for column in range(width):
			var row_score := 0
			for h in range(height):
				var coord := Vector2i(column, h)
				if updated_cell.has(coord):
					var state := updated_cell.get(coord) as Vector3i
					if state.y == 0:
						row_score = maxi(row_score, abs(state.x))
			score += row_score
			
	func is_solution() -> bool:
		for cell_state: Vector3i in updated_cell.values():
			if cell_state.y == 0 and cell_state.x != 0:
				# not blocked and not zero
				return false
		return true

	# ascending order state by score 
	static func sort_by_score(a: SolverState, b: SolverState) -> bool:
		return a.score < b.score
			
# Move: Vector3i
# x: slider_coord.x
# y: slider_coord.y
# z: last_extesion

# CellState: Vector3i
# x: cell_value
# y: is_blocked
# z: stack_count

# Variabili per thread e sincronizzazione
var threads: Array[Thread]
var mutex: Mutex
# Variabili del solver
var visited: Dictionary
var branches: Array[SolverState]
var new_branches: Array[SolverState]
var sliders: Dictionary
var solution_found := false
var solution_moves: Array[Vector3i]
var _level_size: Vector2i


func _ready() -> void:
	# Inizializza i thread
	for i in range(MAX_THREADS):
		threads.append(Thread.new())
	mutex = Mutex.new()
		

func find_solution(level_data: LevelData) -> Array[Vector3i]:
	var time := Time.get_ticks_msec()
	sliders = _get_sliders_range(level_data)
	var cells := _get_cells_state(level_data.cells_list)
	var moves := 0
	_level_size = Vector2i(level_data.width, level_data.height)
	# first moves
	new_branches = _get_next_branches(cells, [])
	
	while !solution_found:
		moves += 1
		# Aggiorna i branch con i nuovi trovati
		if new_branches.size() > MAX_BRANCHES: 
			print("number of branches found: ", new_branches.size())
			await _process_heuristic_parallel()
			new_branches.sort_custom(SolverState.sort_by_score)
			await get_tree().process_frame
			
		branches = new_branches.slice(0, mini(new_branches.size(), MAX_BRANCHES))
		print("range %d -> %d" % [branches[0].score, branches[-1].score])
		new_branches.clear()
		print("number of branches selected: ", branches.size())
					
		# Avvia thread per processare batch di branch
		await _process_branches_parallel()
		
		# Aspetta che tutti i thread finiscano
		for i in range(threads.size()):
			if threads[i].is_started():
				threads[i].wait_to_finish()
	
		if moves > level_data.moves_left:
			break

	if solution_found:
		print("level solution: ", level_data.moves_left)
		print("Solution found in ", moves, " moves")
		time = Time.get_ticks_msec() - time
		print("Solution milliseconds: ", time)
		print(solution_moves)
		return solution_moves
	else:
		print("No solution found")
		return []


func _process_heuristic_parallel() -> void:
	const BATCH_SIZE := 500
	var counter := 0
	while counter < new_branches.size():
		for i in range(threads.size()):
			# Non avviare thread se non ci sono branch da processare
			if counter >= new_branches.size():
				break
			
			# Crea un batch di branch for each thread
			var batch: Array[SolverState]
			var end := mini(counter + BATCH_SIZE - 1, new_branches.size() - 1)
			batch = new_branches.slice(counter, end)
			counter = end + 1
			
			# Avvia il thread con il batch
			threads[i].start(_thread_calculate_heuristic.bind(batch))
		
		# Aspetta che tutti i thread finiscano
		for i in range(threads.size()):
			if threads[i].is_started():
				threads[i].wait_to_finish()
		await get_tree().process_frame


func _process_branches_parallel() -> void:
	const BATCH_SIZE := 50
	while !branches.is_empty() and !solution_found:
		for i in range(threads.size()):
			# Non avviare thread se non ci sono branch da processare
			if branches.is_empty():
				break
			
			# Crea un batch di branch for each thread
			var batch: Array[SolverState]
			while branches.size() > 0 and batch.size() < BATCH_SIZE:
				batch.append(branches.pop_back())
			
			# Avvia il thread con il batch
			threads[i].start(_thread_process_batch.bind(batch))
			await get_tree().process_frame
		
		# Aspetta che tutti i thread finiscano
		for i in range(threads.size()):
			if threads[i].is_started():
				threads[i].wait_to_finish()
					

func _thread_calculate_heuristic(batch: Array[SolverState]) -> void:
	for branch in batch:
		branch.calculate_heuristic(_level_size.x, _level_size.y)


func _thread_process_batch(batch: Array[SolverState]) -> void:
	for branch in batch:
		if solution_found:
			break
			
		# Controlla se questo branch è una soluzione
		if branch.is_solution():
			mutex.lock()
			solution_found = true
			solution_moves = branch.updated_move.duplicate()
			mutex.unlock()
			break
		
		# Calcola le prossime mosse per questo branch
		var next_branches := _get_next_branches(branch.updated_cell, branch.updated_move)
		
		# Aggiungi i nuovi branch ai risultati locali
		mutex.lock()
		for new_branch in next_branches:
			var grid_hash := _generate_hash(new_branch.updated_cell)
			if not visited.has(grid_hash):
				visited[grid_hash] = true
				new_branches.append(new_branch)
		mutex.unlock()


func _get_next_branches(cell_updated: Dictionary, moves: Array[Vector3i]) -> Array[SolverState]:
	var result: Array[SolverState]
	
	for slider_coord: Vector2i in sliders.keys():
		# Calcola l'ultima estensione e quante volte si è mosso
		var move_count: int = 0
		var prev_extension: int = 0
		for move in moves:
			if move.x == slider_coord.x and move.y == slider_coord.y:
				move_count += 1
				prev_extension = move.z
		
		# Ignora gli slider che sono già stati mossi 2 volte
		if move_count > 1:
			continue
		
		var slider_range := sliders.get(slider_coord) as SliderRange
		
		# Ignora gli slider, esclusi i BLOCK, che sono arrivati alla massima estensione
		if prev_extension == slider_range.reachable.size():
			if slider_range.effect != GlobalConst.AreaEffect.BLOCK:
				continue
			else:
				pass 
		
		# Aggiungi lo stato solver per ogni possibile mossa successiva
		match slider_range.behavior:
			GlobalConst.AreaBehavior.BY_STEP:
				var cell_reachable: Array[Vector2i] = []
				# calcola possibilita di tornare indietro degli slider BLOCK
				if slider_range.effect == GlobalConst.AreaEffect.BLOCK and move_count > 0:
					cell_reachable = slider_range.reachable.slice(0, prev_extension)
					cell_reachable.reverse()
					# Aggiungi uno stato per ogni possibile mossa
					for i in range(cell_reachable.size()):
						var affected := cell_reachable.slice(0, i + 1)
						var new_extesion := prev_extension - i - 1
						var new_moves := _get_new_moves(slider_coord, new_extesion, moves)
						var next_action := Action.new(affected, false, slider_range.effect)
						var new_state := SolverState.new(cell_updated, new_moves, next_action)
						result.append(new_state)
				
				# Ottieni le celle raggiungibili dall'ultima estensione
				cell_reachable.clear()
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
					cell_reachable.append(cell_coord)
				
				# Aggiungi uno stato per ogni possibile mossa
				for i in range(cell_reachable.size()):
					var affected := cell_reachable.slice(0, i + 1)
					var new_extesion := prev_extension + i + 1
					var new_moves := _get_new_moves(slider_coord, new_extesion, moves)
					var next_action := Action.new(affected, true, slider_range.effect)
					var new_state := SolverState.new(cell_updated, new_moves, next_action)
					result.append(new_state)
					
			GlobalConst.AreaBehavior.FULL:
				var affected: Array[Vector2i] = []
				if move_count > 0:
					if slider_range.effect == GlobalConst.AreaEffect.BLOCK:
						affected = slider_range.reachable.slice(0, prev_extension)
						var new_moves := _get_new_moves(slider_coord, 0, moves)
						var next_action := Action.new(affected, false, slider_range.effect)
						var new_state := SolverState.new(cell_updated, new_moves, next_action)
						result.append(new_state)
				else:
					for cell_coord in slider_range.reachable:
						var cell_state := cell_updated.get(cell_coord) as Vector3i
						match slider_range.effect:
							GlobalConst.AreaEffect.BLOCK:
								if cell_state.z > 0:
									break
							_:
								if cell_state.y == 1:
									break						
						affected.append(cell_coord)
					
					if affected.is_empty():
						break
					# Aggiungi stato
					var new_moves := _get_new_moves(slider_coord, affected.size(), moves)
					var next_action := Action.new(affected, true, slider_range.effect)
					var new_state := SolverState.new(cell_updated, new_moves, next_action)
					result.append(new_state)
						
	return result


func _get_new_moves(slider: Vector2i, step: int, moves: Array[Vector3i]) -> Array[Vector3i]:
	var result := moves.duplicate()
	var new := Vector3i(slider.x, slider.y, step)
	result.append(new)
	return result


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
	var hash_data := PackedByteArray()
	for coord: Vector2i in cell_list.keys():
		var cell := cell_list[coord] as Vector3i

		# Normalizza valori per avere sempre positivi
		var cx := coord.x - 2  # (0-3 invece di 2-5)
		var cy := coord.y - 2  # (0-3 invece di 2-5)
		var cell_x := cell.x + 4  # (0-8 invece di -4 a 4)
		var cell_y := cell.y      # (0-1, già ok)
		var cell_z := cell.z      # (0-4, già ok)

		# Codifica in un intero usando bit-shifting
		var compressed := (cx << 10) | (cy << 8) | (cell_x << 4) | (cell_y << 3) | cell_z

		# Aggiunge i byte compressi all'array
		hash_data.append(compressed >> 8)  # Byte alto
		hash_data.append(compressed & 0xFF)  # Byte basso
	return hash_data
