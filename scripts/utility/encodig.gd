class_name EncodingLevel

const MOVES: PackedStringArray = [
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q',
	'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
	]
const SIZE: Dictionary = {
	"a" : Vector2i(2,2),
	"b" : Vector2i(2,3),
	"c" : Vector2i(2,4),
	"d" : Vector2i(2,5),
	"f" : Vector2i(3,2),
	"g" : Vector2i(3,3),
	"h" : Vector2i(3,4),
	"i" : Vector2i(3,5),
	"k" : Vector2i(4,2),
	"l" : Vector2i(4,3),
	"m" : Vector2i(4,4),
	"n" : Vector2i(4,5),
	"p" : Vector2i(5,2),
	"q" : Vector2i(5,3),
	"r" : Vector2i(5,4),
	"s" : Vector2i(5,5)
}
const CELL_VALUE: Dictionary = {
	"f" : -4,
	"g" : -3,
	"h" : -2,
	"i" : -1,
	"j" : 0,
	"k" : 1,
	"l" : 2,
	"m" : 3,
	"n" : 4,
}
const CELL_EMPTY := "z"
const CELL_BLOCKED := "x"
const SLIDER: Dictionary = {
	"a" : "plus_bystep",
	"b" : "minus_bystep",
	"c" : "invert_bystep",
	"d" : "block_bystep",
	"i" : "plus_full",
	"j" : "minus_full",
	"k" : "invert_full",
	"l" : "block_full"
}
const ADD_EFFECT := "plus"
const SUBTRACT_EFFECT := "minus"
const CHANGE_SIGN_EFFECT := "invert"
const BLOCK_EFFECT := "block"
const BY_STEP_BEHAVIOR := "bystep"
const FULL_BEHAVIOR := "full"


# char 1 = Moves_left
# char 2 = Grid size
# next chars = Cells
# CELL ORDER: from top-left to bottom-right row by row
# OPTIMIZE CELL: more than two equal cells are indicated with a number preceding the letter
# next chars = Sliders
# SLIDER ORDER: clockwise from top-left
# OPTIMIZE SLIDER: each group of spaces is indicated with a number


func encode(data: LevelData) -> String:
	var encode_data := ""
	var level_size := Vector2i(data.width, data.height)
	encode_data += MOVES[data.moves_left]
	encode_data += SIZE.find_key(level_size)
	encode_data += _encode_cells(data.cells_list, level_size)
	encode_data += _encode_sliders(data.slider_list, level_size)
	return encode_data
	
	
func _encode_cells(cell_list: Dictionary, level_size: Vector2i) -> String:
	var encode_cells := ""
	var last := ""
	var count: int = 0
	for row in range(GlobalConst.MIN_LEVEL_SIZE, level_size.y + 1):
		for column in range(GlobalConst.MIN_LEVEL_SIZE, level_size.x + 1):
			var cell_coord := Vector2i(column,row)
			var current := ""
			if cell_list.has(cell_coord):
				var cell := cell_list.get(cell_coord) as CellData
				if cell.is_blocked:
					current = CELL_BLOCKED
				else:
					current = CELL_VALUE.find_key(cell.value)
			else:
				current = CELL_EMPTY
			if current == last:
				count += 1
			else:
				if count > 1:
					encode_cells += String.num_int64(count)
				encode_cells += last
				last = current
	return encode_cells
	
	
func _encode_sliders(slider_list: Dictionary, level_size: Vector2i) -> String:
	var encode_sliders := ""
	var empty_count: int = 0
	for edge in range(4):
		var max_pos: int
		max_pos = level_size.x if edge % 2 == 0 else level_size.y
		for pos in range(max_pos):
			var slider_coord := Vector2i(edge, pos)
			if slider_list.has(slider_coord):
				if empty_count > 0:
					encode_sliders += String.num_int64(empty_count)
					empty_count = 0
				encode_sliders += _encode_slider(slider_list.get(slider_coord))
			else:
				empty_count += 1
	return encode_sliders
	
	
func _encode_slider(slider_data: SliderData) -> String:
	var encode_slider := ""
	match slider_data.area_effect:
		GlobalConst.AreaEffect.ADD:
			encode_slider += ADD_EFFECT
		GlobalConst.AreaEffect.SUBTRACT:
			encode_slider += SUBTRACT_EFFECT
		GlobalConst.AreaEffect.CHANGE_SIGN:
			encode_slider += CHANGE_SIGN_EFFECT
		GlobalConst.AreaEffect.BLOCK:
			encode_slider += BLOCK_EFFECT
	encode_slider += "_"
	match  slider_data.area_behavior:
		GlobalConst.AreaBehavior.FULL:
			encode_slider += FULL_BEHAVIOR
		GlobalConst.AreaBehavior.BY_STEP:
			encode_slider += BY_STEP_BEHAVIOR
	return SLIDER.find_key(encode_slider)
		

