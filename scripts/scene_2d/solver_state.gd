class_name SolverState

class Action:
	var cell_affected: Array[Vector2i]
	var effect: GlobalConst.AreaEffect
	var is_applied: bool

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
	
	
	
