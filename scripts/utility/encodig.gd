class_name EncodingLevel

const MOVES: Array[String] = [
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


# char 1 = moves_left
# char 2 = grid SIZE
# next chars = cells
# CELL ORDER: from top-left to bottom-right row by row
# OPTIMIZE CELL: more than two equal cells are indicated with a number preceding the letter
# next chars = SLIDER
# SLIDER ORDER: clockwise from top-left
# OPTIMIZE SLIDER: each group of spaces is indicated with a number


func encode(data: LevelData) -> String:
	var encode_data := ""
	var level_size := Vector2i(data.width, data.height)
	encode_data += MOVES[data.moves_left]
	encode_data += _encode_size(level_size)
	encode_data += _encode_cells(data.cells_list, level_size)
	encode_data += _encode_sliders(data.slider_list, level_size)
	return encode_data


func _encode_size(level_size: Vector2i) -> String:
	for key in SIZE.keys():
		if SIZE.get(key) == level_size:
			return key
	return ""
	
	
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
	for edge in range(0, 4):
		var max_pos: int
		max_pos = level_size.x if edge % 2 == 0 else level_size.y
		for pos in range(0, max_pos):
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
			encode_slider += "plus"
		GlobalConst.AreaEffect.SUBTRACT:
			encode_slider += "minus"
		GlobalConst.AreaEffect.CHANGE_SIGN:
			encode_slider += "invert"
		GlobalConst.AreaEffect.BLOCK:
			encode_slider += "block"
	encode_slider += "_"
	match  slider_data.area_behavior:
		GlobalConst.AreaBehavior.FULL:
			encode_slider += "full"
		GlobalConst.AreaBehavior.BY_STEP:
			encode_slider += "bystep"			
	return encode_slider
		

func decode(encode_data: String) -> LevelData:
	var data := LevelData.new()
	var chars := encode_data.split()
	var moves_left := _decode_moves(chars[0])
	if moves_left < 0:
		return null
	data.moves_left = moves_left
	if !SIZE.has(chars[1]):
		return null
	var level_size: Vector2i = SIZE.get(chars[1])
	data.width = level_size.x
	data.height = level_size.y
	var cell_list := _decode_cell_list(chars, level_size)
	if cell_list.is_empty():
		return null
	data.cells_list = cell_list
	var slider_list := _decode_slider_list(chars, level_size)
	if slider_list.is_empty():
		return null
	data.slider_list = slider_list
	return data


func _decode_moves(letter: String) -> int:
	for index in range(0,MOVES.size()):
		if letter == MOVES[index]:
			return index
	return -1
	
	
func _decode_cell_list(_encode_data: PackedStringArray, _level_size: Vector2i) -> Dictionary:
	return {} 

	
func _decode_slider_list(_encode_data: PackedStringArray, _level_size: Vector2i) -> Dictionary:
	return {} 