func decode(encode_data: String) -> LevelData:
	var data := LevelData.new()
	var moves_left := _decode_moves(encode_data[0])
	if moves_left < 0:
		push_warning("invalid moves")
		return null
	data.moves_left = moves_left
	if !SIZE.has(encode_data[1]):
		push_warning("invalid size")
		return null
	var level_size: Vector2i = SIZE.get(encode_data[1])
	data.width = level_size.x
	data.height = level_size.y
	var cell_list := _decode_cell_list(encode_data, level_size)
	if cell_list.is_empty():
		push_warning("invalid cells")
		return null
	data.cells_list = cell_list
	var slider_list := _decode_slider_list(encode_data, level_size)
	if slider_list.is_empty():
		push_warning("invalid sliders")
		return null
	data.slider_list = slider_list
	return data


func _decode_moves(letter: String) -> int:
	for index in range(MOVES.size()):
		if letter == MOVES[index]:
			return index
	return -1
	
	
func _decode_cell_list(encode_data: String, level_size: Vector2i) -> Dictionary:
	var cell_list: Dictionary
	var cell_count := level_size.x * level_size.y
	var count: int = 0
	var cell_coord := Vector2i.ZERO
	for char_index in range(2,encode_data.length()):
		var char_value := encode_data[char_index]
		if char_value.is_valid_int():
			if count > 0:
				count *= 10
			count += char_value.to_int()
		else:
			count = maxi(1,count)
			cell_count -= count
			if cell_count < 0:
				return {}
			for i in range(count):
				if char_value != CELL_EMPTY:
					var cell := CellData.new()
					if char_value == CELL_BLOCKED:
						cell.is_blocked = true
					else:
						cell.value = CELL_VALUE.get(char_value)
					cell_list[cell_coord] = cell
				cell_coord = _get_next_cell_coord(cell_coord, level_size.x)
			count = 0
			if cell_count == 0:
				break
	return cell_list


func _get_next_cell_coord(last_coord: Vector2i, level_width: int) -> Vector2i:
	var column := last_coord.x
	var row := last_coord.y
	column += 1
	if column >= level_width:
		column = 0
		row += 1	
	return Vector2i(column, row)

	
func _decode_slider_list(encode_data: String, level_size: Vector2i) -> Dictionary:
	var slider_list: Dictionary
	var slider_count := level_size.x * 2 + level_size.y * 2
	var slider_coord := Vector2i(4, level_size.y)
	var count: int = 0
	for char_index in range(encode_data.length(), 2, -1):
		var char_value := encode_data[char_index]
		if char_value.is_valid_int():
			if count > 0:
				count *= 10
			count += char_value.to_int()
		else:
			if count > 0:
				slider_count -= count
				if slider_count < 0:
					return {}
				slider_coord = _get_prev_slider_coord(slider_coord, level_size, count)
			var slider := SliderData.new()
			var encode_slider_data : String = SLIDER.get(char_value) as String
			match encode_slider_data.split("_")[0]:
				ADD_EFFECT:
					slider.area_effect = GlobalConst.AreaEffect.ADD
				SUBTRACT_EFFECT:
					slider.area_effect = GlobalConst.AreaEffect.SUBTRACT
				CHANGE_SIGN_EFFECT:
					slider.area_effect = GlobalConst.AreaEffect.CHANGE_SIGN
				BLOCK_EFFECT:
					slider.area_effect = GlobalConst.AreaEffect.BLOCK
			match encode_slider_data.split("_")[1]:
				FULL_BEHAVIOR:
					slider.area_behavior = GlobalConst.AreaBehavior.FULL
				BY_STEP_BEHAVIOR:
					slider.area_behavior = GlobalConst.AreaBehavior.BY_STEP
			slider_list[slider_coord] = slider
			slider_coord = _get_prev_slider_coord(slider_coord, level_size, 1)
			slider_count -= 1
			if slider_count == 0:
				break
	return slider_list


func _get_prev_slider_coord(last_coord: Vector2i, level_size: Vector2i, offset: int) -> Vector2i:
	var edge := last_coord.x
	var pos := last_coord.y
	while offset == 0:
		pos -= 1
		if pos < 0:
			edge -= 1
			pos = level_size.x if edge % 2 == 0 else level_size.y
		offset -= 1
	return Vector2i(edge, pos)